/**
* @description       :
* @author            : Aniket Karmakar
* @group             :
* @last modified on  : 02-17-2025
* @last modified by  :
**/
public class LeadTriggerHandler {

    public static Boolean isConverting = false;
    public static Set<Id> convertingLeadIds = new Set<Id>();

    public static void pincodeIsMandatory(List<Lead> newLeads){
        try{
            for(Lead ledRec : newLeads){
                if (ledRec.postalCode == null || ledRec.postalCode.length() < 6) {
                    ledRec.postalCode.addError('Enter Proper Pincode');
                }
            }
        }catch(Exception e){
            System.debug('error message =====> '+ e.getMessage() + ' at line number =====>'+ e.getLineNumber());
        }
    }

    public static void checkForConversion(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        for(Lead newLead : newLeads) {
            Lead oldLead = oldMap.get(newLead.Id);
            if(oldLead != null && !oldLead.IsConverted && newLead.IsConverted) {
                isConverting = true;
                convertingLeadIds.add(newLead.Id);
                break;
            }
        }
    }
    
    public static void dontCreateDuplicateLead(List<Lead> newLeads) {
        try {
            System.debug('==== Entering dontCreateDuplicateLead ====');
            System.debug('Incoming newLeads size: ' + (newLeads != null ? newLeads.size() : 0));
            System.debug('isConverting: ' + isConverting);
            System.debug('convertingLeadIds: ' + convertingLeadIds);

            if (isConverting && convertingLeadIds.isEmpty()) {
                System.debug('Returning early because convertingLeadIds is empty while converting');
                return;
            }

            Set<String> setOfPhoneNumbers = new Set<String>();
            Set<Id> currentLeadIds = new Set<Id>();

            for (Lead ledRec : newLeads) {
                System.debug('Processing Lead Id: ' + ledRec.Id + ', Phone: ' + ledRec.Phone);
                if (!String.isBlank(ledRec.Phone)) {
                    setOfPhoneNumbers.add(ledRec.Phone);
                }
                currentLeadIds.add(ledRec.Id);
            }

            System.debug('Collected Phone Numbers: ' + setOfPhoneNumbers);
            System.debug('Collected Lead Ids: ' + currentLeadIds);

            if (setOfPhoneNumbers.isEmpty()) {
                System.debug('No phone numbers found, returning early');
                return;
            }

            Map<String, Account> phoneToAccountMap = new Map<String, Account>();
            if (!isConverting) {
                System.debug('Fetching Accounts with matching phone numbers...');
                for (Account acc : [SELECT Id, Phone FROM Account WHERE Phone IN :setOfPhoneNumbers]) {
                    System.debug('Account found - Id: ' + acc.Id + ', Phone: ' + acc.Phone);
                    if (!String.isBlank(acc.Phone)) {
                        phoneToAccountMap.put(acc.Phone, acc);
                    }
                }
            }
            System.debug('phoneToAccountMap: ' + phoneToAccountMap.keySet());

            Map<String, List<Lead>> phoneToLeadMap = new Map<String, List<Lead>>();
            String leadQuery = 'SELECT Id, Phone FROM Lead WHERE Phone IN :setOfPhoneNumbers';

            if (isConverting && !convertingLeadIds.isEmpty()) {
                leadQuery += ' AND Id NOT IN :convertingLeadIds';
            }

            System.debug('Final Lead Query: ' + leadQuery);
            for (Lead existingLead : Database.query(leadQuery)) {
                System.debug('Existing Lead found - Id: ' + existingLead.Id + ', Phone: ' + existingLead.Phone);
                if (!String.isBlank(existingLead.Phone)) {
                    if (!phoneToLeadMap.containsKey(existingLead.Phone)) {
                        phoneToLeadMap.put(existingLead.Phone, new List<Lead>());
                    }
                    phoneToLeadMap.get(existingLead.Phone).add(existingLead);
                }
            }
            System.debug('phoneToLeadMap keys: ' + phoneToLeadMap.keySet());

            for (Lead ledRec : newLeads) {
                System.debug('Checking duplicates for Lead Id: ' + ledRec.Id + ', Phone: ' + ledRec.Phone);
                if (String.isBlank(ledRec.Phone)) {
                    System.debug('Skipping Lead as phone is blank');
                    continue;
                }

                if (isConverting && convertingLeadIds.contains(ledRec.Id)) {
                    System.debug('Skipping converting lead Id: ' + ledRec.Id);
                    continue;
                }

                if (phoneToLeadMap.containsKey(ledRec.Phone)) {
                    System.debug('Found duplicate Lead(s) for phone: ' + ledRec.Phone);
                    for (Lead dupLead : phoneToLeadMap.get(ledRec.Phone)) {
                        if (dupLead.Id != ledRec.Id) {
                            System.debug('Duplicate Lead detected. Adding error.');
                            ledRec.addError('Lead already exists with this phone number');
                            break;
                        }
                    }
                }

                if (!isConverting && phoneToAccountMap.containsKey(ledRec.Phone)) {   
                    System.debug('Matching Account found for phone: ' + ledRec.Phone);
                    ledRec.addError('Account already exists with this phone number');
                    break;
                }
            }

            System.debug('==== Exiting dontCreateDuplicateLead ====');

        } catch (Exception e) {
            System.debug('Error in dontCreateDuplicateLead: ' + e.getMessage() + ' at line: ' + e.getLineNumber() + ', stack trace: ' + e.getStackTraceString());
        }
    }

    
    public static void resetConversionContext() {
        isConverting = false;
        convertingLeadIds.clear();
    }
    
    public static void OthersIsMandatoryIsSourceIsOther(List<Lead> newLeads){
        try{
            for(Lead ledRec : newLeads){
                if (ledRec.Secondary_Sources__c != null && ledRec.Secondary_Sources__c == 'Others' && ledRec.Others__c == null) {
                    ledRec.Others__c.addError('Please Mentioned the Source Name');
                }
            }
        }catch(Exception e){
            System.debug('error message =====> '+ e.getMessage() + ' at line number =====>'+ e.getLineNumber());
        }
    }
    
    public static void callQueableMethodForNewLead(List<Lead> newLeads){
        String templateName = 'new_lead_book_a_test_ride_03';
        try{
            List<Store_Details__mdt> dealerCodes = [Select id,Dealer_Code__c,IsActive__c From Store_Details__mdt WHERE IsActive__c = true];
            
            List<Id> newLeadIds = new List<Id>();
            Map<Id,String> newLeadMap = new Map<Id,String>();
            Set<String> storeDealerCodes = new Set<String>();
            
            for(Store_Details__mdt s : dealerCodes){
                storeDealerCodes.add(s.Dealer_Code__c);
            }
            
            List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
            WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
            String imageUrl = w.new_lead_book_a_test_ride_03__c;
            
            //new enhancement by Aniket on 18/02/2025
            Set<Id> leadIds = new Set<Id>();
            for(Lead l : newLeads){
                leadIds.add(l.Id);
                
            }
            List<Lead> leadListToFetch = [Select Id,LeadSource,Phone,Dealer_Code__c,Lead_Dealer_Code__c FROM Lead WHERE (Dealer_Code__c IN:storeDealerCodes OR Lead_Dealer_Code__c IN:storeDealerCodes) AND Id IN:leadIds];
            //up to here
            // String templateName = 'new_lead_book_a_test_ride_03';
            if(!leadListToFetch.isEmpty()){
                for(Lead lead : leadListToFetch){
                    if((lead.LeadSource == 'Bike Dekho' || lead.LeadSource =='Facebook'||lead.LeadSource=='Google'||lead.LeadSource=='91Wheels') && (storeDealerCodes.contains(lead.Dealer_Code__c)||storeDealerCodes.contains(lead.Lead_Dealer_Code__c)) && lead.Phone !=null ){
                        newLeadIds.add(lead.Id);
                        newLeadMap.put(lead.Id,lead.Phone);
                    }
                }
                if(newLeadIds!=null && templateName!=null && imageUrl!=null && newLeadMap!=null){
                    System.enqueueJob(new QueueableForImageTemplateMsg(newLeadIds, templateName, imageUrl, newLeadMap));
                }
            }
            
        }catch(Exception e){
            System.debug('Error is ==>'+e.getMessage());
            System.debug('Error Line ==>'+e.getLineNumber());
            System.debug('Error Cause ==>'+e.getCause());
        }
    }
    
    public static void callQueableMethodForAfterUpdate(List<Lead> newLeads,Map<Id,Lead> oldLeadMap){
        String templateName = 'new_lead_book_a_test_ride_03';
        try{
            List<Store_Details__mdt> dealerCodes = [Select id,Dealer_Code__c,IsActive__c From Store_Details__mdt WHERE IsActive__c = true];
            List<Id> newLeadIds = new List<Id>();
            Map<Id,String> newLeadMap = new Map<Id,String>();
            
            Set<String> storeDealerCodes = new Set<String>();
            
            for(Store_Details__mdt s : dealerCodes){
                storeDealerCodes.add(s.Dealer_Code__c);
            }
            List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
            
            WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
            String imageUrl = w.new_lead_book_a_test_ride_03__c;
            // String templateName = 'new_lead_book_a_test_ride_03';
            
            List<Lead> leadsToUpdate = new List<Lead>();
            if(!newLeads.isEmpty()){
                for(Lead lead : newLeads){
                    if(lead.Dealer_Code__c != oldLeadMap.get(lead.Id).Dealer_Code__c && (lead.LeadSource == 'Bike Dekho' || lead.LeadSource =='Facebook'||lead.LeadSource=='Google'||lead.LeadSource=='91Wheels') && storeDealerCodes.contains(lead.Dealer_Code__c) && lead.Phone !=null &&lead.WhatsApp_Sent_After_Update__c == false){
                        System.debug('new dealer code ====>'+ lead.Dealer_Code__c);
                        System.debug('old dealer code ======>'+ lead.Dealer_Code__c);
                        
                        newLeadIds.add(lead.Id);
                        newLeadMap.put(lead.Id,lead.Phone);
                        leadsToUpdate.add(new Lead(Id=lead.Id,WhatsApp_Sent_After_Update__c = true));
                        
                    }
                    
                }
                if(!leadsToUpdate.isEmpty()){
                    update leadsToUpdate;
                }
                if(!newLeadIds.isEmpty() && templateName!=null && imageUrl!=null && !newLeadMap.isEmpty()){
                    System.debug('1 is running======>');
                    System.debug('newLeadIds======>' + newLeadIds);
                    System.debug('templateName======>' + templateName);
                    System.debug('imageUrl======>' + imageUrl);
                    System.debug('newLeadMap======>' + newLeadMap);
                    System.enqueueJob(new QueueableForImageTemplateMsg(newLeadIds, templateName, imageUrl, newLeadMap));
                }
                
            }
            
        }catch(Exception e){
            System.debug('Error is ==>'+e.getMessage());
            System.debug('Error Line ==>'+e.getLineNumber());
            System.debug('Error Cause ==>'+e.getCause());
        }
    }
    
    public static void callQueueableAfterRNR(List<Lead> newLeadList,Map<Id,Lead> oldLeadMap){
        String templateName = 'rnr_whatsapp_book_test_ride';
        try{
            // List<Store_Details__mdt> dealerCodes = [Select id,Dealer_Code__c,IsActive__c From Store_Details__mdt WHERE IsActive__c = true];
            
            List<Id> newLeadIds = new List<Id>();
            Map<Id,String> newLeadMap = new Map<Id,String>();
            Set<String> storeDealerCodes = new Set<String>();
            // for(Store_Details__mdt s : dealerCodes){
            //     storeDealerCodes.add(s.Dealer_Code__c);
            // }
            List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
            WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
            String imageUrl = w.rnr_whatsapp_book_test_ride__c;
            Set<Id> toGettestDrives = new Set<Id>();
            for(Lead lead : newLeadList){
                toGettestDrives.add(lead.Id);
            }
            if(toGettestDrives.isEmpty()){
                System.debug('No leads found to process for RNR test drives.');
                return;
                
            }
            List<Lead> leadList = [SELECT Id,Name,Phone,Status,(Select Id from Test_Drives__r) from Lead where Id IN: toGettestDrives];
            
            if(!leadList.isEmpty()){
                for(Lead l : leadList){
                    if(l.Status == 'RNR' && l.Status != oldLeadMap.get(l.Id).Status && l.Phone !=null && l.Test_Drives__r.isEmpty()){ /*storeDealerCodes.contains(l.Dealer_Code__c) &&*/
                        newLeadIds.add(l.Id);
                        newLeadMap.put(l.Id,l.Phone);
                    }
                }
                System.debug('newLeadIds==>'+newLeadIds);
                System.debug('newLeadMap==>'+newLeadMap);
                
                if(!newLeadIds.isEmpty() && (templateName!=null && imageUrl!=null && !newLeadMap.isEmpty())){
                    System.debug('2 is running======>');
                    System.enqueueJob(new QueueableForImageTemplateMsg(newLeadIds, templateName, imageUrl, newLeadMap));
                }
            }
        }catch(Exception e){
            System.debug('Error is ===>'+e.getMessage());
            System.debug('Error Line Number  ===>'+e.getLineNumber());
            
        }
    }
    
    public static void updatePreferredSeller(List<Lead> leadList) {
        System.debug('Entering updatePreferredSeller method.');
        
        if (leadList == null || leadList.isEmpty()) {
            System.debug('No leads fond');
            return;
        }
        
        User currentUser;
        try {
            currentUser = [
                SELECT Id, Profile.Name, Account.Name 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('Error fetching current user: ' + e.getMessage());
            return;
        }
        
        if (currentUser == null) {
            System.debug('No current user found.');
            return;
        }
        
        System.debug('Current User Details: ' + currentUser);
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead lead : leadList) {  
            if (lead != null) {
                if (lead.Is_Order_Created__c == true) {
                    System.debug('Lead ' + lead.Id + ' has order created. Finding preferred store...');
                    String preferredStoreId = getLeadOwnerByPincode(lead.postalCode); // ← you provide this logic
                    if (preferredStoreId != null) {
                        System.debug('Assigning preferred store: ' + preferredStoreId);
                        lead.Dealer_Code__c = preferredStoreId;
                        lead.Dealer_Allocation__c = true;
                    }
                }
                else if ('Sales Manager (Partner)'.equalsIgnoreCase(currentUser.Profile.Name) && currentUser.Account != null) {
                    System.debug('User is a Sales Manager (Partner) with Account: ' + currentUser.Account.Name);
                    lead.PreferredSeller__c = currentUser.Account.Id;
                }
            }
        }  
        System.debug('Exiting updatePreferredSeller method.');
    }

    public static void enqueueLeadProcessing(List<Lead> newLeads) {
        List<Id> leadIds = new List<Id>();
        for (Lead ld : newLeads) {
            leadIds.add(ld.Id);
        }
        
        if (!leadIds.isEmpty()) {
            System.enqueueJob(new LeadProcessingQueueable(leadIds, UserInfo.getUserId()));
        }
    }
    
    public static void callFutureLeadConversion(List<Lead> leadList) {
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        for (Lead l : leadList) {
            if (l.Book_Bike__c || l.WhatsApp_Sent_After_Update__c) {
                leadMap.put(l.Id, l);
            }
        }
        if (!leadMap.isEmpty()) {
            String jsonData = JSON.serialize(leadMap);
            handleLeadConversion(jsonData);
        }
    }
    
    @future public static void handleLeadConversion(String leadMapJson) {
        try {
            Map<String, Object> rawMap = (Map<String, Object>) JSON.deserializeUntyped(leadMapJson);
            Map<Id, Lead> leadMap = new Map<Id, Lead>();
            
            for (String key : rawMap.keySet()) {
                Map<String, Object> values = (Map<String, Object>) rawMap.get(key);
                Lead leadObj = new Lead();
                leadObj.Id = Id.valueOf(key);
                leadObj.Book_Bike__c = (Boolean) values.get('Book_Bike__c');
                leadObj.WhatsApp_Sent_After_Update__c = (Boolean) values.get('WhatsApp_Sent_After_Update__c');
                leadMap.put(leadObj.Id, leadObj);
            }
            
            List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
            List<Account> accountsToUpdate = new List<Account>();
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            List<Test_Drive__c> testDrivesToCreate = new List<Test_Drive__c>();
            
            for (Lead lead : leadMap.values()) {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lead.Id);
                lc.setConvertedStatus('Converted');
                lc.setDoNotCreateOpportunity(false);
                leadConverts.add(lc);
            }
            
            if (!leadConverts.isEmpty()) {
                List<Database.LeadConvertResult> results = Database.convertLead(leadConverts);
                
                Set<Id> contactIds = new Set<Id>();
                for (Database.LeadConvertResult res : results) {
                    if (res.isSuccess()) {
                        contactIds.add(res.getContactId());
                    }
                }
                
                Map<Id, Contact> contactMap = new Map<Id, Contact>(
                    [SELECT Id, Name FROM Contact WHERE Id IN :contactIds]
                );
                
                for (Database.LeadConvertResult res : results) {
                    if (res.isSuccess()) {
                        Lead lead = leadMap.get(res.getLeadId());
                        Contact con = contactMap.get(res.getContactId());
                        Id accId = res.getAccountId();
                        Id oppId = res.getOpportunityId();
                        
                        if (accId != null) {
                            accountsToUpdate.add(new Account(Id = accId, Name = con.Name));
                        }
                        
                        if (oppId != null) {
                            Opportunity opp = new Opportunity(
                                Id = oppId,
                                Name = con.Name,
                                CloseDate = System.today().addDays(30),
                                Probability = lead.Book_Bike__c ? 100 : null
                            );
                            
                            if(lead.WhatsApp_Sent_After_Update__c == true){
                                opp.StageName = 'Test Ride Scheduled';
                            }
                            else if(lead.Book_Bike__c == true){
                                opp.StageName = 'Test Ride Scheduled';
                            }
                            oppsToUpdate.add(opp);

                            
                            
                            if (lead.WhatsApp_Sent_After_Update__c) {
                                testDrivesToCreate.add(new Test_Drive__c(
                                    Name = con.Name + ' -- Test Drive',
                                    Lead__c = lead.Id,
                                    Opportunity__c = opp.Id,
                                    Test_Drive_Status__c = 'Scheduled',
                                    Test_Drive_Date__c = System.today(),
                                    Subject__c = 'Scheduled Event for Test Ride',
                                    DurationInMinutes__c = 30
                                ));
                            }
                        }
                    }
                }
                
                if (!accountsToUpdate.isEmpty()) update accountsToUpdate;
                if(!oppsToUpdate.isEmpty()){
                    update oppsToUpdate;
                    OpportunityTriggerHandler.assignOpportunityToSM(oppsToUpdate);
                }
                
                if (!testDrivesToCreate.isEmpty()) insert testDrivesToCreate;
            }
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
        }
    }
    
    public static void beforeConversionCheckAnyFollowIsOpendThenThrowError(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap) {
        for (Lead lead : newLeadList) {
            if (lead.Status == 'Converted' && oldLeadMap.get(lead.Id).Status != 'Converted') {
                if(lead.PostalCode == null){
                    lead.addError('Postal Code is required to convert the lead');
                }
            }
        }
    }
    
    public static void phoneNumberValidation(List<Lead> newLeadList) {
        for (Lead lead : newLeadList) {
            if (String.isNotBlank(lead.Phone)) {
                String phone = lead.Phone.trim();
                
                if (phone.startsWith('+91')) {
                    phone = phone.substring(3);
                }
                
                phone = phone.replaceAll('[^0-9]', ''); 
                if (phone.length() == 10) {
                    lead.Phone = phone;
                } else {
                    lead.addError('Phone number must be exactly 10 digits after removing special characters and country code.');
                }
            }
        }
    }
    
    public static void thresholdCallAttempt(List<Lead> leadList,Map<Id, Lead> oldMap){
        try{
            for(Lead ledRec : leadList){
                String thresCount = System.label.Threshold_Count;
                if(ledRec.Threshold_Count__c != oldMap.get(ledRec.Id).Threshold_Count__c  && ledRec.Threshold_Count__c >= decimal.valueOf(thresCount)){
                    ledRec.Status = 'Junk';
                }   
            }
        }catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String convertLeadUponStageChange(String recordId, Map<String, Object> formData) {
        System.debug('recordId =====>' + recordId);
        System.debug('formData =====>' + formData);
        try {
            if (recordId == null || formData == null) {
                return 'Invalid input: recordId or formData is null';
            }
            
            Lead leadRec = [SELECT Id, Name, OwnerId,PostalCode FROM Lead WHERE Id = :recordId LIMIT 1];
            
            List<Follow_Up__c> listOfFollowUp = [SELECT Id, Opportunity__c FROM Follow_Up__c WHERE Lead__c = :recordId Order By CreatedDate DESC];
            List<Test_Drive__c> listOfTestDrive = [SELECT Id, Opportunity__c,Test_Drive_Status__c FROM Test_Drive__c WHERE Lead__c = :recordId Order By CreatedDate DESC];
            
            String LeadStatus = formData.containsKey('Status') ? String.valueOf(formData.get('Status')) : null;
            System.debug('LeadStatus =======> ' + LeadStatus);
            String LeadEmail = formData.containsKey('Email') ? String.valueOf(formData.get('Email')) : null;
            System.debug('LeadEmail =======> ' + LeadEmail);
            String LeadPhone = formData.containsKey('Phone') ? String.valueOf(formData.get('Phone')) : null;
            System.debug('LeadPhone =======> ' + LeadPhone);
            String LeadDealerCode = formData.containsKey('DealerCode') ? String.valueOf(formData.get('DealerCode')) : null;
            System.debug('LeadDealerCode =======> ' + LeadDealerCode);
            String LeadLostReason = formData.containsKey('LostReason') ? String.valueOf(formData.get('LostReason')) : null;
            System.debug('LeadLostReason =======> ' + LeadLostReason);
            String LostSubReason = formData.containsKey('LostSubReason') ? String.valueOf(formData.get('LostSubReason')) : null;
            System.debug('LostSubReason =======> ' + LostSubReason);
            String LeadLostFeedback = formData.containsKey('LostFeedback') ? String.valueOf(formData.get('LostFeedback')) : null;
            System.debug('LeadLostFeedback =======> ' + LeadLostFeedback);
            String LeadNotes = formData.containsKey('Notes') ? String.valueOf(formData.get('Notes')) : null;
            System.debug('Notes =======> ' + LeadNotes);
            
            if (LeadStatus == null) {
                return 'Lead Status is required';
            }
            
            if (LeadStatus == 'Converted') {
                Id accountId = getLeadOwnerByPincode(leadRec.PostalCode);
                System.debug('accountId =======> ' + accountId);
                
                if (accountId == null) {
                    return 'No pincodes associated with this postal code, so we cannot convert this lead';
                }
                
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(recordId);
                lc.setConvertedStatus('Converted');
                lc.setDoNotCreateOpportunity(false);
                
                Database.LeadConvertResult result = Database.convertLead(lc);
                System.debug('Lead Conversion Result: ' + result.isSuccess());
                
                if (result.isSuccess()) {
                    Id accId = result.getAccountId();
                    Id conId = result.getContactId();
                    Id oppId = result.getOpportunityId();
                    
                    if (accId != null) {
                        Account acc = [SELECT Id FROM Account WHERE Id = :accId];
                        if (acc != null) {
                            acc.Name = leadRec.Name;
                            update acc;
                        }
                    }
                    
                    if (oppId != null) {
                        
                        Id contactId = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1].Id;
                        System.debug('contactId =======> ' + contactId);
                        
                        Id OwnerId =  [Select Id FROM User WHERE contactId = :contactId LIMIT 1 ].Id;
                        System.debug('ownerId =======> ' + ownerId);
                        
                        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppId];
                        if (opp != null) {
                            opp.Name = leadRec.Name;
                            opp.StageName = 'Decision Pending/ Follow-Up';
                            opp.CloseDate = System.today().addDays(30);
                            opp.OwnerId = ownerId;
                            update opp;
                            
                            OpportunityTriggerHandler.assignOpportunityToSM(new List<Opportunity>{opp});

                            if (!listOfFollowUp.isEmpty()) {
                                for (Follow_Up__c followUpRec : listOfFollowUp) {
                                    followUpRec.Opportunity__c = opp.Id;
                                    followUpRec.Status__c = 'Completed';
                                }
                                update listOfFollowUp;
                            }else{
                                Follow_Up__c followUprec = new Follow_Up__c();
                                followUprec.Name = opp.Name;
                                followUprec.Opportunity__c = opp.Id;
                                followUpRec.Status__c = 'New';
                                followUprec.Follow_Up_Date__c = system.now() + 1;
                                Insert followUprec;
                            }
                            
                            if (!listOfTestDrive.isEmpty()) {
                                for (Test_Drive__c testDriveRec : listOfTestDrive) {
                                    testDriveRec.Opportunity__c = opp.Id;
                                    testDriveRec.Test_Drive_Status__c = 'Canceled';
                                }
                                update listOfTestDrive;
                            }
                        }
                    }
                }
            } 
            else {
                Lead LeadRecs = new Lead(
                    Id = recordId
                );
                if(LeadStatus != null){
                    LeadRecs.Status = LeadStatus;
                }
                if(LeadNotes != null){
                    LeadRecs.Notes__c = LeadNotes;
                }
                
                if (LeadStatus == 'Drop Out') {
                    LeadRecs.Lost_Reason__c = LeadLostReason;
                    LeadRecs.Lead_Secondary_DropOut_Reasons__c = LostSubReason;
                    LeadRecs.Lost_Feedback__c = LeadLostFeedback;
                }
                update LeadRecs;
            }
            return 'SUCCESS';
        } catch (Exception e) {
            System.debug('Error Message =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
            return e.getMessage();
        }
    }
    
    public static String getLeadOwnerByPincode(String postalCode) {
        System.debug('Method getLeadOwnerByPincode started with postalCode: ' + postalCode);
        
        if (String.isEmpty(postalCode)) {
            System.debug('PostalCode is null or empty, returning null');
            return null;
        }
        
        try {
            Pin_Code__c accountId;
            
            List<Pin_Code__c> pinCodeRecords = [SELECT Id, Dealer_Service_Center__c FROM Pin_Code__c WHERE Area_Pincode__c = :postalCode LIMIT 1];
            
            if (!pinCodeRecords.isEmpty()) {
                accountId = pinCodeRecords[0];
                System.debug('Found Pin_Code__c record: ' + accountId);
                return accountId.Dealer_Service_Center__c;
            } else {
                System.debug('No matching Pin_Code__c record found for postalCode: ' + postalCode);
                return null;
            }
        } catch (Exception e) {
            System.debug('Error in getLeadOwnerByPincode: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            return null;
        }
    }
    
    public static void createTaskUnderLeadIfLeadIsNotConverted(List<Lead> leadList) {
        try {
            List<Task> taskList = new List<Task>();
            for (Lead lead : leadList) {
                if (lead.Status != 'Converted') {
                    Task task = new Task();
                    task.Subject = 'Call';
                    task.WhoId = lead.Id;
                    task.ActivityDate = system.today();
                    task.OwnerId = lead.OwnerId;
                    task.Status = 'Not Started';
                    task.Priority = 'Normal';
                    taskList.add(task);
                }
            }
           
            if (!taskList.isEmpty()) {
                insert taskList;
            }
            
        } catch (Exception e) {
            System.debug('Error in createTaskUnderLeadIfLeadIsNotConverted: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
        
    }
    
    public static String getPreferredStoreByPincode(String postalCode) {
        List<Pin_Code__c> pincodeList = [SELECT Id, Dealer_Service_Center__r.Center_Code__c FROM Pin_Code__c WHERE Area_Pincode__c = :postalCode LIMIT 1];
    
        if (!pincodeList.isEmpty() && pincodeList[0].Dealer_Service_Center__c != null) {
            return pincodeList[0].Dealer_Service_Center__r.Center_Code__c;
        }else{
            return 'Out Of Coverage ';
        }
    }
    
    @AuraEnabled public static String getOpportunityId(String recordId) {
        try {
            if (recordId != null) {
                Lead leadRec = [
                    SELECT Id, ConvertedOpportunityId 
                    FROM Lead 
                    WHERE Id = :recordId
                ];
                
                System.debug('ConvertedOpportunityId ========>' +leadRec.ConvertedOpportunityId);
                return leadRec.ConvertedOpportunityId;
            }
            return null;
        } catch (Exception e) {
            System.debug('Error in getOpportunityId: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            return null;
        }
    }
    
    public static void updateLeadSourceForDMSUser(List<Lead> leadList, Map<Id, Lead> oldMap) {
        try {
            for (Lead lead : leadList) {
                Lead oldLead;
                if(oldMap != null){
                    oldLead = oldMap.get(lead.Id); 
                }
                
                if(oldLead != null && oldLead.Source__c != null && lead.Source__c != oldLead.Source__c && lead.OwnerId__c == 'Sales Manager (Partner)') {
                    lead.LeadSource = lead.Source__c;
                }else if (lead.Source__c != null && lead.OwnerId__c == 'Sales Manager (Partner)') {
                    lead.LeadSource = lead.Source__c;   
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }
    }
    
    public static void assignLeadsTestDriveAndFollowUpToOppOwnerWhenLeadIsConverted(List<Lead> leadList) {
        try{

            System.debug('===== Method Start assignLeadsTestDriveAndFollowUpToOppOwnerWhenLeadIsConverted =====');
        System.debug('Input leadList ====> ' + leadList);

            Set<Id> convertedLeadIds = new Set<Id>();
        Map<Id, Id> leadToOppOwnerMap = new Map<Id, Id>();

        for (Lead lead : leadList) {
            if (lead.IsConverted && lead.ConvertedOpportunityId != null) {
                convertedLeadIds.add(lead.Id);
                leadToOppOwnerMap.put(lead.Id, lead.ConvertedOpportunityId);
            }
        }

        System.debug('convertedLeadIds ====> ' + convertedLeadIds);
        System.debug('leadToOppOwnerMap ====> ' + leadToOppOwnerMap);

        if (convertedLeadIds.isEmpty()) {
            System.debug('No converted leads found. Exiting method.');
            return;
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        if(leadToOppOwnerMap.values().size() > 0){
            oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId FROM Opportunity WHERE Id IN :leadToOppOwnerMap.values()]);
        }
        
        System.debug('oppMap ====> ' + oppMap);

        Map<Id, Id> leadToOppOwnerIdMap = new Map<Id, Id>();
        for (Id leadId : leadToOppOwnerMap.keySet()) {
            Id oppId = leadToOppOwnerMap.get(leadId);
            if (oppMap.containsKey(oppId)) {
                Id oppOwnerId = oppMap.get(oppId).OwnerId;
                System.debug(' ' + oppOwnerId);
                leadToOppOwnerIdMap.put(leadId, oppOwnerId);
            }
        }
        System.debug('leadToOppOwnerIdMap ====> ' + leadToOppOwnerIdMap);

        if (!convertedLeadIds.isEmpty()) {
                List<Follow_Up__c> followUpList = [
                SELECT Id, Lead__c, OwnerId FROM Follow_Up__c WHERE Lead__c IN :convertedLeadIds
            ];
            System.debug('Queried followUpList ====> ' + followUpList);

            List<Follow_Up__c> listOfFollowUpToBeUpdated = new List<Follow_Up__c>();
            List<Follow_Up__c> listOfTestDriveToBeUpdated = new List<Follow_Up__c>();
            for (Follow_Up__c followUp : followUpList) {
                if (leadToOppOwnerIdMap.containsKey(followUp.Lead__c)) {
                    followUp.OwnerId = leadToOppOwnerIdMap.get(followUp.Lead__c);
                }
            }

            List<Test_Drive__c> testDriveList = [
                SELECT Id, Lead__c, OwnerId FROM Test_Drive__c WHERE Lead__c IN :convertedLeadIds
            ];
            System.debug('Queried testDriveList ====> ' + testDriveList);

            for (Test_Drive__c testDrive : testDriveList) {
                if (leadToOppOwnerIdMap.containsKey(testDrive.Lead__c)) {
                    testDrive.OwnerId = leadToOppOwnerIdMap.get(testDrive.Lead__c);
                }
            }

            if (!followUpList.isEmpty()) {
                update followUpList;
                System.debug('Final Updated followUpList =====> ' + followUpList);
            } else {
                System.debug('No FollowUp records to update.');
            }

            if (!testDriveList.isEmpty()) {
                update testDriveList;
                System.debug('Final Updated testDriveList =====> ' + testDriveList);
            } else {
                System.debug('No TestDrive records to update.');
            }
        }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }
    }

    public static void pincodeChangeMakeTheDealerMapping(List<Lead> leadList, Map<Id, Lead> oldMap) {
        try {
            Set<String> setOfPincode = new Set<String>();
            Map<String, Pin_Code__c> mapOfPincodeToStore = new Map<String, Pin_Code__c>();
            List<Group> listOfGroup = new List<Group>();
            List<Task> tasksToInsert = new List<Task>();

            for (Lead led : leadList) {
                if (led.PostalCode != null &&
                    oldMap.containsKey(led.Id) &&
                    led.PostalCode != oldMap.get(led.Id).PostalCode &&
                    led.IsConverted == false) {
                    setOfPincode.add(led.PostalCode);
                }
            }

            if (!setOfPincode.isEmpty()) {
                for (Pin_Code__c pin : [SELECT Id, Dealer_Service_Center__r.Center_Code__c,Dealer_Service_Center__r.Store_Name__c,
                        Area_Pincode__c, City__r.Name FROM Pin_Code__c WHERE Area_Pincode__c IN :setOfPincode]) {
                    mapOfPincodeToStore.put(pin.Area_Pincode__c, pin);
                }
            }

            if (mapOfPincodeToStore.isEmpty()) {
                listOfGroup = [
                    SELECT Id, Name FROM Group 
                    WHERE Type = 'Queue' AND Name = 'Head_Quarter'
                ];
            }

            for (Lead leadRec : leadList) {
                if (leadRec.PostalCode == null) continue;

                Boolean pincodeChanged = oldMap.containsKey(leadRec.Id)
                    && leadRec.PostalCode != oldMap.get(leadRec.Id).PostalCode
                    && leadRec.IsConverted == false;

                if (pincodeChanged && mapOfPincodeToStore.containsKey(leadRec.PostalCode)) {
                    Pin_Code__c pin = mapOfPincodeToStore.get(leadRec.PostalCode);
                    leadRec.Dealer_Code__c = pin.Dealer_Service_Center__r.Center_Code__c;
                    leadRec.Stores_Name__c = pin.Dealer_Service_Center__r.Store_Name__c;
                    leadRec.City = pin.City__r.Name;
                    leadRec.Future_Lead__c = false;

                    Task t = new Task();
                    t.Subject = 'Call Customer for Updated Dealer Mapping';
                    t.WhatId = leadRec.Id;
                    t.OwnerId = leadRec.OwnerId;
                    t.Priority = 'Normal';
                    t.Status = 'Open';
                    t.Description = 'Pincode changed to ' + leadRec.PostalCode +
                        '. Please call the customer to confirm dealer assignment.';
                    tasksToInsert.add(t);

                } else if (pincodeChanged && !mapOfPincodeToStore.containsKey(leadRec.PostalCode)) {
                    leadRec.Dealer_Code__c = '';
                    leadRec.Stores_Name__c = 'Out Of Serivce';
                    leadRec.City = '';
                    leadRec.Future_Lead__c = true;
                    if (!listOfGroup.isEmpty()) {
                        leadRec.OwnerId = listOfGroup[0].Id;
                    }
                }
            }

            if (!tasksToInsert.isEmpty()) {
                insert tasksToInsert;
            }

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }
    }

    public class CustomException extends Exception {}
}