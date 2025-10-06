@RestResource(urlMapping='/UpdateFollowUp')
global class MobileAPP_UpdateFollowUp {
    @HttpPatch
    global static void UpdateFollowUp() { 
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
            
            MobileApp_Wrapper.MobileApp_UpdateFollowUp wrp = 
                (MobileApp_Wrapper.MobileApp_UpdateFollowUp) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_UpdateFollowUp.class
                );
            
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);    
            
            
            
            if(wrp.FollowUpId == null || String.isBlank(wrp.FollowUpId) || wrp.FollowUpId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide FollowUpId', null);
                return;
            }

            if(wrp.UserId == null || String.isBlank(wrp.UserId) || wrp.UserId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide UserId', null);
                return;
            }

            String FollowUpId = wrp.FollowUpId;
            boolean FollowUpStatus = wrp.FollowUpStatusCompleted;
            String followUprating = wrp.followUprating;
            String followUpfeedBack = wrp.followUpfeedBack;
            
            if(followUprating != null ){
                List<Follow_Up__c> followUpRec = [Select Id,Opportunity__c from Follow_Up__c Where Id =: FollowUpId AND Opportunity__c != null];
                Opportunity opp = new Opportunity();
                opp.Id = followUpRec[0].Opportunity__c;
                opp.Rating__c = followUprating;
                update opp;

                MobileApp_Wrapper.setResponse(200, 'Rating is Updated', null);
                return;
            }

            if(FollowUpStatus == true){
                Follow_Up__c followUpRec = new Follow_Up__c();
                followUpRec.Id = FollowUpId;
                followUpRec.Status__c = 'Completed';
                followUpRec.Feedback__c = followUpfeedBack;
                update followUpRec;
                system.debug('FollowUpId ========> ' + FollowUpId);

                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Follow-Up updated successfully: ' + FollowUpId,
                    Status__c = 'Success'
                );
                insert logObj;

                MobileApp_Wrapper.setResponse(200, 'Follow-up is updated', null);
                return;
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