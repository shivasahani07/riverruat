@RestResource(urlMapping='/EventProfile')
global class MobileApp_EventProfile {
    
    @Httppost
    global static void getTestDrives() {
        RestRequest req = RestContext.request;
        
        try {
            List<Map<String, Object>> result = new List<Map<String, Object>>();

            User currentUser = [
                SELECT Id, Name, Email, ContactId,
                       Contact.Phone, Contact.Designation__c,
                       Contact.Account.Name, Contact.Account.Phone,Contact.Account.Center_Code__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];

            Map<String, Object> dataMap = new Map<String, Object>();
            dataMap.put('UserId', currentUser.Id);
            dataMap.put('UserName', currentUser.Name);
            dataMap.put('UserDesignation', currentUser.Contact != null ? currentUser.Contact.Designation__c : null);
            dataMap.put('StoreName', currentUser.Contact != null && currentUser.Contact.Account != null ? currentUser.Contact.Account.Name : null);
            dataMap.put('StorePhone', currentUser.Contact != null && currentUser.Contact.Account != null ? currentUser.Contact.Account.Phone : null);
            dataMap.put('UserPhone', currentUser.Contact != null ? currentUser.Contact.Phone : null);
            dataMap.put('UserEmail', currentUser.Email);
            dataMap.put('DealerCode', currentUser.Contact != null && currentUser.Contact.Account != null && currentUser.Contact.Account.Center_Code__c != null ? currentUser.Contact.Account.Center_Code__c : null);
            result.add(dataMap);

            MobileApp_Wrapper.setResponses(200, 'Success', result);

        } catch (Exception e) {
            MobileApp_Wrapper.setResponses(500, 'Error: ' + e.getMessage(), null);
            System.debug('Error ====> ' + e.getMessage() + ' at line number =====> ' + e.getLineNumber());
        }
    }
}