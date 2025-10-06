@RestResource(urlMapping='/ManageOrder')
global with sharing class OrderAPI {
    
    @HttpPost
    global static void createStandardOrder() {
        
        Set<String> orderPicklistValues = new Set<String>(); 
        List<OpportunityLineItem> oppItems = new List<OpportunityLineItem>();
        List<String> productSkuIds = new List<String>();
        
        Map<String, Id> mapSkuToProdId = new Map<String, Id>();
        Map<Id, Product2> mapIdToProduct = new Map<Id, Product2>();
        Map<String, Object> response = new Map<String, Object>();
        Map<Id, Double> mapProdIdToPrice = new Map<Id, Double>();
        Map<Id, Id> mapProdIdToPEntryId = new Map<Id, Id>();
        
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        
        Map<String, Object> billing_address = (Map<String, Object>) requestMap.get('billing_address') != null ? (Map<String, Object>) requestMap.get('billing_address') : null;
        Map<String, Object> shipping_address = (Map<String, Object>) requestMap.get('shipping_address') != null ? (Map<String, Object>) requestMap.get('shipping_address') : null;
        Map<String, Object> PaymentDetails = (Map<String, Object>) requestMap.get('payment_info') != null ? (Map<String, Object>) requestMap.get('payment_info') : null;
        Map<String, Object> payGwyInfo = new Map<String, Object>();
        if (PaymentDetails != null) payGwyInfo = (Map<String, Object>) PaymentDetails.get('pay_gwy_info') != null ? (Map<String, Object>) PaymentDetails.get('pay_gwy_info') : null;
        Map<String, Object> loanDetails = (Map<String, Object>) requestMap.get('loan_info') != null ? (Map<String, Object>) requestMap.get('loan_info') : null;
        Map<String, Object> insuranceDetails = (Map<String, Object>) requestMap.get('insurance_info') != null ? (Map<String, Object>) requestMap.get('insurance_info') : null;
        Map<String, Object> subsidyDetails = (Map<String, Object>) requestMap.get('subsidy_info') != null ? (Map<String, Object>) requestMap.get('subsidy_info') : null;
        Map<String, Object> offerDetails = (Map<String, Object>) requestMap.get('offer_info') != null ? (Map<String, Object>) requestMap.get('offer_info') : null;
        Map<String, Object> warrantyDetails = (Map<String, Object>) requestMap.get('warranty_info') != null ? (Map<String, Object>) requestMap.get('warranty_info') : null;
        
        List<Object> OrderProducts = (List<Object>) requestMap.get('products') != null ? (List<Object>) requestMap.get('products') : null;
        
        Opportunity opp;
        Savepoint sp = Database.setSavepoint();
        
        try {
            String customerAccountId = (String) requestMap.get('crm_account_id');

            Map<Id,Account> customerAccNameMap = new Map<Id,Account>([SELECT Name FROM Account WHERE Id=:customerAccountId]);
            System.debug('customerAccNameMap===>'+customerAccNameMap);
            
            if (requestMap.get('seller_code') == null || (String)requestMap.get('seller_code') == '') {
                throw new CustomException('Required field missing: seller_code');
            }
            
            List<Account> customer = new List<Account>();
            List<Account> seller = new List<Account>();
            
            List<Account> sellerAndCustomer = [SELECT Id, Type, Center_Code__c FROM Account
                                              WHERE (Center_Code__c = : (String)requestMap.get('seller_code') AND (Type = 'Dealer' OR Type = 'COCO Store'))
                                                OR Id = : (String)requestMap.get('crm_account_id')];
            for (Account acc : sellerAndCustomer) {
                if (acc.Id == (String)requestMap.get('crm_account_id')) {
                    customer.add(acc);
                } else if (acc.Center_Code__c == (String)requestMap.get('seller_code') && (acc.Type == 'Dealer' || acc.Type == 'COCO Store')) {
                    seller.add(acc);
                }
            }
            
            if (seller.size() == 0) {
                throw new CustomException('Dealer not found! Please check the seller_code');
            }
            
            if (customer.size() == 0) {
                throw new CustomException('Customer account not found! Please check the crm_account_id');
            }
            
            if (customerAccountId == '' || customerAccountId == null) {
                throw new CustomException('Required field missing: seller_code');
            }
            
            if (!requestMap.containsKey('city')) {
                throw new CustomException('Required field missing: city');
            }
            
           
            if (OrderProducts != null && !OrderProducts.isEmpty()) {
                for (Object product : OrderProducts) {
                    Map<String, Object> prodMap = (Map<String, Object>) product;
                    productSkuIds.add((String) prodMap.get('product_sku_id'));
                }
            }
            System.debug('productSkuIds==>' + productSkuIds);
            
            String cityIdentifier = (String)requestMap.get('city');
            String postalCode = (String)billing_address.get('pincode');

            List<Pin_Code__c> pinCodes = [SELECT City__c FROM Pin_Code__c WHERE Area_Pincode__c = :postalCode];

            Set<Id> cityIdsFromPin = new Set<Id>();
            for(Pin_Code__c pc : pinCodes){
                if(pc.City__c != null){
                    cityIdsFromPin.add(pc.City__c);
                }
            }

            List<City__c> cities = [SELECT Id, Price_Book__c, City_Masking_Name__c, Price_Book__r.IsActive 
            FROM City__c 
            WHERE Id IN :cityIdsFromPin];
            
            if (cities.size() <= 0) {
                throw new CustomException('City not found with identifier: ' + (String) requestMap.get('city'));
            } else if (cities[0].Price_Book__c == null) {
                throw new CustomException('No Price Book is associated with the selected city. Please ensure the Price Book is associated before proceeding.');
            } else if (!cities[0].Price_Book__r.IsActive) {
                throw new CustomException('The Price Book associated with the selected city is not active. Please ensure the Price Book is active before proceeding.');
            }
            
            Pricebook2 Pricebook = new Pricebook2();
            
            if (!Test.isRunningTest()) {
                Pricebook = [SELECT Id FROM Pricebook2 WHERE Id = :cities[0].Price_Book__c];
            } else {
                Pricebook = [SELECT Id FROM Pricebook2 LIMIT 1];
            }
            
            
            if (productSkuIds != null && !productSkuIds.isEmpty()) {
                populateProductAndPriceMaps(productSkuIds, Pricebook.Id, mapIdToProduct, mapSkuToProdId, mapProdIdToPrice, mapProdIdToPEntryId);
            }
            System.debug('mapIdToProduct ====>' + mapIdToProduct);
            System.debug('mapSkuToProdId ====>' + mapSkuToProdId);
            System.debug('mapProdIdToPrice ====>' + mapProdIdToPrice);
            System.debug('mapProdIdToPEntryId ====>' + mapProdIdToPEntryId);
            
            
            List<Opportunity> oppListInSystem = [SELECT Id, StageName, AccountId, Order__c,OwnerId,PreferredSeller__c FROM Opportunity WHERE AccountId = : customerAccountId Order By CreatedDate DESC LIMIT 1];
            if (!oppListInSystem.isEmpty()) {
                opp = oppListInSystem[0];
                
                if (opp.StageName != 'Closed Won') {
                    update OpportunityTriggerHandler.getOwnerFromPincodeAndAssignToOpp(oppListInSystem,postalCode);

                    List<OpportunityLineItem> oppItemList = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = : opp.Id];
                    if (!oppItemList.isEmpty()) {
                        delete oppItemList;
                    }
                    
                    
                    
                    if (OrderProducts != null && !OrderProducts.isEmpty()) {
                        for (Object product : OrderProducts) {
                            Map<String, Object> productmap = (Map<String, Object>) product;
                            
                            Id productId = mapSkuToProdId.get((String) productmap.get('product_sku_id'));
                            if (productId == null) {
                                throw new CustomException('Product is not available with SKU ' + (String) productmap.get('product_sku_id'));
                            } else if (mapProdIdToPEntryId.get(productId) == null) {
                                throw new CustomException('Price is not defined for the product with SKU ' + (String) productmap.get('product_sku_id'));
                            }
                            
                            OpportunityLineItem oppItem = new OpportunityLineItem(
                                OpportunityId = opp.Id,
                                PricebookEntryId = mapProdIdToPEntryId.get(productId),
                                Product2Id = productId,
                                Quantity = (Integer) productmap.get('product_qty'),
                                UnitPrice = mapProdIdToPrice.get(productId),
                                Order_Item_Id__c = (String) productmap.get('order_item_id'),
                                Offer_Amount__c = (String) productmap.get('offer_amount') != null ? (String) productmap.get('offer_amount') : '0',
                                Offer_Description__c = (String) productmap.get('offer_description') != null ? (String) productmap.get('offer_description') : ''
                            );
                            
                            oppItems.add(oppItem);
                        }
                    }
                    
                    
                    try {
                        if (!oppItems.isEmpty()) insert oppItems;
                        
                        
                        Payment__c newPayment = new Payment__c();
                        newPayment.Amount__c = PaymentDetails != null && PaymentDetails.get('payment_amount') != null ? (Decimal) PaymentDetails.get('payment_amount') : 0 ;
                        newPayment.Bank_Reference_Number__c = payGwyInfo != null && payGwyInfo.get('bank_ref_no') != null ? (String) payGwyInfo.get('bank_ref_no') : '';
                        newPayment.Card_Name__c = payGwyInfo != null && payGwyInfo.get('card_name') != null ? (String) payGwyInfo.get('card_name') : '';
                        newPayment.Mode_Of_Payment__c = payGwyInfo != null && payGwyInfo.get('payment_mode') != null ? (String) payGwyInfo.get('payment_mode') : '';
                        newPayment.Tracking_Id__c = payGwyInfo != null && payGwyInfo.get('tracking_id') != null ? (String) payGwyInfo.get('tracking_id') : '';
                        newPayment.Payment_Status__c = payGwyInfo != null && payGwyInfo.get('status') != null ? (String) payGwyInfo.get('status') : '';
                        newPayment.Description__c = payGwyInfo != null && payGwyInfo.get('failure_message') != null ? (String) payGwyInfo.get('failure_message') : '';
                        newPayment.Transaction_Id__c = PaymentDetails != null && PaymentDetails.get('payment_id') != null ? (String) PaymentDetails.get('payment_id') : '';
                        newPayment.Enquiry__c = opp.Id;
                        insert newPayment;
                        
                        
                        if (opp.Order__c != null) {
                            Order orderToUpdate = [SELECT Id, AccountId, RecordTypeId, Dealer__c, Website_Order_Id__c, EffectiveDate, Status, Description, Pricebook2Id, Notify_By_SMS__c, Notify_By_Email__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, City__c FROM Order WHERE Id = : opp.Order__c LIMIT 1];
                            
                            Order standardOrder = new Order(
                                Id = orderToUpdate.Id,
                                recordTypeid = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId(),
                                AccountId = (String) requestMap.get('crm_account_id'),
                                Dealer__c = seller[0].Id,
                                Website_Order_Id__c = (String) requestMap.get('order_id'),
                                EffectiveDate = Date.today(),
                                Status = (String) requestMap.get('order_status') != null ? (String) requestMap.get('order_status') : 'Activated',
                                Description = (String) requestMap.get('delivery_timeline_description') != null ? (String) requestMap.get('delivery_timeline_description') : '',
                                Pricebook2Id = Pricebook.Id,
                                Notify_By_SMS__c = (Boolean) requestMap.get('notify_by_sms') != null ? (Boolean) requestMap.get('notify_by_sms') : false,
                                Notify_By_Email__c = (Boolean) requestMap.get('notify_by_email') != null ? (Boolean) requestMap.get('notify_by_email') : false,
                                BillingStreet = billing_address != null ? ((String)billing_address.get('address_1') != null ? (String)billing_address.get('address_1') : '') + ' ' + ((String)billing_address.get('address_2') != null ? (String)billing_address.get('address_2') : '') : null,
                                BillingCity = billing_address != null ? (String)billing_address.get('city') != null ? (String)billing_address.get('city') : '' : '',
                                BillingState = billing_address != null ? (String)billing_address.get('state') != null ? (String)billing_address.get('state') : '' : '',
                                BillingPostalCode = billing_address != null ? (String)billing_address.get('pincode') != null ? (String)billing_address.get('pincode') : '' : '',
                                BillingCountry = billing_address != null ? (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India' : 'India',
                                ShippingStreet = shipping_address != null ? ((String)shipping_address.get('address_1') != null ? (String)shipping_address.get('address_1') : '') + ' ' + ((String)shipping_address.get('address_2') != null ? (String)shipping_address.get('address_2') : '') : null,
                                ShippingCity = shipping_address != null ? (String)shipping_address.get('city') != null ? (String)shipping_address.get('city') : '' : '',
                                ShippingState = shipping_address != null ? (String)shipping_address.get('state') != null ? (String)shipping_address.get('state') : '' : '',
                                ShippingPostalCode = shipping_address != null ? (String)shipping_address.get('pincode') != null ? (String)shipping_address.get('pincode') : '' : '',
                                ShippingCountry = shipping_address != null ? (String)shipping_address.get('country') != null ? (String)shipping_address.get('country') : 'India' : 'India',
                                City__c = cities[0].Id
                            );
                            
                            
                            List<Schema.PicklistEntry> picklistValuez = Order.Status.getDescribe().getPicklistValues();
                            for (Schema.PicklistEntry picklistValue : picklistValuez) {
                                orderPicklistValues.add(picklistValue.getValue());
                            }
                            
                            //Update the order status
                            if (requestMap.get('order_status') != null) {
                                if (!orderPicklistValues.contains((String) requestMap.get('order_status'))) {
                                    String availableValues = String.join(orderPicklistValues, ', ');
                                    throw new CustomException('Sorry! Unsupported value for Order Status. Please choose one of the following: ' + availableValues + '.');
                                } else {
                                    standardOrder.Status = (String) requestMap.get('order_status');
                                }
                            }
                            
                            
                            try {
                                update standardOrder;
                                standardOrder = addOrderDetails(requestMap, standardOrder);
                            } catch (Exception e) {
                                throw new CustomException('Error while inserting Order: ' + e.getMessage());
                            }
                        }
                        
                    } catch (Exception e) {
                        throw new CustomException('Error while creating order products: ' + e.getMessage());
                    }
                    
                } else if (opp.StageName == 'Closed Won') {
                    
                    opp = new Opportunity(
                        // Name = 'Web Order - ' + System.now().format(),
                        Name = customerAccNameMap.get(customerAccountId).Name,
                        AccountId = customerAccountId,
                        StageName = 'New',
                        LeadSource = 'Online',
                        Lead_Secondary_Source__c = 'River Website',
                        CloseDate = System.today().addDays(30),
                        ForecastCategoryName = 'Pipeline'
                    );
                    insert opp;
                    
                    
                    if (OrderProducts != null && !OrderProducts.isEmpty()) {
                        for (Object product : OrderProducts) {
                            Map<String, Object> prodMap = (Map<String, Object>) product;
                           
                        }
                    }
                    
                    if (OrderProducts != null && !OrderProducts.isEmpty()) {
                        List<OpportunityLineItem> newOppItems = new List<OpportunityLineItem>();
                        for (Object product : OrderProducts) {
                            Map<String, Object> productmap = (Map<String, Object>) product;
                            Id productId = mapSkuToProdId.get((String) productmap.get('product_sku_id'));
                            if (productId == null) {
                                throw new CustomException('Product is not available with SKU ' + (String) productmap.get('product_sku_id'));
                            } else if (mapProdIdToPEntryId.get(productId) == null) {
                                throw new CustomException('Price is not defined for the product with SKU ' + (String) productmap.get('product_sku_id'));
                            }
                            
                            OpportunityLineItem oppItem = new OpportunityLineItem(
                                OpportunityId = opp.Id,
                                PricebookEntryId = mapProdIdToPEntryId.get(productId),
                                Product2Id = productId,
                                Quantity = (Integer) productmap.get('product_qty'),
                                UnitPrice = mapProdIdToPrice.get(productId),
                                Order_Item_Id__c = (String) productmap.get('order_item_id'),
                                Offer_Amount__c = (String) productmap.get('offer_amount') != null ? (String) productmap.get('offer_amount') : '0',
                                Offer_Description__c = (String) productmap.get('offer_description') != null ? (String) productmap.get('offer_description') : ''
                            );
                            newOppItems.add(oppItem);
                        }
                        if (!newOppItems.isEmpty()) insert newOppItems;
                    }
                    
                    Payment__c newPayment = new Payment__c();
                    newPayment.Amount__c = PaymentDetails != null && PaymentDetails.get('payment_amount') != null ? (Decimal) PaymentDetails.get('payment_amount') : 0 ;
                    newPayment.Bank_Reference_Number__c = payGwyInfo != null && payGwyInfo.get('bank_ref_no') != null ? (String) payGwyInfo.get('bank_ref_no') : '';
                    newPayment.Card_Name__c = payGwyInfo != null && payGwyInfo.get('card_name') != null ? (String) payGwyInfo.get('card_name') : '';
                    newPayment.Mode_Of_Payment__c = payGwyInfo != null && payGwyInfo.get('payment_mode') != null ? (String) payGwyInfo.get('payment_mode') : '';
                    newPayment.Tracking_Id__c = payGwyInfo != null && payGwyInfo.get('tracking_id') != null ? (String) payGwyInfo.get('tracking_id') : '';
                    newPayment.Payment_Status__c = payGwyInfo != null && payGwyInfo.get('status') != null ? (String) payGwyInfo.get('status') : '';
                    newPayment.Description__c = payGwyInfo != null && payGwyInfo.get('failure_message') != null ? (String) payGwyInfo.get('failure_message') : '';
                    newPayment.Transaction_Id__c = PaymentDetails != null && PaymentDetails.get('payment_id') != null ? (String) PaymentDetails.get('payment_id') : '';
                    newPayment.Enquiry__c = opp.Id;
                    insert newPayment;
                    
                    
                }
                
            } else {
               
                opp = new Opportunity(
                    // Name = 'Web Order - ' + System.now().format(),
                    Name = customerAccNameMap.get(customerAccountId).Name,
                    AccountId = customerAccountId,
                    StageName = 'New',
                    CloseDate = System.today().addDays(30),
                    ForecastCategoryName = 'Pipeline'
                );
                insert opp;
                
                if (OrderProducts != null && !OrderProducts.isEmpty()) {
                    for (Object product : OrderProducts) {
                        Map<String, Object> productmap = (Map<String, Object>) product;
                        
                        Id productId = mapSkuToProdId.get((String) productmap.get('product_sku_id'));
                        if (productId == null) {
                            throw new CustomException('Product is not available with SKU ' + (String) productmap.get('product_sku_id'));
                        } else if (mapProdIdToPEntryId.get(productId) == null) {
                            throw new CustomException('Price is not defined for the product with SKU ' + (String) productmap.get('product_sku_id'));
                        }
                        
                        OpportunityLineItem oppItem = new OpportunityLineItem(
                            OpportunityId = opp.Id,
                            PricebookEntryId = mapProdIdToPEntryId.get(productId),
                            Product2Id = productId,
                            Quantity = (Integer) productmap.get('product_qty'),
                            UnitPrice = mapProdIdToPrice.get(productId),
                            Order_Item_Id__c = (String) productmap.get('order_item_id'),
                            Offer_Amount__c = (String) productmap.get('offer_amount') != null ? (String) productmap.get('offer_amount') : '0',
                            Offer_Description__c = (String) productmap.get('offer_description') != null ? (String) productmap.get('offer_description') : ''
                        );
                        
                        oppItems.add(oppItem);
                    }
                    if (!oppItems.isEmpty()) insert oppItems;
                }
                
                Payment__c newPayment = new Payment__c();
                newPayment.Amount__c = PaymentDetails != null && PaymentDetails.get('payment_amount') != null ? (Decimal) PaymentDetails.get('payment_amount') : 0 ;
                newPayment.Bank_Reference_Number__c = payGwyInfo != null && payGwyInfo.get('bank_ref_no') != null ? (String) payGwyInfo.get('bank_ref_no') : '';
                newPayment.Card_Name__c = payGwyInfo != null && payGwyInfo.get('card_name') != null ? (String) payGwyInfo.get('card_name') : '';
                newPayment.Mode_Of_Payment__c = payGwyInfo != null && payGwyInfo.get('payment_mode') != null ? (String) payGwyInfo.get('payment_mode') : '';
                newPayment.Tracking_Id__c = payGwyInfo != null && payGwyInfo.get('tracking_id') != null ? (String) payGwyInfo.get('tracking_id') : '';
                newPayment.Payment_Status__c = payGwyInfo != null && payGwyInfo.get('status') != null ? (String) payGwyInfo.get('status') : '';
                newPayment.Description__c = payGwyInfo != null && payGwyInfo.get('failure_message') != null ? (String) payGwyInfo.get('failure_message') : '';
                newPayment.Transaction_Id__c = PaymentDetails != null && PaymentDetails.get('payment_id') != null ? (String) PaymentDetails.get('payment_id') : '';
                newPayment.Enquiry__c = opp.Id;
                insert newPayment;
            }
            
            
            response.put('status', 'Success');
            response.put('message', 'Processed request successfully');
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(response));
            createLogRecord('Order Creation', requestMap, 'Success', response);
            
        } catch (Exception e) {
            System.debug('Error Occured==>' + e.getMessage());
            System.debug('Error Line Number ==>' + e.getLineNumber());
            Database.rollback(sp);
            if (res != null) { handleException(res, e, 'Order Creation', requestMap); }
        }
    }
    
    @HttpPatch
    global static void updateStandardOrder() {
        List<OrderItem> orderItems = new List<OrderItem>();
        Map<String, Id> mapSkuToProdId = new Map<String, Id>();
        Map<Id, Product2> mapIdToProduct = new Map<Id, Product2>();
        Map<String, Object> response = new Map<String, Object>();
        Map<Id, Double> mapProdIdToPrice = new Map<Id, Double>();
        Map<Id, Id> mapProdIdToPEntryId = new Map<Id, Id>();
        List<String> productSkuIds = new List<String>();
        Set<String> orderPicklistValues = new Set<String>();
        
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        
        Map<String, Object> billing_address = (Map<String, Object>) requestMap.get('billing_address') != null ? (Map<String, Object>) requestMap.get('billing_address') : null;
        Map<String, Object> shipping_address = (Map<String, Object>) requestMap.get('shipping_address') != null ? (Map<String, Object>) requestMap.get('shipping_address') : null;
        List<Object> OrderProducts = (List<Object>) requestMap.get('products') != null ? (List<Object>) requestMap.get('products') : null;
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            
            List<Order> existingOrders = [SELECT Id, AccountId, Website_Order_Id__c, Description, Notify_By_SMS__c, Notify_By_Email__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, Is_Integration__c,
                                          BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry FROM Order WHERE Website_Order_Id__c = : (String) requestMap.get('order_id') AND AccountId = : (String) requestMap.get('crm_account_id') LIMIT 1];
            
            
            if (existingOrders.size() == 0) {
                throw new CustomException('Sorry! Order is not available with Order Id: ' + (String) requestMap.get('order_id') + ' and Account Id: ' + (String) requestMap.get('crm_account_id'));
            } else {
                Order existingOrder = existingOrders[0];
                
                
                Order standardOrder = new Order(
                    Id = existingOrder.Id,
                    Description = (String) requestMap.get('delivery_timeline_description') != null ? (String) requestMap.get('delivery_timeline_description') : '',
                    Notify_By_SMS__c = (Boolean) requestMap.get('notify_by_sms') != null ? (Boolean) requestMap.get('notify_by_sms') : false,
                    Notify_By_Email__c = (Boolean) requestMap.get('notify_by_email') != null ? (Boolean) requestMap.get('notify_by_email') : false
                );
                
                if (billing_address != null) {
                    standardOrder.BillingStreet = ((String) billing_address.get('address_1') != null ? (String) billing_address.get('address_1') : '') + ' ' + ((String) billing_address.get('address_2') != null ? (String) billing_address.get('address_2') : '');
                    standardOrder.BillingCity = (String) billing_address.get('city') != null ? (String) billing_address.get('city') : '';
                    standardOrder.BillingState = (String) billing_address.get('state') != null ? (String) billing_address.get('state') : '';
                    standardOrder.BillingPostalCode = (String) billing_address.get('pincode') != null ? (String) billing_address.get('pincode') : '';
                    standardOrder.BillingCountry = billing_address.get('country') != null ? (String) billing_address.get('country') : 'India';
                }
                
                if (shipping_address != null) {
                    standardOrder.ShippingStreet = ((String) shipping_address.get('address_1') != null ? (String) shipping_address.get('address_1') : '') + ' ' + ((String) shipping_address.get('address_2') != null ? (String) shipping_address.get('address_2') : '');
                    standardOrder.ShippingCity = (String) shipping_address.get('city') != null ? (String) shipping_address.get('city') : '';
                    standardOrder.ShippingState = (String) shipping_address.get('state') != null ? (String) shipping_address.get('state') : '';
                    standardOrder.ShippingPostalCode = (String) shipping_address.get('pincode') != null ? (String) shipping_address.get('pincode') : '';
                    standardOrder.ShippingCountry = shipping_address.get('country') != null ? (String) shipping_address.get('country') : 'India';
                }
                
                
                List<Schema.PicklistEntry> picklistValues = Order.Status.getDescribe().getPicklistValues();
                for (Schema.PicklistEntry picklistValue : picklistValues) {
                    orderPicklistValues.add(picklistValue.getValue());
                }
                
                
                if (requestMap.get('order_status') != null) {
                    if (!orderPicklistValues.contains((String) requestMap.get('order_status'))) {
                        String availableValues = String.join(orderPicklistValues, ', ');
                        throw new CustomException('Sorry! Unsupported value for Order Status. Please choose one of the following: ' + availableValues + '.');
                    } else {
                        standardOrder.Status = (String) requestMap.get('order_status');
                    }
                }
                
                
                standardOrder.Is_Integration__c = !existingOrder.Is_Integration__c;
                
                
                standardOrder = addOrderDetails(requestMap, standardOrder);
                
              
                try { update standardOrder; } catch (Exception e) { throw new CustomException('Error while updating Order: ' + e.getMessage()); }
                
                
                List<OrderItem> Items = [SELECT Id, Status__c, Order_Item_Id__c, OrderId FROM OrderItem WHERE OrderId = : existingOrder.Id];
                
                Map<String, OrderItem> mapExtIdToItem = new Map<String, OrderItem>();
                if (Items.size() > 0) {
                    for (OrderItem Item : Items) {
                        mapExtIdToItem.put(Item.Id, Item);
                    }
                }
                
                
                if (OrderProducts != null) {
                    for (Object product : OrderProducts) {
                        Map<String, Object> productmap = (Map<String, Object>) product;
                        if (mapExtIdToItem.get((String) productmap.get('order_item_id')) == null) {
                            throw new CustomException('Order product is not present with the specified Id: ' + (String) productmap.get('order_item_id'));
                        } else {
                            OrderItem orderItem = new OrderItem(
                                Id = mapExtIdToItem.get((String) productmap.get('order_item_id')).Id,
                                Status__c = (String) productmap.get('product_order_status')
                            );
                            if (!orderItems.contains(orderItem)) orderItems.add(orderItem);
                        }
                    }
                }
                
                
                Database.update(orderItems, false);
                
                
                response.put('status', 'Success');
                response.put('order_id', standardOrder.Id);
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(response));
                
                
                createLogRecord('Order Update', requestMap, 'Success', response);
            }
            
        } catch (Exception e) {
            System.debug('errror occured while updating the orde item>>' + e);
            Database.rollback(sp);
            if (res != null) { handleException(res, e, 'Order Update', requestMap); }
        }
    }
    
    /*********************************************************************************************************************************************/
    
   
    private static void createLogRecord(String integrationType, Map<String, Object> request, String status, Map<String, Object> response) {
        Integration_log__c logObj = new Integration_log__c();
        logObj.Integration_Type__c = integrationType;
        logObj.Request_Payload__c = JSON.serializePretty(request);
        logObj.Response_Payload__c = JSON.serializePretty(response);
        logObj.Status__c = status;
        insert logObj;
    }
    
    /*************************************************************************************************************************************************/
    
    
    private static void handleException(RestResponse res, Exception e, String integrationType, Map<String, Object> requestMap) {
        if (res != null) {
            Map<String, Object> response = new Map<String, Object>();
            response.put('status', 'Error');
            response.put('message', e.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(response));
            
            //Log Obj creation
            createLogRecord(integrationType, requestMap, 'Failed', response);
        }
    }
    
    /***************************************************************************************************************************************************/
    
    private static void populateProductAndPriceMaps(List<String> skuIds, Id pricebookId,
                                                    Map<Id, Product2> mapIdToProduct,
                                                    Map<String, Id> mapSkuToProdId,
                                                    Map<Id, Double> mapProdIdToPrice,
                                                    Map<Id, Id> mapProdIdToPEntryId) {
        if (skuIds == null || skuIds.isEmpty()) return;
        
        
        for (Product2 prod : [SELECT Id, Name, StockKeepingUnit FROM Product2 WHERE StockKeepingUnit IN : skuIds]) {
            mapIdToProduct.put(prod.Id, prod);
            if (prod.StockKeepingUnit != null) {
                mapSkuToProdId.put(prod.StockKeepingUnit, prod.Id);
            }
        }
        
        
        if (!mapIdToProduct.keySet().isEmpty()) {
            for (PricebookEntry pre : [SELECT Id, Product2Id, PriceBook2Id, UnitPrice FROM PricebookEntry WHERE Product2Id IN : mapIdToProduct.keySet() AND PriceBook2Id = : pricebookId]) {
                mapProdIdToPrice.put(pre.Product2Id, pre.UnitPrice);
                mapProdIdToPEntryId.put(pre.Product2Id, pre.Id);
            }
        }
    }
    
    /***************************************************************************************************************************************************/
    
    public static Order addOrderDetails(Map<String, Object> requestMap, Order standardOrder) {
        
        Map<String, Object> loanDetails = (Map<String, Object>) requestMap.get('loan_info') != null ? (Map<String, Object>) requestMap.get('loan_info') : null;
        Map<String, Object> insuranceDetails = (Map<String, Object>) requestMap.get('insurance_info') != null ? (Map<String, Object>) requestMap.get('insurance_info') : null;
        Map<String, Object> subsidyDetails = (Map<String, Object>) requestMap.get('subsidy_info') != null ? (Map<String, Object>) requestMap.get('subsidy_info') : null;
        Map<String, Object> offerDetails = (Map<String, Object>) requestMap.get('offer_info') != null ? (Map<String, Object>) requestMap.get('offer_info') : null;
        Map<String, Object> warrantyDetails = (Map<String, Object>) requestMap.get('warranty_info') != null ? (Map<String, Object>) requestMap.get('warranty_info') : null;
        
        
       
        if (loanDetails != null && (String) loanDetails.get('finance_code') != null) {
            
            List<Finance__c> finance = [SELECT id, Name From Finance__c WHERE Finance_Code__c = : (String) loanDetails.get('finance_code') LIMIT 1];
            
            if (finance.size() == 0) { throw new CustomException('Sorry! No Finace provider record found'); }
            else {
                standardOrder.Finance__c = finance[0].Id;
                standardOrder.Financed_Amount__c = loanDetails.get('amount') != null ? (Double) loanDetails.get('amount') : 0;
                standardOrder.Tenure__c = loanDetails.get('tenure') != null ? (Double) loanDetails.get('tenure') : 0;
                standardOrder.Tenure_Type__c = (String) loanDetails.get('tenure_type') != null ? (String) loanDetails.get('tenure_type') : 'Year';
                standardOrder.Approval_Status__c = true;
                standardOrder.Loan_Start_Date__c = System.today();
                standardOrder.EMI_Amount__c = loanDetails.get('emi_amount') != null ? (Double) loanDetails.get('emi_amount') : 0;
            }
        }
        
       
        if (insuranceDetails != null && (String) insuranceDetails.get('insurer_code') != null) {
            
            List<Insurance__c> insurance = [SELECT id, Name From Insurance__c WHERE Insurer_Code__c = : (String) insuranceDetails.get('insurer_code') LIMIT 1];
            
            if (insurance.size() == 0) {
                throw new CustomException('Sorry! No Insurance provider record found');
            } else {
                standardOrder.Insurance__c = insurance[0].Id;
                standardOrder.Insurance_Amount__c = insuranceDetails.get('amount') != null ? (Double) insuranceDetails.get('amount') : 0;
            }
        }
        
        
        if (subsidyDetails != null && subsidyDetails.get('eligible_for_subsidy') != null && (Boolean) subsidyDetails.get('eligible_for_subsidy') != false) {
            
            List<Subsidy__c> subsidies = [SELECT id, Name From Subsidy__c WHERE Subsidy_Code__c = : (String) subsidyDetails.get('subsidy_code') LIMIT 1];
            
            if (subsidies.size() == 0) { throw new CustomException('Sorry! No subidy details found'); }
            else {
                standardOrder.Subsidy__c = subsidies[0].Id;
                standardOrder.Subsidy_Amount__c = subsidyDetails.get('amount') != null ? (Double) subsidyDetails.get('amount') : 0;
                
                standardOrder.Eligible_For_Subsidy__c = subsidyDetails.get('eligible_for_subsidy') != null ? (Boolean) subsidyDetails.get('eligible_for_subsidy') : false;
            }
        }
        
       
        if (offerDetails != null && offerDetails.get('offer_amount') != null) {
            standardOrder.Offers_Amount__c = offerDetails.get('offer_amount') != null ? (Double) offerDetails.get('offer_amount') : 0;
            standardOrder.Offer_description__c = offerDetails.get('offer_description') != null ? (String) offerDetails.get('offer_description') : '';
        }
        
        
        if (warrantyDetails != null && warrantyDetails.get('warranty_amount') != null) {
            standardOrder.Warranty_Amount__c = warrantyDetails.get('warranty_amount') != null ? (Double) warrantyDetails.get('warranty_amount') : 0;
            standardOrder.Extended_Warranty__c = warrantyDetails.get('is_extended') != null ? (Boolean) warrantyDetails.get('is_extended') : false;
        }
        
        return standardOrder;
    }
    /***************************************************************************************************************************************************/
    
    public class CustomException extends Exception {}
}