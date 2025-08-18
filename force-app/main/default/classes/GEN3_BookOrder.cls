@RestResource(urlMapping='/CreateGENOrder')
global class GEN3_BookOrder {
    @HttpPost
    global static void createAccount() { 
        RestRequest req = RestContext.request;
        system.debug(' req ===============>' + req);
        Blob body = req.requestBody;
        try {
            
            String requestString = req.requestBody != null ? req.requestBody.toString() : '';
            system.debug(' requestString ===============>' + requestString);
            if (String.isBlank(requestString)) {
                GEN3_Wrapper.setResponse(400, 'Empty request body', null);
                return;
            }
            
            GEN3_Wrapper.AccountCreation wrp = (GEN3_Wrapper.AccountCreation) JSON.deserialize(requestString,GEN3_Wrapper.AccountCreation.class);
            List<Map<String, Object>> result = new List<Map<String, Object>>();
            Map<String, Object> responseData = new Map<String, Object>();
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);   
            
            if(wrp.Name == null || wrp.Name == '' || String.isBlank(wrp.Name)) {
                GEN3_Wrapper.setResponse(401, 'Please provide Name', null);
                return;
            }
            
            if(wrp.Email == null || wrp.Email == '' || String.isBlank(wrp.Email)) {
                GEN3_Wrapper.setResponse(401, 'Please provide Email', null);
                return;
            }
            
            if(wrp.Phone == null || wrp.Phone == '' || String.isBlank(wrp.Phone)) {
                GEN3_Wrapper.setResponse(401, 'Please provide Phone', null);
                return;
            }
            if (wrp.Phone.length() != 10 || wrp.Phone.startsWith('+91')) {
                GEN3_Wrapper.setResponse(401, 'Phone must be 10 digits and should not include +91', null);
                return;
            }
            if(wrp.pincode == null || wrp.pincode == '' || String.isBlank(wrp.pincode)) {
                GEN3_Wrapper.setResponse(401, 'Please provide pincode', null);
                return;
            }
            if(wrp.Address == null || wrp.Address == '' || String.isBlank(wrp.Address)) {
                GEN3_Wrapper.setResponse(401, 'Please provide pincode', null);
                return;
            }

            String Name = wrp.Name;
            string Email = wrp.Email;
            string Phone = wrp.Phone;
            string pincode = wrp.pincode;
            string Address = wrp.Address;
            
            Map<String,String> mapOfPincodeAndCenterName = new Map<String,String>();
            Map<String, String> mapOfPincodeAndDealerCode = new Map<String, String>();
            Map<String, String> mapOfPincodeAndCityName = new Map<String, String>();
            Map<String, String> mapOfDealerCodeAndCityName = new Map<String, String>();
            
            for (Pin_Code__c grp : [SELECT Id, Dealer_Service_Center__c,Dealer_Service_Center__r.Name,Dealer_Service_Center__r.Center_Code__c,
                                    Dealer_Service_Center__r.Store_Name__c,City__r.Name,Area_Pincode__c FROM Pin_Code__c]) {
                                        mapOfPincodeAndCenterName.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Store_Name__c);
                                        mapOfPincodeAndDealerCode.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Center_Code__c);
                                        mapOfPincodeAndCityName.put(grp.Area_Pincode__c, grp.City__r.Name);
                                        mapOfDealerCodeAndCityName.put(grp.Dealer_Service_Center__r.Center_Code__c, grp.City__r.Name);
                                    }
            
            String DealerCode = mapOfPincodeAndDealerCode.get(pincode);
            String StoreName = mapOfPincodeAndCenterName.get(pincode);
            String CityName = mapOfDealerCodeAndCityName.get(DealerCode);
            
            Account acc = new Account();
            acc.Name = Name;
            acc.Phone = phone;
            acc.BillingPostalCode = pincode;
            acc.ownerId = UserInfo.getUserId();
            acc.Center_Code__c = DealerCode;
            acc.Store_Name__c = StoreName;
            acc.BillingCity = CityName;
            acc.Type = 'Customer';
            acc.Email__c = email;
            acc.BillingStreet = Address;
            insert acc;
            
            Contact con = new Contact();
            con.LastName = Name;
            con.Phone = phone;
            con.AccountId = acc.Id;
            con.Email = email;
            con.MailingStreet = Address;
            insert con;
            
            Opportunity newOpp = new Opportunity(); 
            newOpp.Name = Name;
            newOpp.AccountId = acc.Id;
            newOpp.StageName = 'New';
            newOpp.CloseDate = System.today().addDays(7);
            newOpp.ownerId = UserInfo.getUserId();
            insert newOpp;
            
            OpportunityContactRole ocr = new OpportunityContactRole();
            ocr.OpportunityId = newOpp.Id;
            ocr.ContactId = con.Id;
            ocr.Role = 'Decision Maker';
            ocr.IsPrimary = true;
            insert ocr;
            
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = 'Mobile App',
                Request_Payload__c = JSON.serializePretty(body),
                Response_Payload__c = 'Enquiry Created successfully: ' + newOpp.Id,
                Status__c = 'Success'
            );
            insert logObj;
            
            responseData.put('AccountId', acc.Id);
            responseData.put('ContactId', con.Id);
            responseData.put('OpportunityId', newOpp.Id);
            
            result.add(responseData); 
            GEN3_Wrapper.setResponses(200, 'Success', result);
            
        }
        
        catch (Exception e) {
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = 'Mobile App',
                Request_Payload__c = JSON.serializePretty(body),
                Response_Payload__c = 'Error: ' + e.getMessage(),
                Error_Message__c = 'Exception: ' + e.getMessage(),
                Status__c = 'Failed'
            );
            insert logObj;
            
            System.debug('Error: ' + e.getStackTraceString() + ' Message ====>' + e.getMessage() + ' Line Number ====>' + e.getLineNumber());
            GEN3_Wrapper.setResponse(500, 'Internal server error: ' + e.getMessage(), null);
        }
    }
}