/**
* @File Name : SobjectLoadAssignmentHelper.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 12, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 12, 2025 |   | Initial Version
**/

public class SobjectLoadAssignmentHelper {
    Public Static Map<Id,Assignment_Group__c> rv_MapOfAGIdByAG = new Map<Id,Assignment_Group__c>();
    Public Static Map<Id,List<Assignment_Group_Member__c>> rv_MapOfAGIDByASMList = new Map<Id,List<Assignment_Group_Member__c>>();
    
    public static void ExecuteSobjectOwnerAssignment(List<Sobject> sObjectList, String GroupId, Id queueId) {
        system.debug('sObjectList=========>' + sObjectList);
        system.debug('GroupId=========>' + GroupId);
        system.debug('queueId=========>' + queueId);
        try{
            Integer lastAllocatedId = 0;
            rv_MapOfAGIdByAG = SobjectLoadAssignmentUtility.GetassigmentGroup();
            
            List<Assignment_Group_Member__c> rv_AssignmentGroupMember = [SELECT Id, Assignment_Group__c, Active__c, Last_Allocated_RRID__c, 
                                                                         Max_Case_Per_Day__c, Out_Of_Office__c, Group_Member__c, 
                                                                         Max_Sobject_Assignment_Count__c, Assignment_Id__c
                                                                         FROM Assignment_Group_Member__c 
                                                                         WHERE Assignment_Group__r.isActive__c = true 
                                                                         AND Active__c = true 
                                                                         AND Assignment_Group__c = :GroupId];
            
            Map<Decimal, Id> mapofUserRRIDByUserId = new Map<Decimal, Id>();
            Map<Decimal, Id> mapofAvailableUserRRIDByUserId = new Map<Decimal, Id>();
            Map<Id, Integer> userAssignedCount = new Map<Id, Integer>();
            
            for (Assignment_Group_Member__c agmRec : rv_AssignmentGroupMember) {
                mapofUserRRIDByUserId.put(agmRec.Assignment_Id__c, agmRec.Group_Member__c);
                if (!agmRec.Out_Of_Office__c) {
                    mapofAvailableUserRRIDByUserId.put(agmRec.Assignment_Id__c, agmRec.Group_Member__c);
                    userAssignedCount.put(agmRec.Group_Member__c, 0);
                }
            }
            
            // Get today's assigned leads count for each user
            Map<Id, Integer> assignedLeadsToday = new Map<Id, Integer>();
            List<AggregateResult> assignedCounts = [SELECT OwnerId, COUNT(Id) recordCount 
                                                    FROM Lead 
                                                    WHERE OwnerId IN :userAssignedCount.keySet() 
                                                    AND CreatedDate = TODAY 
                                                    GROUP BY OwnerId];
            for (AggregateResult ar : assignedCounts) {
                assignedLeadsToday.put((Id) ar.get('OwnerId'), (Integer) ar.get('recordCount'));
            }
            
            if (rv_AssignmentGroupMember.size() == rv_MapOfAGIdByAG.get(GroupId).Last_Allocated_RRid__c) {
                lastAllocatedId = 1;
            } else {
                lastAllocatedId = (Integer) rv_MapOfAGIdByAG.get(GroupId).Last_Allocated_RRid__c + 1;
            }
            
            Boolean isUserAssigned;
            for (Sobject objectRec : sObjectList) {
                String sObjectType = String.valueOf(objectRec.getSObjectType());
                isUserAssigned = true;
                if (!mapofAvailableUserRRIDByUserId.isEmpty()) {
                    while (isUserAssigned) {
                        if (mapofAvailableUserRRIDByUserId.containsKey(lastAllocatedId)) {
                            Id userId = mapofAvailableUserRRIDByUserId.get(lastAllocatedId);
                            Integer assignedCount = assignedLeadsToday.containsKey(userId) ? assignedLeadsToday.get(userId) : 0;
                            decimal maxCases = 0;
                            
                            for (Assignment_Group_Member__c agm : rv_AssignmentGroupMember) {
                                if (agm.Group_Member__c == userId) {
                                    system.debug('1=========>');
                                    maxCases = agm.Max_Case_Per_Day__c;
                                    break;
                                }
                            }
                            
                            if (assignedCount < maxCases) {
                                system.debug('2=========>');
                                objectRec.put('OwnerId', userId);
                                system.debug('userId=========>' + userId);

                                if (sObjectType == 'Opportunity'){
                                    objectRec.put('StageName', 'Test Ride Scheduled');
                                }
                                objectRec.put('Is_Assigned_to_User__c', true);
                                objectRec.put('AG_Related_to__c', GroupId);
                                system.debug('AG_Related_to__c=========>' + GroupId);
                                objectRec.put('Sobject_Load_Balancing_Executed__c', true);
                                objectRec.put('Assigned_Date__c', system.today());
                                assignedLeadsToday.put(userId, assignedCount + 1);
                                isUserAssigned = false;
                            }
                        }
                        if (rv_AssignmentGroupMember.size() == lastAllocatedId) {
                            lastAllocatedId = 1;
                        } else {
                            lastAllocatedId = lastAllocatedId + 1;
                        }
                    }
                }
            }
            
            Assignment_Group__c ov_AGTobeUpdated = new Assignment_Group__c();
            ov_AGTobeUpdated.Id = GroupId;
            ov_AGTobeUpdated.Last_Allocated_RRid__c = lastAllocatedId - 1;
            update ov_AGTobeUpdated;
            update sObjectList;
        }catch (Exception e) {
            System.debug('Error Message =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
    }
    
}