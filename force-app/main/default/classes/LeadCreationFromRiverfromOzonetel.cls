@RestResource(urlMapping='/createLeadinOzonetel')  
global class LeadCreationFromRiverfromOzonetel {
    
    @HttpPost  
    global static String createLeadFromWebsite() {  
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString(); 
        Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);  
        
        // Extract values from request
        String fullName = (String) requestBodyMap.get('FullName');  
        String email = (String) requestBodyMap.get('Email');  
        String phone = (String) requestBodyMap.get('Phone');  
        String city = (String) requestBodyMap.get('City');  
        String postalCode = String.valueOf(requestBodyMap.get('PostalCode'));  
        Boolean homeTestRide = (Boolean) requestBodyMap.get('HomeTestRide');  
        Boolean instoreTestdrive = (Boolean) requestBodyMap.get('InstoreTestdrive');
        String utm_source = (String) requestBodyMap.get('utm_source'); 
        Boolean verified = (Boolean) requestBodyMap.get('verified');  
        String dealerCode = (String) requestBodyMap.get('DealerCode');  
        
        // DateTime parsing
        String startDateTimeStr = (String) requestBodyMap.get('startDateTimeStr');  
        String endDateTimeStr = (String) requestBodyMap.get('endDateTimeStr');  
        Datetime startDateTime, endDateTime;
        
        if (startDateTimeStr != null) {
            startDateTimeStr = startDateTimeStr.replace('T', ' ');
            if (startDateTimeStr.endsWith('Z')) startDateTimeStr = startDateTimeStr.removeEnd('Z');
            startDateTime = DateTime.valueOf(startDateTimeStr);
        }
        
        if (endDateTimeStr != null) {
            endDateTimeStr = endDateTimeStr.replace('T', ' ');
            if (endDateTimeStr.endsWith('Z')) endDateTimeStr = endDateTimeStr.removeEnd('Z');
            endDateTime = DateTime.valueOf(endDateTimeStr);
        }
        
        Id testDriveId;
        Id followUpId;
        String testDriveStatus = 'Not processed';
        String followUpStatus = 'Not processed';
        
        try {
            // Step 1: Lookup existing lead
            List<Lead> leads = [SELECT Id, LastName, Company FROM Lead WHERE Phone = :phone LIMIT 1];  
            Lead lead = leads.isEmpty() ? new Lead() : leads[0];
            Boolean isNewLead = lead.Id == null;
            
            // Step 2: Validate and populate fields
            if (String.isBlank(fullName)) {
                return JSON.serializePretty(new Map<String, Object>{
                    'error' => 'Missing Required Field',
                        'message' => 'FullName is required to create or update a Lead.'
                        });
            }
            
            lead.LastName = fullName;
            lead.Company = fullName;
            lead.Email = email;
            lead.Phone = phone;
            lead.City = city;
            lead.PostalCode = postalCode;
            lead.Dealer_Code__c = dealerCode;
            lead.Utm_Source__c = utm_source;
            lead.Verified__c = verified;
            lead.Home_Test_Ride__c = homeTestRide != null ? homeTestRide : false;
            lead.Instore_Test_drive__c = instoreTestdrive != null ? instoreTestdrive : false;
            lead.LeadSource = 'OzoneTel WhatsApp';
            
            // Step 3: Save lead (insert or update)
            if (isNewLead) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.DuplicateRuleHeader.allowSave = true;
                dmlOpts.DuplicateRuleHeader.runAsCurrentUser = true;
                lead.setOptions(dmlOpts);
                insert lead;
            } else {
                update lead;
            }
            
            // Step 4: Handle Test Drive (if startDateTime exists & endDateTime is null)
            if (startDateTime != null && endDateTime == null) {
                List<Test_Drive__c> existingTD = [SELECT Id FROM Test_Drive__c WHERE Lead__c = :lead.Id LIMIT 1];
                if (!existingTD.isEmpty()) {
                    Test_Drive__c td = existingTD[0];
                    td.Test_Ride_Date__c = startDateTime;
                    td.Test_Drive_Status__c = 'Scheduled';
                    
                    // Set Ride Type
                    if (homeTestRide == true) {
                        td.Ride_Type__c = 'HTR';
                    } else if (instoreTestdrive == true) {
                        td.Ride_Type__c = 'STR';
                    }
                    
                    update td;
                    testDriveId = td.Id;
                    testDriveStatus = 'Updated';
                } else {
                    Test_Drive__c td = new Test_Drive__c();
                    td.Lead__c = lead.Id;
                    td.Test_Ride_Date__c = startDateTime;
                    td.Test_Drive_Status__c = 'Scheduled';
                    
                    // Set Ride Type
                    if (homeTestRide == true) {
                        td.Ride_Type__c = 'HTR';
                    } else if (instoreTestdrive == true) {
                        td.Ride_Type__c = 'STR';
                    }
                    
                    insert td;
                    testDriveId = td.Id;
                    testDriveStatus = 'Created';
                }
            }
            
            // Step 5: Handle Follow-Up (if endDateTime exists & startDateTime is null)
            if (endDateTime != null && startDateTime == null) {
                List<Follow_Up__c> oldFollowUps = [SELECT Id, Status__c FROM Follow_Up__c WHERE Lead__c = :lead.Id AND Status__c != 'Completed'];
                for (Follow_Up__c oldFU : oldFollowUps) {
                    oldFU.Status__c = 'Completed';
                }
                if (!oldFollowUps.isEmpty()) update oldFollowUps;
                
                Follow_Up__c newFU = new Follow_Up__c();
                newFU.Lead__c = lead.Id;
                newFU.Follow_Up_Date__c = endDateTime;
                newFU.Status__c = 'Not Started';
                insert newFU;
                followUpId = newFU.Id;
                followUpStatus = 'Not Started';
            }
            
            // Final success response
            return JSON.serializePretty(new Map<String, Object>{
                'message' => 'Lead processed successfully',
                    'leadId' => lead.Id,
                    'testDriveId' => testDriveId,
                    'testDriveStatus' => testDriveStatus,
                    'followUpId' => followUpId,
                    'followUpStatus' => followUpStatus
                    });
            
        } catch (Exception e) {
            return JSON.serializePretty(new Map<String, Object>{
                'error' => 'DML Exception',
                    'message' => e.getMessage(),
                    'suggestion' => 'Lead may already exist. Check duplicate rules or verify lead before inserting.'
                    });
        }
    }
}