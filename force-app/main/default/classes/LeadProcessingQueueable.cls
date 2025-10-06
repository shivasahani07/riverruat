public class LeadProcessingQueueable implements Queueable, Database.AllowsCallouts {

    @testVisible private List<Id> leadIds;
    @testVisible private Id currentUserId;
    
    public LeadProcessingQueueable(List<Id> leadIds, Id currentUserId) {
        this.leadIds = leadIds;
        this.currentUserId = currentUserId;
    }
    
    public void execute(QueueableContext context) {
        try {
            Map<Id, Lead> newLeadsMap = new Map<Id, Lead>([
                SELECT Id, PostalCode, OwnerId, Dealer_Allocation__c 
                FROM Lead 
                WHERE Id IN :leadIds
            ]);
            
            Map<String, Id> queueMap = new Map<String, Id>();
            for (Group grp : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']) {
                queueMap.put(grp.DeveloperName, grp.Id);
            }
            
            Map<String, String> mapOfPincodeAndCenterName = new Map<String, String>();
            Map<String, String> mapOfPincodeAndDealerCode = new Map<String, String>();
            Map<String, String> mapOfPincodeAndCityName = new Map<String, String>();
            Map<String, String> mapOfDealerCodeAndCityName = new Map<String, String>();
            Map<String, String> mapOfPincodeToLanguages = new Map<String, String>();
            
            for (Pin_Code__c pincode : [
                SELECT Area_Pincode__c,Languages__c,
                    Dealer_Service_Center__r.Store_Name__c,
                    Dealer_Service_Center__r.Center_Code__c,
                    City__r.Name
                FROM Pin_Code__c
            ]) {
                mapOfPincodeAndCenterName.put(pincode.Area_Pincode__c, pincode.Dealer_Service_Center__r.Store_Name__c);
                mapOfPincodeAndDealerCode.put(pincode.Area_Pincode__c, pincode.Dealer_Service_Center__r.Center_Code__c);
                mapOfPincodeAndCityName.put(pincode.Area_Pincode__c, pincode.City__r.Name);
                mapOfDealerCodeAndCityName.put(pincode.Dealer_Service_Center__r.Center_Code__c, pincode.City__r.Name);
                mapOfPincodeToLanguages.put(pincode.Area_Pincode__c, pincode.Languages__c);
            }
            
            User currentUser = [
                SELECT Id, Profile.Name, Contact.Account.Center_Code__c, 
                       Contact.Account.Store_Name__c, Contact.Account.BillingPostalCode
                FROM User 
                WHERE Id = :currentUserId
            ];
            
            List<User> adminUsers = [
                SELECT Id 
                FROM User 
                WHERE Profile.Name = 'System Administrator' 
                AND Name = 'Binesh Nair' 
                LIMIT 1
            ];
            Id adminUserId = adminUsers.isEmpty() ? null : adminUsers[0].Id;
            
            List<Assignment_Group__c> assignmentGroups = [
                SELECT Id, Last_Allocated_RRid__c, 
                       Business_Hours_Morning__c, Business_Hours_End_Time__c 
                FROM Assignment_Group__c 
                WHERE isActive__c = true 
                AND Name = 'Business Hours' 
                LIMIT 1 
                FOR UPDATE
            ];
            
            Assignment_Group__c assignmentGroup = assignmentGroups.isEmpty() ? null : assignmentGroups[0];
            Time businessHoursStart = assignmentGroup?.Business_Hours_Morning__c != null ? assignmentGroup.Business_Hours_Morning__c : Time.newInstance(8, 0, 0, 0);
            Time businessHoursEnd = assignmentGroup?.Business_Hours_End_Time__c != null ? assignmentGroup.Business_Hours_End_Time__c : Time.newInstance(20, 0, 0, 0);
            
            List<Assignment_Group_Member__c> groupMembers = new List<Assignment_Group_Member__c>();
            if (assignmentGroup != null) {
                groupMembers = [
                    SELECT Id, Group_Member__c, Assignment_Id__c, Known_languages__c
                    FROM Assignment_Group_Member__c 
                    WHERE Assignment_Group__c = :assignmentGroup.Id 
                    AND Active__c = true 
                    ORDER BY Assignment_Id__c ASC
                ];
            }
            
            Decimal lastIndex = assignmentGroup?.Last_Allocated_RRid__c;
            Integer nextIndex = lastIndex != null ? lastIndex.intValue() : 0;
            Integer memberCount = groupMembers.size();
            
            List<Lead> notServiceableLeads = new List<Lead>();
            List<Lead> outOfHoursLeads = new List<Lead>();
            List<Lead> dmsLeads = new List<Lead>();
            List<Lead> roundRobinLeads = new List<Lead>();
            
            Time currentTime = System.now().time();
            Boolean isBusinessHours = currentTime >= businessHoursStart && currentTime <= businessHoursEnd;
            
            for (Lead ld : newLeadsMap.values()) {
                String postalCode = ld.PostalCode;
                Boolean isServiceable = postalCode != null && mapOfPincodeAndCenterName.containsKey(postalCode);
                Boolean isPartnerUser = currentUser.Profile.Name == 'Sales Manager (Partner)';
                
                if (!isServiceable) {
                    notServiceableLeads.add(new Lead(
                        Id = ld.Id,
                        Future_Lead__c = true,
                        Status = 'New',
                        Stores_Name__c = 'Out Of Coverage',
                        PostalCode = postalCode,
                        OwnerId = queueMap.get('Head_Quarter')
                    ));
                    continue;
                }
                if (isPartnerUser && ld.Home_Test_Ride__c == true) {
                    dmsLeads.add(new Lead(
                        Id = ld.Id,
                        OwnerId = currentUser.Id,
                        Dealer_Code__c = currentUser.Contact?.Account?.Center_Code__c,
                        Stores_Name__c = currentUser.Contact?.Account?.Store_Name__c,
                        City = mapOfDealerCodeAndCityName.get(currentUser.Contact?.Account?.Center_Code__c),
                        PostalCode = currentUser.Contact?.Account?.BillingPostalCode
                    ));
                    continue; 
                }
                if (isBusinessHours) {
                    if (memberCount > 0) {
                        String languagesForPincode = mapOfPincodeToLanguages.get(postalCode);
                        Set<String> requiredLanguages = new Set<String>();
                        if (languagesForPincode != null) {
                            requiredLanguages.addAll(languagesForPincode.split(';'));
                        }
                        
                        Integer startIndex = nextIndex;
                        Assignment_Group_Member__c selectedMember = null;
                        boolean found = false;
                        
                        do {
                            Assignment_Group_Member__c candidate = groupMembers[nextIndex];
                            
                            if (requiredLanguages.isEmpty()) {
                                selectedMember = candidate;
                                found = true;
                            } 
                            else if (candidate.Known_languages__c != null) {
                                Set<String> knownLanguages = new Set<String>(candidate.Known_languages__c.split(';'));
                                for (String lang : requiredLanguages) {
                                    if (knownLanguages.contains(lang)) {
                                        selectedMember = candidate;
                                        found = true;
                                        break;
                                    }
                                }
                            }
                            
                            if (found) {
                                roundRobinLeads.add(new Lead(
                                    Id = ld.Id,
                                    OwnerId = selectedMember.Group_Member__c,
                                    Status = 'Follow Up',
                                    Dealer_Code__c = mapOfPincodeAndDealerCode.get(postalCode),
                                    Stores_Name__c = mapOfPincodeAndCenterName.get(postalCode),
                                    City = mapOfPincodeAndCityName.get(postalCode),
                                    PostalCode = postalCode
                                ));
                                
                                nextIndex++;
                                if (nextIndex >= memberCount) {
                                    nextIndex = 0;
                                }
                                
                                break;
                            }
                            
                            nextIndex++;
                            if (nextIndex >= memberCount) {
                                nextIndex = 0;
                            }
                            
                        } while (nextIndex != startIndex);
                        
                        if (!found) {
                            outOfHoursLeads.add(new Lead(
                                Id = ld.Id,
                                Status = 'New',
                                OwnerId = queueMap.get('Out_of_Business_Hours') != null ? queueMap.get('Out_of_Business_Hours') : adminUserId,
                                Dealer_Code__c = mapOfPincodeAndDealerCode.get(postalCode),
                                Stores_Name__c = mapOfPincodeAndCenterName.get(postalCode),
                                City = mapOfPincodeAndCityName.get(postalCode),
                                PostalCode = postalCode
                            ));
                        }
                    } else {
                        outOfHoursLeads.add(new Lead(
                            Id = ld.Id,
                            Status = 'New',
                            OwnerId = queueMap.get('Out_of_Business_Hours') != null ? queueMap.get('Out_of_Business_Hours') : adminUserId,
                            Dealer_Code__c = mapOfPincodeAndDealerCode.get(postalCode),
                            Stores_Name__c = mapOfPincodeAndCenterName.get(postalCode),
                            City = mapOfPincodeAndCityName.get(postalCode),
                            PostalCode = postalCode
                        ));
                    }
                }
                else {
                    outOfHoursLeads.add(new Lead(
                        Id = ld.Id,
                        Status = 'New',
                        OwnerId = queueMap.get('Out_of_Business_Hours') != null ? queueMap.get('Out_of_Business_Hours') : adminUserId,
                        Dealer_Code__c = mapOfPincodeAndDealerCode.get(postalCode),
                        Stores_Name__c = mapOfPincodeAndCenterName.get(postalCode),
                        City = mapOfPincodeAndCityName.get(postalCode),
                        PostalCode = postalCode
                    ));
                }
            }
            
            if (memberCount > 0 && assignmentGroup != null && nextIndex != lastIndex) {
                assignmentGroup.Last_Allocated_RRid__c = nextIndex;
                update assignmentGroup;
            }
            
            List<Lead> allUpdates = new List<Lead>();
            List<Lead> allUpdatesForLeads = new List<Lead>();
            allUpdates.addAll(notServiceableLeads);
            allUpdates.addAll(outOfHoursLeads);
            allUpdates.addAll(dmsLeads);
            allUpdatesForLeads.addAll(roundRobinLeads);
            
            if (!allUpdates.isEmpty()) {
                update allUpdates;
            }

            if(!allUpdatesForLeads.isEmpty()){
                update allUpdatesForLeads;
                LeadTriggerHandler.createTaskUnderLeadIfLeadIsNotConverted(allUpdatesForLeads);
            }
            
            if (!dmsLeads.isEmpty()) {
                Map<Id, Lead> dmsLeadMap = new Map<Id, Lead>(dmsLeads);
                LeadTriggerHandler.handleLeadConversion(JSON.serialize(dmsLeadMap));
            }
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }
    }
}