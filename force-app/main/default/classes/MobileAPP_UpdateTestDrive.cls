@RestResource(urlMapping='/UpdateTestDrive')
global class MobileAPP_UpdateTestDrive {
    @HttpPatch
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
            
            MobileApp_Wrapper.MobileApp_UpdateTestDrive wrp = 
                (MobileApp_Wrapper.MobileApp_UpdateTestDrive) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_UpdateTestDrive.class
                );
            
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);    
            
            if (wrp.UserId == null || String.isBlank(wrp.UserId) || wrp.UserId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide UserId', null);
                return;
            }
            if (wrp.TestDriveId == null || String.isBlank(wrp.TestDriveId) || wrp.TestDriveId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide TestDriveId', null);
                return;
            }
            
            if(wrp.TestDriveStatus == null || String.isBlank(wrp.TestDriveStatus) || wrp.TestDriveStatus == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide TestDriveStatus', null);
                return;
            }
            
            if(wrp.TestDriveStatus != null || wrp.TestDriveStatus == 'Reschedule' || String.isEmpty(wrp.TestDriveStatus)) {
                if (wrp.TestDriveDate == null) {
                    MobileApp_Wrapper.setResponse(401, 'Please provide TestDriveDate', null);
                    return;
                }
                if (wrp.TestDriveTime == null) {
                    MobileApp_Wrapper.setResponse(401, 'Please provide TestDriveTime', null);
                    return;
                }
            }
            
            if(wrp.StartTestDrive == true) {
                // if(wrp.customerLicense == null || String.isBlank(wrp.customerLicense) || wrp.customerLicense == ''){
                //     MobileApp_Wrapper.setResponse(401, 'Please provide customerLicense', null);
                //     return;
                // }
                // if(wrp.IndemnityBond == null || String.isBlank(wrp.IndemnityBond) || wrp.IndemnityBond == ''){
                //     MobileApp_Wrapper.setResponse(401, 'Please provide IndemnityBond', null);
                //     return;
                // }
            }
            if(wrp.rideType == 'HTR' && (String.isBlank(wrp.homeTestDriveAddress) || wrp.HomeTestDriveAddress == null)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide HomeTestDriveAddress', null);
                return;
            }
            if(wrp.rideType == 'HTR' && (String.isBlank(wrp.pincode) || wrp.pincode == null)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide HomeTestDriveAddress', null);
                return;
            }
            
            String userId = wrp.UserId;
            String TestDriveId = wrp.TestDriveId;
            String TestDriveDate = wrp.TestDriveDate;
            String TestDriveTime = wrp.TestDriveTime;
            String TestDriveStatus = wrp.TestDriveStatus;
            boolean StartTestDrive = wrp.StartTestDrive;
            boolean CompleteTestDrive = wrp.CompleteTestDrive;
            String rideType = wrp.rideType;
            String homeTestDriveAddress = wrp.homeTestDriveAddress;
            String pincode = wrp.pincode;
            
            system.debug('UserId ========>' + userId);
            system.debug('TestDriveId ========> ' + TestDriveId);
            
            Datetime TestDriveDateTime;
            if(TestDriveStatus == 'Reschedule'){
                Date datePart = Date.valueOf(TestDriveDate);
                List<String> timeParts = TestDriveTime.split(':');
                System.debug('timeParts ========>' + timeParts);
                Integer hour = Integer.valueOf(timeParts[0]);
                System.debug('hour ========>' + hour);
                Integer minute = Integer.valueOf(timeParts[1]);
                System.debug('minute ========>' + minute);
                
                Time timePart = Time.newInstance(hour, minute, 0, 0);
                System.debug('timePart ========>' + timePart);
                TestDriveDateTime = Datetime.newInstance(datePart, timePart);
                System.debug('TestDriveDateTime ========>' + TestDriveDateTime);
            }
            
            List<Test_Drive__c> testDriveList = [SELECT Id, Test_Drive_Status__c,Opportunity__c,Lead__c FROM Test_Drive__c WHERE Id = :TestDriveId LIMIT 1];
            if(testDriveList.size() == 0){
                MobileApp_Wrapper.setResponse(401, 'Test Drive not found', null);
                return;
            }

            List<Opportunity> oppList = [SELECT Id,Name,StageName FROM Opportunity WHERE Id =:testDriveList[0].Opportunity__c LIMIT 1];
            if(oppList.size() == 0) {
                MobileApp_Wrapper.setResponse(404, 'Opportunity not found', null);
                return;
            }
            
            Test_Drive__c testDriveRec = new Test_Drive__c();
            testDriveRec.OwnerId = userId;
            testDriveRec.Opportunity__c = oppList[0].Id;
            testDriveRec.Id = TestDriveId;
            if (StartTestDrive == true) {
                testDriveRec.Test_Drive_Status__c = 'On-Going';
            } else if (CompleteTestDrive == true) {
                testDriveRec.Test_Drive_Status__c = 'Completed';
            } else {
                if (TestDriveStatus == 'Reschedule') {
                    testDriveRec.Test_Drive_Status__c = 'Reschedule';
                    testDriveRec.Test_Drive_Date__c = TestDriveDateTime != null ? TestDriveDateTime : null;
                    testDriveRec.Ride_Type__c = rideType;
                    testDriveRec.Address__Street__s = homeTestDriveAddress;
                    testDriveRec.Address__PostalCode__s = pincode;

                } else {
                    testDriveRec.Test_Drive_Status__c = TestDriveStatus;
                }
            }

            update testDriveRec;
            
            if(testDriveRec.Id == null) {
                MobileApp_Wrapper.setResponse(500, 'Test Drive not Updated', null);
                return;
            }else{

                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Test_Drive Updated successfully: ' + testDriveRec.Id,
                    Status__c = 'Success'
                );
                insert logObj;

                MobileApp_Wrapper.setResponse(200, 'Test Drive Updated', null);
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