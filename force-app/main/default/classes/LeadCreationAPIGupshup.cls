@RestResource(urlMapping='/createLeadGupshup')
global class LeadCreationAPIGupshup {

    @HttpPost
    global static String createLeadFromWebsite() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String requestBody = req.requestBody.toString();
        Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        // Extract values safely
        String fullName = (String) requestBodyMap.get('FullName');
        String company = (String) requestBodyMap.get('Company');
        String email = (String) requestBodyMap.get('Email');
        String phone = (String) requestBodyMap.get('Phone');
        String city = (String) requestBodyMap.get('City');
        String buyingSpan = (String) requestBodyMap.get('buyingSpan');
        String postalCode = requestBodyMap.get('PostalCode') != null ? String.valueOf(requestBodyMap.get('PostalCode')) : null;
        Boolean homeTestRide = requestBodyMap.get('HomeTestRide') != null ? (Boolean) requestBodyMap.get('HomeTestRide') : false;
        Boolean instoreTestdrive = requestBodyMap.get('InstoreTestdrive') != null ? (Boolean) requestBodyMap.get('InstoreTestdrive') : false;
        String startDateTimeStr = (String) requestBodyMap.get('startDateTimeStr');
        String endDateTimeStr = (String) requestBodyMap.get('endDateTimeStr');
        String dealerCode = (String) requestBodyMap.get('DealerCode');

        Datetime startDateTime = null;
        Datetime endDateTime = null;
        try {
            if (startDateTimeStr != null) startDateTime = Datetime.valueOf(startDateTimeStr);
            if (endDateTimeStr != null) endDateTime = Datetime.valueOf(endDateTimeStr);
        } catch (Exception e) {
            // If date parsing fails, ignore and keep null
        }

        try {
            // Query for duplicate lead with same phone
            List<Lead> leads = [
                SELECT Id, LastName, Company, Email, Phone, City,
                       Test_ride_Start_date__c, Test_ride_end_date__c,
                       Dealer_Code__c, Home_Test_Ride__c, Instore_Test_drive__c,
                       Lead_Age__c
                FROM Lead
                WHERE Phone = :phone
                LIMIT 1
            ];

            Lead leadToUpdate = null;
            Boolean isDuplicateRecent = false;

            if (!leads.isEmpty()) {
                leadToUpdate = leads[0];

                // Check if Lead is "too recent" (<= 90 days old)
                if (leadToUpdate.Lead_Age__c != null && leadToUpdate.Lead_Age__c <= 90) {
                    isDuplicateRecent = true;
                }
            }

           /* if (isDuplicateRecent) {
                // Block and log duplicate
                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Lead Creation - GupShup',
                    Duplicate_Lead_Phone__c = phone,
                    Request_Payload__c = JSON.serializePretty(requestBodyMap),
                    Response_Payload__c = 'Duplicate Lead Found within 90 days: ' + leadToUpdate.Id,
                    Lead__c = leadToUpdate.Id,
                    Status__c = 'Failed' // Confirm 'Conflict' picklist value exists
                );
                insert logObj;

                res.statusCode = 409;
                return 'Duplicate Lead Found within 90 days: ' + leadToUpdate.Id;
            } */

            if (leadToUpdate == null) {
                leadToUpdate = new Lead();
            }

            // Always update LeadSource
            leadToUpdate.LeadSource = 'GupShup';

            // Extract last name from fullName (mandatory for Lead)
            String lastName = '';
            if (fullName != null) {
                List<String> nameParts = fullName.trim().split(' ');
                if (!nameParts.isEmpty()) {
                    lastName = nameParts[nameParts.size() - 1]; // last word as last name
                } else {
                    lastName = fullName;
                }
            } else {
                lastName = 'Unknown'; // fallback mandatory field
            }
            leadToUpdate.LastName = lastName;

            // Assign other lead values
            leadToUpdate.Company = company != null ? company : fullName != null ? fullName : '';
            leadToUpdate.Email = email;
            leadToUpdate.Phone = phone;
            leadToUpdate.City = city;
            leadToUpdate.PostalCode = postalCode;
            leadToUpdate.Buying_Span__c = buyingSpan;
            leadToUpdate.Test_ride_Start_date__c = startDateTime;
            leadToUpdate.Test_ride_end_date__c = endDateTime;
            leadToUpdate.Home_Test_Ride__c = homeTestRide;
            leadToUpdate.Instore_Test_drive__c = instoreTestdrive;

            // Assign Dealer from PostalCode via helper method
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

            if (leadToUpdate.Id != null) {
                update leadToUpdate;
            } else {
                insert leadToUpdate;
            }

            // Log success
            Integration_Log__c logObjSuccess = new Integration_Log__c(
                Integration_Type__c = 'Lead Creation - GupShup',
                Request_Payload__c = JSON.serializePretty(requestBodyMap),
                Response_Payload__c = 'Lead processed successfully: ' + leadToUpdate.Id,
                Status__c = 'Success'
            );
            insert logObjSuccess;

            return 'Lead processed successfully: ' + leadToUpdate.Id;

        } catch (Exception e) {
            // Log failure
            Integration_Log__c logObjFailure = new Integration_Log__c(
                Integration_Type__c = 'Lead Creation - GupShup',
                Request_Payload__c = JSON.serializePretty(requestBodyMap),
                Response_Payload__c = 'Error: ' + e.getMessage(),
                Error_Message__c = e.getMessage(),
                Status__c = 'Failed'
            );
            insert logObjFailure;

            res.statusCode = 500;
            return 'Error: ' + e.getMessage();
        }
    }
}