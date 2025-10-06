@RestResource(urlMapping='/EventBooking')
global class MobileApp_EventBooking {
    @Httppost
    global static void getRetails() {
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
                addQuery = ' AND CreatedDate = THIS_WEEK';
            } else if (filterDate == 'THIS_MONTH') {
                addQuery = ' AND CreatedDate = THIS_MONTH';
            }else if(filterDate == 'TODAY') {
                addQuery = ' AND CreatedDate = TODAY';
            }  
            else if (filterDate != null) {
                Date startDate = Date.valueOf(filterDate);
                Date endDate = (filterEndRange != null) ? Date.valueOf(filterEndRange) : startDate.addDays(1);
                addQuery = ' AND CreatedDate >= :startDate AND CreatedDate < :endDate';
            }
            
            String query = 'SELECT Id, OpportunityId,Opportunity.AccountId,Order_Id__c,Delivery_Date__c,Opportunity.Account.Phone,AccountId,Account.Phone,Account.Name,Opportunity.Name, Status, Grand_Total__c, Remaining_Amount__c, Name, PME_Drive__c, Registration_Date__c ' +
               'FROM Order ' +
               'WHERE OwnerId = \'' + userId + '\' ' +
               'AND Status IN (\'Vehicle Delivered\') ' +
               addQuery;

            List<Order> ordList = Database.query(query);
            System.debug('ordList ======>' + ordList);
            List<Map<String, Object>> result = new List<Map<String, Object>>();

            if (!ordList.isEmpty()) {
                for (Order t : ordList) {
                    result.add(new Map<String, Object>{
                        'OrderId'           => t.Id,
                        'LeadPhone'         => t.OpportunityId != null && t.Opportunity.AccountId != null && t.Opportunity.Account.Phone != null ? t.Opportunity.Account.Phone : t.AccountId != null && t.Account.Phone != null ? t.Account.Phone : '' ,
                        'LeadName'          => t.OpportunityId != null && t.Opportunity.Name != null ? t.Opportunity.Name : t.AccountId != null && t.Account.Name != null ? t.Account.Name : '',
                        'OrdId'             => t.Order_Id__c,
                        'PME_Drive'         => t.PME_Drive__c,
                        'RTORegistrationDate' => t.Registration_Date__c,
                        'PurchaseDate'  => t.Delivery_Date__c,
                        'Status'=> t.Status
                    });
                }
            }

            MobileApp_Wrapper.setResponses(200, 'Success', result);
        } catch (Exception e) {
            MobileApp_Wrapper.setResponses(500, 'Error: ' + e.getMessage(), null);
            System.debug('Error ====>'+e.getMessage() + ' at line number =====>' + e.getLineNumber());
        }
    }
}