/**
* @description       : 
* @author            : Md Anwar Chikle
* @group             : Anurag Raichand
* @last modified on  : 04/sep/25
* @last modified by  : Md Anwar Chikle
**/

@RestResource(urlMapping='/createLead91Wheels')
global class LeadCreationAPI91Wheels {
    
    @HttpPost
    global static void LeadCreationAPI91Wheels() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        System.debug('requestBody ==> ' + requestBody);
        RestResponse res = RestContext.response;  
        Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        Map<String, Object> responseMap = new Map<String, Object>();
        
        String fullName	         = (String) requestBodyMap.get('FullName');
        String company			 = (String) requestBodyMap.get('Company');
        String email 			 = (String) requestBodyMap.get('Email');
        String phone 			 = (String) requestBodyMap.get('Phone');
        String city 			 = (String) requestBodyMap.get('City');
        String postalCode		 = String.valueOf(requestBodyMap.get('PostalCode'));
        String utm_source 		 = (String) requestBodyMap.get('utm_source');
        String normalizedPhone = phone != null ? phone.replaceAll('[^0-9]', '') : null;
        
        try {
            List<Account> acc       = [SELECT Id FROM Account WHERE Phone = :normalizedPhone LIMIT 1];
            List<Lead> leadRec      = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE Phone = :normalizedPhone LIMIT 1];
            Pin_Code__c pinCode     = [SELECT Id, Name , Dealer_Service_Center__c FROM Pin_Code__c  where Area_Pincode__c = :postalCode LIMIT 1];
            List<Contact> conList   = [SELECT Id, Name FROM contact where AccountId = :pinCode.Dealer_Service_Center__c And Designation__c = 'SM' LIMIT 1];
            User usr;
            if(!conList.isEmpty()){
                usr                 = [SELECT Id, Name FROM User where ContactId = :conList[0].Id LIMIT 1];    
            }
            if (!acc.isEmpty()) {
                List<Opportunity> oppList = [SELECT Id, StageName,accountId FROM Opportunity WHERE AccountId = :acc[0].Id Order By CreatedDate DESC LIMIT 1 ];
                if (!oppList.isEmpty()) {
                    Opportunity opp = oppList[0];
                    if (opp.StageName == 'Closed Won') {
                        Opportunity newOpp = new Opportunity(
                            Name                    = fullName,
                            AccountId               = acc[0].Id,
                            StageName               = 'New',
                            CloseDate               = System.today().addDays(30),
                            Phone__c                = normalizedPhone,
                            LeadSource              = 'Online',
                            Lead_Secondary_Source__c= '91 wheels'
                        );
                        if( usr != null && usr.Id != null){
                            newOpp.OwnerId          = usr.Id;
                        }
                        insert OpportunityTriggerHandler.getOwnerFromPincodeAndAssignToOpp(new List<Opportunity>{newOpp}, postalCode);

                        responseMap.put('status', 'failure');
                        responseMap.put('statuscode', '401');
                        responseMap.put('opportunity Id', newOpp.Id);
                        responseMap.put('account Id', newOpp.accountId);
                        responseMap.put('message', 'Duplicate Lead Found - Lead Exists');
                        
                        insert new Integration_Log__c(
                            Integration_Type__c = 'Opportunity Creation',
                            DML__c              = 'New Opportunity after Closed Won - 91Wheels',
                            Duplicate_Lead_Phone__c = normalizedPhone,
                            Request_Payload__c  = JSON.serializePretty(requestBodyMap),
                            Responses__c  = JSON.serializePretty(responseMap),
                            Response_Payload__c = 'New Opportunity created: ' + newOpp.Id,
                            Status__c           = 'Failed',
                            Opportunity__c      = newOpp.Id,
                            Account__c          = acc[0].Id
                        );
                        sendResponse(responseMap);
                        res.statusCode = 401;
                        res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
                        return;                        
                    } else {
                        opp.StageName               = 'New';
                        opp.Phone__c                = normalizedPhone;
                        if( usr != null && usr.Id  != null){
                            opp.OwnerId             = usr.Id;
                        }
                        update opp;
                        
                        responseMap.put('status', 'failure');
                        responseMap.put('statuscode', '401');
                        responseMap.put('opportunity Id', opp.Id);
                        responseMap.put('account Id', opp.accountId);
                        responseMap.put('message', 'Duplicate Lead Found - Lead Exists');

                        insert new Integration_Log__c(
                            Integration_Type__c     = 'Opportunity Creation',
                            DML__c                  = 'Updated Existing Opportunity - 91Wheels',
                            Duplicate_Lead_Phone__c = normalizedPhone,
                            Request_Payload__c      = JSON.serializePretty(requestBodyMap),
                            Responses__c  = JSON.serializePretty(responseMap),
                            Response_Payload__c     = 'Opportunity updated: ' + opp.Id,
                            Status__c               = 'Failed',
                            Opportunity__c          = opp.Id,
                            Account__c              = acc[0].Id
                        ); 
                        
                        sendResponse(responseMap);
                        res.statusCode = 401;
                        res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
                        return;    
                    }
                }else{
                    Opportunity newOpp = new Opportunity(
                            Name                    = fullName,
                            AccountId               = acc[0].Id,
                            StageName               = 'New',
                            CloseDate               = System.today().addDays(30),
                            Phone__c                = normalizedPhone,
                            LeadSource              = 'Online',
                            Lead_Secondary_Source__c= '91 wheels'
                        );
                        if( usr != null && usr.Id != null){
                            newOpp.OwnerId          = usr.Id;
                        }
                        insert OpportunityTriggerHandler.getOwnerFromPincodeAndAssignToOpp(new List<Opportunity>{newOpp}, postalCode);

                        responseMap.put('status', 'failure');
                        responseMap.put('statuscode', '401');
                        responseMap.put('opportunity Id', newOpp.Id);
                        responseMap.put('account Id', newOpp.accountId);
                        responseMap.put('message', 'Duplicate Lead Found - Lead Exists');

                        insert new Integration_Log__c(
                            Integration_Type__c = 'Opportunity Creation',
                            DML__c              = 'New Opportunity after Closed Won - 91Wheels',
                            Duplicate_Lead_Phone__c = normalizedPhone,
                            Request_Payload__c  = JSON.serializePretty(requestBodyMap),
                            Responses__c  = JSON.serializePretty(responseMap),
                            Response_Payload__c = 'New Opportunity created: ' + newOpp.Id,
                            Status__c           = 'Failed',
                            Opportunity__c      = newOpp.Id,
                            Account__c          = acc[0].Id
                        );
						sendResponse(responseMap);
                        res.statusCode = 401;
                        res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
                        return;    
                }
            }else if (!leadRec.isEmpty()) {
                System.debug('leadRec==>'+leadRec);
                
                if (leadRec[0].IsConverted && leadRec[0].ConvertedAccountId != null) {
                    List<Opportunity> oppList = [SELECT Id, StageName,accountId FROM Opportunity WHERE AccountId = :leadRec[0].ConvertedAccountId Order By CreatedDate DESC LIMIT 1];
                    if (!oppList.isEmpty()) {
                        Opportunity opp = oppList[0];
                        if (opp.StageName == 'Closed Won') {
                            Opportunity newOpp = new Opportunity(
                                Name                    = fullName,
                                AccountId               = leadRec[0].ConvertedAccountId,
                                StageName               = 'New',
                                CloseDate               = System.today().addDays(30),
                                Phone__c                = normalizedPhone,
                                LeadSource              = 'Online',
                                Lead_Secondary_Source__c= '91 wheels'
                            );
                            if( usr != null && usr.Id != null){
                                newOpp.OwnerId          = usr.Id;
                            }
                            insert OpportunityTriggerHandler.getOwnerFromPincodeAndAssignToOpp(new List<Opportunity>{newOpp}, postalCode);
                            
                            responseMap.put('status', 'failure');
                            responseMap.put('statuscode', '401');
                            responseMap.put('opportunity Id', opp.Id);
                            responseMap.put('account Id', opp.accountId);
                            responseMap.put('message', 'Duplicate Lead Found - Lead Exists');

                            insert new Integration_Log__c(
                                Integration_Type__c     = 'Opportunity Creation',
                                DML__c                  = 'New Opportunity after Closed Won - 91Wheels',
                                Duplicate_Lead_Phone__c = normalizedPhone,
                                Request_Payload__c      = JSON.serializePretty(requestBodyMap),
                                Responses__c  = JSON.serializePretty(responseMap),
                                Response_Payload__c     = 'New Opportunity created: ' + newOpp.Id,
                                Status__c               = 'Failed',
                                Opportunity__c          = newOpp.Id,
                                Account__c              = leadRec[0].ConvertedAccountId
                            );
                            sendResponse(responseMap);
                            res.statusCode = 401;
                            res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
                            return;    
                        } else {
                            opp.StageName               = 'New';
                            opp.Phone__c                = normalizedPhone;
                            if( usr != null && usr.Id != null){
                                opp.OwnerId             = usr.Id;
                            }
                            update opp;
                            
                            responseMap.put('status', 'failure');
                            responseMap.put('statuscode', '401');
                            responseMap.put('opportunity Id', opp.Id);
                            responseMap.put('account Id', opp.accountId);
                            responseMap.put('message', 'Duplicate Lead Found - Lead Exists');

                            insert new Integration_Log__c(
                                Integration_Type__c     = 'Opportunity Creation',
                                DML__c                  = 'Updated Opportunity from Converted Lead - 91Wheels',
                                Duplicate_Lead_Phone__c = normalizedPhone,
                                Request_Payload__c      = JSON.serializePretty(requestBodyMap),
                                Responses__c  = JSON.serializePretty(responseMap),
                                Response_Payload__c     = 'Opportunity updated: ' + opp.Id,
                                Status__c               = 'Failed',
                                Opportunity__c          = opp.Id,
                                Account__c              = leadRec[0].ConvertedAccountId
                            );  
                            sendResponse(responseMap);
                            res.statusCode = 401;
                            res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
                            return;    
                        }   
                    }else {
                        Opportunity newOpp = new Opportunity(
                            Name                    = fullName,
                            AccountId               = acc[0].Id,
                            StageName               = 'New',
                            CloseDate               = System.today().addDays(30),
                            Phone__c                = normalizedPhone,
                            LeadSource              = 'Online',
                            Lead_Secondary_Source__c= '91 wheels'
                        );
                        if( usr != null && usr.Id != null){
                            newOpp.OwnerId          = usr.Id;
                        }
                        insert OpportunityTriggerHandler.getOwnerFromPincodeAndAssignToOpp(new List<Opportunity>{newOpp}, postalCode);

                        responseMap.put('status', 'failure');
                        responseMap.put('statuscode', '401');
                        responseMap.put('opportunity Id', newOpp.Id);
                        responseMap.put('account Id', newOpp.accountId);
                        responseMap.put('message', 'Duplicate Lead Found - Lead Exists');

                        insert new Integration_Log__c(
                            Integration_Type__c = 'Opportunity Creation',
                            DML__c              = 'New Opportunity after Closed Won - 91Wheels',
                            Duplicate_Lead_Phone__c = normalizedPhone,
                            Request_Payload__c  = JSON.serializePretty(requestBodyMap),
                            Responses__c  = JSON.serializePretty(responseMap),
                            Response_Payload__c = 'New Opportunity created: ' + newOpp.Id,
                            Status__c           = 'Failed',
                            Opportunity__c      = newOpp.Id,
                            Account__c          = acc[0].Id
                        ); 
                        sendResponse(responseMap);
                        res.statusCode = 401;
                        res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
                        return;                      
                    } 
                } else {
                    leadRec[0].LastName                 = fullName;
                    leadRec[0].Company                  = company;
                    leadRec[0].Email                    = email;
                    leadRec[0].City                     = city;
                    leadRec[0].PostalCode               = postalCode;
                    leadRec[0].Status                   = 'New';
                    leadRec[0].Secondary_Sources__c     = '91 wheels';
                    update leadRec;
                    
                    responseMap.put('status', 'failure');
                    responseMap.put('statuscode', '401');        
                    responseMap.put('Lead Id', leadRec[0].Id);
                    responseMap.put('message', 'Duplicate Lead Found - Lead Exists');

                    insert new Integration_Log__c(
                        Integration_Type__c     = 'Lead Creation',
                        DML__c                  = 'Updated Existing Lead - 91Wheels',
                        Duplicate_Lead_Phone__c = normalizedPhone,
                        Request_Payload__c      = JSON.serializePretty(requestBodyMap),
                        Responses__c  = JSON.serializePretty(responseMap),
                        Response_Payload__c     = 'Lead updated: ' + leadRec[0].Id,
                        Status__c               = 'Failed',
                        Lead__c                 = leadRec[0].Id
                    );
                    sendResponse(responseMap);
                    res.statusCode = 401;
                    res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
                    return;    
                }
                
                
            }else{              
                Lead newLead = new Lead(
                    LastName                = fullName,
                    Company                 = company,
                    Email                   = email,
                    Phone                   = normalizedPhone,
                    City                    = city,
                    PostalCode              = postalCode,
                    LeadSource              = 'Online',
                    Utm_Source__c           = utm_source,
                    Secondary_Sources__c    = '91 wheels'
                );
                insert newLead;
                
                responseMap.put('status', 'Success');
                responseMap.put('statusCode', '200');
                responseMap.put('message', 'New Lead Created');
                responseMap.put('leadId', newLead.Id);

                insert new Integration_Log__c(
                    Integration_Type__c = 'Lead Creation',
                    DML__c              = 'New Lead - 91Wheels',
                    Request_Payload__c  = JSON.serializePretty(requestBodyMap),
                    Responses__c  = JSON.serializePretty(responseMap),
                    Response_Payload__c = 'New Lead created: ' + newLead.Id,
                    Status__c           = 'Success',
                    Lead__c             = newLead.Id
                );
                sendResponse(responseMap);
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
                return;    
            }
        } catch (Exception e) {

            responseMap.put('status', 'Error');
            responseMap.put('statusCode', '400');
            responseMap.put('message', e.getMessage());
            responseMap.put('lineNumber', e.getLineNumber());

            insert new Integration_Log__c(
                Integration_Type__c = 'Lead Creation',
                Request_Payload__c  = JSON.serializePretty(requestBodyMap),
                Responses__c  = JSON.serializePretty(responseMap),
                DML__c              = 'Exception - 91Wheels',
                Response_Payload__c = 'Error: ' + e.getMessage(),
                Error_Message__c    = 'Exception: ' + e.getMessage() + ' at line: ' + e.getLineNumber(),
                Status__c           = 'Failed'
            );
            
            system.debug('message  ======>'+ e.getMessage() + 'lineNumber ======>'+ e.getLineNumber());
            sendResponse(responseMap);
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
            return;    
        }
    }
    
    private static void sendResponse(Map<String, Object> responseMap) {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serializePretty(responseMap));
    }
}