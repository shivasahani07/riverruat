/*Expose the API as a REST Resource

Created by Prathap KR

No changes needed in this class if you are using the custom setting in `OAuthHelper`.

*/
@RestResource(urlMapping='/createCarBike360')
global class LeadCreationCarBike360{
    @HttpPost  
    global static string createLeadFromWebsite() {  
        RestRequest req = RestContext.request;  
        RestResponse res = RestContext.response;  
        
        // Parse the request body  
        String requestBody = req.requestBody.toString();  
        Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);  
        
        String fullName = (String) requestBodyMap.get('LastName');  
        String company = (String) requestBodyMap.get('Company');  
        String email = (String) requestBodyMap.get('Email');  
        String phone = (String) requestBodyMap.get('Phone');  
        String city = (String) requestBodyMap.get('City');  
        String postalCode = String.valueOf(requestBodyMap.get('PostalCode'));  
        String dealerCode = (String) requestBodyMap.get('DealerCode');  
        
        try {
            List<Lead> leads = [SELECT Id, LastName, Company, Email, Phone, City, Dealer_Code__c  
                                FROM Lead WHERE Phone = :phone LIMIT 1];  
            
            Lead leadToUpdate;  
            Boolean isNewLead = false;
            if (!leads.isEmpty()) {  
                leadToUpdate = leads[0];  
                
                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = ' Lead Creation',
                    Duplicate_Lead_Phone__c = leads[0].Phone,
                    Request_Payload__c = JSON.serializePretty(requestBodyMap),
                    Response_Payload__c = 'Duplicate Lead Found: ' + leads[0].Id,
                    Lead__c = leads[0].Id
                );
                insert logObj;
            } else {  
                leadToUpdate = new Lead();  
                isNewLead = true;
                leadToUpdate.LeadSource = 'CarBike360';  
            }  
            
            leadToUpdate.LastName = fullName;  
            leadToUpdate.Company = fullName;  
            leadToUpdate.Email = email;  
            leadToUpdate.Phone = phone;  
            leadToUpdate.City = city;  
            leadToUpdate.PostalCode = postalCode;  
            
            Account dealerCodeAccount;  
            if (String.isNotBlank(postalCode)) {  
                String resolvedDealerCode = LeadTriggerHandler.getPreferredStoreByPincode(postalCode);  
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
            
            leadToUpdate.Stores_Name__c = dealerCodeAccount != null ? dealerCodeAccount.Name : '';  
            leadToUpdate.Dealer_Code__c = dealerCodeAccount != null ? dealerCodeAccount.Center_Code__c : dealerCode;  
            
            if (isNewLead) {
                insert leadToUpdate;
                Integration_Log__c successLog = new Integration_Log__c(  
                    Integration_Type__c = 'Lead Creation',  
                    Request_Payload__c = JSON.serializePretty(requestBodyMap),  
                    Response_Payload__c = 'Lead processed successfully: ' + leadToUpdate.Id,  
                    Status__c = 'Success',
                    Lead__c = leadToUpdate.Id
                );  
                insert successLog;  
            } else {
                if (leadToUpdate != null && leadToUpdate.Id != null) {
                    update leadToUpdate;
                }
            }
            
            return 'Lead processed successfully: ' + leadToUpdate.Id;  
            
        } catch (Exception e) {  
            Integration_Log__c logObj = new Integration_Log__c(  
                Integration_Type__c = ' Lead Creation',
                Request_Payload__c = JSON.serializePretty(requestBodyMap),  
                Response_Payload__c = 'Error: ' + e.getMessage(),  
                Error_Messages__c = 'Exception: ' + e.getMessage() + ' at line number ====>' + e.getLineNumber() + ' /createCarBike360',
                Status__c = 'Failed'  
            );  
            insert logObj;  
            System.debug('Error =====>' +  + e.getMessage() + ' at line number ====>' + e.getLineNumber());
            return 'Error: ' + e.getMessage();  
        } 
    }  
}