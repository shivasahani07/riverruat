@RestResource(urlMapping='/TransferEnquiry')
global class MobileAPP_TransferEnquiry {
    @HttpPatch
    global static void createLead() { 
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
            
            MobileApp_Wrapper.MobileApp_TransferEnquiry wrp = 
                (MobileApp_Wrapper.MobileApp_TransferEnquiry) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_TransferEnquiry.class
                );
            
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);   

            
            
            if(wrp.Phone == null || wrp.Phone == '' || String.isBlank(wrp.Phone)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide Phone', null);
                return;
            }
            if (wrp.Phone.length() != 10 || wrp.Phone.startsWith('+91')) {
                MobileApp_Wrapper.setResponse(401, 'Phone must be 10 digits and should not include +91', null);
                return;
            }

            string Phone = wrp.Phone;

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            Map<String, Object> responseData = new Map<String, Object>();
            
            List<Opportunity> oppList = [SELECT Id, StageName FROM Opportunity WHERE Phone__c = :Phone AND AccountId != null AND Account.Phone = :Phone AND StageName != 'Closed Won' ORDER BY CreatedDate DESC];
            
            List<Account> accList = [SELECT Id, Phone,Name FROM Account WHERE Phone = :Phone  ORDER BY CreatedDate DESC];
            
            List<Lead> leadList = [SELECT Id,Name,OwnerId FROM Lead WHERE Phone = :Phone AND Status != 'Converted' AND IsConverted = false ORDER BY CreatedDate DESC];
            
            if (!oppList.isEmpty()) {
                Opportunity opp = oppList[0];
                opp.OwnerId = UserInfo.getUserId();
                update opp;
                
                responseData.put('OpportunityId', opp.Id);
                result.add(responseData);

                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Enquiry Transfer successfully:  ' + opp.Id,
                    Status__c = 'Success'
                );
                insert logObj;
                
                MobileApp_Wrapper.setResponses(200, 'Success', result);
                
            }else if(!accList.isEmpty()){
                Account acc = accList[0];
               
                List<Opportunity> oppLists = [SELECT Id, StageName FROM Opportunity WHERE Phone__c = :Phone AND AccountId != null AND AccountId =: acc.Id AND Account.Phone = :Phone AND StageName != 'Closed Won' ORDER BY CreatedDate DESC];
                Opportunity opp;
                if(!oppLists.isEmpty()){
                    opp = oppLists[0];
                    opp.Phone__c = Phone;
                    opp.Enquiry_Primary_Source__c = 'Walk-In';
                    opp.Secondary_Sources__c = 'Walk-in';
                    opp.OwnerId = UserInfo.getUserId();
                    update opp;
                }else{
                    opp = new Opportunity();
                    opp.accountId = acc.Id;
                    opp.Name = acc.Name;
                    opp.StageName = 'New';
                    opp.OwnerId = UserInfo.getUserId();
                    opp.CloseDate = System.today().addDays(7);                
                    opp.Enquiry_Primary_Source__c = 'Walk-In';
                    opp.Secondary_Sources__c = 'Walk-in';
                    opp.Phone__c = Phone;
                    opp.StageName = 'New';
                    Insert opp;
                }
                
                responseData.put('OpportunityId', opp.Id);
                result.add(responseData);

                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Enquiry Transfer successfully:  ' + opp.Id,
                    Status__c = 'Success'
                );
                insert logObj;
                
                MobileApp_Wrapper.setResponses(200, 'Success', result);  
            } 
            else if (!leadList.isEmpty()) {
                Map<Id, Lead> leadMap = new Map<Id, Lead>(leadList);
                List<Test_Drive__c> testDrivesToCreate = new List<Test_Drive__c>();
                
                if (!leadList.isEmpty()) {
                    Lead lead = leadList[0];
                    Lead.OwnerId = UserInfo.getUserId();
                    update lead;
                    List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
                    
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(lead.Id);
                    lc.setConvertedStatus('Converted');
                    lc.setDoNotCreateOpportunity(false);
                    leadConverts.add(lc);
                    
                    List<Database.LeadConvertResult> results = Database.convertLead(leadConverts);
                    
                    Set<Id> contactIds = new Set<Id>();
                    for (Database.LeadConvertResult res : results) {
                        if (res.isSuccess()) {
                            contactIds.add(res.getContactId());
                        }
                    }
                    Id oppId ; 
                    for (Database.LeadConvertResult res : results) {
                        if (res.isSuccess()) {
                            oppId = res.getOpportunityId();
                            if (oppId != null) {
                                Opportunity opp = new Opportunity(
                                    Id = oppId,
                                    Name = lead.Name,
                                    CloseDate = System.today().addDays(7),
                                    OwnerId = UserInfo.getUserId(),
                                    Enquiry_Primary_Source__c = 'Walk-In',
                                    Secondary_Sources__c = 'Walk-in',
                                    Phone__c = Phone,
                                    StageName = 'New'
                                );
                                update opp;
                            }
                        }
                    }

                    responseData.put('OpportunityId', oppId);
                    result.add(responseData); 

                    Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Mobile App',
                        Request_Payload__c = JSON.serializePretty(body),
                        Response_Payload__c = 'Enquiry Transfer successfully: ' + oppId,
                        Status__c = 'Success'
                    );
                    insert logObj;

                    MobileApp_Wrapper.setResponses(200, 'Success', result);
                }
            } 
            else {
                    Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Mobile App',
                        Request_Payload__c = JSON.serializePretty(body),
                        Response_Payload__c = 'No Lead is there in the system with the phone number' + Phone,
                        Status__c = 'Success'
                    );
                    insert logObj;
                    MobileApp_Wrapper.setResponse(401, 'No Result Found with this Phone Number: ' , null);

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