@RestResource(urlMapping='/EventTicket')
global class MobileApp_EventTicket {
    @Httppost
    global static void getTickets() {
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

            String addQuery = ' AND CreatedDate = THIS_MONTH';
            
            String query = 'SELECT Id, Name,Status__c, Subject__c, Type__c, Account__c, Contact__c, Description__c, Internal_Team_Remarks__c, Closing_Date__c, Ticket_Age__c, Created_By_Name__c, Supporting_Topics__c, '+  
            'Team_Analysis__c, Additional_Details__c FROM Salesforce_Support__c' + ' WHERE OwnerId = \'' + userId + '\' ' + 'AND Status__c != \'Completed\' ' + addQuery + ' ORDER BY CreatedDate DESC';
            System.debug('query ======>' + query);

            List<Salesforce_Support__c> ticketsList = Database.query(query);
            

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for (Salesforce_Support__c ticket : ticketsList) {
                result.add(new Map<String, Object>{
                    'TicketId' => ticket.Id,
                    'Name' => ticket.Name,
                    'Status' => ticket.Status__c,
                    'Subject' => ticket.Subject__c,
                    'Type' => ticket.Type__c,
                    'AccountId' => ticket.Account__c,
                    'ContactId' => ticket.Contact__c,
                    'Description' => ticket.Description__c,
                    'Remarks' => ticket.Internal_Team_Remarks__c,
                    'ClosingDate' => ticket.Closing_Date__c,
                    'TicketAge' => ticket.Ticket_Age__c,
                    'CreatedBy' => ticket.Created_By_Name__c,
                    'Topics' => ticket.Supporting_Topics__c,
                    'Analysis' => ticket.Team_Analysis__c,
                    'AdditionalDetails' => ticket.Additional_Details__c
                });
            }
            
            MobileApp_Wrapper.setResponses(200, 'Success', result);
        } catch (Exception e) {
            System.debug('Error ====> ' + e.getMessage() + ' at line number =====> ' + e.getLineNumber());
            MobileApp_Wrapper.setResponses(500, 'Error: ' + e.getMessage(), null);
        }
    }
}