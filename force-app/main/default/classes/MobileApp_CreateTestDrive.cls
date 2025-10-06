@RestResource(urlMapping='/CreateTestDrive')
global class MobileApp_CreateTestDrive {
    @HttpPost
    global static void createTestDrive() { 
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
            
            MobileApp_Wrapper.MobileApp_CreateTestDrive wrp = 
                (MobileApp_Wrapper.MobileApp_CreateTestDrive) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_CreateTestDrive.class
                );
            
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);    
            
            if (wrp.UserId == null || String.isBlank(wrp.UserId) || wrp.UserId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide UserId', null);
                return;
            }
            if (wrp.LeadId == null || String.isBlank(wrp.LeadId) || wrp.LeadId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide LeadId', null);
                return;
            }
            if (wrp.TestDriveDate == null || String.isBlank(wrp.TestDriveDate) || wrp.TestDriveDate == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide TestDriveDate', null);
                return;
            }
            if (wrp.TestDriveTime == null || String.isBlank(wrp.TestDriveTime) || wrp.TestDriveTime == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide TestDriveTime', null);
                return;
            }
            
            String userId = wrp.UserId;
            String leadId = wrp.LeadId;
            String TestDriveDate = wrp.TestDriveDate;
            String TestDriveTime = wrp.TestDriveTime;
            boolean homeTestDrive = wrp.homeTestDrive;
            String HomeTestDriveAddress = wrp.HomeTestDriveAddress;
            boolean storeTestDrive = wrp.storeTestDrive;
            String pincode = wrp.pincode;
            
            if(homeTestDrive == true && (String.isBlank(HomeTestDriveAddress) || HomeTestDriveAddress == null)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide HomeTestDriveAddress', null);
                return;
            }
            
            system.debug('UserId ========>' + userId);
            system.debug('LeadId ========> ' + LeadId);
            system.debug('homeTestDrive ========>' + homeTestDrive);
            system.debug('HomeTestDriveAddress ========>' + HomeTestDriveAddress);
            system.debug('storeTestDrive ========> ' + storeTestDrive);
            
            Date datePart = Date.valueOf(TestDriveDate);
            List<String> timeParts = TestDriveTime.split(':');
            System.debug('timeParts ========>' + timeParts);
            Integer hour = Integer.valueOf(timeParts[0]);
            System.debug('hour ========>' + hour);
            Integer minute = Integer.valueOf(timeParts[1]);
            System.debug('minute ========>' + minute);
            
            Time timePart = Time.newInstance(hour, minute, 0, 0);
            System.debug('timePart ========>' + timePart);
            Datetime TestDriveDateTime = Datetime.newInstance(datePart, timePart);
            System.debug('TestDriveDateTime ========>' + TestDriveDateTime);
            
            Test_Drive__c testDriveRec = new Test_Drive__c();
            testDriveRec.OwnerId = userId;
            
            if(leadId.startsWith('006')) {
                testDriveRec.Opportunity__c = leadId;
                List<Opportunity> OppList = [SELECT Id,Name FROM Opportunity WHERE Id = :leadId LIMIT 1];
                if(OppList.size() == 0) {
                    MobileApp_Wrapper.setResponse(404, 'Lead not found', null);
                    return;
                }else{
                    testDriveRec.Name = OppList[0].Name + ' Test Drive';
                }
            }
            // else if(leadId.startsWith('00Q')) {
            //     testDriveRec.Lead__c = leadId;
            //     List<Lead> leadList = [SELECT Id,Name FROM Lead WHERE Id = :leadId LIMIT 1];
            //     if(leadList.size() == 0) {
            //         MobileApp_Wrapper.setResponse(404, 'Lead not found', null);
            //         return;
            //     }else{
            //         testDriveRec.Name = leadList[0].Name + ' Test Drive';
            //     }
            // }
            if(homeTestDrive == true) {
                testDriveRec.Ride_Type__c = 'HTR';
                testDriveRec.Address__Street__s = HomeTestDriveAddress;
                testDriveRec.Address__PostalCode__s = pincode;
            } else if(storeTestDrive == true) {
                testDriveRec.Ride_Type__c = 'STR';
            } else {
                testDriveRec.Ride_Type__c = 'STR';
            }
            testDriveRec.Test_Drive_Date__c = TestDriveDateTime;
            testDriveRec.Test_Drive_Status__c = 'Scheduled';
            insert testDriveRec;
            
            if(testDriveRec.Id == null) {
                MobileApp_Wrapper.setResponse(500, 'Test Drive not created', null);
                return;
            }else{

                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Test Drive Created Successfully ' + testDriveRec.Id,
                    Status__c = 'Success'
                );
                insert logObj;

                MobileApp_Wrapper.setResponse(200, 'Test Drive Created', null);
                System.debug('Test Drive Created Successfully with Id: ' + testDriveRec.Id);
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