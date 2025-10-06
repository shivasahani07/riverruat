@RestResource(urlMapping='/CreateLead')
global class MobileAPP_CreateLead {
    @HttpPost
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
            
            MobileApp_Wrapper.MobileApp_CreateLead wrp = 
                (MobileApp_Wrapper.MobileApp_CreateLead) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_CreateLead.class
                );
            
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);   
            
            // bookATestRide
            // TestDriveDate
            // TestDriveTime
            // RideType
            // HomeTestDriveAddress
            
            if(wrp.FirstName == null || wrp.FirstName == '' || String.isBlank(wrp.FirstName)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide FirstName', null);
                return;
            }
            
            if(wrp.LastName == null || wrp.LastName == '' || String.isBlank(wrp.LastName)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide LastName', null);
                return;
            }
            
            // if(wrp.Email == null || wrp.Email == '' || String.isBlank(wrp.Email)) {
            //     MobileApp_Wrapper.setResponse(401, 'Please provide Email', null);
            //     return;
            // }
            
            if(wrp.Phone == null || wrp.Phone == '' || String.isBlank(wrp.Phone)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide Phone', null);
                return;
            }
            if (wrp.Phone.length() != 10 || wrp.Phone.startsWith('+91')) {
                MobileApp_Wrapper.setResponse(401, 'Phone must be 10 digits and should not include +91', null);
                return;
            }
            
            if(wrp.LeadSource == null || wrp.LeadSource == '' || String.isBlank(wrp.LeadSource)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide LeadSource', null);
                return;
            }
            
            if(wrp.LeadSecondarySource == null || wrp.LeadSecondarySource == '' || String.isBlank(wrp.LeadSecondarySource)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide LeadSecondarySource', null);
                return;
            }

            String FirstName = wrp.FirstName;
            string LastName = wrp.LastName;
            string Email = wrp.Email;
            string Phone = wrp.Phone;
            string LeadSource = wrp.LeadSource;
            String LeadSecondarySource = wrp.LeadSecondarySource;
            
            List<Map<String, Object>> result = new List<Map<String, Object>>();
            Map<String, Object> responseData = new Map<String, Object>();
            
            List<Opportunity> oppList = [SELECT Id, StageName FROM Opportunity WHERE Phone__c = :Phone AND AccountId != null AND Account.Phone = :Phone AND StageName != 'Closed Won' ORDER BY CreatedDate DESC];
            
            List<Account> accList = [SELECT Id, Phone,Name FROM Account WHERE Phone = :Phone  ORDER BY CreatedDate DESC];
            
            List<Lead> leadList = [SELECT Id,Name,OwnerId FROM Lead WHERE Phone = :Phone AND Status != 'Converted' AND IsConverted = false ORDER BY CreatedDate DESC];
            
            if (!oppList.isEmpty()) {
                Opportunity opp = oppList[0];
                opp.Name = FirstName + ' ' + LastName;
                opp.Enquiry_Primary_Source__c = LeadSource;
                opp.Secondary_Sources__c = LeadSecondarySource;
                opp.OwnerId = UserInfo.getUserId();
                opp.Phone__c = Phone;
                update opp;
                
                responseData.put('OpportunityId', opp.Id);
                result.add(responseData);

                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Enquiry Created successfully: ' + opp.Id,
                    Status__c = 'Success'
                );
                insert logObj;
                
                MobileApp_Wrapper.setResponses(200, 'Success', result);
                
            }else if(!accList.isEmpty()){
                Account acc = accList[0];
               
                Opportunity opp = new Opportunity();
                opp.Name = FirstName + ' ' + LastName;
                opp.CloseDate = System.today() + 7;
                opp.AccountId = acc.Id;
                opp.StageName = 'New';
                opp.Phone__c = Phone;
                opp.Enquiry_Primary_Source__c = LeadSource;
                opp.Secondary_Sources__c = LeadSecondarySource;
                opp.OwnerId = UserInfo.getUserId();
                Insert opp;
                
                responseData.put('OpportunityId', opp.Id);
                result.add(responseData);

                Integration_Log__c logObj = new Integration_Log__c(
                    Integration_Type__c = 'Mobile App',
                    Request_Payload__c = JSON.serializePretty(body),
                    Response_Payload__c = 'Enquiry Created successfully: ' + opp.Id,
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
                                    Enquiry_Primary_Source__c = LeadSource,
                                    Secondary_Sources__c = LeadSecondarySource,
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
                        Response_Payload__c = 'Enquiry Created successfully: ' + oppId,
                        Status__c = 'Success'
                    );
                    insert logObj;

                    MobileApp_Wrapper.setResponses(200, 'Success', result);
                }
            } 
            else {
                    Map<String,String> mapOfPincodeAndCenterName = new Map<String,String>();
                    Map<String, String> mapOfPincodeAndDealerCode = new Map<String, String>();
                    Map<String, String> mapOfPincodeAndCityName = new Map<String, String>();
                    Map<String, String> mapOfDealerCodeAndCityName = new Map<String, String>();
                    
                    for (Pin_Code__c grp : [SELECT Id, Dealer_Service_Center__c,Dealer_Service_Center__r.Name,Dealer_Service_Center__r.Center_Code__c,
                                            Dealer_Service_Center__r.Store_Name__c,City__r.Name,Area_Pincode__c FROM Pin_Code__c]) {
                                                mapOfPincodeAndCenterName.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Store_Name__c);
                                                mapOfPincodeAndDealerCode.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Center_Code__c);
                                                mapOfPincodeAndCityName.put(grp.Area_Pincode__c, grp.City__r.Name);
                                                mapOfDealerCodeAndCityName.put(grp.Dealer_Service_Center__r.Center_Code__c, grp.City__r.Name);
                                            }
                    
                    User usrObj = [select Id,firstname,Contact.Account.Name,Profile.Name,Contact.Account.Center_Code__c,Contact.Account.BillingPostalCode,Contact.Account.Store_Name__c from user where id=:userinfo.getuserid()];
                    
                    String DealerCode = usrObj.Contact.Account.Center_Code__c;
                    String StoreName = usrObj.Contact.Account.Store_Name__c;
                    String CityName = mapOfDealerCodeAndCityName.get(DealerCode);
                    String postalCode = usrObj.Contact.Account.BillingPostalCode;
 
                    Account acc = new Account();
                    acc.Name = FirstName + ' ' + LastName;
                    acc.Phone = phone;
                    acc.BillingPostalCode = postalCode;
                    acc.ownerId = UserInfo.getUserId();
                    acc.Center_Code__c = DealerCode;
                    acc.Store_Name__c = StoreName;
                    acc.BillingCity = CityName;
                    acc.Type = 'Customer';
                    insert acc;
                    
                    Contact con = new Contact();
                    con.FirstName = FirstName;
                    con.LastName = LastName;
                    con.Phone = phone;
                    con.AccountId = acc.Id;
                    con.ownerId = UserInfo.getUserId();
                    insert con;
                    
                    Opportunity newOpp = new Opportunity(); 
                    newOpp.Name = FirstName + ' ' + LastName;
                    newOpp.AccountId = acc.Id;
                    newOpp.StageName = 'New';
                    newOpp.Enquiry_Primary_Source__c = LeadSource;
                    newOpp.Secondary_Sources__c = LeadSecondarySource;
                    newOpp.CloseDate = System.today().addDays(7);
                    newOpp.ownerId = UserInfo.getUserId();
                    newOpp.Phone__c = phone;
                    insert newOpp;
                    
                    OpportunityContactRole ocr = new OpportunityContactRole();
                    ocr.OpportunityId = newOpp.Id;
                    ocr.ContactId = con.Id;
                    ocr.Role = 'Decision Maker';
                    ocr.IsPrimary = true;
                    insert ocr;

                    Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Mobile App',
                        Request_Payload__c = JSON.serializePretty(body),
                        Response_Payload__c = 'Enquiry Created successfully: ' + newOpp.Id,
                        Status__c = 'Success'
                    );
                    insert logObj;

                    responseData.put('OpportunityId', newOpp.Id);
                    result.add(responseData); 
                    MobileApp_Wrapper.setResponses(200, 'Success', result);

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