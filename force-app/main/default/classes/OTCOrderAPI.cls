/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/createOTCOrder')
global without sharing class OTCOrderAPI {
   @HttpPost
    global static void createOTCOrderFromWebsite(){
        List<String> productSKUList = new List<String>();
        Map<Id,Product2> IdToProductMap = new Map<Id,Product2>();
        Map<String,Id> skuToProductIdMap = new Map<String,Id>();
        Map<String,Double> productUnitPriceMap = new Map<String,Double>();
        Map<Id,Id> pricebookEntryProductMap = new Map<Id,Id>();
        Set<String> skus = new Set<String>();

        Account dealerAcccount;
        Account customerAccount;
        
        City__c c;
        Id priceBookForOrder; 

        List<OrderItem> orderItems = new List<OrderItem>();

        List<String> paymentTypePicklistValues = new List<String>();


        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        Savepoint sp = Database.setSavepoint();
        try{
            String reqBody = req.requestBody != null ? req.requestBody.toString() : '';
            System.debug('Request Body ==> ' + reqBody);

            Map<String, Object> requestMap = (reqBody != '') ?  (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String,Object>();
            System.debug('Request Map ==>' + requestMap);

            String sellerCode = requestMap.containsKey('seller_code') ? (String)requestMap.get('seller_code') : 'Not Found';
            String crmAccId = requestMap.containsKey('crm_account_id') ? (String)requestMap.get('crm_account_id') : 'Not Found';
            List<Account> dealerAccList = [SELECT Id,Center_Code__c FROM Account WHERE Center_Code__c =:sellerCode LIMIT 1];
            if(dealerAccList.isEmpty()){
                Database.rollback(sp);
                res.statuscode=404;
                res.responseBody = responseUtility('No Dealer Was Found with that Seller Code','404',false);
                return;
            }
            dealerAcccount = dealerAccList[0];

            List<Account> customerAccList = [SELECT Id FROM Account WHERE Id=:crmAccId LIMIT 1];
            if(customerAccList.isEmpty()){
                Database.rollback(sp);
                res.statuscode=404;
                res.responseBody = responseUtility('No Customer Was Found with that crm_account_id','404',false);
                return;
            }
            customerAccount = customerAccList[0];

            List<Object> OrderProducts = (List<Object>)requestMap.get('products') != null? (List<Object>)requestMap.get('products'):null;
            if(OrderProducts.isEmpty()){
                Database.rollback(sp);
                res.statuscode=404;
                res.responseBody = responseUtility('Order Product List Is Empty','404',false);
                return;
            }
            for(Object o : OrderProducts){
                Map<String,Object> skuMap = (Map<String,Object>)o;
                productSKUList.add((String)skuMap.get('product_sku_id'));
            }
            if(!requestMap.containsKey('city')){
                Database.rollback(sp);
                res.statuscode=404;
                res.responseBody = responseUtility('City is a required field','404',false);
            }
            String cityIdentifier = (String)requestMap.get('city');
            List<City__c> cityList = [SELECT Id, Price_Book__c, City_Masking_Name__c, Price_Book__r.IsActive FROM City__c WHERE City_Masking_Name__c =: cityIdentifier OR City_Pincode__c =: cityIdentifier LIMIT 1];
            if(cityList.isEmpty()){
                Database.rollback(sp);
                res.responseBody = responseUtility('No City was Found with the Provided Name ' + cityIdentifier ,'404',false);
                return; 
            }
            c = cityList[0];
            if(String.isBlank(c.Price_Book__c)){
                Database.rollback(sp);
                res.statuscode=404;
                res.responseBody = responseUtility('No Proicebook was Found for the City ' + cityIdentifier ,'404',false);
                return; 
            }
            priceBookForOrder = c.Price_Book__c;
            String orderStatus = requestMap.containsKey('order_status') ? (String)requestMap.get('order_status') : 'Blank Status';
            
            List<String> orderPickListValueForOTC = new List<String>{'Draft','Pre Invoice','Invoice Generation','Completed','Order Cancelled'};
            if(!orderPickListValueForOTC.contains(orderStatus)){
                String availableValue = String.join(orderPickListValueForOTC,', ');
                Database.rollback(sp);
                res.statuscode=404;
                res.responseBody = responseUtility('Bad Value For Order Status, Available Values Are  ' + availableValue ,'404',false);
                return;
            }
            
            Map<String, Object> billing_address = (Map<String, Object>)requestMap.get('billing_address') != null? (Map<String, Object>)requestMap.get('billing_address'):null;
            Map<String, Object> shipping_address = (Map<String, Object>)requestMap.get('shipping_address') != null? (Map<String, Object>)requestMap.get('shipping_address'):null;

            String orderId = (String)requestMap.get('order_id');
            Id otcRecordType = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('OTC').getRecordTypeId();
            List<Order> existingOrder = [SELECT Id,Website_Order_Id__c FROM Order WHERE Website_Order_Id__c=:orderId LIMIT 1];
            if(!existingOrder.isEmpty()){
                Database.rollback(sp);
                res.statuscode=404;
                res.responseBody = responseUtility('Order Already Exists With Order Id ' + orderId ,'404',false);
                return;
            }
            Vehicle v;
            if(requestMap.containsKey('vin')){
                String vin_Number = (String)requestMap.get('vin');
                System.debug('vin_Number==>'+vin_Number);
                List<Vehicle> vehicleList = [SELECT Id,VehicleIdentificationNumber FROM Vehicle WHERE VehicleIdentificationNumber=:vin_Number LIMIT 1];
                System.debug('Vehicle==>'+vehicleList);
                if(vehicleList.isEmpty()){
                    Database.rollback(sp);
                    res.statuscode=404;
                    res.responseBody = responseUtility('No Vehicle Found with VIN ' + vin_Number ,'404',false);
                    return;
                }
                v = vehicleList[0];

            }
            
            Order oTCOrder = new Order(
                recordTypeid = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('OTC').getRecordTypeId(),
                AccountId = customerAccount.Id,
                Dealer__c = dealerAcccount.Id,
                Assigned_Vehicle__c = v != null ? v.Id : null,
                Website_Order_Id__c = (String)requestMap.get('order_id'),
                EffectiveDate = Date.today(),
                // Status = (String)requestMap.get('order_status') != null?(String)requestMap.get('order_status'):'New', 
                Status = 'New', 
                Description = (String)requestMap.get('delivery_timeline_description') != null? (String)requestMap.get('delivery_timeline_description'):'',
                pricebook2Id = priceBookForOrder,
                Notify_By_SMS__c = (Boolean)requestMap.get('notify_by_sms') != null?(Boolean)requestMap.get('notify_by_sms'):false,
                Notify_By_Email__c = (Boolean)requestMap.get('notify_by_email') != null?(Boolean)requestMap.get('notify_by_email'):false,
                BillingStreet = ((String)billing_address.get('address_1') != null ? (String)billing_address.get('address_1') : '') +' '+ ((String)billing_address.get('address_2') != null ? (String)billing_address.get('address_2') : ''),
                BillingCity = (String)billing_address.get('city') != null ? (String)billing_address.get('city') : '',
                BillingState = (String)billing_address.get('state') != null ? (String)billing_address.get('state') : '',
                BillingPostalCode = (String)billing_address.get('pincode') != null ? (String)billing_address.get('pincode') : '',
                BillingCountry = (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India',
                ShippingStreet = ((String)shipping_address.get('address_1') != null ? (String)shipping_address.get('address_1') : '')+ ' '+((String)shipping_address.get('address_2') != null ? (String)shipping_address.get('address_2') : ''),
                ShippingCity = (String)shipping_address.get('city') != null ? (String)shipping_address.get('city') : '',
                ShippingState = (String)shipping_address.get('state') != null ? (String)shipping_address.get('state') : '',
                ShippingPostalCode = (String)shipping_address.get('pincode') != null ? (String)shipping_address.get('pincode') : '',
                ShippingCountry = (String)shipping_address.get('country') != null ? (String)shipping_address.get('country') : 'India',
                City__c = c.Id,
                Order_Source__c='Website'
            );

         
        insert oTCOrder;
          
        
         List<Product2> productList = [SELECT Id, Name,StockKeepingUnit FROM Product2 WHERE StockKeepingUnit IN :productSKUList];
         if(!productList.isEmpty()){
            for(Product2 p : productList){
                skuToProductIdMap.put(p.StockKeepingUnit,p.Id);
                IdToProductMap.put(p.Id,p);
            }
         }
         List<PriceBookEntry> priceBookEntryList = [SELECT Id, Product2Id, PriceBook2Id, UnitPrice FROM PriceBookEntry WHERE Product2Id IN :IdToProductMap.keySet() AND PriceBook2Id =:priceBookForOrder];
         if(!priceBookEntryList.isEmpty()){
            for(PricebookEntry pb : priceBookEntryList){
                productUnitPriceMap.put(pb.Product2Id,pb.UnitPrice);
                pricebookEntryProductMap.put(pb.Product2Id,pb.Id);
            }
         }

         if(!OrderProducts.isempty()){
                For(Object product : OrderProducts){
                    Map<string, Object> productmap = (Map<string, Object>) product;
                    
                    If(skuToProductIdMap.get((string)productmap.get('product_sku_id')) == null){
                        Database.rollback(sp);
                        res.statuscode=404;
                        res.responseBody = responseUtility('Product is not available with SKU '+(string)productmap.get('product_sku_id'),'404',false);
                        return;
                    }else if(pricebookEntryProductMap.get(skuToProductIdMap.get((string)productmap.get('product_sku_id'))) == null){
                        Database.rollback(sp);
                        res.statuscode=404;
                        res.responseBody = responseUtility('Price is not defined for the product with SKU '+(string)productmap.get('product_sku_id'),'404',false);
                        return;
                    }else if((string)productmap.get('product_type') == 'vehicle' || (string)productmap.get('product_type') == 'Vehicle'){
                        Database.rollback(sp);
                        res.statuscode=404;
                        res.responseBody = responseUtility('Vehicle is not allowed in OTC Order','404',false);
                        return;
                    }
                    
                    OrderItem orderItem = new OrderItem(
                    OrderId = oTCOrder.Id,
                    PricebookEntryId = pricebookEntryProductMap.get(skuToProductIdMap.get((String)productmap.get('product_sku_id'))),
                    Product2Id = skuToProductIdMap.get((String)productmap.get('product_sku_id')),
                    Quantity = (Integer)productmap.get('product_qty'), 
                    UnitPrice = productUnitPriceMap.get(skuToProductIdMap.get((String)productmap.get('product_sku_id'))),
                    Order_Item_Id__c = (String)productmap.get('order_item_id'),
                    Status__c = (productmap.containsKey('product_order_status') && productmap.get('product_order_status') != null) ? (String)productmap.get('product_order_status') : '',
                    Offer_Amount__c = (productmap.containsKey('offer_amount') && productmap.get('offer_amount') != null) ? (Double)productmap.get('offer_amount') : 0,
                    Offer_Description__c = (productmap.containsKey('offer_description') && productmap.get('offer_description') != null) ? (String)productmap.get('offer_description') : ''
                );

                    
                    orderItems.add(orderItem);
                }
            }
            if(!orderItems.isEmpty()){
                
                insert orderItems;
                
            }
            
            Map<String, Object> PaymentDetails = (Map<String, Object>)requestMap.get('payment_info') != null? (Map<String, Object>)requestMap.get('payment_info'):null;            
        
            Map<String, Object> payGwyInfo = new Map<String, Object>(); 
            payGwyInfo = (Map<String, Object>)PaymentDetails.get('pay_gwy_info') != null? (Map<String, Object>)PaymentDetails.get('pay_gwy_info'):null;

            Payment__c newPayment = new Payment__c();
            newPayment.Amount__c = (Decimal) PaymentDetails.get('payment_amount') != null?(Decimal) PaymentDetails.get('payment_amount'):0 ;
            newPayment.Bank_Reference_Number__c = (String) payGwyInfo.get('bank_ref_no') != null? (String) payGwyInfo.get('bank_ref_no'):'';
            newPayment.Card_Name__c = (String) payGwyInfo.get('card_name') != null? (String) payGwyInfo.get('card_name'):'';
            newPayment.Mode_Of_Payment__c = (String) payGwyInfo.get('payment_mode')!= null? (String) payGwyInfo.get('payment_mode'):'';
            newPayment.Tracking_Id__c = (String) payGwyInfo.get('tracking_id') != null? (String) payGwyInfo.get('tracking_id'):'';
            newPayment.Payment_Status__c = (String) payGwyInfo.get('status') != null? (String) payGwyInfo.get('status'):'';
            newPayment.Description__c = (String) payGwyInfo.get('failure_message') != null? (String) payGwyInfo.get('failure_message'):''; 
            newPayment.Transaction_Id__c = (String) PaymentDetails.get('payment_id') != null?(String) PaymentDetails.get('payment_id'):'';
            
            
            insert newPayment;
            
                

            Order_Payment__c orderPayment = new Order_Payment__c();
            orderPayment.Order__c = oTCOrder.Id;
            orderPayment.Payments__c = newPayment.Id;
            
           
            If(PaymentDetails.get('payment_type') == null || PaymentDetails.get('payment_type') == ''){
                Database.rollback(sp);
                res.statuscode=404;
                res.responseBody = responseUtility('Required field missing: payment_type','404',false);
                return;
                

            }
            
            List<Schema.PicklistEntry> picklistValues = Order_Payment__c.Type__c.getDescribe().getPicklistValues();
            for (Schema.PicklistEntry picklistValue : picklistValues){
                paymentTypePicklistValues.add(picklistValue.getValue());
            }
            
            If(!paymentTypePicklistValues.contains((String)PaymentDetails.get('payment_type'))){
                String availableValues = String.join(paymentTypePicklistValues, ', ');
                
                Database.rollback(sp);
                res.statuscode=404;
                res.responseBody = responseUtility('Sorry! Unsupported value for payment type (payment_type). Please choose one of the following: ' + availableValues,'404',false);
                return;
                
            }else{
                orderPayment.Type__c = (String) PaymentDetails.get('payment_type');
            }
            
            
            insert orderPayment;
           
         res.statuscode=201;
         res.responseBody = successResponse('OTC Order Is Successfully Created with Salesforce Order Id ' + oTCOrder.Id,'201',true,String.valueof(oTCOrder.Id));   
         
         createLogRecord('OTC Website', reqBody, 'Success', res.responseBody.toString());


        }catch(Exception e){
            Database.rollback(sp);
            res.statuscode=404;
            res.responseBody = responseUtility('Error In Creating OTC Order' + e.getMessage(),'404',false);  
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            
            createLogRecord('OTC Website', req.requestBody.toString(), 'Failed', res.responseBody.toString());

        }
    }
    public static Blob responseUtility(String message,String statusCode, Boolean isSuccess){
        try{
            Map<String,Object> responseBody = new Map<String,Object>();
            Map<String,Object> data = new Map<String,Object>();
            data.put('success', isSuccess);
            data.put('message', message);
            responseBody.put('data', data);
            responseBody.put('status_code', statusCode);

            return Blob.valueOf(JSON.serializePretty(responseBody));

        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            return null;
        }
    }

    public static Blob successResponse(String message,String statusCode, Boolean isSuccess,String orderId){
        try{
            Map<String,Object> responseBody = new Map<String,Object>();
            Map<String,Object> data = new Map<String,Object>();
            data.put('success', isSuccess);
            data.put('message', message);
            data.put('id',orderId);
            responseBody.put('data', data);
            responseBody.put('status_code', statusCode);

            return Blob.valueOf(JSON.serializePretty(responseBody));

        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            return null;
        }
    }
     private static void createLogRecord(String integrationType, String request, String status, String response) {
        
        Integration_log__c logObj = new Integration_log__c();
        logObj.Integration_Type__c = integrationType;
        logObj.Request_Payload__c = request;
        logObj.Response_Payload__c = response;
        logObj.Status__c = status;
        insert logObj;
    }
    
}