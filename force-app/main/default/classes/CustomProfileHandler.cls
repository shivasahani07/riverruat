public wiThout SHARING class CustomProfileHandler {
    
    public static void shareRecordsWithHierarchy(Map<Id,Batch_Processing__c> insertsMap) {
        try {
            // 1. Get the OwnerIds from all the records
            Map<Id, Id> recordToOwnerMap = new Map<Id, Id>();
            set<id> recordIds = new set<id>();
            
            for (Batch_Processing__c rec : insertsMap.values()){
                recordToOwnerMap.put(rec.Id, rec.OwnerId);
                recordIds.add(rec.Id);
            }
            
            
            // 2. Fetch User records (filter out Queues)
            Set<Id> ownerUserIds = new Set<Id>();
            for (Id ownerId : recordToOwnerMap.values()) {
                if (ownerId.getSObjectType() == User.SObjectType) {
                    ownerUserIds.add(ownerId);
                }
            }
            
            Map<Id, User> usersMap = new Map<Id, User>(
                [SELECT Id, ContactId FROM User WHERE Id IN :ownerUserIds]
            );
            
            // 3. Fetch Contacts related to those users
            Set<Id> contactIds = new Set<Id>();
            for (User u : usersMap.values()) {
                if (u.ContactId != null) {
                    contactIds.add(u.ContactId);
                }
            }
            
            Map<Id, Contact> contactMap = new Map<Id, Contact>(
                [SELECT Id, Designation__c, AccountId FROM Contact WHERE Id IN :contactIds]
            );
            
            // 4. Fetch all related contacts under each account
            Set<Id> accountIds = new Set<Id>();
            for (Contact c : contactMap.values()) {
                if (c.AccountId != null) {
                    accountIds.add(c.AccountId);
                }
            }
            
            Map<Id, List<Contact>> accountToContacts = new Map<Id, List<Contact>>();
            for (Contact related : [
                SELECT Id, User__c, Designation__c, AccountId
                FROM Contact
                WHERE AccountId IN :accountIds AND Designation__c != null
            ]) {
                if (!accountToContacts.containsKey(related.AccountId)) {
                    accountToContacts.put(related.AccountId, new List<Contact>());
                }
                accountToContacts.get(related.AccountId).add(related);
            }
            
            // 5. Prepare shares
            List<Batch_Processing__Share> shares = new List<Batch_Processing__Share>();
            
            for (Id recordId : recordIds) {
                Id ownerId = recordToOwnerMap.get(recordId);
                if (ownerId == null || !usersMap.containsKey(ownerId)) continue;
                
                User ownerUser = usersMap.get(ownerId);
                if (ownerUser.ContactId == null || !contactMap.containsKey(ownerUser.ContactId)) continue;
                
                Contact ownerContact = contactMap.get(ownerUser.ContactId);
                Set<String> hierarchyRoles = getHierarchy(ownerContact.Designation__c);
                
                List<Contact> relatedContacts = accountToContacts.get(ownerContact.AccountId);
                if (relatedContacts == null) continue;
                
                for (Contact contact : relatedContacts) {
                    if (contact.User__c != null && hierarchyRoles.contains(contact.Designation__c)) {
                        Batch_Processing__Share share = new Batch_Processing__Share();
                        share.ParentId = recordId;
                        share.UserOrGroupId = contact.User__c;
                        share.AccessLevel = 'Read';
                        share.RowCause = Schema.Batch_Processing__Share.RowCause.Manual;
                        shares.add(share);
                    }
                }
            }
            
            // 6. Insert all shares at once
            if (!shares.isEmpty()) {
                try {
                    insert shares;
                    System.debug('Inserted ' + shares.size() + ' share records.');
                } catch (DmlException dmlEx) {
                    System.debug('DML Exception: ' + dmlEx.getMessage());
                    for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
                        System.debug('Share Failed: ' + dmlEx.getDmlMessage(i));
                    }
                }
            } else {
                System.debug('No eligible share records to insert.');
            }
            
        } catch (Exception ex) {
            System.debug('Unexpected exception: ' + ex.getMessage());
            System.debug('Line: ' + ex.getLineNumber());
        }
    }
    
    private static Set<String> getHierarchy(String designation) {
        
        // Ideally pull from Custom Metadata or define statically
        // Ideally pull from Custom Metadata or define statically
        Map<String, Set<String>> hierarchyMap = new Map<String, Set<String>>{
            'WM' => new Set<String>{'Service Centre'},
                'SM' => new Set<String>{'WM', 'Service Centre'},
                    'PS' => new Set<String>{'SM', 'WM', 'Service Centre'},
                        'SA' => new Set<String>{'PS', 'SM', 'WM', 'Service Centre'},
                            'CRE' => new Set<String>{'PS', 'SM', 'WM','SA','ASM' ,'Service Centre'}
        };
            return hierarchyMap.containsKey(designation) ? hierarchyMap.get(designation) : new Set<String>();
    }
    
    
    
    Public Static  void createAccountWithGrop(List<Account> PartnerAcc){
        Account SignleAccount=PartnerAcc[0];
        
        //'store-001F400002SOh0yIAD'
        
    }
    
    //Service Centre ->WM,
    //WM ->PS,PS
    
    
    
    
}