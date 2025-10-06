@RestResource(urlMapping='/OrderComments')
global class MobileAPP_OrderComments {
    @HttpPost
    global static void OrderComments() { 
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
            
            MobileApp_Wrapper.MobileApp_Comments wrp = 
                (MobileApp_Wrapper.MobileApp_Comments) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_Comments.class
                );
            
            if(wrp.userId == null || String.isBlank(wrp.userId) || wrp.userId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide userId', null);
                return;
            }
            if(wrp.OrderId == null || String.isBlank(wrp.OrderId) || wrp.OrderId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide OrderId', null);
                return;
            }
            if(wrp.Comments == null || String.isBlank(wrp.Comments) || wrp.Comments == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide Comments', null);
                return;
            }
            
            String userId = wrp.userId;
            String OrderId = wrp.OrderId;
            String Comments = wrp.Comments;

            Map<String, Object> responseData = new Map<String, Object>();
            
            Comment__c comRec = new Comment__c();
            comRec.Order__c = OrderId;
            comRec.Description__c = Comments;
            Insert comRec;
            
            if(comRec.Id == null) {
                MobileApp_Wrapper.setResponse(500, 'Comment Creation Failed', null);
            } else {
                
                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Comment created successfully: ' + comRec.Id,
                    Status__c = 'Success'
                );
                insert logObj;
                
                responseData.put('comment', comRec.Id);
                MobileApp_Wrapper.setResponse(200, 'Comment created successfully:', responseData);
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