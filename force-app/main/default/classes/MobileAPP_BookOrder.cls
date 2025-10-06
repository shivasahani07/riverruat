@RestResource(urlMapping='/CreateOrder')
global class MobileAPP_BookOrder {
    @HttpPost
    global static void createOrder() { 
        RestRequest req = RestContext.request;  
        system.debug(' req ===============>' + req);
        Blob body = req.requestBody;
        try {
            String requestString = req.requestBody != null ? req.requestBody.toString() : '';
            system.debug(' requestString ===============>' + requestString);
            if (String.isBlank(requestString)) {
                MobileApp_Wrapper.setResponse(400, 'Empty request body', null);
                return;
            } 
            
            MobileApp_Wrapper.MobileApp_BookOrder wrp = 
                (MobileApp_Wrapper.MobileApp_BookOrder) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_BookOrder.class
                );
            
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);    
            
            String OrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
            
            if(wrp.UserId == null || String.isBlank(wrp.UserId) || wrp.UserId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide UserId', null);
                return;
            }
            if(wrp.opportunityId == null || String.isBlank(wrp.opportunityId) || wrp.opportunityId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide opportunityId', null);
                return;
            }
            if(wrp.paymentStatus == null || String.isBlank(wrp.paymentStatus) || wrp.paymentStatus == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide paymentStatus', null);
                return;
            }
            if(wrp.transactionId == null || String.isBlank(wrp.transactionId) || wrp.transactionId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide transactionId', null);
                return;
            }
            if(wrp.PaymentMode == null || String.isBlank(wrp.PaymentMode) || wrp.PaymentMode == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide Payment Mode', null);
                return;
            }
            if(wrp.paymentGateway == null || String.isBlank(wrp.paymentGateway) || wrp.paymentGateway == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide paymentGateway', null);
                return;
            }
            if(wrp.OrderAmount == null) {
                MobileApp_Wrapper.setResponse(401, 'Please provide Order Amount', null);
                return;
            }
            if(wrp.VehicleColor == null || String.isBlank(wrp.VehicleColor) || wrp.VehicleColor == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide Vehicle Color', null);
                return;
            }
            if(wrp.timestamp == null ) {
                MobileApp_Wrapper.setResponse(401, 'Please provide timestamp', null);
                return;
            }
            if(wrp.gatewayResponseMessage == null || String.isBlank(wrp.gatewayResponseMessage) || wrp.gatewayResponseMessage == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide gatewayResponseMessage', null);
                return;
            }
            if(wrp.customerDetails == null) {
                MobileApp_Wrapper.setResponse(401, 'Please provide customerDetails', null);
                return;
            }
            if(wrp.customerDetails.name == null || String.isBlank(wrp.customerDetails.name) || wrp.customerDetails.name == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide Name', null);
                return;
            }
            if(wrp.customerDetails.phone == null || String.isBlank(wrp.customerDetails.phone) || wrp.customerDetails.phone == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide phone', null);
                return;
            }
            
            Map<String, Object> responseData = new Map<String, Object>();
            
            String userId = UserInfo.getUserId();
            String opportunityId = wrp.OpportunityId;
            boolean paymentStatus = wrp.paymentStatus == 'SUCCESS'? true : false;
            String transactionId = wrp.transactionId;
            String paymentMode = wrp.paymentMode;
            String paymentGateway = wrp.paymentGateway;
            Decimal orderAmount = wrp.OrderAmount;
            String vehicleColor = wrp.VehicleColor;
            DateTime timestamp = wrp.timestamp;
            String gatewayResponseMessage = wrp.gatewayResponseMessage;
            String Name = wrp.customerDetails.name;
            String email = wrp.customerDetails.email;
            String phone = wrp.customerDetails.phone;
            system.debug('1=================>');
            
            List<Opportunity> oppList = [SELECT Id, Name, AccountId,Order__c,StageName,Booking_Amount__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            if(oppList.size() > 0){
                if(paymentStatus){  
                    List<Contact> contact;
                    if(oppList[0].AccountId != null){
                        system.debug('AccountId is not null');
                        contact = [SELECT Id, Name, Email FROM Contact WHERE AccountId = :oppList[0].AccountId LIMIT 1];
                        system.debug('contact ====>'+ contact);
                    }
                    
                    User userRec = [SELECT Id,ContactId ,Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                    system.debug('2=================>' + userRec);
                    
                    Pin_Code__c pincode;
                    if(userRec != null && userRec.ContactId != null && userRec.Contact.AccountId != null){
                        pincode = [SELECT Id, City__r.Price_Book__c, Dealer_Service_Center__c FROM Pin_Code__c WHERE Dealer_Service_Center__c = :userRec.Contact.AccountId LIMIT 1];
                        system.debug('3=================>');
                        system.debug('pincode ====>'+ pincode);
                    }
                    
                    Pricebook2 pb;
                    system.debug('pincode.City__r.Price_Book__c ====>'+ pincode.City__r.Price_Book__c);
                    if(pincode != null){
                        pb = [SELECT Id, Name, IsActive, IsStandard FROM Pricebook2 WHERE IsActive = true AND Id = :pincode.City__r.Price_Book__c LIMIT 1];
                        system.debug('4=================>');
                        system.debug('pb ====>'+ pb);
                    }else{
                        pb = [SELECT Id, Name, IsActive, IsStandard FROM Pricebook2 WHERE IsActive = true AND Name = 'Standard Price Book' LIMIT 1];
                        system.debug('5=================>');
                        system.debug('pb ====>'+ pb);
                    }
                    Opportunity opp;
                    opp = [SELECT Id,Pricebook2Id,StageName,booking_Amount__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
                    opp.Pricebook2Id = pb.Id;
                    update opp;
                    
                    PricebookEntry pbe;
                    if(pb != null){
                        pbe = [SELECT Id,UnitPrice FROM PricebookEntry WHERE Product2.Colour__c LIKE: ('%' + vehicleColor + '%') AND Product2.Type__c = 'Vehicle' AND IsActive = true AND Pricebook2Id = :pb.Id LIMIT 1];
                        system.debug('6=================>');
                        system.debug('pbe ====>'+ pbe);   
                    }
                    
                    Product2 prd = [SELECT Id, Name FROM Product2 WHERE Name LIKE :('%' + vehicleColor + '%') LIMIT 1];
                    system.debug('7=================>');
                    
                    OpportunityLineItem oli = new OpportunityLineItem(
                        OpportunityId = opportunityId,
                        PricebookEntryId = pbe.Id,
                        Product2Id = prd.Id,
                        Quantity = 1,
                        UnitPrice = pbe.UnitPrice,
                        Payment_Method__c = PaymentMode
                    );
                    insert oli;
                    system.debug('oli=================>' + oli);
                    system.debug('8=================>');

                    Payment__c pay = new Payment__c();
                    pay.Enquiry__c = opportunityId;
                    pay.Amount__c = orderAmount;
                    pay.Payment_Date__c = Date.today();
                    pay.Payment_Status__c = 'Success';
                    pay.Source_Of_Payment__c = 'In Person';
                    pay.Mode_Of_Payment__c = paymentMode;
                    if(paymentMode == 'Cash'){
                        pay.Transaction_Id__c = String.valueOf(System.now());
                    }else{
                        pay.Transaction_Id__c = transactionId;
                    }
                    Insert pay;

                    List<Order> orderList = [SELECT Id, Name FROM Order WHERE OpportunityId = :opportunityId LIMIT 1];
                    system.debug('Order Created: ' + orderList[0].Id);
                    system.debug('10=================>');

                    if(orderList[0].Id == null) {
                        MobileApp_Wrapper.setResponse(500, 'Order Creation Failed', null);
                    } else {
                        
                        Integration_Log__c logObj = new Integration_Log__c(
                            Integration_Type__c = 'Mobile App',
                            Request_Payload__c = JSON.serializePretty(body),
                            Response_Payload__c = 'Order created successfully: ' + orderList[0].Id,
                            Status__c = 'Success'
                        );
                        insert logObj;
                        
                        responseData.put('OrderId', orderList[0].Id);
                        MobileApp_Wrapper.setResponse(200, 'Order Created Successfully', responseData);
                    }
                }else{
                    MobileApp_Wrapper.setResponse(400, 'Payment Failed', null);
                }
            }else{
                MobileApp_Wrapper.setResponse(400, 'No Data with the lead Id: ', null);
            }
        } catch (Exception e) {
            
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = 'Mobile App',
                Request_Payload__c = JSON.serializePretty(body),
                Response_Payload__c = 'Error: ' + e.getMessage(),
                Error_Message__c = 'Exception: ' + e.getMessage(),
                Status__c = 'Failed'
            );
            insert logObj;
            
            System.debug('Error: ' + e.getStackTraceString() + ' Message ====>' + e.getMessage() + ' Line Number ====>' + e.getLineNumber());
            MobileApp_Wrapper.setResponse(500, 'Internal server error: ' + e.getMessage(), null);
        }
    }
}