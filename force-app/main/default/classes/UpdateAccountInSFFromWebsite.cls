/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 07-07-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/updateAccount')
global with sharing class UpdateAccountInSFFromWebsite {
    @HttpPatch
    global static void updateAccount(){
       RestRequest request = RestContext.request;
    RestResponse response = RestContext.response;
 
    try {
        String reqBody = request.requestBody != null ? request.requestBody.toString() : '';
        System.debug('Request Body ==> ' + reqBody);
 
        Map<String, Object> requestMap = (reqBody != '') ? (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String, Object>();
        System.debug('Request Map ==> ' + requestMap);
 
        
        if (!requestMap.containsKey('crm_account_id')) {
            sendErrorResponse(response, 400, 'Missing mandatory field: crm_account_id');
            return;
        }
 
        String accountId = (String) requestMap.get('crm_account_id');
        List<Account> accountList = [SELECT Id, Name, Phone, Email__c, BillingStreet, BillingCity, BillingPostalCode, BillingState FROM Account WHERE Id = :accountId LIMIT 1];
 
        if (accountList.isEmpty()) {
            sendErrorResponse(response, 400, 'No Account was found with the provided crm_account_id');
            return;
        }
 
        Account a = accountList[0];
 
        
        if (requestMap.containsKey('full_name')) {
            a.Name = (String) requestMap.get('full_name');
        }
 
            
                if (requestMap.containsKey('phone_number')) {
            String phoneNumber = (String) requestMap.get('phone_number');
            if (!Pattern.matches('^\\d{10}$', phoneNumber)) {
                sendErrorResponse(response, 400, 'Invalid phone number. It must be exactly 10 digits.');
                return;
            }

            
            List<Account> existingAccounts = [
                SELECT Id, Name, Phone, Secondary_Phone_Number__c 
                FROM Account 
                WHERE Phone = :phoneNumber 
                AND Id != :accountId 
                LIMIT 1
            ];
            
            if (!existingAccounts.isEmpty()) {
                Account existingAcc = existingAccounts[0];
                existingAcc.Secondary_Phone_Number__c = phoneNumber;
                update existingAcc;

                Map<String, Object> responseMap = new Map<String, Object>();
                Map<String, Object> data = new Map<String, Object>();
                data.put('status code', 200);
                data.put('message', 'Phone number already exists on another Account. Secondary Phone updated for that Account.');
                responseMap.put('data', data);
                response.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
                response.statusCode = 200;
                return;
            }

            
            a.Phone = phoneNumber;
        }

        
        if (requestMap.containsKey('email_address')) {
            String emailAdd = (String) requestMap.get('email_address');
            if (!Pattern.matches('^[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}$', emailAdd)) {
                sendErrorResponse(response, 400, 'Invalid email format.');
                return;
            }
            a.Email__c = emailAdd;
        }
 
       
        if (requestMap.containsKey('billing_address')) {
            Map<String, Object> billingAddress = (Map<String, Object>) requestMap.get('billing_address');
            if (billingAddress.containsKey('address_1')) {
                a.BillingStreet = (String) billingAddress.get('address_1');
                a.ShippingStreet = (String) billingAddress.get('address_1');
            }
            if (billingAddress.containsKey('city')) {
                a.BillingCity = (String) billingAddress.get('city');
                a.ShippingCity = (String) billingAddress.get('city');
            }
            if (billingAddress.containsKey('pin_code')) {
                a.BillingPostalCode = (String) billingAddress.get('pin_code');
                a.ShippingPostalCode = (String) billingAddress.get('pin_code');
            }
            if (billingAddress.containsKey('state')) {
                a.BillingState = (String) billingAddress.get('state');
                a.ShippingState = (String) billingAddress.get('state');
            }
        }
 
        update a;
        System.debug('Updated Account ==> ' + a);
 
        Map<String, Object> responseMap = new Map<String, Object>();
        Map<String, Object> data = new Map<String, Object>();
        data.put('status code', 200);
        data.put('message', 'Account updated successfully');
        responseMap.put('data', data);
        response.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
        response.statusCode = 200;
 
    } catch (Exception e) {
        sendErrorResponse(response, 500, e.getMessage());
        System.debug('Error Occurred ==> ' + e.getMessage());
        System.debug('Error Line Number ==> ' + e.getLineNumber());
    }
    }

    private static void sendErrorResponse(RestResponse response, Integer statusCode, String message) {
    Map<String, Object> responseMap = new Map<String, Object>();
    Map<String, Object> errorMap = new Map<String, Object>();
    errorMap.put('status code', statusCode);
    errorMap.put('message', message);
    responseMap.put('error', errorMap);

    response.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
    response.statusCode = statusCode;
}

    @HttpPost
    global static void updateOrderProduct(){
         RestRequest request = RestContext.request;
    RestResponse response = RestContext.response;

    try {
        String reqBody = request.requestBody != null ? request.requestBody.toString() : '';
        System.debug('Request Body ==> ' + reqBody);

        Map<String, Object> requestMap = (reqBody != '') ?  (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String,Object>();
        System.debug('Request Map ==>' + requestMap);

        String websiteOrderId = requestMap.containsKey('website_orderId') ? (String)requestMap.get('website_orderId') : null;
        String oldSKU = requestMap.containsKey('old_sku') ? (String)requestMap.get('old_sku') : null;
        String newSKU = requestMap.containsKey('new_sku') ? (String)requestMap.get('new_sku') : null;
        String responseId = requestMap.containsKey('id') ? (String)requestMap.get('id') : 'Blank';
        
        if (String.isBlank(websiteOrderId) || String.isBlank(oldSKU) || String.isBlank(newSKU) || String.isBlank(responseId)) {
            Map<String, Object> errorResponse = new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'status code' => 400,
                    'message' => 'Missing required fields: website_orderId, old_sku, or new_sku, or id'
                }
            };
            response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
            response.statusCode = 400;
            return;
        }

        List<Order> orderList = [SELECT Id, Website_Order_Id__c,Pricebook2Id FROM Order WHERE Website_Order_Id__c = :websiteOrderId LIMIT 1];
        if (orderList.isEmpty()) {
            Map<String, Object> errorResponse = new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'status code' => 400,
                    'message' => 'Order not found for given website_orderId'
                }
            };
            response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
            response.statusCode = 400;
            return;
        }

        Order o = orderList[0];

        String pricebook;

        List<OrderItem> orderProductList = [
            SELECT Id,Product2.StockKeepingUnit,PricebookEntryId FROM OrderItem WHERE OrderId = :o.Id AND Product2.StockKeepingUnit = :oldSKU LIMIT 1
        ];

        if (!orderProductList.isEmpty()) {
            pricebook = orderProductList[0].PricebookEntryId;
            System.debug('orderProductList==>'+orderProductList[0]);
            delete orderProductList[0];

           
        
        /*Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
        mail2.setToAddresses(new String[] { 'aniket.k@utilitarianlabs.com' });
        mail2.setSubject('Order Product Deleted');
        mail2.setPlainTextBody('The Order Product for Website Order ID: ' + websiteOrderId + ' has been successfully updated.\n\n' +
                            'Old SKU: ' + oldSKU + '\n' +
                            'New SKU: ' + newSKU + '\n' +
                            'Response ID: ' + responseId + '\n\n' +
                            'Thank you.');
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail2 });
        System.debug('Send Email Result: ' + results[0].isSuccess());*/
        //upto here 
            
        }
       

        List<Product2> productList = [SELECT Id,StockKeepingUnit FROM Product2 WHERE StockKeepingUnit = :newSKU LIMIT 1];
        if (productList.isEmpty()) {
            Map<String, Object> errorResponse = new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'status code' => 400,
                    'message' => 'New SKU not found in Product2'
                }
            };
            response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
            response.statusCode = 400;
            return;
        }
        Product2 newProduct = productList[0];

        List<PricebookEntry> pbeList = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :newProduct.Id AND Pricebook2Id = :o.Pricebook2Id 
                                               AND IsActive = true LIMIT 1 ];

        if (pbeList.isEmpty()) {
           
            Map<String, Object> errorResponse = new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'status code' => 400,
                    'message' => 'No active PricebookEntry found for this Product in the Order\'s Pricebook'
                }
            };
            response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
            response.statusCode = 400;
            return;
        }

       // Product2 newProduct = productList[0];

        OrderItem newItem = new OrderItem();
        newItem.Product2Id = newProduct.Id;
        newItem.OrderId = o.Id;
        newItem.Quantity = 1;
        newItem.PricebookEntryId = pbeList[0].Id;
        newItem.UnitPrice = pbeList[0].UnitPrice;
        newitem.Website_Response_Id__c=responseId;
        insert newItem;

        System.debug('newItem==>'+newItem);

        Map<String, Object> successResponse = new Map<String, Object>{
            'data' => new Map<String, Object>{
                'status code' => 200,
                'message' => 'Order product updated successfully'
            }
        };
        response.responseBody = Blob.valueOf(JSON.serializePretty(successResponse));
        response.statusCode = 200;

    } catch (Exception e) {
        System.debug('Error Occured ==> ' + e.getMessage());
        System.debug('Error Line Number Is ==> ' + e.getLineNumber());

        Map<String, Object> errorResponse = new Map<String, Object>{
            'data' => new Map<String, Object>{
                'status code' => 500,
                'message' => 'Internal server error: ' + e.getMessage()
            }
        };
        response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
        response.statusCode = 500;
    }
}
@HttpDelete
global static void deleteOrderProduct(){
    RestRequest request = RestContext.request;
    RestResponse response = RestContext.response;
 
     
    try{
        String reqBody = request.requestBody != null ? request.requestBody.toString() : '';
        System.debug('Request Body ==> ' + reqBody);
 
        Map<String, Object> requestMap = (reqBody != '') ? (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String, Object>();
        System.debug('Request Map ==> ' + requestMap);
 
        Object orderIdInPayload = requestMap.get('crm_order_id');
        String orderId = orderIdInPayload!= null ? String.valueof(orderIdInPayload) : 'Not Found';

        Map<String,Object> orderitemDetails = (Map<String,Object>) requestMap.get('order_item_details');

        String productSKU = orderitemDetails.containsKey('product_sku')? String.valueof(orderitemDetails.get('product_sku') ): 'Not Found';

        List<OrderItem> orderItemList= [SELECT id,OrderId,Product2.StockKeepingUnit FROM OrderItem WHERE OrderId=: orderId AND Product2.StockKeepingUnit =:productSKU LIMIT 1];
        if(orderItemList.isEmpty()){
            Map<String, Object> successResponse = new Map<String, Object>{
            'data' => new Map<String, Object>{
                'status code' => 400,
                'message' => 'No Order Product Found For the SKU '+productSKU
            }
        };
        response.responseBody = Blob.valueOf(JSON.serializePretty(successResponse));
        response.statusCode = 400;
        }
        OrderItem oi = orderItemList[0];
        Delete oi;

         Map<String, Object> successResponse = new Map<String, Object>{
            'data' => new Map<String, Object>{
                'status code' => 200,
                'message' => 'Order Product is deleted with SKU '+productSKU
            }
        };
        response.responseBody = Blob.valueOf(JSON.serializePretty(successResponse));
        response.statusCode = 200;

    }catch(Exception e){
        System.debug('Error Occured ==>'+e.getMessage());
        System.debug('Error Line Number Is ==>'+e.getLineNumber());
    }
}
@HttpPut
global static void createOrderProductInSF(){
     RestRequest request = RestContext.request;
    RestResponse response = RestContext.response;
    try{
        String reqBody = request.requestBody != null ? request.requestBody.toString() : '';
        System.debug('Request Body ==> ' + reqBody);

        Map<String, Object> requestMap = (reqBody != '') ?  (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String,Object>();
        System.debug('Request Map ==>' + requestMap);

        String websiteOrderId = requestMap.containsKey('website_orderId') ? (String)requestMap.get('website_orderId') : null;
        String SKU = requestMap.containsKey('product_sku') ? (String)requestMap.get('product_sku') : null;
        
        Decimal quantity = requestMap.containsKey('quantity') ? (Decimal)requestMap.get('quantity') : null;

        if (String.isBlank(websiteOrderId) || String.isBlank(SKU) || quantity == null) {
            Map<String, Object> errorResponse = new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'status code' => 400,
                    'message' => 'Missing required fields: website_orderId, SKU, or quantity'
                }
            };
            response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
            response.statusCode = 400;
            return;
        }
       List<Order> orderList = [SELECT Id, Website_Order_Id__c,Pricebook2Id FROM Order WHERE Website_Order_Id__c = :websiteOrderId LIMIT 1];
        if (orderList.isEmpty()) {
            Map<String, Object> errorResponse = new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'status code' => 400,
                    'message' => 'Order not found for given website_orderId'
                }
            };
            response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
            response.statusCode = 400;
            return;
        }
        Order o = orderList[0];

        String pricebook;


        List<Product2> productList = [SELECT Id,StockKeepingUnit FROM Product2 WHERE StockKeepingUnit = :SKU LIMIT 1];
        if (productList.isEmpty()) {
            Map<String, Object> errorResponse = new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'status code' => 400,
                    'message' => 'SKU not found in Product2'
                }
            };
            response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
            response.statusCode = 400;
            return;
        }
        Product2 newProduct = productList[0];

                List<PricebookEntry> pbeList = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :newProduct.Id AND Pricebook2Id = :o.Pricebook2Id 
                                               AND IsActive = true LIMIT 1 ];

        if (pbeList.isEmpty()) {
           
            Map<String, Object> errorResponse = new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'status code' => 400,
                    'message' => 'No active PricebookEntry found for this Product in the Order\'s Pricebook'
                }
            };
            response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
            response.statusCode = 400;
            return;
        }

       // Product2 newProduct = productList[0];

        OrderItem newItem = new OrderItem();
        newItem.Product2Id = newProduct.Id;
        newItem.OrderId = o.Id;
        newItem.Quantity = quantity;
        newItem.PricebookEntryId = pbeList[0].Id;
        newItem.UnitPrice = pbeList[0].UnitPrice;
        insert newItem;

        System.debug('newItem==>'+newItem);

        Map<String, Object> successResponse = new Map<String, Object>{
            'data' => new Map<String, Object>{
                'status code' => 200,
                'message' => 'Order product got inserted successfully'
            }
        };
        response.responseBody = Blob.valueOf(JSON.serializePretty(successResponse));
        response.statusCode = 200;


    }catch(Exception e){
        System.debug('Error Occured==>'+e.getMessage());
        System.debug('Error Line Number Is ==>'+e.getLineNumber());
         Map<String, Object> errorResponse = new Map<String, Object>{
            'data' => new Map<String, Object>{
                'status code' => 500,
                'message' => 'Internal server error: ' + e.getMessage()
            }
        };
        response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
        response.statusCode = 500;
    }
}
}