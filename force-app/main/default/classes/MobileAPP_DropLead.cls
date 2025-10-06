@RestResource(urlMapping='/DropLead')
global class MobileAPP_DropLead {
    @HttpPatch
    global static void DropLead() { 
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
            
            MobileApp_Wrapper.MobileApp_DropLead wrp = 
                (MobileApp_Wrapper.MobileApp_DropLead) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_DropLead.class
                );
            
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);    
            
            if (wrp.LeadId == null || String.isBlank(wrp.LeadId) || wrp.LeadId == '') {
                MobileApp_Wrapper.setResponse(401, 'Please provide LeadId', null);
                return;
            }
            
            if(wrp.DropOutReason == null || wrp.DropOutReason == '' || String.isEmpty(wrp.DropOutReason)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide DropOutReason', null);
                return;
            }
            if(wrp.DropOutSubReason == null || wrp.DropOutSubReason == '' || String.isEmpty(wrp.DropOutSubReason)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide DropOutSubReason', null);
                return;
            }

            if(wrp.DropOutSubReason == 'Others – need reason'){
                if(wrp.Others == null || wrp.Others == '' || String.isEmpty(wrp.Others)) {
                    MobileApp_Wrapper.setResponse(401, 'Please provide Others', null);
                    return;
                }
            }
            String userId = wrp.UserId;
            String LeadId = wrp.LeadId;
            String DropOutReason = wrp.DropOutReason;
            String DropOutSubReason = wrp.DropOutSubReason;
            String Others = wrp.Others;
            
            system.debug('UserId ========>' + userId);
            system.debug('LeadId ========> ' + LeadId);
            system.debug('DropOutReason ========>' + DropOutReason);
            system.debug('DropOutSubReason ========>' + DropOutSubReason);
            system.debug('Others ========> ' + Others);
            
            // if(LeadId.startsWith('00Q')) {
            //     system.debug('LeadId is not null');
            //     Lead leadRec = new Lead();
            //     leadRec.Id = LeadId;
            //     leadRec.Lost_Reason__c = DropOutReason;
            //     leadRec.Lost_Feedback__c = Others;
            //     leadRec.Status = 'Drop Out';
            //     update leadRec;

            //     Integration_Log__c logObj = new Integration_Log__c(
            //             Integration_Type__c = 'Mobile App',
            //             Request_Payload__c = JSON.serializePretty(body),
            //             Response_Payload__c = 'Lead updated successfully: ' + leadRec.Id,
            //             Status__c = 'Success'
            //         );
            //         insert logObj;

            //     MobileApp_Wrapper.setResponse(200, 'Lead is updated successfully', null);
            //     return;
            // } else 
            if(LeadId.startsWith('006')){
                Opportunity oppRec = new Opportunity();
                oppRec.Id = LeadId;
                oppRec.Drop_Out_Reasons__c = DropOutReason;
                oppRec.Drop_Out_Sub_Reasons__c = DropOutSubReason;
                oppRec.Others__c = Others;
                update oppRec;

                oppRec.StageName = 'Drop Out';
                update oppRec;

                Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Mobile App',
                        Request_Payload__c = JSON.serializePretty(body),
                        Response_Payload__c = 'opportunity updated successfully: ' + oppRec.Id,
                        Status__c = 'Success'
                    );
                    insert logObj;

                MobileApp_Wrapper.setResponse(200, 'Lead is updated successfully', null);
                return;
            }else{
                 Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Mobile App',
                        Request_Payload__c = JSON.serializePretty(body),
                        Response_Payload__c = 'opportunity updated successfully: ' + LeadId,
                        Status__c = 'Success'
                    );
                    insert logObj;

                MobileApp_Wrapper.setResponse(401, 'lead id is not correct', null);
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