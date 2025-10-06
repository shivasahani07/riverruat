@RestResource(urlMapping='/EventFollowUp')
global class MobileApp_EventFollowUp {
    @Httppost
    global static void getFollowUps() {
        try {
            RestRequest req = RestContext.request;
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
                addQuery = ' AND Follow_Up_Date__c = THIS_WEEK';
            } else if (filterDate == 'THIS_MONTH') {
                addQuery = ' AND Follow_Up_Date__c = THIS_MONTH';
            }else if(filterDate == 'TODAY') {
                addQuery = ' AND Follow_Up_Date__c = TODAY';
            }else if (filterDate != null) {
                Date startDate = Date.valueOf(filterDate);
                Date endDate = (filterEndRange != null) ? Date.valueOf(filterEndRange) : startDate.addDays(1);
                addQuery = ' AND Follow_Up_Date__c >= :startDate AND Follow_Up_Date__c < :endDate';
            }

            String query = 'SELECT Id, Opportunity__r.Follow_Up_Count__c, Opportunity__r.Rating__c, Feedback__c, Opportunity__c, Next_Follow_Up_Date__c, Lead__c, Status__c, Opportunity__r.Name, Opportunity__r.Account.Phone, ' +
                           'Opportunity__r.CreatedDate, Lead__r.Name, Lead__r.Phone, Lead__r.CreatedDate,FollowUpType__c,Follow_Up_Date__c ' +'FROM Follow_Up__c ' + 'WHERE OwnerId = \'' + userId + '\' ' + ' AND Lead__c = null AND Opportunity__c != null AND Status__c != null AND Status__c != \'Completed\' ' + addQuery;

            System.debug('query ======>' + query);
            List<Follow_Up__c> followUpListOpp = [
                SELECT Id, Follow_Up_Date__c, Feedback__c, Opportunity__c, Status__c,
                Opportunity__r.Name, Opportunity__r.Account.Phone, Opportunity__r.CreatedDate,FollowUpType__c,
                Lead__r.Name, Lead__r.Phone, Lead__r.CreatedDate
                FROM Follow_Up__c 
                WHERE OwnerId =: userId AND Status__c = 'Completed' AND CreatedDate <= Today];

            List<Follow_Up__c> followUps = Database.query(query);

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for (Follow_Up__c t : followUps) {
                result.add(new Map<String, Object>{
                    'LeadAge' => t.Opportunity__c != null && t.Opportunity__r.CreatedDate != null ? System.today().daysBetween(t.Opportunity__r.CreatedDate.date()) : 0,
                    'Feedback' => t.Feedback__c,
                    'FollowUpId' => t.Id,
                    'Rating' => t.Opportunity__c != null && t.Opportunity__r.Rating__c != null ? t.Opportunity__r.Rating__c : null,
                    'LeadPhone' => t.Opportunity__c != null && t.Opportunity__r.AccountId != null && t.Opportunity__r.Account.Phone != null ? t.Opportunity__r.Account.Phone : '',
                    'LeadName' => t.Opportunity__c != null && t.Opportunity__r.Name != null ? t.Opportunity__r.Name : '',
                    'FollowUpCount' =>t.Opportunity__c != null && t.Opportunity__r.Follow_Up_Count__c != null ? t.Opportunity__r.Follow_Up_Count__c : 0 ,
                    'NextFollowUp' => t.Next_Follow_Up_Date__c,
                    'LeadId' => t.Opportunity__c,   
                    'FollowUpStatus' => t.Status__c,
                    'FollowUpType' => t.FollowUpType__c,
                    'FollowUpDate' => t.Follow_Up_Date__c,
                    'followUpListOpp' => followUpListOpp
                });
            }

            Set<String> FollowUpStatuses = TaskLeadController.statusPicklistValues('Follow_Up__c','Status__c');
            Map<String, Object> dataMap = new Map<String, Object>{
                'FollowUpStatuses' => FollowUpStatuses
            };

            result.add(dataMap);

            MobileApp_Wrapper.setResponses(200, 'Success', result);
        } catch (Exception e) {
            MobileApp_Wrapper.setResponses(500, 'Error: ' + e.getMessage(), null);
        }
    }
}