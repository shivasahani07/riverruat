@RestResource(urlMapping='/userDashboard')
global class MobileApp_Dashboard {
    @Httppost
    global static void LeadTotalLeads() { 
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
            String testRideDate = '';
            String followUpDate = '';
            if (filterDate == 'THIS_WEEK') {
                addQuery = ' AND CreatedDate = THIS_WEEK';
                testRideDate = ' AND Test_Drive_Date__c = THIS_WEEK';
                followUpDate = ' AND Follow_Up_Date__c = THIS_WEEK';
            } else if (filterDate == 'THIS_MONTH') {
                addQuery = ' AND CreatedDate = THIS_MONTH';
                testRideDate = ' AND Test_Drive_Date__c = THIS_MONTH';
                followUpDate = ' AND Follow_Up_Date__c = THIS_MONTH';
            }else if(filterDate == 'TODAY') {
                addQuery = ' AND CreatedDate = Today';
                testRideDate = ' AND Test_Drive_Date__c = Today';
                followUpDate = ' AND Follow_Up_Date__c = Today';
            }  else if (filterDate != null) {
                Date startDate = Date.valueOf(filterDate);
                Date endDate = (filterEndRange != null) ? Date.valueOf(filterEndRange) : startDate.addDays(1);
                addQuery = ' AND CreatedDate >= :startDate AND CreatedDate < :endDate';
                testRideDate = ' AND Test_Drive_Date__c >= :startDate AND Test_Drive_Date__c < :endDate';
                followUpDate = ' AND Follow_Up_Date__c >= :startDate AND Follow_Up_Date__c < :endDate';
            }

            Integer totalOpenOpp = Database.countQuery(
                'SELECT COUNT() FROM Opportunity WHERE OwnerId = :userId AND StageName NOT IN (\'Drop Out\', \'Closed Won\',\'No Show\')' + addQuery
            );
            System.debug('totalOpenOpp ====>'+ totalOpenOpp);

            Integer totalClosedWon = Database.countQuery(
                'SELECT COUNT() FROM Order WHERE OwnerId = \'' + userId + '\' AND Status IN (\'Booking\', \'Payment and Allocation\', \'Pre Invoice\', \'Invoice and Insurance\', ' +
                '\'RTO Registration\', \'Ready For Delivery\')' + addQuery
            );
            System.debug('totalClosedWon ====> ' + totalClosedWon);

            Integer totalDelivered = Database.countQuery(
                'SELECT COUNT() FROM Order WHERE OwnerId = :userId AND Status IN (\'Vehicle Delivered\')' + addQuery
            );
            System.debug('totalDelivered ====>'+ totalDelivered);

            Integer totalTestDrive = Database.countQuery(
                'SELECT COUNT() FROM Test_Drive__c WHERE OwnerId = :userId AND Test_Drive_Status__c NOT IN (\'New\',\'Completed\',\'No Show\', \'Canceled\')' + testRideDate
            );

            System.debug('totalTestDrive ====>'+ totalTestDrive);

            
            Integer totalFollowUp = Database.countQuery(
                'SELECT COUNT() FROM Follow_Up__c WHERE OwnerId = :userId AND Status__c NOT IN (\'Completed\')  AND Status__c != null  AND Lead__c = null AND Opportunity__c != null' + followUpDate
            );
            System.debug('totalFollowUp ====>'+ totalFollowUp);
            Integer totalOldFollowUp = Database.countQuery(
                'SELECT COUNT() FROM Follow_Up__c WHERE OwnerId = :userId AND Status__c NOT IN (\'Completed\') AND Lead__c = null AND Opportunity__c != null AND Follow_Up_Date__c < TODAY'
            );
            System.debug('totalOldFollowUp ====>'+ totalOldFollowUp);

            String OldfollowUp = 'SELECT Id,FollowUpType__c,Follow_Up_Date__c,Feedback__c,Opportunity__c,Lead__r.Name,Lead__c,Lead__r.Phone,Status__c,Opportunity__r.Name,Opportunity__r.Account.Phone,Opportunity__r.CreatedDate,Lead__r.CreatedDate FROM Follow_Up__c ' + ' WHERE OwnerId = \'' + userId + '\' ' + 'AND Status__c NOT IN (\'Completed\') AND Follow_Up_Date__c < today';

            List<Follow_Up__c> OldfollowUpList = Database.query(OldfollowUp);
            system.debug('OldfollowUpList size ===> ' + OldfollowUpList.size());

            Map<String, Object> responseData = new Map<String, Object>{
                'OpportunitySources' => TaskLeadController.getFieldDependencies('Opportunity','Enquiry_Primary_Source__c','Secondary_Sources__c'),
                'OpportunityDropOutSources' => TaskLeadController.getFieldDependencies('Opportunity','Drop_Out_Reasons__c','Drop_Out_Sub_Reasons__c'),
                'TestDriveType' => TaskLeadController.statusPicklistValues('Opportunity','Enquiry_Primary_Source__c'),
                'totalOpenOpp' => totalOpenOpp,
                'totalBookings' => totalClosedWon,
                'totalPurchase' => totalDelivered,
                'totalTestDrive' => totalTestDrive,
                'totalFollowUp' => totalFollowUp,
                'totalOldFollowUp' => totalOldFollowUp,
                'totalOldFollowUpList' => buildOverDueFollowUpMap(OldfollowUpList)
            };

            MobileApp_Wrapper.setResponse(200, 'Success', responseData);

        } catch (Exception e) {
            MobileApp_Wrapper.setResponse(500, 'Internal server error: ' + e.getMessage(), null);
            System.debug('Error ====>'+e.getMessage() + ' at line number =====>' + e.getLineNumber());
        }
    }


    private static List<Map<String,Object>> buildOverDueFollowUpMap(List<Follow_Up__c> followUpList){
        List<Map<String, Object>> followUpMaps = new List<Map<String, Object>>();
        
        System.debug('followUpList ====>' + followUpList);
        Set<Id> followUpLeadId = new Set<Id>();
        Set<Id> followUpOppIds = new Set<Id>();
        
        for (Follow_Up__c f : followUpList) {
            if (f.Opportunity__c != null) followUpLeadId.add(f.Opportunity__c);        }
        System.debug('followUpLeadId=====>' + followUpLeadId.size());
        
        List<Follow_Up__c> followUpListOpp = [
            SELECT Id, Follow_Up_Date__c, Feedback__c, Opportunity__c, Lead__c, Status__c,
            Opportunity__r.Name, Opportunity__r.Account.Phone, Opportunity__r.CreatedDate,FollowUpType__c,
            Lead__r.Name, Lead__r.Phone, Lead__r.CreatedDate
            FROM Follow_Up__c
            WHERE (Opportunity__c IN :followUpLeadId)
            AND Status__c = 'Completed'
        ];
        System.debug('followUpListOpp ====>' + followUpListOpp.size());
        
        Map<Id, List<Follow_Up__c>> followUpMap = new Map<Id, List<Follow_Up__c>>();
        for (Follow_Up__c f : followUpListOpp) {
            Id key = f.Opportunity__c;
            if (key != null) {
                if (!followUpMap.containsKey(key)) {
                    followUpMap.put(key, new List<Follow_Up__c>());
                }
                followUpMap.get(key).add(f);
            }
        }
        
        for (Follow_Up__c f : followUpList) {
            if(f.Opportunity__c != null){
                Map<String, Object> mapEntry = new Map<String, Object>{
                'LeadAge'   => System.today().daysBetween(f.Opportunity__r.CreatedDate.date()),
                    'FollowUpId' => f.Id,
                    'LeadPhone'  => f.Opportunity__r.Account.Phone,
                    'LeadName'   => f.Opportunity__r.Name,
                    'LeadId'     => f.Opportunity__c,
                    'Status'     => f.Status__c,
                    'FollowUpDate'   => f.Follow_Up_Date__c,
                    'Feedback'       => f.Feedback__c,
                    'FollowUpType' => f.FollowUpType__c
                };                    
                Id key = f.Opportunity__c;
                if (followUpMap.containsKey(key)) {
                    List<Map<String, Object>> oldFollowUps = new List<Map<String, Object>>();
                    for (Follow_Up__c old : followUpMap.get(key)) {
                        oldFollowUps.add(new Map<String, Object>{
                            'FollowUpId'     => old.Id,
                                'FollowUpDate'   => old.Follow_Up_Date__c,
                                'Feedback'       => old.Feedback__c,
                                'Status'         => old.Status__c,
                                'FollowUpType' => old.FollowUpType__c
                                });
                    }
                    mapEntry.put('OldFollowUps', oldFollowUps);
                } else {
                    mapEntry.put('OldFollowUps', new List<Map<String, Object>>());
                }
                
                followUpMaps.add(mapEntry);
            }
        }
        
        return followUpMaps;
    }
}