@RestResource(urlMapping='/createLeadRiverWebsite')  
global class LeadCreationFromRiverWebsite {
    
    @HttpPost  
    global static string createLeadFromWebsite() {  
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;  
        
        // Parse the request body  
        String requestBody = req.requestBody.toString(); 
        System.debug('requestBody == >'+requestBody);
        Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);  
        
        String fullName = (String) requestBodyMap.get('FullName');  
        String company = (String) requestBodyMap.get('Company');  
        String email = (String) requestBodyMap.get('Email');  
        String phone = (String) requestBodyMap.get('Phone');  
        String city = (String) requestBodyMap.get('City');  
        String postalCode = String.valueOf(requestBodyMap.get('PostalCode'));  
        Boolean homeTestRide = (Boolean) requestBodyMap.get('HomeTestRide');  
        Boolean instoreTestdrive = (Boolean) requestBodyMap.get('InstoreTestdrive');
        String utm_source = (String) requestBodyMap.get('utm_source'); 
        Boolean verified = (Boolean) requestBodyMap.get('verified');  
        String startDateTimeStr = (String) requestBodyMap.get('startDateTimeStr');  
        String endDateTimeStr = (String) requestBodyMap.get('endDateTimeStr');  
        Datetime startDateTime;  
        Datetime endDateTime;  
        
        if (startDateTimeStr != null) {  
            startDateTime = Datetime.valueOf(startDateTimeStr);  
        } else {  
            startDateTime = null; 
        }  
        
        if (endDateTimeStr != null) {  
            endDateTime = Datetime.valueOf(endDateTimeStr);  
        } else {  
            endDateTime = null; 
        }  
        
        String dealerCode = (String) requestBodyMap.get('DealerCode');  
        List<Lead> leads = [SELECT Id, LastName, Company, Email, Phone, City,   
                            Test_ride_Start_date__c, Test_ride_end_date__c,   
                            Dealer_Code__c, Home_Test_Ride__c, Instore_Test_drive__c,Utm_Source__c,Verified__c,Status
                            FROM Lead WHERE Phone = :phone LIMIT 1];  
        
        Lead leadToUpdate;  
        Boolean isNewLead = false;
        try {
            if (!leads.isEmpty()) {  
                leadToUpdate = leads[0];  
                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Lead Creation',
                    Duplicate_Lead_Phone__c = leads[0].Phone,
                    Request_Payload__c = JSON.serializePretty(requestBodyMap),
                    Response_Payload__c = 'Duplicate Lead Found: ' + leads[0].Id,
                    Lead__c = leads[0].Id
                );
                insert logObj;
            } else {  
                leadToUpdate = new Lead();  
                isNewLead = true;
                leadToUpdate.LeadSource = 'River Website';
            }  
            
            leadToUpdate.LastName = fullName;  
            leadToUpdate.Company = fullName;  
            leadToUpdate.Email = email;  
            leadToUpdate.Phone = phone;  
            leadToUpdate.City = city;  
            leadToUpdate.PostalCode = postalCode;  
            leadToUpdate.Test_ride_Start_date__c = startDateTime;  
            leadToUpdate.Test_ride_end_date__c = endDateTime;    
            Account dealerCodeAccount;
            if (String.isNotBlank(dealerCode)) {
                List<Account> dealerAccounts = [SELECT Id, Name FROM Account WHERE Type = 'Dealer' AND Center_Code__c = :dealerCode LIMIT 1];
                if (!dealerAccounts.isEmpty()) {
                    dealerCodeAccount = dealerAccounts[0];
                }
            }
            
            leadToUpdate.Dealer_Code__c = dealerCode;
            leadToUpdate.Utm_Source__c = utm_source;
            Boolean isValue;
            
            leadToUpdate.Verified__c = verified;
            leadToUpdate.Home_Test_Ride__c = homeTestRide != null ? homeTestRide : false;  
            leadToUpdate.Instore_Test_drive__c = instoreTestdrive != null ? instoreTestdrive : false;  
            
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
            System.debug('leadToUpdate ===> ' + leadToUpdate);
            return 'Lead processed successfully: ' + leadToUpdate.Id;
            
        } catch(Exception e) {
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = ' Lead Creation',
                Request_Payload__c = JSON.serializePretty(requestBodyMap),
                Response_Payload__c = 'Error: ' + e.getMessage(),
                Error_Messages__c = 'Exception: ' + e.getMessage() + ' at line number ====>' + e.getLineNumber() + ' /createLeadRiverWebsite',
                Status__c = 'Failed'
            );
            Insert logObj;
            System.debug('Log created for failed lead creation: ' + logObj);
            System.debug('Error =====>' +  + e.getMessage() + ' at line number ====>' + e.getLineNumber());
            return 'Error: ' + e.getMessage();
        }
    }
    
    public class CustomException extends Exception {}
}