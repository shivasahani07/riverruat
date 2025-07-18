/**
* @File Name : SobjectLoadAssignmentUtility.cls
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

public class SobjectLoadAssignmentUtility {
    Public static  Map<String,Id> GetQueuesNameAndId(){
        Map<String,Id> mapofQueuenameAndId = new Map<String,Id>();
        try{
            List<Assignment_Group__c> grouplist = [Select id , Round_Robin_Queue_Name__c From Assignment_Group__c];
            set<string> queueName = new  set<string>();
            
            for(Assignment_Group__c assignGroupRec : grouplist){
                if (assignGroupRec.Round_Robin_Queue_Name__c != null) {
                    System.debug('queueName ========>' + queueName);
                    // mapofgroupNameId.put(assignGroupRec.Round_Robin_Queue_Name__c, assignGroupRec.Id);
                    queueName.add(assignGroupRec.Round_Robin_Queue_Name__c);
                    System.debug('queueName ========>' + queueName);
                }
                list<Group> queueList = [Select id,Name From Group WHERE Type = 'Queue' AND Name IN:queueName];
                System.debug('queueList ========>' + queueList);
                
                for(Group queueRec :queueList ){
                    mapofQueuenameAndId.put(queueRec.Name, queueRec.Id);
                    System.debug('mapofQueuenameAndId ========>' + mapofQueuenameAndId);
                }
            }
            
            System.debug('mapofQueuenameAndId ========>' + mapofQueuenameAndId);
            
            
            
        }catch (Exception e) {
            System.debug('Error Message =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
        return mapofQueuenameAndId;
    }
    
    Public static  Map<id,Assignment_Group__c> GetassigmentGroup(){
        Map<id,Assignment_Group__c> mapofIdandAssingmentGroup = new Map<id,Assignment_Group__c>();
        
        try{
            list<Assignment_Group__c> assigmentgroupList = [SELECT
                                                            //  Case_Assigning_Criteria__c,Case_Stage__c
                                                            Case_Stage_Exceed_Count__c,Case_to_Assign_in_Single_Transaction__c,
                                                            CreatedDate,Execution_SOQL__c,Id,isActive__c,Last_Allocated_RRid__c,Max_Sobject_Assignment_Count__c,Name,OwnerId,Round_Robin_Queue_Name__c FROM Assignment_Group__c Where isActive__c = True];
            
            if(!assigmentgroupList.IsEmpty()){
                for(Assignment_Group__c assignGroup : assigmentgroupList){
                    if (assignGroup.id != null) {
                        mapofIdandAssingmentGroup.put(assignGroup.id, assignGroup);
                    }
                }
            }
            System.debug('mapofIdandAssingmentGroup ========>' + mapofIdandAssingmentGroup);
        }catch (Exception e) {
            System.debug('Error Message =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
        return mapofIdandAssingmentGroup;
    }

}