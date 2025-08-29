public without sharing class GenericRecordSharer {
    
    public static void shareRecordsWithHierarchy(Map<Id, SObject> insertsMap,String objectApiName,String accessLevel,String rowCause) {
        try {
            // 1. Get owner map
            Map<Id, Id> recordToOwnerMap = new Map<Id, Id>();
            Set<Id> recordIds = new Set<Id>();
            
            for (SObject rec : insertsMap.values()) {
                recordToOwnerMap.put((Id)rec.get('Id'), (Id)rec.get('OwnerId'));
                recordIds.add((Id)rec.get('Id'));
            }
            
            // 2. Filter only user owners
            Set<Id> ownerUserIds = new Set<Id>();
            for (Id ownerId : recordToOwnerMap.values()) {
                if (ownerId.getSObjectType() == User.SObjectType) {
                    ownerUserIds.add(ownerId);
                }
            }
            
            Map<Id, User> usersMap = new Map<Id, User>(
                [SELECT Id, ContactId FROM User WHERE Id IN :ownerUserIds]
            );
            
            system.debug('usersMap---:' +usersMap);
            // 3. Contacts of these users
            Set<Id> contactIds = new Set<Id>();
            for (User u : usersMap.values()) {
                if (u.ContactId != null) contactIds.add(u.ContactId);
            }
            
            Map<Id, Contact> contactMap = new Map<Id, Contact>(
                [SELECT Id, Designation__c, AccountId, Role_Type__c FROM Contact WHERE Id IN :contactIds]
            );
            
            system.debug('contactMap---:' +contactMap);
            // 4. Related contacts
            Set<Id> accountIds = new Set<Id>();
            for (Contact c : contactMap.values()) {
                if (c.AccountId != null) accountIds.add(c.AccountId);
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
            
            system.debug('accountToContacts---:' +accountToContacts);
            // 5. Prepare shares dynamically
            String shareObjectName ='';
            if (objectApiName.endsWith('__c')) {
                shareObjectName = objectApiName.removeEnd('__c') + '__Share';
            } else {
                shareObjectName = objectApiName + 'Share';
            }
            
            system.debug('shareObjectName---:' +shareObjectName);
            // === Check Share Object Existence ===
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (!gd.containsKey(shareObjectName)) {
                System.debug('No share object exists for ' + objectApiName + '. Sharing logic will not execute.');
                return;
            }
            Schema.SObjectType shareType = gd.get(shareObjectName);
            List<SObject> shares = new List<SObject>();
            for (Id recordId : recordIds) {
                Id ownerId = recordToOwnerMap.get(recordId);
                if (!usersMap.containsKey(ownerId)) continue;
                
                User ownerUser = usersMap.get(ownerId);
                if (!contactMap.containsKey(ownerUser.ContactId)) continue;
                
                Contact ownerContact = contactMap.get(ownerUser.ContactId);
                Set<String> hierarchyRoles = getHierarchy(ownerContact.Designation__c, ownerContact.Role_Type__c);
                
                List<Contact> relatedContacts = accountToContacts.get(ownerContact.AccountId);
                if (relatedContacts == null) continue;
                
                for (Contact contact : relatedContacts) {
                    if (contact.User__c != null && hierarchyRoles.contains(contact.Designation__c)) {
                        SObject shareRecord = shareType.newSObject();
                        if(objectApiName=='lead'){
                            shareRecord.put('LeadId', recordId);
                            shareRecord.put('LeadAccessLevel', accessLevel);
                            
                        }
                        else if(objectApiName=='Contact'){
                            shareRecord.put('ContactId', recordId);
                            shareRecord.put('ContactAccessLevel', accessLevel);
                            
                        }
                        else if(objectApiName=='Account'){
                            shareRecord.put('AccountId', recordId);
                            shareRecord.put('AccountAccessLevel', accessLevel);
                            
                        }
                        else if(objectApiName=='Order'){
                            shareRecord.put('OrderId', recordId);
                            shareRecord.put('OrderAccessLevel', accessLevel);
                            
                        }
                        else if(objectApiName=='Asset'){
                            shareRecord.put('AssetId', recordId);
                            shareRecord.put('AssetAccessLevel', accessLevel);
                            
                        }
                        else if(objectApiName=='Case'){
                            shareRecord.put('CaseId', recordId);
                            shareRecord.put('CaseAccessLevel', accessLevel);
                            
                        }
                        else if(objectApiName=='Opportunity'){
                            shareRecord.put('OpportunityId', recordId);
                            shareRecord.put('OpportunityAccessLevel', accessLevel);
                            
                        }
                        else{
                            shareRecord.put('ParentId', recordId);
                            shareRecord.put('AccessLevel', accessLevel);
                        }
                        shareRecord.put('UserOrGroupId', contact.User__c);
                        
                        if (String.isNotBlank(rowCause)) {
                            shareRecord.put('RowCause', rowCause);
                        }
                        shares.add(shareRecord);
                    }
                }
            }
            
            // 6. Insert shares
            if (!shares.isEmpty()) {
                try {
                    insert shares;
                    System.debug('Share---'+shares);
                    System.debug('Inserted ' + shares.size() + ' share records.');
                } catch (DmlException ex) {
                    System.debug('DML Exception while inserting shares: ' + ex.getMessage()); 
                    System.debug('Line Number: ' + ex.getLineNumber());
                }
            }
            
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            System.debug('Error: ' + ex.getLineNumber());
        }
    }
    
    private static Set<String> getHierarchy(String designation, String roleType) {
        Set<String> hierarchySet = new Set<String>();
        
        try {
            if (String.isBlank(roleType)) {
                System.debug('Role Type is blank.');
                return hierarchySet;
            }
            
            if (String.isBlank(designation)) {
                System.debug('Designation is blank.');
                return hierarchySet;
            }
            
            // Handle 'Service' role type
            if (roleType.equalsIgnoreCase('Service')) {
                Map<String, Service_Roles_Hirarchy__mdt> metadataMap = new Map<String, Service_Roles_Hirarchy__mdt>();
                for (Service_Roles_Hirarchy__mdt mdt : [SELECT DeveloperName, Eg_Value__c, Label FROM Service_Roles_Hirarchy__mdt]) {
                    metadataMap.put(mdt.Label, mdt);
                }
                System.debug('metadataMap ---'+ metadataMap);
                if (metadataMap.containsKey(designation)) {
                    for (String val : metadataMap.get(designation).Eg_Value__c.split(',')) {
                        hierarchySet.add(val.trim());
                    }
                }
            }
            // Handle 'Sales' role type
            else if (roleType.equalsIgnoreCase('Sales')) {
                Map<String, Sales_Role_Hirarchy__mdt> metadataMap = new Map<String, Sales_Role_Hirarchy__mdt>();
                for (Sales_Role_Hirarchy__mdt mdt : [SELECT DeveloperName, Label, Eg_Value__c FROM Sales_Role_Hirarchy__mdt]) {
                    metadataMap.put(mdt.Label, mdt);
                }
                System.debug('metadataMap ---'+ metadataMap);
                if (metadataMap.containsKey(designation)) {
                    for (String val : metadataMap.get(designation).Eg_Value__c.split(',')) {
                        hierarchySet.add(val.trim());
                    }
                }
            } else {
                System.debug('Unsupported role type: ' + roleType);
            }
            
            System.debug('hierarchySet---: ' + hierarchySet);
            return hierarchySet;
            
        } catch(Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            System.debug('Error: ' + ex.getLineNumber());
            return null;
        }
    }
}