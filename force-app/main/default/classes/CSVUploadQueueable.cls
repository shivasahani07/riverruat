public class CSVUploadQueueable implements Queueable {
    @TestVisible
    private String userId;
    
    @TestVisible
    private String objectName;
    
    @TestVisible
    private Map<String, String> fieldMapping;
    
    @TestVisible
    private List<String> csvRows;

    @TestVisible
    private Integer recordsProcessed;
    
    @TestVisible
    private static final Integer CHUNK_SIZE = 80;
    
    public CSVUploadQueueable(String userId, String objectName, Map<String, String> fieldMapping, List<String> csvRows) {
        this(userId, objectName, fieldMapping, csvRows, 0);
    }
    
    public CSVUploadQueueable(String userId, String objectName, Map<String, String> fieldMapping, List<String> csvRows, Integer recordsProcessed) {
        this.userId = userId;
        this.objectName = objectName;
        this.fieldMapping = fieldMapping;
        this.csvRows = csvRows;
        this.recordsProcessed = recordsProcessed;
    }
    
    public void execute(QueueableContext context) {
        try {
            if (csvRows == null || csvRows.isEmpty()) return;
            
            List<String> chunkRows = new List<String>();
            List<String> remainingRows = new List<String>();
            Integer totalRows = csvRows.size();
            
            if (totalRows > CHUNK_SIZE) {
                for (Integer i = 0; i < CHUNK_SIZE; i++) {
                    chunkRows.add(csvRows[i]);
                }
                for (Integer i = CHUNK_SIZE; i < totalRows; i++) {
                    remainingRows.add(csvRows[i]);
                }
            } else {
                chunkRows = csvRows;
            }
            
            processChunk(chunkRows);
            
            if (!remainingRows.isEmpty()) {
                System.enqueueJob(new CSVUploadQueueable(userId, objectName, fieldMapping, remainingRows, recordsProcessed));
            } else {
                sendUserNotification(userId, 'Success', recordsProcessed + ' records uploaded successfully.');
            }
        } catch (Exception e) {
            sendUserNotification(userId, 'Failed', 'Error: ' + e.getMessage());
            System.debug('Error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
    
    @TestVisible
    private void processChunk(List<String> chunkRows) {
        List<Account> accountsToInsert = new List<Account>();
        List<Contact> contactsToInsert = new List<Contact>();
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        List<Lead> leadsToInsert = new List<Lead>();
        
        for (String row : chunkRows) {
            if (String.isBlank(row)) continue;
            
            String[] values = row.split(',');
            Integer index = 0;
            
            Account acc = new Account();
            Contact con = new Contact();
            Opportunity opp = new Opportunity();
            Lead led = new Lead();
            
            for (String csvColumn : fieldMapping.keySet()) {
                String fieldName = fieldMapping.get(csvColumn);
                if (index < values.size()) {
                    String value = values[index++];
                    if (String.isBlank(value)) continue;
                    
                    if (objectName.equalsIgnoreCase('opportunity')) {
                        if (opp.Enquiry_Source__c != null) {
                            opp.LeadSource = null;
                            if (acc != null) acc.AccountSource = null;
                            if (con != null) con.LeadSource = null;
                        }
                        mapOpportunityFields(acc, con, opp, fieldName, value);
                    } else if (objectName.equalsIgnoreCase('lead')) {
                        mapLeadFields(led, fieldName, value);
                    }
                }
            }
            
            if (!acc.getPopulatedFieldsAsMap().isEmpty()) accountsToInsert.add(acc);
            if (!con.getPopulatedFieldsAsMap().isEmpty()) contactsToInsert.add(con);
            if (!opp.getPopulatedFieldsAsMap().isEmpty()) opportunitiesToInsert.add(opp);
            if (!led.getPopulatedFieldsAsMap().isEmpty()) leadsToInsert.add(led);
            
            System.debug(accountsToInsert.size() + '=====accs======' + accountsToInsert);
            System.debug(contactsToInsert.size() + '=====cons======' + contactsToInsert);
            System.debug(opportunitiesToInsert.size() + '=====opps======' + opportunitiesToInsert);
            System.debug(leadsToInsert.size() + '=====leds======' + leadsToInsert);
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            if (!leadsToInsert.isEmpty()) {
                System.debug('=====leadsToInsert======' + leadsToInsert);
                processLeadsWithAccountCheckHQInsert(leadsToInsert);
            }
            
            if (!opportunitiesToInsert.isEmpty()) {
                System.debug('=====opportunitiesToInsert======' + leadsToInsert);
                processOpportunitiesWithAccountCheckDMSInsert(accountsToInsert, contactsToInsert, opportunitiesToInsert);
            }
        } catch (Exception e) {
            System.debug(' error message =====>'+e.getMessage() + ' at line number =====>' + e.getLineNumber());
            Database.rollback(sp);
            throw e;
        }
    }
    
    @TestVisible 
    private void processLeadsWithAccountCheckHQInsert(List<Lead> leadsToInsert) {
        Set<String> leadPhones = new Set<String>();
        Map<String, Lead> phoneToLeadMap = new Map<String, Lead>();
        Set<String> phonesWithAccounts = new Set<String>();
        List<Opportunity> opportunitiesToCreate = new List<Opportunity>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<Duplicate_Record__c> duplicateToCreate = new List<Duplicate_Record__c>();
        List<Lead> leadsToInsertWithoutAccounts = new List<Lead>();
        List<Lead> insertLeadsIfNoExistingAccountAndLeadsAreThereInSystem = new List<Lead>();
        List<Lead> leadsToUpdate = new List<Lead>();
        List<Follow_Up__c> followUpsToCreate = new List<Follow_Up__c>();
        Map<String, Lead> duplicatePhone = new Map<String, Lead>();
        
        
        for (Lead led : leadsToInsert) {
            if (led.Phone != null) {
                leadPhones.add(led.Phone);
                phoneToLeadMap.put(led.Phone, led);
            }
        }
        
        if (!leadPhones.isEmpty()) {
            List<Account> existingAccounts = [SELECT Id, Name, Phone, AccountSource, OwnerId FROM Account WHERE Phone IN :leadPhones];
            List<Lead> existingLeads = [SELECT Id, Name, Phone, Secondary_Sources__c,LeadSource FROM Lead WHERE Phone IN :leadPhones AND isConverted = false];
            Set<Id> accountIds = new Set<Id>();
            
            System.debug(existingAccounts.size() + '=====existingAccounts======' + existingAccounts);
            System.debug(existingLeads.size() + '=====existingLeads======' + existingLeads);
            
            if (!existingAccounts.isEmpty()) {
                System.debug('1 ==============>');
                for (Account acc : existingAccounts) {
                    accountIds.add(acc.Id);
                    duplicatePhone.put(acc.phone,null);
                }
                
                Map<Id, Opportunity> accountOpportunities = new Map<Id, Opportunity>();
                for (Opportunity opp : [SELECT Id, AccountId,Name, Phone__c, StageName, CloseDate, LeadSource 
                                        FROM Opportunity 
                                        WHERE AccountId IN :accountIds]) {
                                            accountOpportunities.put(opp.AccountId, opp);
                                        }
                
                Map<Id, List<Test_Drive__c>> testDrivesByAccount = new Map<Id, List<Test_Drive__c>>();
                for (Test_Drive__c td : [SELECT Id, Opportunity__c,Opportunity__r.Name, Opportunity__r.AccountId, Test_Drive_Status__c,Opportunity__r.Enquiry_Source__c
                                         FROM Test_Drive__c 
                                         WHERE Opportunity__r.AccountId IN :accountIds]) {
                                             if (!testDrivesByAccount.containsKey(td.Opportunity__r.AccountId)) {
                                                 testDrivesByAccount.put(td.Opportunity__r.AccountId, new List<Test_Drive__c>());
                                             }
                                             testDrivesByAccount.get(td.Opportunity__r.AccountId).add(td);
                                         }
                
                for (Account acc : existingAccounts) {
                    Opportunity existingOpp = accountOpportunities.get(acc.Id);
                    List<Test_Drive__c> testDrives = testDrivesByAccount.get(acc.Id);
                    
                    if (existingOpp != null && existingOpp.StageName != 'Closed Won' || existingOpp.StageName != 'Drop Out') {
                        Boolean hasIncompleteTestDrive = false;
                        if (testDrives != null) {
                            for (Test_Drive__c td : testDrives) {
                                if (td.Test_Drive_Status__c != 'Completed') {
                                    hasIncompleteTestDrive = true;
                                    break;
                                }
                            }
                        }
                        if (hasIncompleteTestDrive) {
                            opportunitiesToUpdate.add(new Opportunity(
                                Id = existingOpp.Id,
                                Enquiry_Primary_Source__c = 'Walk-in',
                                Secondary_Sources__c = 'Walk-in'
                            ));
                        } else {
                            followUpsToCreate.add(new Follow_Up__c(
                                Name = existingOpp.Name + ' - Follow-up',
                                Phone__c = acc.Phone,
                                Opportunity__c = existingOpp.Id,
                                Subject__c = 'Call',
                                Follow_Up_Date__c = System.today() + 1,
                                Due_Date__c = System.today() + 2
                            ));
                        }
                    } else {
                        Opportunity newOpp = new Opportunity(
                            Name = acc.Name,
                            Phone__c = acc.Phone,
                            LeadSource = phoneToLeadMap.get(acc.Phone).LeadSource != null ? phoneToLeadMap.get(acc.Phone).LeadSource : null,
                            Lead_Secondary_Source__c = phoneToLeadMap.get(acc.Phone).Secondary_Sources__c != null ? phoneToLeadMap.get(acc.Phone).Secondary_Sources__c : null,
                            // Enquiry_Primary_Source__c = phoneToLeadMap.get(acc.Phone).LeadSource != null ? phoneToLeadMap.get(acc.Phone).LeadSource : null,
                            // Secondary_Sources__c = phoneToLeadMap.get(acc.Phone).Secondary_Sources__c != null ? phoneToLeadMap.get(acc.Phone).Secondary_Sources__c : null,
                            Secondary_Source__c = 'Bulk Upload',
                            StageName = 'New',
                            CloseDate = System.today(),
                            AccountId = acc.Id,
                            OwnerId = userId
                            //Enquiry_Source__c = phoneToLeadMap.get(acc.Phone).Enquiry_Source__c
                        );
                        opportunitiesToCreate.add(newOpp);
                    }
                    
                    duplicateToCreate.add(new Duplicate_Record__c(
                        Name__c = acc.Name,
                        Phone__c = acc.Phone,
                        Object_Type__c = 'Enquiry'
                    ));
                    phonesWithAccounts.add(acc.Phone);
                }
            }
            
            if (!existingLeads.isEmpty()) {
                System.debug('2 ==============>');
                for (Lead led : existingLeads) {
                    led.Secondary_Source__c = 'Bulk Upload';
                    leadsToUpdate.add(led);
                    duplicateToCreate.add(new Duplicate_Record__c(
                        Name__c = led.Name,
                        Phone__c = led.Phone,
                        Object_Type__c = 'Lead'
                    ));
                    duplicatePhone.put(led.phone,led);
                    phonesWithAccounts.add(led.Phone);
                }
                
            }

            for(lead led : leadsToInsert){
                if(!duplicatePhone.containskey(led.phone)){
                    insertLeadsIfNoExistingAccountAndLeadsAreThereInSystem.add(led);
                }
            }
            
            if(existingAccounts.isEmpty() && existingLeads.isEmpty()){
                insertLeadsIfNoExistingAccountAndLeadsAreThereInSystem = leadsToInsert;
            }
        }
        
        if (!insertLeadsIfNoExistingAccountAndLeadsAreThereInSystem.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(insertLeadsIfNoExistingAccountAndLeadsAreThereInSystem, false);
            errorMessages(srList, insertLeadsIfNoExistingAccountAndLeadsAreThereInSystem);
        }
        
        if (!leadsToInsertWithoutAccounts.isEmpty()) {
            System.debug('3 ==============>');
            Database.SaveResult[] srList = Database.insert(leadsToInsertWithoutAccounts, false);
            errorMessages(srList, leadsToInsertWithoutAccounts);
            recordsProcessed += leadsToInsertWithoutAccounts.size();
        }
        
        if (!leadsToUpdate.isEmpty()) {
            System.debug('4 ==============>');
            Database.SaveResult[] srList = Database.update(leadsToUpdate, false);
            errorMessages(srList, leadsToUpdate);
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            System.debug('5 ==============>');
            Database.SaveResult[] srList = Database.update(opportunitiesToUpdate, false);
            errorMessages(srList, opportunitiesToUpdate);
        }
        
        if (!opportunitiesToCreate.isEmpty()) {
            System.debug('6 ==============>');
            Database.SaveResult[] srList = Database.Insert(opportunitiesToCreate, false);
            errorMessages(srList, opportunitiesToCreate);
            recordsProcessed += opportunitiesToCreate.size();
            set<Id> setOfInsertedOpportunity = new set<Id>();
            for(Opportunity opp : opportunitiesToCreate){
                System.debug('6.1 ==============>');
                setOfInsertedOpportunity.add(opp.Id);
            }
            List<Opportunity> oppList = [Select Id,Name,Phone__c from Opportunity Where Id IN: setOfInsertedOpportunity];
            List<Follow_Up__c> followUpListToBeInserted = new List<Follow_Up__c>();
            for(Opportunity opp : oppList){
                System.debug('6.2 ==============>');
                followUpListToBeInserted.add(new Follow_Up__c(
                    Name = opp.Name + ' - Follow-up',
                    Phone__c = opp.Phone__c,
                    Opportunity__c = opp.Id,
                    Subject__c = 'Call',
                    Follow_Up_Date__c = System.today() + 1,
                    Due_Date__c = System.today() + 2
                ));
            }
            if(!followUpListToBeInserted.isEmpty()){
                System.debug('6.3 ==============>');
                Database.SaveResult[] srLists = Database.Insert(followUpListToBeInserted, false);
                errorMessages(srList, followUpListToBeInserted);
            }
        }
        
        if (!followUpsToCreate.isEmpty()) {
            System.debug('7 ==============>');
            //insert followUpsToCreate;
            Database.SaveResult[] srList = Database.Insert(followUpsToCreate, false);
            errorMessages(srList, followUpsToCreate);
        }
        
        if (!duplicateToCreate.isEmpty()) {
            System.debug('8 ==============>');
            Database.SaveResult[] srList = Database.Insert(duplicateToCreate, false);
            errorMessages(srList, duplicateToCreate);
        }
    }
    
    @TestVisible 
    private void processOpportunitiesWithAccountCheckDMSInsert(List<Account> accountsToInsert, List<Contact> contactsToInsert, List<Opportunity> opportunitiesToInsert) {
        Set<String> oppPhones = new Set<String>();
        Map<String, Opportunity> phoneToOppMap = new Map<String, Opportunity>();
        Set<String> duplicatePhones = new Set<String>();
        List<Duplicate_Record__c> duplicateToCreate = new List<Duplicate_Record__c>();
        List<Opportunity> opportunitiesToCreateForExistingAccounts = new List<Opportunity>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<Lead> leadsToConvert = new List<Lead>();
        List<Follow_Up__c> followUpsToCreate = new List<Follow_Up__c>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        Map<Id, Opportunity> leadIdToOpportunityMap = new Map<Id, Opportunity>();
        Map<Id,Lead> mapOfLeadsWhichCoverted = new Map<Id,Lead>();
        Map<String,String> mapOfEnquirySource = new Map<String,String>();
        List<Opportunity> insertLeadsIfNoExistingAccountAndLeadsAreThereInSystem = new List<Opportunity>();
        
        for (Opportunity opp : opportunitiesToInsert) {
            if (opp.Phone__c != null) {
                oppPhones.add(opp.Phone__c);
                phoneToOppMap.put(opp.Phone__c, opp);
                mapOfEnquirySource.put(opp.Phone__c, opp.Enquiry_Source__c);
            }
        }
        
        if (!oppPhones.isEmpty()) {
            System.debug('9 ==============>');
            List<Account> existingAccounts = [
                SELECT Id, Name, Phone, AccountSource, OwnerId, 
                (SELECT Id,Name, StageName, CloseDate, LeadSource,Enquiry_Source__c,Enquiry_Primary_Source__c,Secondary_Sources__c FROM Opportunities Order By CreatedDate DESC ) 
                FROM Account WHERE Phone IN :oppPhones
            ];
            
            List<Lead> existingLeads = [
                SELECT Id, Name, Phone, Company, IsConverted ,LeadSource
                FROM Lead 
                WHERE Phone IN :oppPhones AND IsConverted = false
            ];
            
            System.debug(existingAccounts.size() + '=====existingAccountsDMS======' + existingAccounts);
            System.debug(existingLeads.size() + '=====existingLeadsDMS======' + existingLeads);
            
            if (!existingAccounts.isEmpty()) {
                System.debug('10 ==============>');
                for (Account acc : existingAccounts) {
                    duplicatePhones.add(acc.Phone);
                    Boolean hasOpenOpportunity = !acc.Opportunities.isEmpty();
                    Opportunity existingOpp = hasOpenOpportunity ? acc.Opportunities[0] : null;
                    
                    System.debug('duplicatePhones ==============>' + duplicatePhones);
                    System.debug('hasOpenOpportunity ==============>' + hasOpenOpportunity);
                    System.debug('existingOpp ==============>' + existingOpp);
                    
                    if (hasOpenOpportunity && existingOpp.StageName != 'Closed Won' && existingOpp.StageName != 'Drop Out') {
                        List<Test_Drive__c> testDrives = [
                            SELECT Id 
                            FROM Test_Drive__c 
                            WHERE Opportunity__c = :existingOpp.Id 
                            AND Test_Drive_Status__c != 'Completed'
                            LIMIT 1
                        ];
                        
                        if (!testDrives.isEmpty()) {
                            Opportunity updateOpp = new Opportunity(
                                Id = existingOpp.Id,
                                Secondary_Source__c = 'Bulk-Upload'
                            );
                            
                            // Only update Enquiry Source if present in CSV
                            updateOpp.Enquiry_Primary_Source__c = phoneToOppMap.get(acc.Phone).Enquiry_Primary_Source__c != null ? phoneToOppMap.get(acc.Phone).Enquiry_Primary_Source__c : '';
                            updateOpp.Secondary_Sources__c = phoneToOppMap.get(acc.Phone).Secondary_Sources__c != null ? phoneToOppMap.get(acc.Phone).Secondary_Sources__c : '';
                            opportunitiesToUpdate.add(updateOpp);
                        }
                        else {
                            followUpsToCreate.add(new Follow_Up__c(
                                Name = existingOpp.Name + ' - Follow-up',
                                Phone__c = acc.Phone,
                                Opportunity__c = existingOpp.Id,
                                Subject__c = 'Call',
                                Follow_Up_Date__c = System.today() + 1,
                                Due_Date__c = System.today() + 2
                            ));
                            
                            Opportunity updateOpp = new Opportunity(
                                Id = existingOpp.Id,
                                Secondary_Source__c = 'Bulk-Upload'
                            );
                            
                            // Only update Enquiry Source if present in CSV
                            updateOpp.Enquiry_Primary_Source__c = phoneToOppMap.get(acc.Phone).Enquiry_Primary_Source__c != null ? phoneToOppMap.get(acc.Phone).Enquiry_Primary_Source__c : '';
                            updateOpp.Secondary_Sources__c = phoneToOppMap.get(acc.Phone).Secondary_Sources__c != null ? phoneToOppMap.get(acc.Phone).Secondary_Sources__c : '';
                            opportunitiesToUpdate.add(updateOpp);
                        }
                    } else {
                        System.debug('21 ==============>');
                        Opportunity newOpp = new Opportunity(
                            Name = phoneToOppMap.get(acc.Phone).Name,
                            Phone__c = acc.Phone,
                            Enquiry_Primary_Source__c = phoneToOppMap.get(acc.Phone).Enquiry_Primary_Source__c != null ? phoneToOppMap.get(acc.Phone).Enquiry_Primary_Source__c : '',
                            Secondary_Sources__c = phoneToOppMap.get(acc.Phone).Secondary_Sources__c != null ? phoneToOppMap.get(acc.Phone).Secondary_Sources__c : '',
                            StageName = 'New',
                            Secondary_Source__c = 'Bulk Upload',
                            Enquiry_Source__c = phoneToOppMap.get(acc.Phone).Enquiry_Source__c,
                            CloseDate = phoneToOppMap.get(acc.Phone).CloseDate,
                            AccountId = acc.Id,
                            OwnerId = userId 
                        );
                        opportunitiesToCreateForExistingAccounts.add(newOpp);
                        System.debug(opportunitiesToCreateForExistingAccounts.size() + '=====newOpp======' + newOpp);
                        
                        if (acc.OwnerId != userId) {
                            accountsToUpdate.put(acc.Id, new Account(
                                Id = acc.Id, 
                                OwnerId = userId
                            ));
                        }
                    }
                    
                    duplicateToCreate.add(new Duplicate_Record__c(
                        Name__c = acc.Name,
                        Phone__c = acc.Phone,
                        Object_Type__c = 'Enquiry'
                    ));
                }
            }
            
            if (!existingLeads.isEmpty()) {
                System.debug('11 ==============>');
                for (Lead led : existingLeads) {
                    duplicatePhones.add(led.Phone);
                    leadsToConvert.add(led);
                    
                    if (phoneToOppMap.containsKey(led.Phone)) {
                        leadIdToOpportunityMap.put(led.Id, phoneToOppMap.get(led.Phone));
                    }
                    
                    duplicateToCreate.add(new Duplicate_Record__c(
                        Name__c = led.Name,
                        Phone__c = led.Phone,
                        Object_Type__c = 'Lead'
                    ));
                }
            }
        }
        
        if (!leadsToConvert.isEmpty()) {
            System.debug('12 ==============>');
            List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
            Map<Id, Id> leadIdToOpportunityId = new Map<Id, Id>();
            Map<Id, Lead> mapOfLeads = new Map<Id, Lead>();
            for (Lead led : leadsToConvert) {
                
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(led.Id);
                lc.setConvertedStatus('Converted');
                lc.setOwnerId(userId);
                lc.setDoNotCreateOpportunity(false);
                leadConverts.add(lc);
                
                mapOfLeads.put(led.Id,led);
            }
            
            List<Database.LeadConvertResult> lcrList = Database.convertLead(leadConverts);
            for (Database.LeadConvertResult lcr : lcrList) {
                if (lcr.isSuccess() && lcr.getOpportunityId() != null) {
                    leadIdToOpportunityId.put(lcr.getLeadId(), lcr.getOpportunityId());
                }
            }
            
            for (Id leadId : leadIdToOpportunityId.keySet()) {
                if (leadIdToOpportunityMap.containsKey(leadId)) {
                    Opportunity csvOpp = leadIdToOpportunityMap.get(leadId);
                    String LeadSource = mapOfEnquirySource.get(leadId);
                    
                    Opportunity newOpp = new Opportunity(
                        Id = leadIdToOpportunityId.get(leadId),
                        Enquiry_Primary_Source__c = csvOpp.Enquiry_Primary_Source__c != null ? csvOpp.Enquiry_Primary_Source__c : LeadSource,
                        Secondary_Sources__c = csvOpp.Secondary_Sources__c != null ? csvOpp.Secondary_Sources__c : LeadSource,
                        CloseDate = csvOpp.CloseDate,
                        Phone__c = mapOfLeads.get(leadId).Phone,
                        Secondary_Source__c = 'Bulk Upload'
                    );
                    opportunitiesToUpdate.add(newOpp);
                }
            }
        }
        
        List<Account> filteredAccounts = new List<Account>();
        List<Contact> filteredContacts = new List<Contact>();
        List<Opportunity> filteredOpportunities = new List<Opportunity>();
        
        for (Integer i = 0; i < opportunitiesToInsert.size(); i++) {
            Opportunity opp = opportunitiesToInsert[i];
            if (opp.Phone__c == null || !duplicatePhones.contains(opp.Phone__c)) {
                filteredOpportunities.add(opp);                
                if (i < accountsToInsert.size()) {
                    Account acc = accountsToInsert[i];
                    acc.Type = 'Customer';
                    filteredAccounts.add(acc);
                }
                if (i < contactsToInsert.size()) {
                    filteredContacts.add(contactsToInsert[i]);
                }
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            if (!filteredAccounts.isEmpty()) {
                System.debug('13 ==============>');
                
                Database.SaveResult[] srList = Database.Insert(filteredAccounts, false);
                errorMessages(srList,filteredAccounts);
                recordsProcessed += filteredAccounts.size();
            }
            
            for (Integer i = 0; i < filteredAccounts.size() && i < filteredContacts.size(); i++) {
                filteredContacts[i].AccountId = filteredAccounts[i].Id;
            }
            
            if (!filteredContacts.isEmpty()) {
                System.debug('14 ==============>');
                Database.SaveResult[] srList = Database.Insert(filteredContacts, false);
                errorMessages(srList,filteredContacts);
                recordsProcessed += filteredContacts.size();
            }
            
            for (Integer i = 0; i < filteredAccounts.size() && i < filteredOpportunities.size(); i++) {
                filteredOpportunities[i].AccountId = filteredAccounts[i].Id;
            }
            
            if (!filteredOpportunities.isEmpty()) {
                System.debug('15 ==============>');
                Database.SaveResult[] srList = Database.Insert(filteredOpportunities, false);
                errorMessages(srList,filteredOpportunities);
                recordsProcessed += filteredOpportunities.size();
            }
            
            if (!opportunitiesToCreateForExistingAccounts.isEmpty()) {
                System.debug('16 ==============>');
                Database.SaveResult[] srList = Database.Insert(opportunitiesToCreateForExistingAccounts, false);
                errorMessages(srList,opportunitiesToCreateForExistingAccounts);
                recordsProcessed += opportunitiesToCreateForExistingAccounts.size();
                
                set<Id> setOfInsertedOpportunity = new set<Id>();
                for(Opportunity opp : opportunitiesToCreateForExistingAccounts){
                    System.debug('16.1 ==============>');
                    setOfInsertedOpportunity.add(opp.Id);
                }
                
                List<Opportunity> oppList = [Select Id,Name,Phone__c from Opportunity Where Id IN: setOfInsertedOpportunity];
                List<Follow_Up__c> followUpListToBeInserted = new List<Follow_Up__c>();
                for(Opportunity opp : oppList){
                    System.debug('16.2 ==============>');
                    followUpListToBeInserted.add(new Follow_Up__c(
                        Name = opp.Name + ' - Follow-up',
                        Phone__c = opp.Phone__c,
                        Opportunity__c = opp.Id,
                        Subject__c = 'Call',
                        Follow_Up_Date__c = System.today() + 1,
                        Due_Date__c = System.today() + 2
                    ));
                }
                if(!followUpListToBeInserted.isEmpty()){
                    System.debug('16.3 ==============>');
                    Database.SaveResult[] srLists = Database.Insert(followUpListToBeInserted, false);
                    errorMessages(srList,followUpListToBeInserted);
                }
            }
            
            if (!accountsToUpdate.isEmpty()) {
                System.debug('17 ==============>');
                Database.SaveResult[] srList = Database.update(accountsToUpdate.values(), false);
                errorMessages(srList,accountsToUpdate.values());
            }
            
            if (!opportunitiesToUpdate.isEmpty()) {
                System.debug('18 ==============>');
                Database.SaveResult[] srList = Database.update(opportunitiesToUpdate, false);
                errorMessages(srList,opportunitiesToUpdate);
                
                set<Id> setOfInsertedOpportunity = new set<Id>();
                for(Opportunity opp : opportunitiesToUpdate){
                    System.debug('18.1 ==============>');
                    setOfInsertedOpportunity.add(opp.Id);
                }
                List<Opportunity> oppList = [Select Id,Name,Phone__c from Opportunity Where Id IN: setOfInsertedOpportunity];
                List<Follow_Up__c> followUpListToBeInserted = new List<Follow_Up__c>();
                for(Opportunity opp : oppList){
                    System.debug('18.2 ==============>');
                    followUpListToBeInserted.add(new Follow_Up__c(
                        Name = opp.Name + ' - Follow-up',
                        Phone__c = opp.Phone__c,
                        Opportunity__c = opp.Id,
                        Subject__c = 'Call',
                        Follow_Up_Date__c = System.today() + 1,
                        Due_Date__c = System.today() + 2
                    ));
                }
                if(!followUpListToBeInserted.isEmpty()){
                    System.debug('18.3 ==============>');
                    Database.SaveResult[] srLists = Database.Insert(followUpListToBeInserted, false);
                    errorMessages(srList,followUpListToBeInserted);
                }
            }
            
            if (!followUpsToCreate.isEmpty()) {
                System.debug('19 ==============>');
                Database.SaveResult[] srList = Database.Insert(followUpsToCreate, false);
                errorMessages(srList,followUpsToCreate);
            }
            
            if (!duplicateToCreate.isEmpty()) {
                System.debug('20 ==============>');
                Database.SaveResult[] srList = Database.Insert(duplicateToCreate, false);
                errorMessages(srList,duplicateToCreate);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw e;
        }
    }
    
    @TestVisible 
    private void mapOpportunityFields(Account acc, Contact con, Opportunity opp, String fieldName, String value) {
        if (fieldName.startsWithIgnoreCase('name')) {
            acc.Name = value;
            con.LastName = value;
            opp.Name = value;
        } else if (fieldName.startsWithIgnoreCase('phone__c')) {
            acc.Phone = value;
            con.Phone = value;
            opp.Phone__c = value;
        } else if (fieldName == 'closedate') {
            opp.CloseDate = Date.valueOf(value);
        } else if (fieldName == 'leadsource') { 
            acc.AccountSource = value;
            con.LeadSource = value;
            opp.LeadSource = value;
        } else if (fieldName == 'enquiry_source__c') {
            opp.Enquiry_Source__c = value;
        }else if (fieldName == 'enquiry_primary_source__c') {
            opp.Enquiry_Primary_Source__c = value;
        } else if (fieldName == 'secondary_sources__c') {
            opp.Secondary_Sources__c = value;
        }  else {
            opp.put(fieldName, value);
        }
    }
    
    @TestVisible 
    private void mapLeadFields(Lead led, String fieldName, String value) {
        if (fieldName == 'lastname' && String.isBlank(led.Company)) {
            led.Company = value;
        }
        led.put(fieldName, value);
    }
    
    @TestVisible
    private static void sendUserNotification(String userId, String status, String message) {
        System.debug('Notification: ' + status + ' - ' + message);
    }
    
    @TestVisible
    private static void errorMessages(List<Database.SaveResult> srList, List<SObject> originalRecords){
        List<Exception_Log__c> exceptionsList = new List<Exception_Log__c>();
        
        for (Integer i = 0; i < srList.size(); i++) {
            Database.SaveResult sr = srList[i];
            SObject failedRecord = originalRecords[i];
            
            if (sr.isSuccess()) {
                System.debug('Successfully inserted record. Id: ' + sr.getId());
            } else {
                for (Database.Error err : sr.getErrors()) {
                    Exception_Log__c exceptionsRec = new Exception_Log__c();
                    exceptionsRec.Error_Message__c = err.getMessage();
                    exceptionsRec.Error_Stack_Trace__c = String.valueOf(err.getStatusCode());

                    if (failedRecord instanceof Lead) {
                        exceptionsRec.Phone__c = ((Lead)failedRecord).Phone;
                        exceptionsRec.Last_Name__c = ((Lead)failedRecord).LastName;
                        exceptionsRec.Rec_Name__c = ((Lead)failedRecord).FirstName;
                        exceptionsRec.Event_Name__c = ((Lead)failedRecord).Event_Name__c;
                        exceptionsRec.Event_Location__c = ((Lead)failedRecord).Event_Loaction__c;
                    }
                    else if (failedRecord instanceof Contact) {
                        exceptionsRec.Phone__c = ((Contact)failedRecord).Phone;
                        exceptionsRec.Last_Name__c = ((Contact)failedRecord).LastName;
                        exceptionsRec.Rec_Name__c = ((Contact)failedRecord).FirstName;
                    }
                    else if (failedRecord instanceof Follow_Up__c) {
                        exceptionsRec.Phone__c = ((Follow_Up__c)failedRecord).Phone__c;
                        exceptionsRec.Rec_Name__c = ((Follow_Up__c)failedRecord).Name;
                    }
                    else if (failedRecord instanceof Account) {
                        exceptionsRec.Phone__c = ((Account)failedRecord).Phone;
                        exceptionsRec.Rec_Name__c = ((Account)failedRecord).Name;
                    }
                    else if (failedRecord instanceof Opportunity) {
                        exceptionsRec.Phone__c = ((Opportunity)failedRecord).Phone__c;
                        exceptionsRec.Rec_Name__c = ((Opportunity)failedRecord).Name;
                    }
                    else if (failedRecord instanceof Test_Drive__c) {
                        exceptionsRec.Phone__c = ((Test_Drive__c)failedRecord).Phone__c;
                        exceptionsRec.Rec_Name__c = ((Test_Drive__c)failedRecord).Name;
                    }

                    exceptionsList.add(exceptionsRec);
                    
                    System.debug('Error for record with Mobile: ' + exceptionsRec.Response_Body__c + ' => ' + err.getMessage());
                }
            }
        }
        
        if (!exceptionsList.isEmpty()) {
            insert exceptionsList;
        }
    }

}