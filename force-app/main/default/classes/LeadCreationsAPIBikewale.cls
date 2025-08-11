@RestResource(urlMapping='/createLeadBikeWale')  
global class LeadCreationsAPIBikewale {  
    
    @HttpPost  
    global static String createLeadFromWebsite() {  
        
        RestRequest req = RestContext.request;  
        RestResponse res = RestContext.response;  
        
        String requestBody = req.requestBody.toString();  
        System.debug('Request Body ===> ' + requestBody);
        Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);  
        
        // Extract fields from request
        String fullName = (String) requestBodyMap.get('LastName');  
        String company = (String) requestBodyMap.get('Company');  
        String phone = (String) requestBodyMap.get('Phone');  
        String postalCode = String.valueOf(requestBodyMap.get('PostalCode'));  
        String dealerCode = (String) requestBodyMap.get('DealerCode');  
        
        try {
            // Check if a Lead with same phone exists
            List<Lead> leads = [
                SELECT Id, LastName, Company, Email, Phone, City, Dealer_Code__c  
                FROM Lead WHERE Phone = :phone LIMIT 1
            ];  
            
            if (!leads.isEmpty()) {
                // Duplicate found, log and return
                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = ' Lead Creation',
                    Duplicate_Lead_Phone__c = leads[0].Phone,
                    Request_Payload__c = JSON.serializePretty(requestBodyMap),
                    Response_Payload__c = 'Duplicate Lead Found: ' + leads[0].Id,
                    Lead__c = leads[0].Id
                    // Status__c = 'Duplicate'
                );
                insert logObj;
                
                res.statusCode = 409; // Conflict
                return 'Duplicate Lead Found: ' + leads[0].Id;
            }
            
            // Get OwnerId from queue
            Map<String, Id> queueMap = new Map<String, Id>();
            for (Group grp : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']) {
                queueMap.put(grp.DeveloperName, grp.Id);
            }
            System.debug('queueMap populated =========>' + queueMap);
            
            // Create new Lead
            Lead leadToCreate = new Lead();  
            leadToCreate.LastName = fullName;  
            leadToCreate.Company = fullName;  
            leadToCreate.Phone = phone;  
            leadToCreate.PostalCode = postalCode;  
            leadToCreate.LeadSource = 'BikeWale';  
            leadToCreate.OwnerId = queueMap.get('Head_Quarter');  
            
            // Determine Dealer from Postal Code
            Account dealerCodeAccount;
            if (String.isNotBlank(postalCode)) {
                String resolvedDealerCode = LeadTriggerHandler.getPreferredStoreByPincode(postalCode);
                System.debug('📮 Resolved Dealer Code from Postal Code: ' + resolvedDealerCode);
                if (String.isNotBlank(resolvedDealerCode)) {
                    List<Account> dealerAccounts = [
                        SELECT Id, Name, Center_Code__c 
                        FROM Account 
                        WHERE Type = 'Dealer' AND Center_Code__c = :resolvedDealerCode 
                        LIMIT 1
                    ];
                    if (!dealerAccounts.isEmpty()) {
                        dealerCodeAccount = dealerAccounts[0];
                    }
                }
            }
            
            leadToCreate.Stores_Name__c = dealerCodeAccount != null ? dealerCodeAccount.Name : '';
            leadToCreate.Dealer_Code__c = dealerCodeAccount != null ? dealerCodeAccount.Center_Code__c : null;
            
            insert leadToCreate;
            
            // Log success
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = ' Lead Creation',
                Request_Payload__c = JSON.serializePretty(requestBodyMap),
                Response_Payload__c = 'Lead created successfully: ' + leadToCreate.Id,
                Status__c = 'Success'
            );
            insert logObj;
            
            res.statusCode = 200;
            return 'Lead created successfully: ' + leadToCreate.Id;
            
        } catch (Exception e) {
            // Log failure
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