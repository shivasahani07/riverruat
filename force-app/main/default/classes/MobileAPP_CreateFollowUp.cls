@RestResource(urlMapping='/CreateFollowUp')
global class MobileAPP_CreateFollowUp {
    @HttpPost
    global static void createFollowup() { 

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
            
            MobileApp_Wrapper.MobileApp_CreateFollowUp wrp = 
                (MobileApp_Wrapper.MobileApp_CreateFollowUp) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_CreateFollowUp.class
                );
            
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);    
            
            if (wrp.UserId == null || String.isBlank(wrp.UserId) || wrp.UserId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide UserId', null);
                return;
            }
            if (wrp.LeadId == null  || String.isBlank(wrp.LeadId) || wrp.LeadId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide LeadId', null);
                return;
            }
            if (wrp.FollowUpDate == null || String.isBlank(wrp.FollowUpDate) || wrp.FollowUpDate == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide FollowUpDate', null);
                return;
            }
            if (wrp.FollowUpTime == null || String.isBlank(wrp.FollowUpTime) || wrp.FollowUpTime == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide FollowUpTime', null);
                return;
            }
            // if (wrp.FollowUpFeedback == null || String.isBlank(wrp.FollowUpFeedback) || wrp.FollowUpFeedback == '') {
            //     MobileApp_Wrapper.setResponse(401, 'Please provide FollowUpFeedback', null);
            //     return;
            // }
            
            String userId = wrp.UserId;
            String leadId = wrp.LeadId;
            String followUpDate = wrp.FollowUpDate;
            String followUpTime = wrp.FollowUpTime;
            String followUpFeedback = wrp.FollowUpFeedback;
            String followUpType = wrp.followUpType;
            String followUpReason = wrp.followUpReason;
            String followUpSubReason = wrp.followUpSubReason;
            String followUpOther = wrp.followUpOther;
            
            system.debug('UserId ========>' + userId);
            system.debug('LeadId ========> ' + LeadId);
            system.debug('followUpDate ========>' + followUpDate);
            system.debug('followUpTime ========>' + followUpTime);
            system.debug('followUpFeedback ========> ' + followUpFeedback);
            system.debug('followUpType ========> ' + followUpType);
            system.debug('followUpReason ========> ' + followUpReason);
            system.debug('followUpSubReason ========> ' + followUpSubReason);
            system.debug('followUpOther ========> ' + followUpOther);

            
            
            Date datePart = Date.valueOf(followUpDate);
            List<String> timeParts = followUpTime.split(':');
            System.debug('timeParts ========>' + timeParts);
            
            Integer hour = Integer.valueOf(timeParts[0]);
            System.debug('hour ========>' + hour);
            
            Integer minute = Integer.valueOf(timeParts[1]);
            System.debug('minute ========>' + minute);
            
            Time timePart = Time.newInstance(hour, minute, 0, 0);
            System.debug('timePart ========>' + timePart);
            
            Datetime followUpDateTime = Datetime.newInstance(datePart, timePart);
            System.debug('followUpDateTime ========>' + followUpDateTime);

            Follow_Up__c followUp = new Follow_Up__c();
            // if(leadId.startsWith('00Q')) {
            //     List<Lead> leadList = [SELECT Id,Name FROM Lead WHERE Id = :leadId LIMIT 1];
            //     if(leadList.size() == 0) {
            //         MobileApp_Wrapper.setResponse(404, 'Lead not found', null);
            //         return;
            //     }else{
            //         followUp.Name = leadList[0].Name + ' Follow Up';
            //     }
            // }
            if(leadId.startsWith('006')) {
                List<Opportunity> oppList = [SELECT Id,Name FROM Opportunity WHERE Id = :leadId LIMIT 1];
                if(oppList.size() == 0) {
                    MobileApp_Wrapper.setResponse(404, 'Opportunity not found', null);
                    return;
                }else{
                    followUp.Name = oppList[0].Name + ' - Follow Up';
                }
            }
            
            followUp.OwnerId = userId;
            // if(leadId.startsWith('00Q')) {
            //     followUp.Lead__c = leadId;
            // }
            if(leadId.startsWith('006')) {
                followUp.Opportunity__c = leadId;
            }
            followUp.Follow_Up_Date__c = followUpDateTime;
            //followUp.Feedback__c = followUpFeedback;
            //followUp.Status__c = 'New';
            followUp.followUpType__c = followUpType;
            followUp.Status__c = followUpReason != null ? followUpReason : 'New';
            followUp.Follow_Up_Remarks__c = followUpSubReason;
            followUp.Feedback__c = followUpOther;
            insert followUp;
            
            if(followUp.Id == null) {
                MobileApp_Wrapper.setResponse(500, 'Follow Up not created', null);
                return;
            }else{

                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Follow Created successfully: ' + followUp.Id,
                    Status__c = 'Success'
                );
                insert logObj;

                MobileApp_Wrapper.setResponse(200, 'Follow Up Created', null);
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