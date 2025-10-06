@RestResource(urlMapping='/EventTestDrive')
global class MobileApp_EventTestDrive {
    @Httppost
    global static void getTestDrives() {
            RestRequest req = RestContext.request;

        try {
            String requestString = req.requestBody != null ? req.requestBody.toString() : '';
            if (String.isBlank(requestString)) {
                MobileApp_Wrapper.setResponse(400, 'Empty request body', null);
                return;
            }

            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrp = 
                (MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper.class
                );

            if (wrp.UserId == null || String.isBlank(wrp.UserId) || wrp.UserId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide UserId', null);
                return;
            }

            String userId = UserInfo.getUserId();
            String filterDate = wrp.FilterDate;
            String filterEndRange = wrp.FilterEndRange;

            String addQuery = '';
            if (filterDate == 'THIS_WEEK') {
                addQuery = ' AND Test_Drive_Date__c = THIS_WEEK';
            } else if (filterDate == 'THIS_MONTH') {
                addQuery = ' AND Test_Drive_Date__c = THIS_MONTH';
            }else if(filterDate == 'TODAY') {
                addQuery = ' AND Test_Drive_Date__c = TODAY';
            }  
            else if (filterDate != null) {
                Date startDate = Date.valueOf(filterDate);
                Date endDate = (filterEndRange != null) ? Date.valueOf(filterEndRange) : startDate.addDays(1);
                addQuery = ' AND Test_Drive_Date__c >= :startDate AND Test_Drive_Date__c < :endDate';
            }

            String query = 'SELECT Id, Test_Drive_Status__c, Opportunity__r.Name,Opportunity__r.AccountId ,Opportunity__r.Account.Email__c, Opportunity__r.Account.Phone, Opportunity__r.CreatedDate, Start_Date__c, End_Date__c, '+ 
            'Opportunity__c,Test_Drive_Date__c,Address__c,Ride_Type__c FROM Test_Drive__c WHERE OwnerId = :userId AND Test_Drive_Status__c NOT IN (\'New\',\'Completed\',\'No Show\',\'Canceled\') ' + addQuery;
            List<Test_Drive__c> testDrives = Database.query(query);
            List<Map<String, Object>> result = new List<Map<String, Object>>();

            if(!testDrives.isEmpty()){
                for (Test_Drive__c t : testDrives) {
                    result.add(new Map<String, Object>{
                        'LeadAge' => t.Opportunity__c != null && t.Opportunity__r.CreatedDate != null? System.today().daysBetween(t.Opportunity__r.CreatedDate.date()) : 0,
                        'ScheduleDateTime' => t.Test_Drive_Date__c,
                        'TestDriveId' => t.Id,
                        'LeadPhone' =>t.Opportunity__c != null && t.Opportunity__r.AccountId != null && t.Opportunity__r.Account.Phone != null ? t.Opportunity__r.Account.Phone : '',
                        'LeadName' =>t.Opportunity__c != null && t.Opportunity__r.Name != null ? t.Opportunity__r.Name : '',
                        'LeadId' => t.Opportunity__c,
                        'TestStatus' => t.Test_Drive_Status__c,
                        'Address' => t.Address__c,
                        'RideType'=> t.Ride_Type__c
                    });
                }
            }

            Set<String> TestDriveStatuses = TaskLeadController.statusPicklistValues('Test_Drive__c','Test_Drive_Status__c');
            Set<String> TestDriveRideType = TaskLeadController.statusPicklistValues('Test_Drive__c','Ride_Type__c');
            Map<String, Object> dataMap = new Map<String, Object>{
                'TestDriveStatuses' => TestDriveStatuses,
                'TestDriveRideType' => TestDriveRideType
            };

            result.add(dataMap);

            MobileApp_Wrapper.setResponses(200, 'Success', result);
        } catch (Exception e) {
            MobileApp_Wrapper.setResponses(500, 'Error: ' + e.getMessage(), null);
            System.debug('Error ====>'+e.getMessage() + ' at line number =====>' + e.getLineNumber());
        }
    }
}