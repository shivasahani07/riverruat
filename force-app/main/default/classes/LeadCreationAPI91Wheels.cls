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
            // Query existing lead
            List<Lead> leads = [
                SELECT Id, LastName, Company, Email, Phone, City, Dealer_Code__c  
                FROM Lead WHERE Phone = :phone LIMIT 1
            ];  
            
            if (!leads.isEmpty()) {
                // Duplicate found — log and return with 409
                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = ' Lead Creation',
                    Duplicate_Lead_Phone__c = leads[0].Phone,
                    Request_Payload__c = JSON.serializePretty(requestBodyMap),
                    Response_Payload__c = 'Duplicate Lead Found: ' + leads[0].Id,
                    Lead__c = leads[0].Id
                    //Status__c = 'Duplicate'
                );
                insert logObj;
                
                res.statusCode = 409; // Conflict
                return 'Duplicate Lead Found: ' + leads[0].Id;
            }
            
            // Create new lead
            Lead newLead = new Lead();
            newLead.LastName = fullName;  
            newLead.Company = fullName;  
            //newLead.Email = email;  
            newLead.Phone = phone;  
            //newLead.City = city;  
            newLead.PostalCode = postalCode;  
            newLead.LeadSource = '91Wheels';  
            newLead.Dealer_Code__c = dealerCode;
            
            insert newLead;
            
            // Success log
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = ' Lead Creation',
                Request_Payload__c = JSON.serializePretty(requestBodyMap),
                Response_Payload__c = 'Lead created successfully: ' + newLead.Id,
                Status__c = 'Success'
            );
            insert logObj;
            
            res.statusCode = 200;
            return 'Lead created successfully: ' + newLead.Id;
            
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