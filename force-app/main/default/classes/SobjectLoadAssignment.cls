/**
* @File Name : SobjectLoadAssignment.cls
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

public class SobjectLoadAssignment {
    Public Static Map<String,Id> rv_MapOfQueueNameByQueueID = new Map<String,Id>();
    Public Static Map<Id,List<Assignment_Group_Member__c>> rv_MapOfAGIDByASMList = new Map<Id,List<Assignment_Group_Member__c>>();
    Public Static Map<Id,Assignment_Group_Member__c> rv_MapOfAGMIDByAGM = new Map<Id,Assignment_Group_Member__c>();
    Public Static Map<Id,Assignment_Group__c> rv_MapOfAGIdByAG = new Map<Id,Assignment_Group__c>();
    Public Static Map<Id,Map<Integer,Id>> rv_MapofAGIdByAGMRRIDByAGMId = new Map<Id,Map<Integer,Id>>();
    
    Public Static void ExecuteLoadAssignment(Integer limitSize){
        try{
            rv_MapOfQueueNameByQueueID = SobjectLoadAssignmentUtility.GetQueuesNameAndId();
            System.debug('rv_MapOfQueueNameByQueueID ========>' + rv_MapOfQueueNameByQueueID);
            rv_MapOfAGIdByAG = SobjectLoadAssignmentUtility.GetassigmentGroup();
            System.debug('rv_MapOfAGIdByAG ========>' + rv_MapOfAGIdByAG);
            for(Assignment_Group__c rv_AGRec : rv_MapOfAGIdByAG.values()){
                System.debug('rv_AGRec.Execution_SOQL__c ========>' + rv_AGRec.Execution_SOQL__c);
                if(rv_AGRec.Execution_SOQL__c != null){
                    rv_AGRec.Execution_SOQL__c += ' LIMIT ' + 5000;
                    System.debug('rv_AGRec.Execution_SOQL__c ========>' + rv_AGRec.Execution_SOQL__c);
                    System.debug('rv_AGRec.Id ========>' + rv_AGRec.Id);
                    System.debug('rv_MapOfQueueNameByQueueID.get(rv_AGRec.Round_Robin_Queue_Name__c) ========>' + rv_MapOfQueueNameByQueueID.get(rv_AGRec.Round_Robin_Queue_Name__c));
                    ExecuteSobjectAssignment(rv_AGRec.Execution_SOQL__c,rv_AGRec.Id,rv_MapOfQueueNameByQueueID.get(rv_AGRec.Round_Robin_Queue_Name__c));
                }
            }
        }catch (Exception e) {
            System.debug('Error Message =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
        
    }
    
    @future
    Public static void ExecuteSobjectAssignment(String databaseQuery,String GroupId,Id queueId){
        try{
            system.debug('databaseQuery==='+databaseQuery);
            system.debug('GroupId==='+GroupId);
            system.debug('queueId==='+queueId);
            List<sObject> rv_SobjectRecDetails = Database.query(databaseQuery);
            SobjectLoadAssignmentHelper.ExecuteSobjectOwnerAssignment(rv_SobjectRecDetails, GroupId, queueId);
        }catch (Exception e) {
            System.debug('Error Message =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
        
        
    }
}