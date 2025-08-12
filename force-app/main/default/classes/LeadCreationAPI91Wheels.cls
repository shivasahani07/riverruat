@RestResource(urlMapping='/createLead91Wheels')
global class LeadCreationAPI91Wheels {
    
    @HttpPost  
    global static String createLeadFromWebsite() {  
        RestRequest req = RestContext.request;  
        RestResponse res = RestContext.response;  
        
        String requestBody = req.requestBody.toString();  
        System.debug('Request Body ===> ' + requestBody);
        
        // Deserialize request
        Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);  
        
        // Extract fields
        String fullName = (String) requestBodyMap.get('LastName');  
        String company = (String) requestBodyMap.get('Company');  
        //String email = (String) requestBodyMap.get('Email');  
        String phone = (String) requestBodyMap.get('Phone');  
        //String city = (String) requestBodyMap.get('City');  
        String postalCode = String.valueOf(requestBodyMap.get('PostalCode'));  
        String dealerCode = (String) requestBodyMap.get('DealerCode');  
        
        try {
            Lead leadToUpdate;  
            // Query existing lead
            List<Lead> leads = [
                SELECT Id, LastName, Company, Email, Phone, City, Dealer_Code__c  
                FROM Lead WHERE Phone = :phone LIMIT 1
            ];  
            
            if (!leads.isEmpty()) {
                leadToUpdate = leads[0];  
                // Duplicate found — log and return with 409
                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = ' Lead Creation',
                    Duplicate_Lead_Phone__c = leads[0].Phone,
                    Source__c = '91Wheels',
                    Request_Payload__c = JSON.serializePretty(requestBodyMap),
                    Response_Payload__c = 'Duplicate Lead Found: ' + leads[0].Id,
                    Lead__c = leads[0].Id
                    //Status__c = 'Duplicate'
                );
                insert logObj;
            }else{
                leadToUpdate = new Lead();  
                leadToUpdate.LeadSource = '91Wheels';
            }

            leadToUpdate.LastName = fullName;
            leadToUpdate.Company = fullName;
            //leadToUpdate.Email = email;
            leadToUpdate.Phone = phone;  
            //leadToUpdate.City = city;
            leadToUpdate.PostalCode = postalCode;
            leadToUpdate.Dealer_Code__c = dealerCode;
            
            if (leadToUpdate.Id != null) {  
                update leadToUpdate;  
            } else {  
                insert leadToUpdate;  
            }
            System.debug('leadToUpdate ===> ' + leadToUpdate);
            
            // Success log
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = ' Lead Creation',
                Source__c = '91Wheels',
                Request_Payload__c = JSON.serializePretty(requestBodyMap),
                Response_Payload__c = 'Lead created successfully: ' + leadToUpdate.Id,
                Status__c = 'Success'
            );
            insert logObj;
            
            res.statusCode = 200;
            return 'Lead created successfully: ' + leadToUpdate.Id;
            
        } catch (Exception e) {
            // Error log
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = ' Lead Creation',
                Request_Payload__c = JSON.serializePretty(requestBodyMap),
                Response_Payload__c = 'Error: ' + e.getMessage(),
                Error_Messages__c = 'Exception: ' + e.getMessage(),
                Status__c = 'Failed'
            );
            insert logObj;
            
            res.statusCode = 500;
            return 'Error: ' + e.getMessage();
        }
    }
}