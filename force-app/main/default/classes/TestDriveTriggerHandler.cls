/**
* @description       : 
* @author            : Aniket Karmakar
* @group             : 
* @last modified on  : 02-26-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class TestDriveTriggerHandler {
    
    public static void afterUpdate(List<Test_Drive__c> newTestDrives,Map<Id,Test_Drive__c> oldTestDriveMap){
        List<Id> whenHTR = new List<Id>();
        Map<Id,String> HTRByLeadPhoneMap = new Map<Id,String>();
        String templateNameforHTR='home_test_ride_done_with_form1';
        
        
        List<Id> whenSTR = new List<Id>();
        Map<Id,String> STRByLeadPhoneMap = new Map<Id,String>();
        String templateNameforSTR='store_test_ride_done_with_form1';
        
        List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
        WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
        String imageUrl = w.test_ride_done__c;
        
        Set<Id> leadIds = new Set<Id>();
        
        try{
            for (Test_Drive__c td : newTestDrives) {
                if (td.Test_Drive_Status__c == 'Completed' && oldTestDriveMap.get(td.Id).Test_Drive_Status__c != 'Completed') {
                    if (td.Lead__c != null) {
                        leadIds.add(td.Lead__c);
                    }
                }
            }

            Map<Id, Lead> leadMap = new Map<Id, Lead>();
            if(!leadIds.isEmpty()){
                leadMap = new Map<Id, Lead>([SELECT Id, Phone FROM Lead WHERE Id IN :leadIds]);
            }
            
            for(Test_Drive__c td : newTestDrives){
                if(td.Test_Drive_Status__c == 'Completed' && oldTestDriveMap.get(td.Id).Test_Drive_Status__c !='Completed'){
                    if(td.Ride_Type__c != null && td.Ride_Type__c == 'HTR' && td.Lead__c != null){
                        whenHTR.add(td.Id);
                        String phoneNumber = leadMap.get(td.Lead__c).Phone;
                        HTRByLeadPhoneMap.put(td.Id,phoneNumber);
                    }else if(td.Ride_Type__c != null && td.Ride_Type__c == 'STR' && td.Lead__c != null){
                        whenSTR.add(td.Id);
                        String phoneNumber = leadMap.get(td.Lead__c).Phone;
                        STRByLeadPhoneMap.put(td.Id,phoneNumber);
                    }
                    
                }
            }
            
            if (!whenHTR.isEmpty() && (templateNameforHTR!=null && HTRByLeadPhoneMap!=null && imageUrl !=null)) {
                System.enqueueJob(new QueueableForImageTemplateMsg(whenHTR, templateNameforHTR,imageUrl, HTRByLeadPhoneMap));
            }
            if (!whenSTR.isEmpty()&& (templateNameforSTR!=null && STRByLeadPhoneMap!=null && imageUrl !=null)) {
                System.enqueueJob(new QueueableForImageTemplateMsg(whenSTR, templateNameforSTR,imageUrl, STRByLeadPhoneMap));
            }
            
        }
        catch(Exception e){
            System.debug('Error is ====>'+e.getMessage());
            System.debug('Error Line Number is ==>'+e.getLineNumber());
        } 
    }
    
    public static void afterInsert(List<Test_Drive__c> newTestDrives){
        //dataSet for Home ride
        List<Id> testDriveIdsToProcessForHome = new List<Id>();
        Map<Id,String> idToPhoneNumberMapForHome = new Map<Id,String>();
        Map<Id,String> idToFormattedDateTimeMapForHome = new Map<Id,String>();
        Map<Id,String> rideTypeMapForHome = new Map<Id,String>(); 
        
        //dataSet for Store Ride
        List<Id> testDriveIdsToProcessForStore = new List<Id>();
        Map<Id,String> idToPhoneNumberMapForStore = new Map<Id,String>();
        Map<Id,String> idToFormattedDateTimeMapForStore = new Map<Id,String>();
        Map<Id,String> rideTypeMapForStore = new Map<Id,String>();
        
        //delaer code custom metadata dataset
        List<String> dealerCodes = new List<String>();
        Map<String,String> dealerToStoreNameMap = new Map<String,String>();
        try{
            List<Store_Details__mdt> storeDetails = [Select id,Name__c,Dealer_Code__c,IsActive__c from Store_Details__mdt WHERE IsActive__c = true];
            System.debug('storeDetails==>'+storeDetails);
            for(Store_Details__mdt store : storeDetails){
                dealerCodes.add(store.Dealer_Code__c);
                dealerToStoreNameMap.put(store.Dealer_Code__c,store.Name__c);
            }
            System.debug('dealerCodes==>'+dealerCodes);
            System.debug('dealerToStoreNameMap==>'+dealerToStoreNameMap);
            
            Set<Id> leadIds = new Set<Id>();
            for (Test_Drive__c t : newTestDrives) {
                if (t.Lead__c != null) {
                    leadIds.add(t.Lead__c);
                }
            }
            Map<Id, Lead> leadMap = new Map<Id, Lead>();
            if(!leadIds.isEmpty()){
                leadMap = new Map<Id, Lead>([SELECT Id, LeadSource, Dealer_Code__c,Lead_Dealer_Code__c,Phone FROM Lead WHERE Id IN :leadIds]);
            }
            
            for (Test_Drive__c t : newTestDrives) {
                if (t.Lead__c != null && leadMap.containsKey(t.Lead__c)) {
                    Lead leadRecord = leadMap.get(t.Lead__c);  
                    
                    
                    if (leadRecord != null && /*leadRecord.LeadSource != 'OzoneTel WhatsApp'  &&*/ (dealerCodes.contains(leadRecord.Dealer_Code__c) || dealerCodes.contains(leadRecord.Lead_Dealer_Code__c))) {
                        
                        if (t.Ride_Type__c == 'HTR' && t.Test_Ride_Date__c != null) {

                            Datetime dateTimeString = t.Test_Ride_Date__c;
                            String formattedTimeForHome = dateTimeString.format('dd/MM/yyyy');
                            String rideTypeValueForHome = 'the comfort of your home';
                            
                            testDriveIdsToProcessForHome.add(t.Id);
                            idToPhoneNumberMapForHome.put(t.Id, leadRecord.Phone);
                            idToFormattedDateTimeMapForHome.put(t.Id, formattedTimeForHome);
                            rideTypeMapForHome.put(t.Id, rideTypeValueForHome);
                        } else if (t.Ride_Type__c == 'STR' && t.Test_Ride_Date__c != null) {
                            Datetime dateTimeString = t.Test_Ride_Date__c;
                            String formattedTimeForStore = dateTimeString.format('dd/MM/yyyy');
                            //additional condition
                            String rideTypeValueForStore;
                            
                            if(leadRecord.Dealer_Code__c == null){
                                rideTypeValueForStore = dealerToStoreNameMap.get(leadRecord.Lead_Dealer_Code__c);
                            }else{
                                rideTypeValueForStore = dealerToStoreNameMap.get(leadRecord.Dealer_Code__c);
                            }
                            
                            
                            testDriveIdsToProcessForStore.add(t.Id);
                            idToPhoneNumberMapForStore.put(t.Id, leadRecord.Phone);
                            idToFormattedDateTimeMapForStore.put(t.Id, formattedTimeForStore);
                            rideTypeMapForStore.put(t.Id, rideTypeValueForStore);
                        }
                    }
                }
            }
            
            System.debug('testDriveIdsToProcessForHome===>'+testDriveIdsToProcessForHome);
            System.debug('testDriveIdsToProcessForStore===>'+testDriveIdsToProcessForStore);
            
            if(!testDriveIdsToProcessForHome.isEmpty() && (idToPhoneNumberMapForHome!=null && idToFormattedDateTimeMapForHome!=null &&rideTypeMapForHome!=null)){
                System.enqueueJob(new QueueableOnTestDriveCreation(testDriveIdsToProcessForHome,idToPhoneNumberMapForHome,idToFormattedDateTimeMapForHome,rideTypeMapForHome));
            }
            if(!testDriveIdsToProcessForStore.isEmpty()&& (idToPhoneNumberMapForStore!=null && idToFormattedDateTimeMapForStore!=null &&rideTypeMapForStore!=null)){
                System.enqueueJob(new QueueableOnTestDriveCreation(testDriveIdsToProcessForStore,idToPhoneNumberMapForStore,idToFormattedDateTimeMapForStore,rideTypeMapForStore));
            }
            
        }catch(Exception e){
            System.debug('Error Occured====>'+e.getMessage());
            System.debug('Error Line Number is ==>'+e.getLineNumber());  
            
        }
    }
    
    public static void ifTestRideCancelled(List<Test_Drive__c> newList,Map<Id,Test_Drive__c> oldMapTestDrive){
        String templateName = 'test_ride_not_taken2';
        
        
        List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
        WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
        String imageUrl = w.test_ride_not_taken2__c;
        
        List<Id> tdIdsToProcess = new List<Id>();
        Map<Id,String> idToPhoneMap = new Map<Id,String>();
        
        Set<Id> tdIdsForFetchingLead = new Set<Id>();
        try{
            for(Test_Drive__c td : newList){
                if(td.Test_Drive_Status__c == 'Canceled' && td.Test_Drive_Status__c !=oldMapTestDrive.get(td.Id).Test_Drive_Status__c && td.Lead__c !=null){
                    tdIdsForFetchingLead.add(td.Lead__c);
                }
            }
            Map<Id,Lead> leadMap = new Map<Id,Lead>();
            if(!tdIdsForFetchingLead.isEmpty()){
                leadMap = new Map<Id,Lead>([Select Id,Dealer_Code__c,Phone from Lead WHERE Id IN:tdIdsForFetchingLead]);
            }
            System.debug('leadMap==>'+leadMap);
            for(Test_Drive__c t : newList){
                if(t.Test_Drive_Status__c == 'Canceled' && t.Test_Drive_Status__c !=oldMapTestDrive.get(t.Id).Test_Drive_Status__c && t.Lead__c !=null){
                    Lead l = leadMap.get(t.Lead__c);
                    tdIdsToProcess.add(l.Id);
                    idToPhoneMap.put(l.Id,l.Phone);
                    
                }
                if(!tdIdsToProcess.isEmpty() && (templateName!=null&&imageUrl!=null &&idToPhoneMap!=null)){
                    System.enqueueJob(new QueueableForImageTemplateMsg(tdIdsToProcess, templateName,imageUrl,idToPhoneMap));
                }
            }
            
        }
        catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Nyumber ==>'+e.getLineNumber());
        } 
    }
    
    /////////////////////////////Lead Conversion Added by Anwar//////////////////////////////////////
    
    public static void dontConvertTheLeadIfTheTestRideIsNotScheduled(List<Test_Drive__c> newList, Map<Id, Test_Drive__c> oldMapTestDrive) {
        try {    
            Set<Id> setOfLeadId = new Set<Id>();
            set<Id> setOfLeadIdForTestDrive = new Set<Id>();
            Map<Id,Lead> mapOfLeadRecs = new Map<Id,Lead>();

            for(Test_Drive__c tdRec :newList){
                if(tdRec.Lead__c != null && tdRec.Test_Drive_Status__c == 'Scheduled' && tdRec.Opportunity__c == null) {
                    setOfLeadIdForTestDrive.add(tdRec.Lead__c);
                }
            }

            if(!setOfLeadIdForTestDrive.isEmpty()) {
                mapOfLeadRecs = new Map<Id,Lead>([SELECT Id, Status, PostalCode FROM Lead Where Id IN: setOfLeadIdForTestDrive AND Status != 'Converted']);

                if(!mapOfLeadRecs.isEmpty()) {
                    for (Test_Drive__c testDriveRec : newList) {
                        System.debug('testDriveRec.Lead__r.PostalCode =====>'+mapOfLeadRecs.get(testDriveRec.Lead__c));
                        System.debug('testDriveRec.Lead__r.PostalCode =====>'+mapOfLeadRecs.get(testDriveRec.Lead__c).PostalCode);
                        System.debug('testDriveRec.Lead__r.Status =====>'+mapOfLeadRecs.get(testDriveRec.Lead__c).Status);
                        if (oldMapTestDrive.containsKey(testDriveRec.Id) 
                            && testDriveRec.Lead__c != null && mapOfLeadRecs.get(testDriveRec.Lead__c) != null && 
                            mapOfLeadRecs.get(testDriveRec.Lead__c).Status != 'Converted' && mapOfLeadRecs.get(testDriveRec.Lead__c).PostalCode == null 
                            && testDriveRec.Test_Drive_Status__c == 'Scheduled'
                            && testDriveRec.Test_Drive_Status__c != oldMapTestDrive.get(testDriveRec.Id).Test_Drive_Status__c) {
                                testDriveRec.addError('This Lead Cannot be Converted Because there is no Postal Code Associated with it ');
                            }
                        
                        if (oldMapTestDrive.containsKey(testDriveRec.Id) 
                            && testDriveRec.Lead__c != null && mapOfLeadRecs.get(testDriveRec.Lead__c) != null && 
                            mapOfLeadRecs.get(testDriveRec.Lead__c).Status != 'Converted' && mapOfLeadRecs.get(testDriveRec.Lead__c).PostalCode != null 
                            && testDriveRec.Test_Drive_Status__c == 'Scheduled'
                            && testDriveRec.Test_Drive_Status__c != oldMapTestDrive.get(testDriveRec.Id).Test_Drive_Status__c) {
                                setOfLeadId.add(testDriveRec.Lead__c);
                            }
                    }
                }else{
                    System.debug(' lead is Already converted or not found in system ======> at line number 236');
                }
            } 

            if (setOfLeadId.isEmpty()) {
                return;
            }
            List<Lead> leadRec = new list<Lead>();
            for(Lead lds : mapOfLeadRecs.values()){
                if(setOfLeadId.contains(lds.Id)){
                    leadRec.add(lds);
                }
            }
            System.debug('leadRec=====>'+leadRec);
            
            Map<Id, Lead> leadMap = new Map<Id, Lead>();
            Map<String, String> mapOfPincodes = new Map<String, String>();
            List<Follow_Up__c> listOfFollowUp = new List<Follow_Up__c>();
            List<Test_Drive__c> listOfTestDrive = new List<Test_Drive__c>();
            if(!setOfLeadId.isEmpty()){
                listOfFollowUp = [SELECT Id, Opportunity__c FROM Follow_Up__c WHERE Status__c IN ('Not Started', 'In Progress','Waiting for someone else') AND Lead__c IN :setOfLeadId];
                System.debug('Retrieved Follow_Up__c records: ' + listOfFollowUp);
            }
            if(!setOfLeadId.isEmpty()){
                listOfTestDrive = [SELECT Id, Lead__c FROM Test_Drive__c WHERE Test_Drive_Status__c IN ('New', 'In Progress') AND Lead__c IN :setOfLeadId];
                System.debug('Retrieved Test_Drive__c records: ' + listOfTestDrive);
            }
            
            for (Lead lead : leadRec) {
                leadMap.put(lead.Id, lead);
                System.debug('alead.PostalCode=====>'+lead.PostalCode);
                string accountId = LeadTriggerHandler.getLeadOwnerByPincode(lead.PostalCode);
                System.debug('accountId=====>'+accountId);
                mapOfPincodes.put(lead.PostalCode, accountId);
                System.debug('mapOfPincodes=====>'+mapOfPincodes);
            }
            System.debug('mapOfPincodes=====>'+mapOfPincodes);
            System.debug('leadMap=====>'+leadMap);
            
            for (Test_Drive__c testDriveRec : newList) {
                if (leadMap.containsKey(testDriveRec.Lead__c)) {
                    Lead associatedLead = leadMap.get(testDriveRec.Lead__c);
                    System.debug('associatedLead=====>'+associatedLead);
                    if (mapOfPincodes.get(associatedLead.PostalCode) == null) {
                        System.debug('mapOfPincodes.get(associatedLead.PostalCode) 1 =========>');
                        testDriveRec.addError('This Lead Cannot be Converted Because there is No Store Associated with this Postal Code');
                    }
                } 
                
                if(listOfFollowUp.size()>0){
                    testDriveRec.addError('This Lead Cannot be Converted Because there are Follow Up Records Associated with it which are Not Closed');
                }
                
                if (listOfTestDrive.size() > 0) {
                    for (Integer i = listOfTestDrive.size() - 1; i >= 0; i--) {
                        if (listOfTestDrive[i].Id == testDriveRec.Id) {
                            listOfTestDrive.remove(i);
                            break;
                        }
                    }
                    
                    if (!listOfTestDrive.isEmpty()) {
                        testDriveRec.addError('This Lead Cannot be Converted Because there are Test Drive Records Associated with it which are Not Closed');
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in dontConvertTheLeadIfTheTestRideIsNotScheduled =====> ' + e.getMessage() + ' at line number =====>' + e.getLineNumber());
        }
    }
    
    public static void convertLeadIfStatusIsScheduled(List<Test_Drive__c> newList, Map<Id, Test_Drive__c> oldMapTestDrive) {
        try {
            Set<Id> setOfLeadId = new Set<Id>();
            for (Test_Drive__c testDriveRec : newList) {
                if (testDriveRec.Lead__c != null && testDriveRec.Opportunity__c == null && testDriveRec.Test_Drive_Status__c == 'Scheduled' && (oldMapTestDrive == null || testDriveRec.Test_Drive_Status__c != oldMapTestDrive.get(testDriveRec.Id)?.Test_Drive_Status__c)) {
                    setOfLeadId.add(testDriveRec.Lead__c);
                }
            }

            if (!setOfLeadId.isEmpty()) {
                List<Lead> leadRec = [SELECT Id, Name, Status, PostalCode FROM Lead WHERE Id IN :setOfLeadId AND Status != 'Converted'];
                List<Follow_Up__c> listOfFollowUp = [SELECT Id, Name, Opportunity__c, Lead__c FROM Follow_Up__c WHERE Lead__c IN :setOfLeadId];
                List<Test_Drive__c> listOfTestDrive = [SELECT Id, Name, Lead__c, Opportunity__c FROM Test_Drive__c WHERE Lead__c IN :setOfLeadId];

                List<Account> accountsToUpdate = new List<Account>();
                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                List<Follow_Up__c> followUpsToUpdate = new List<Follow_Up__c>();
                List<Test_Drive__c> testDrivesToUpdate = new List<Test_Drive__c>();

                for (Lead lead : leadRec) {
                    Id accountId = LeadTriggerHandler.getLeadOwnerByPincode(lead.PostalCode);
                    if (accountId == null) {
                        throw new CustomException('No pincodes associated with this postal code, so we cannot convert this lead: ' + lead.PostalCode);
                    }

                    Id contactId = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1].Id;
                    Id ownerId = [SELECT Id FROM User WHERE ContactId = :contactId LIMIT 1].Id;

                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(lead.Id);
                    lc.setConvertedStatus('Converted');
                    lc.setDoNotCreateOpportunity(false);

                    Database.LeadConvertResult result = Database.convertLead(lc);

                    if (result.isSuccess()) {
                        Id accId = result.getAccountId();
                        Id oppId = result.getOpportunityId();

                        if (accId != null) {
                            Account acc = new Account(Id = accId, Name = lead.Name);
                            accountsToUpdate.add(acc);
                        }

                        if (oppId != null) {
                            Opportunity opp = new Opportunity(
                                Id = oppId,
                                StageName = 'Test Ride Scheduled',
                                CloseDate = System.today().addDays(30),
                                OwnerId = ownerId
                            );
                            oppsToUpdate.add(opp);

                            for (Follow_Up__c f : listOfFollowUp) {
                                if (f.Lead__c == lead.Id) {
                                    f.Opportunity__c = opp.Id;
                                    followUpsToUpdate.add(f);
                                }
                            }
                            for (Test_Drive__c t : listOfTestDrive) {
                                if (t.Lead__c == lead.Id) {
                                    t.Opportunity__c = opp.Id;
                                    testDrivesToUpdate.add(t);
                                }
                            }
                        }
                    }
                }

                if (!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }
                if (!oppsToUpdate.isEmpty()) {
                    update oppsToUpdate;
                    OpportunityTriggerHandler.assignOpportunityToSM(oppsToUpdate);
                }
                if (!followUpsToUpdate.isEmpty()) {
                    update followUpsToUpdate;
                }
                if (!testDrivesToUpdate.isEmpty()) {
                    update testDrivesToUpdate;
                }
            }
        } catch (Exception e) {
            System.debug('Error in convertLeadIfStatusIsScheduled ===> ' + e.getMessage() + ' at line ===> ' + e.getLineNumber());
        }
    }


    public static void sendLeadToDealerOnTestRideScheduled(List<Test_Drive__c> newList,Map<Id, Test_Drive__c> oldMapTestDrive) {
        try {
            Set<Id> setOfLeadId = new Set<Id>();
            Map<Id, Test_Drive__c> testDrivesToUpdate = new Map<Id, Test_Drive__c>();
            Map<String, Id> mapOfDealerCodeToUserId = new Map<String, Id>();
            for (User usr : [SELECT Id, Dealer_Code__c FROM User WHERE Profile.Name = 'Sales Manager (Partner)' AND Dealer_Code__c != null AND UserName Like '%@Store%']) {
                mapOfDealerCodeToUserId.put(usr.Dealer_Code__c, usr.Id);
            }

            for (Test_Drive__c testDrive : newList) {
                Test_Drive__c oldTestDrive = oldMapTestDrive != null ? oldMapTestDrive.get(testDrive.Id) : null;

                Boolean isInsert = oldTestDrive == null;
                Boolean isStatusChangedToScheduled = (testDrive.Test_Drive_Status__c == 'Scheduled' &&(isInsert || oldTestDrive.Test_Drive_Status__c != 'Scheduled'));

                if (testDrive.Lead__c != null && isStatusChangedToScheduled) {
                    setOfLeadId.add(testDrive.Lead__c);
                }
            }

            if (!setOfLeadId.isEmpty()) {
                List<Lead> leadsToUpdate = new List<Lead>();
                List<Test_Drive__c> testDrivesToUpdateList = new List<Test_Drive__c>();

                Map<Id, Lead> mapLeadIdToLead = new Map<Id, Lead>(
                    [SELECT Id, Dealer_Code__c FROM Lead WHERE Id IN :setOfLeadId]
                );

                for (Test_Drive__c testDrive : newList) {
                    if (setOfLeadId.contains(testDrive.Lead__c)) {
                        Lead lead = mapLeadIdToLead.get(testDrive.Lead__c);

                        if (lead != null && lead.Dealer_Code__c != null && mapOfDealerCodeToUserId.containsKey(lead.Dealer_Code__c)) {
                            Id userId = mapOfDealerCodeToUserId.get(lead.Dealer_Code__c);

                            lead.OwnerId = userId;
                            lead.Status = 'Test Ride';
                            leadsToUpdate.add(lead);

                            Test_Drive__c tdToUpdate = new Test_Drive__c(Id = testDrive.Id, OwnerId = userId);
                            testDrivesToUpdateList.add(tdToUpdate);
                        }
                    }
                }

                if (!leadsToUpdate.isEmpty()) {
                    update leadsToUpdate;
                }

                if (!testDrivesToUpdateList.isEmpty()) {
                    update testDrivesToUpdateList;
                }
            }

        } catch (Exception e) {
            System.debug('Error in sendLeadToDealerOnTestRideScheduled: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
        }
    }

    public static void deleteNotesAndAttachmentsOnTestRideCompletion(List<Test_Drive__c> newList,Map<Id, Test_Drive__c> oldMapTestDrive){
        try{
            set<Id> setOfTestDriveRecId = new set<Id>();
            Set<Id> docIds = new Set<Id>();
            for(Test_Drive__c testDriveRec : newList){
                Test_Drive__c oldTestDrive = oldMapTestDrive.get(testDriveRec.Id);
                if(testDriveRec.Test_Drive_Status__c == 'Completed' && testDriveRec.Test_Drive_Status__c != oldTestDrive.Test_Drive_Status__c){
                    setOfTestDriveRecId.add(testDriveRec.Id);
                }
            }
            if(!setOfTestDriveRecId.isEmpty()){
                List<ContentDocumentLink> links = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN: setOfTestDriveRecId];

                if(!links.isEmpty()){
                    for (ContentDocumentLink link : links) {
                        docIds.add(link.ContentDocumentId);
                    }
                    
                    if (!docIds.isEmpty()) {
                        List<ContentDocument> docsToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :docIds];
                        delete docsToDelete;
                    }
                }
            }
        }catch (Exception e) {
            System.debug('Error ===> ' + e.getMessage() + ' at line ===> ' + e.getLineNumber());
        }
    }

    public static void onCreationOfTestDriveUpdateOppAndOnCompletionOfTestDrive(List<Test_Drive__c> newList) {
        try{
            Set<Id> oppIdsToUpdate = new Set<Id>();
            for (Test_Drive__c testDriveRec : newList) {
                if (testDriveRec.Opportunity__c != null && 
                    ((testDriveRec.Test_Drive_Status__c == 'Scheduled' || testDriveRec.Test_Drive_Status__c == 'Completed'))) {
                    oppIdsToUpdate.add(testDriveRec.Opportunity__c);
                }
            }

            if (oppIdsToUpdate.isEmpty()) return;

            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
                [SELECT Id, StageName FROM Opportunity WHERE Id IN :oppIdsToUpdate]
            );

            List<Opportunity> oppsToUpdate = new List<Opportunity>();

            for (Test_Drive__c testDriveRec : newList) {
                Id oppId = testDriveRec.Opportunity__c;
                if (oppMap.containsKey(oppId)) {
                    Opportunity opp = oppMap.get(oppId);

                    if (testDriveRec.Test_Drive_Status__c == 'Scheduled') {
                        opp.StageName = 'Test Ride Scheduled';
                    } else if (testDriveRec.Test_Drive_Status__c == 'Completed') {
                        opp.StageName = 'Test Ride Completed';
                    }

                    oppsToUpdate.add(opp);
                }
            }

            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error ===> ' + e.getMessage() + ' at line ===> ' + e.getLineNumber());
        }
    }

    public static void updateOpportunityStatusOnTestRideStatusUpdate(List<Test_Drive__c> newList,Map<Id, Test_Drive__c> oldMapTestDrive){
        try{
            Map<Id, Opportunity> oppMapToBeUpdated = new Map<Id, Opportunity>();
            for(Test_Drive__c testDriveRec : newList){
                if(testDriveRec.Opportunity__c != null && oldMapTestDrive.containsKey(testDriveRec.Id) && 
                    oldMapTestDrive.get(testDriveRec.Id).Test_Drive_Status__c != testDriveRec.Test_Drive_Status__c && (testDriveRec.Test_Drive_Status__c == 'Scheduled' || 
                    testDriveRec.Test_Drive_Status__c == 'Completed' || testDriveRec.Test_Drive_Status__c == 'Canceled' || testDriveRec.Test_Drive_Status__c == 'Reschedule' ||
                    testDriveRec.Test_Drive_Status__c == 'Test Ride Confirmed' || testDriveRec.Test_Drive_Status__c == 'No Show')) {

                    Opportunity opp = new Opportunity();
                    opp.Id = testDriveRec.Opportunity__c;

                    if(testDriveRec.Test_Drive_Status__c == 'Scheduled'){
                        opp.StageName = 'Test Ride Scheduled';
                    }
                    if(testDriveRec.Test_Drive_Status__c == 'Reschedule'){
                        opp.StageName = 'Test Ride Re-Scheduled';
                    }
                    if(testDriveRec.Test_Drive_Status__c == 'Completed'){
                        opp.StageName = 'Test Ride Completed';
                    }
                    if(testDriveRec.Test_Drive_Status__c == 'No Show'){
                        opp.StageName = 'No Show';
                    }
                    if(testDriveRec.Test_Drive_Status__c == 'Canceled'){
                        opp.StageName = 'Drop Out';
                    }
                    oppMapToBeUpdated.put(opp.Id, opp);
                }
            }
            if(!oppMapToBeUpdated.isEmpty()){
                update oppMapToBeUpdated.values();
            }
        } catch (Exception e) {
            System.debug('Error ===> ' + e.getMessage() + ' at line ===> ' + e.getLineNumber());
        }
    }


    public static void convertLeadIfTheRideTypeIsStoreTestRideAndLeadHomeTestdriveIsTrue(List<Test_Drive__c> newList){
        try {
            Set<Id> setOfLeadId = new Set<Id>();
            Set<Id> setOfLeadIdForConversion = new Set<Id>();

            for (Test_Drive__c testDriveRec : newList) {
                if (testDriveRec.Lead__c != null  && testDriveRec.Opportunity__c == null && testDriveRec.Ride_Type__c == 'HTR') {
                    setOfLeadId.add(testDriveRec.Lead__c);
                }
            }

            List<Lead> leadList = new List<Lead>();
            if(!setOfLeadId.isEmpty()){
                leadList = [SELECT Id, Instore_Test_drive__c, Secondary_Sources__c FROM Lead WHERE Id IN :setOfLeadId AND Home_Test_Ride__c = true AND Secondary_Sources__c = 'River Website'];
            }

            if(!leadList.isEmpty()){
                for(Lead ledRec : leadList){
                    setOfLeadIdForConversion.add(ledRec.Id);
                }
            }   

            if (!setOfLeadIdForConversion.isEmpty()) {
                List<Lead> leadRec = [SELECT Id, Name, Status, PostalCode FROM Lead WHERE Id IN :setOfLeadIdForConversion AND Status != 'Converted'];
                List<Follow_Up__c> listOfFollowUp = [SELECT Id, Name, Opportunity__c, Lead__c FROM Follow_Up__c WHERE Lead__c IN :setOfLeadIdForConversion];
                List<Test_Drive__c> listOfTestDrive = [SELECT Id, Name, Lead__c, Opportunity__c FROM Test_Drive__c WHERE Lead__c IN :setOfLeadIdForConversion];

                List<Account> accountsToUpdate = new List<Account>();
                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                List<Follow_Up__c> followUpsToUpdate = new List<Follow_Up__c>();
                List<Test_Drive__c> testDrivesToUpdate = new List<Test_Drive__c>();

                for (Lead lead : leadRec) {
                    Id accountId = LeadTriggerHandler.getLeadOwnerByPincode(lead.PostalCode);
                    if (accountId == null) {
                        throw new CustomException('No pincodes associated with this postal code, so we cannot convert this lead: ' + lead.PostalCode);
                    }

                    Id contactId = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1].Id;
                    Id ownerId = [SELECT Id FROM User WHERE ContactId = :contactId LIMIT 1].Id;

                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(lead.Id);
                    lc.setConvertedStatus('Converted');
                    lc.setDoNotCreateOpportunity(false);

                    Database.LeadConvertResult result = Database.convertLead(lc);

                    if (result.isSuccess()) {
                        Id accId = result.getAccountId();
                        Id oppId = result.getOpportunityId();

                        if (accId != null) {
                            Account acc = new Account(Id = accId, Name = lead.Name);
                            accountsToUpdate.add(acc);
                        }

                        if (oppId != null) {
                            Opportunity opp = new Opportunity(
                                Id = oppId,
                                StageName = 'Test Ride Scheduled',
                                CloseDate = System.today().addDays(30),
                                OwnerId = ownerId
                            );
                            oppsToUpdate.add(opp);

                            for (Follow_Up__c f : listOfFollowUp) {
                                if (f.Lead__c == lead.Id) {
                                    f.Opportunity__c = opp.Id;
                                    followUpsToUpdate.add(f);
                                }
                            }
                            for (Test_Drive__c t : listOfTestDrive) {
                                if (t.Lead__c == lead.Id) {
                                    t.Opportunity__c = opp.Id;
                                    testDrivesToUpdate.add(t);
                                }
                            }
                        }
                    }
                }

                if (!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }
                if (!oppsToUpdate.isEmpty()) {
                    update oppsToUpdate;
                    OpportunityTriggerHandler.assignOpportunityToSM(oppsToUpdate);
                }
                if (!followUpsToUpdate.isEmpty()) {
                    update followUpsToUpdate;
                }
                if (!testDrivesToUpdate.isEmpty()) {
                    update testDrivesToUpdate;
                }
            }
        } catch (Exception e) {
            System.debug('Error in convertLeadIfStatusIsScheduledMerged ===> ' + e.getMessage() + ' at line ===> ' + e.getLineNumber());
        }
    }


    public static void assignSameOwnerOfLeadAndOppToTestDriveOwner(List<Test_Drive__c> newList) {
        Set<Id> setOfLeadId = new Set<Id>();
        Set<Id> setOfOppId = new Set<Id>();

        for (Test_Drive__c testDriveRec : newList) {
            if (testDriveRec.Lead__c != null) {
                setOfLeadId.add(testDriveRec.Lead__c);
            }
            if (testDriveRec.Opportunity__c != null) {
                setOfOppId.add(testDriveRec.Opportunity__c);
            }
        }

        Map<Id, Id> mapOfLeadOwner = new Map<Id, Id>();
        Map<Id, Id> mapOfOppOwner = new Map<Id, Id>();

        if(!setOfLeadId.isEmpty()){
            for (Lead lead : [SELECT Id, OwnerId FROM Lead WHERE Id IN :setOfLeadId]) {
                mapOfLeadOwner.put(lead.Id, lead.OwnerId);
            }
        }

        if(!setOfOppId.isEmpty()){
            for (Opportunity opp : [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :setOfOppId]) {
                mapOfOppOwner.put(opp.Id, opp.OwnerId);
            }
        }

        for (Test_Drive__c testDriveRec : newList) {
            if (mapOfOppOwner.containsKey(testDriveRec.Opportunity__c)) {
                testDriveRec.OwnerId = mapOfOppOwner.get(testDriveRec.Opportunity__c);
            } else if (mapOfLeadOwner.containsKey(testDriveRec.Lead__c)) {
                testDriveRec.OwnerId = mapOfLeadOwner.get(testDriveRec.Lead__c);
            }
        }
    }

    @AuraEnabled
    public static void updateTestDriveStatus(String recordId, String status, String reason, String subReason, String others) {
        try{
            if(recordId != null){
                Test_Drive__c td = [SELECT Id, Opportunity__c FROM Test_Drive__c WHERE Id = :recordId];
                td.Test_Drive_Status__c = status;
                
                if (status == 'Canceled') {
                    if (td.Opportunity__c != null) {
                        Opportunity opp = new Opportunity(
                            Id = td.Opportunity__c,
                            Drop_Out_Reasons__c = reason,
                            Drop_Out_Sub_Reasons__c = subReason,
                            Others__c = others
                        );
                        update opp;
                    }  
                } 
                update td;
            }
        }catch(Exception e){
            System.debug('Error ===> ' + e.getMessage() + ' at line ===> ' + e.getLineNumber());
        }
    }

    public static void createFollowUpOnTestRideCompletion(List<Test_Drive__c> testDriveList){
        try{
            set<Id> setOfOppId = new Set<Id>();
            for(Test_Drive__c testDirveRec: testDriveList){
                if(testDirveRec.Test_Drive_Status__c == 'Completed'){
                    setOfOppId.add(testDirveRec.Opportunity__c);
                }
            }
            List<Follow_Up__c> followUpList = new List<Follow_Up__c>();
            if(!setOfOppId.isEmpty()){
                followUpList = [SELECT Id, Opportunity__c,Status__c,Name FROM Follow_Up__c WHERE Opportunity__c IN :setOfOppId];
            }
            List<Follow_Up__c> followUpListToBeUpdated = new List<Follow_Up__c>();
            List<Follow_Up__c> followUpListToBeInserted = new List<Follow_Up__c>();
            if(!followUpList.isEmpty()){
                for(Follow_Up__c followUpRec : followUpList){
                    if(followUprec.Status__c != 'Completed'){
                        Follow_Up__c newFollowUp = new Follow_Up__c();
                        newFollowUp.Follow_Up_Date__c = system.today().addDays(1);
                        newFollowUp.Opportunity__c = followUpRec.Opportunity__c;
                        newFollowUp.Name = followUpRec.Name;
                        newFollowUp.FollowUpType__c = 'booking call';
                        followUpListToBeInserted.add(newFollowUp);
                        
                        followUprec.Status__c = 'Completed';
                        followUpListToBeUpdated.add(followUprec); 
                    }
                }
            }
            
            if(!followUpListToBeUpdated.isEmpty()){
                update followUpListToBeUpdated;
            }
            if(!followUpListToBeInserted.isEmpty()){
                insert followUpListToBeInserted;
            }
        }catch(Exception e){
            System.debug('Error ===> ' + e.getMessage() + ' at line ===> ' + e.getLineNumber());
        }
    }

    public static void deleteOldNotCompletedTestDrive(List<Test_Drive__c> testDriveList){
        try{
            set<Id> setOfoppId = new set<Id>();
            set<Id> setOfTestDriveId = new set<Id>();
            for(Test_Drive__c testDriveRec : testDriveList){
                if(testDriveRec.Opportunity__c != null){
                    setOfoppId.add(testDriveRec.Opportunity__c);
                    setOfTestDriveId.add(testDriveRec.Id);
                }
            }
            if(!setOfoppId.isEmpty() && !setOfTestDriveId.isEmpty()){
                List<Test_Drive__c> listOfOldTestDriveWhichIsNotCompeleted = [Select Id from Test_Drive__c Where Id NOT IN: setOfTestDriveId AND Opportunity__c IN: setOfoppId AND Test_Drive_Status__c != 'Completed'];
                delete listOfOldTestDriveWhichIsNotCompeleted;
            }
        }catch(Exception e){
            System.debug('Error ===> ' + e.getMessage() + ' at line ===> ' + e.getLineNumber());
        }
    }
    
    public class CustomException extends Exception {}
}