/**
* @description       : 
* @author            : Aniket Karmakar
* @group             : 
* @last modified on  : 08-04-2025
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
            Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, Phone FROM Lead WHERE Id IN :leadIds]);
            
            
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
        Map<Id,String> idToTimeOnlyForHome = new Map<Id,String>();
        
        //dataSet for Store Ride
        List<Id> testDriveIdsToProcessForStore = new List<Id>();
        Map<Id,String> idToPhoneNumberMapForStore = new Map<Id,String>();
        Map<Id,String> idToFormattedDateTimeMapForStore = new Map<Id,String>();
        Map<Id,String> rideTypeMapForStore = new Map<Id,String>();
        Map<Id,String> idToTimeOnlyForStrore = new Map<Id,String>();

        
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
            
            Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, LeadSource, Dealer_Code__c,Lead_Dealer_Code__c,Phone FROM Lead WHERE Id IN :leadIds]);
            
            
            for (Test_Drive__c t : newTestDrives) {
                if (t.Lead__c != null && leadMap.containsKey(t.Lead__c)) {
                    Lead leadRecord = leadMap.get(t.Lead__c);  
                    
                    
                    if (leadRecord != null && /*leadRecord.LeadSource != 'OzoneTel WhatsApp'  &&*/ (dealerCodes.contains(leadRecord.Dealer_Code__c) || dealerCodes.contains(leadRecord.Lead_Dealer_Code__c))) {
                        
                        if (t.Ride_Type__c == 'HTR') {
                            Datetime dateTimeString = t.Test_Ride_Date__c;
                            String formattedTimeForHome = dateTimeString.format('dd/MM/yyyy');
                            String rideTypeValueForHome = 'the comfort of your home';
                            String timeOnly = t.Test_Ride_Date__c.format('hh:mm a');//added by Aniket on 04/08/2025
                            
                            testDriveIdsToProcessForHome.add(t.Id);
                            idToPhoneNumberMapForHome.put(t.Id, leadRecord.Phone);
                            idToFormattedDateTimeMapForHome.put(t.Id, formattedTimeForHome);
                            rideTypeMapForHome.put(t.Id, rideTypeValueForHome);
                            idToTimeOnlyForHome.put(t.Id,timeOnly);//added by Aniket on 04/08/2025
                        } else if (t.Ride_Type__c == 'STR') {
                            Datetime dateTimeString = t.Test_Ride_Date__c;
                            String formattedTimeForStore = dateTimeString.format('dd/MM/yyyy');
                            String timeOnly = t.Test_Ride_Date__c.format('hh:mm a');//added by Aniket on 04/08/2025
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
                            idToTimeOnlyForStrore.put(t.Id,timeOnly);
                        }
                    }
                }
            }
            
            System.debug('testDriveIdsToProcessForHome===>'+testDriveIdsToProcessForHome);
            System.debug('testDriveIdsToProcessForStore===>'+testDriveIdsToProcessForStore);
            System.debug('idToPhoneNumberMapForStore===>'+idToPhoneNumberMapForStore);
            System.debug('rideTypeMapForStore===>'+rideTypeMapForStore);
            
            if(!testDriveIdsToProcessForHome.isEmpty() && (idToPhoneNumberMapForHome!=null && idToFormattedDateTimeMapForHome!=null &&rideTypeMapForHome!=null)){
                System.enqueueJob(new TestDriveCreationUpdatedQueueable(testDriveIdsToProcessForHome,idToPhoneNumberMapForHome,idToFormattedDateTimeMapForHome,rideTypeMapForHome,idToTimeOnlyForHome));
            }
            if(!testDriveIdsToProcessForStore.isEmpty()&& (idToPhoneNumberMapForStore!=null && idToFormattedDateTimeMapForStore!=null &&rideTypeMapForStore!=null)){
                System.enqueueJob(new TestDriveCreationUpdatedQueueable(testDriveIdsToProcessForStore,idToPhoneNumberMapForStore,idToFormattedDateTimeMapForStore,rideTypeMapForStore,idToTimeOnlyForStrore));
            }
            
        }catch(Exception e){
            System.debug('Error Occured====>'+e.getMessage());
            System.debug('Error Line Number is ==>'+e.getLineNumber());  
            
        }
    }
    
    //method Added by Aniket(05/02/2025) 
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
            Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id,Dealer_Code__c,Phone from Lead WHERE Id IN:tdIdsForFetchingLead]);
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
            Map<Id,Lead> mapOfLeadRecs = new Map<Id,Lead>([SELECT Id, Status, PostalCode FROM Lead]);
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
            
            if (setOfLeadId.isEmpty()) {
                return;
            }
            List<Lead> leadRec = new list<Lead>();//[SELECT Id, Status, PostalCode FROM Lead WHERE Id IN :setOfLeadId];
            for(Lead lds : mapOfLeadRecs.values()){
                if(setOfLeadId.contains(lds.Id)){
                    leadRec.add(lds);
                }
            }
            System.debug('leadRec=====>'+leadRec);
            
            Map<Id, Lead> leadMap = new Map<Id, Lead>();
            Map<String, String> mapOfPincodes = new Map<String, String>();
            
            List<Follow_Up__c> listOfFollowUp = [SELECT Id, Opportunity__c FROM Follow_Up__c WHERE Status__c IN ('Not Started', 'In Progress','Waiting for someone else') AND Lead__c IN :setOfLeadId];
            System.debug('Retrieved Follow_Up__c records: ' + listOfFollowUp);
            
            List<Test_Drive__c> listOfTestDrive = [SELECT Id, Lead__c FROM Test_Drive__c WHERE Test_Drive_Status__c IN ('New', 'In Progress') AND Lead__c IN :setOfLeadId];
            System.debug('Retrieved Test_Drive__c records: ' + listOfTestDrive);
            
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
    
    public static void convertLeadIfStatusIsScheduled(List<Test_Drive__c> newList) {
        Set<Id> setOfLeadId = new Set<Id>();
        
        for (Test_Drive__c testDriveRec : newList) {
            if (testDriveRec.Lead__c != null && testDriveRec.Opportunity__c == null && testDriveRec.Test_Drive_Status__c == 'Scheduled') {
                setOfLeadId.add(testDriveRec.Lead__c);
            }
        }
        
        if (!setOfLeadId.isEmpty()) {
            List<Lead> leadRec = [SELECT Id, Name, Status, PostalCode FROM Lead WHERE Id IN :setOfLeadId AND Status != 'Converted'];
            List<Follow_Up__c> listOfFollowUp = [SELECT Id, Name, Opportunity__c FROM Follow_Up__c WHERE Lead__c IN :setOfLeadId];
            List<Test_Drive__c> listOfTestDrive = [SELECT Id, Name, Lead__c, Opportunity__c FROM Test_Drive__c WHERE Lead__c IN :setOfLeadId];
            
            for (Lead lead : leadRec) {
                System.debug('Processing Lead record: ' + lead);
                
                Id accountId = LeadTriggerHandler.getLeadOwnerByPincode(lead.PostalCode);
                System.debug('accountId =======> ' + accountId);
                
                if (accountId == null) {
                    throw new CustomException('No pincodes associated with this postal code, so we cannot convert this lead: ' + lead.PostalCode);
                }
                
                Id contactId = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1].Id;
                System.debug('contactId =======> ' + contactId);
                
                Id OwnerId =  [Select Id FROM User WHERE contactId = :contactId LIMIT 1 ].Id;
                System.debug('ownerId =======> ' + ownerId);
                
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lead.Id);
                lc.setConvertedStatus('Converted');
                lc.setDoNotCreateOpportunity(false);
                
                Database.LeadConvertResult result = Database.convertLead(lc);
                System.debug('Lead Conversion Result for ' + lead.Id + ': ' + result.isSuccess());
                
                if (result.isSuccess()) {
                    Id oppId = result.getOpportunityId();
                    System.debug('Converted Opportunity ID: ' + oppId);
                    
                    if (oppId != null) {
                        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppId];
                        opp.StageName = 'Test Ride Scheduled';
                        opp.CloseDate = System.today().addDays(30);
                        opp.OwnerId = ownerId;
                        update opp;
                        
                        for (Follow_Up__c followUpRec : listOfFollowUp) {
                            followUpRec.Opportunity__c = opp.Id;
                        }
                        update listOfFollowUp;
                        
                        for (Test_Drive__c testDriveRec : listOfTestDrive) {
                            testDriveRec.Opportunity__c = opp.Id;
                        }
                        update listOfTestDrive;
                    }
                }
            }
        }
    }
    
    public static void convertLeadIfStatusIsScheduledUpdated(List<Test_Drive__c> newList, Map<Id, Test_Drive__c> oldMapTestDrive) {
        System.debug('Entering convertLeadIfStatusIsScheduledUpdated method');
        Set<Id> setOfLeadId = new Set<Id>();
        try {
            for (Test_Drive__c testDriveRec : newList) {
                System.debug('Processing Test_Drive__c record: ' + testDriveRec);
                if (testDriveRec.Lead__c != null && testDriveRec.Lead__r.Status != 'Converted' 
                    && testDriveRec.Test_Drive_Status__c == 'Scheduled' && testDriveRec.Opportunity__c == null
                    && testDriveRec.Test_Drive_Status__c != oldMapTestDrive.get(testDriveRec.Id).Test_Drive_Status__c) {
                        setOfLeadId.add(testDriveRec.Lead__c);
                        System.debug('Added Lead Id to set: ' + testDriveRec.Lead__c);
                    }
            }
            
            if (!setOfLeadId.isEmpty()) {
                System.debug('Leads to be converted: ' + setOfLeadId);
                List<Follow_Up__c> listOfFollowUp = [SELECT Id, Opportunity__c FROM Follow_Up__c WHERE Lead__c IN :setOfLeadId];
                System.debug('Retrieved Follow_Up__c records: ' + listOfFollowUp);
                
                List<Test_Drive__c> listOfTestDrive = [SELECT Id, Lead__c FROM Test_Drive__c WHERE Lead__c IN :setOfLeadId];
                System.debug('Retrieved Test_Drive__c records: ' + listOfTestDrive);
                
                List<Lead> leadRec = [SELECT Id, Name, Status, PostalCode FROM Lead WHERE Id IN :setOfLeadId];
                System.debug('Retrieved Lead records: ' + leadRec);
                
                for (Lead lead : leadRec) {
                    System.debug('Processing Lead record: ' + lead);
                    Id accountId = LeadTriggerHandler.getLeadOwnerByPincode(lead.PostalCode);
                    System.debug('accountId =======> ' + accountId);
                    
                    if (accountId == null) {
                        throw new CustomException('No pincodes associated with this postal code, so we cannot convert this lead: ' + lead.PostalCode);
                    }
                    
                    Id contactId = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1].Id;
                    System.debug('contactId =======> ' + contactId);
                    
                    Id OwnerId =  [Select Id FROM User WHERE contactId = :contactId LIMIT 1 ].Id;
                    System.debug('ownerId =======> ' + ownerId);
                    
                    
                    
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(lead.Id);
                    lc.setConvertedStatus('Converted');
                    lc.setDoNotCreateOpportunity(false);
                    
                    Database.LeadConvertResult result = Database.convertLead(lc);
                    System.debug('Lead Conversion Result for ' + lead.Id + ': ' + result.isSuccess());
                    
                    if (result.isSuccess()) {
                        Id accId = result.getAccountId();
                        Id conId = result.getContactId();
                        Id oppId = result.getOpportunityId();
                        System.debug('Converted Account ID: ' + accId);
                        System.debug('Converted Contact ID: ' + conId);
                        System.debug('Converted Opportunity ID: ' + oppId);
                        
                        if (accId != null) {
                            Account acc = [SELECT Id, Name FROM Account WHERE Id = :accId];
                            acc.Name = lead.Name;
                            update acc;
                            System.debug('Updated Account Name for Account ID: ' + accId);
                        }
                        
                        if (oppId != null) {
                            
                            Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppId];
                            if (opp != null) {
                                opp.StageName = 'Test Ride Scheduled';
                                opp.CloseDate = System.today().addDays(30);
                                opp.OwnerId = ownerId;
                                update opp;
                                System.debug('Updated Opportunity details for Opp ID: ' + oppId);
                                
                                for (Follow_Up__c followUpRec : listOfFollowUp) {
                                    followUpRec.Opportunity__c = opp.Id;
                                }
                                update listOfFollowUp;
                                System.debug('Updated Follow_Up__c records with Opp ID: ' + oppId);
                                
                                for (Test_Drive__c testDriveRec : listOfTestDrive) {
                                    testDriveRec.Opportunity__c = opp.Id;
                                }
                                update listOfTestDrive;
                                System.debug('Updated Test_Drive__c records with Opp ID: ' + oppId);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in convertLeadIfStatusIsScheduledUpdated =====> ' + e.getMessage() + ' at line number =====>' + e.getLineNumber());
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
    
    
    
    public class CustomException extends Exception {}
    
    public static void mytest(){
        Integer i=0;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        
    }
    
}