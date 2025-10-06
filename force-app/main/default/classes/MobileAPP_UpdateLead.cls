@RestResource(urlMapping='/UpdateLead')
global class MobileAPP_UpdateLead {
    @HttpPost
    global static void updateLead() { 
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
            
            MobileApp_Wrapper.MobileApp_UpdateLead wrp = 
                (MobileApp_Wrapper.MobileApp_UpdateLead) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_UpdateLead.class
                );
            
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);    
            
            if (wrp.LeadId == null || String.isBlank(wrp.LeadId) || wrp.LeadId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide LeadId', null);
                return;
            }
            
            if(wrp.LeadStatus == null || wrp.LeadStatus == '' || String.isEmpty(wrp.LeadStatus)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide LeadStatus', null);
                return;
            }

            String LeadId = wrp.LeadId;
            String LeadStatus = wrp.LeadStatus;
            
 
            if(LeadId.startsWith('00Q')) {
                system.debug('LeadId is not null');
                Lead leadRec = new Lead();
                leadRec.Id = LeadId;
                leadRec.Status = LeadStatus;
                update leadRec;

                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Lead updated successfully: ' + leadRec.Id,
                    Status__c = 'Success'
                );
                insert logObj;

                MobileApp_Wrapper.setResponse(200, 'Lead is updated successfully', null);
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