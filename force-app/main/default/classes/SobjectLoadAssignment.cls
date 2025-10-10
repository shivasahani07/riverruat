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

    public static Map<String, Id> rv_MapOfQueueNameByQueueID = new Map<String, Id>();
    public static Map<Id, List<Assignment_Group_Member__c>> rv_MapOfAGIDByASMList = new Map<Id, List<Assignment_Group_Member__c>>();
    public static Map<Id, Assignment_Group_Member__c> rv_MapOfAGMIDByAGM = new Map<Id, Assignment_Group_Member__c>();
    public static Map<Id, Assignment_Group__c> rv_MapOfAGIdByAG = new Map<Id, Assignment_Group__c>();
    public static Map<Id, Map<Integer, Id>> rv_MapofAGIdByAGMRRIDByAGMId = new Map<Id, Map<Integer, Id>>();

    public static void ExecuteLoadAssignment(Integer limitSize) {
        try {
            rv_MapOfQueueNameByQueueID = SobjectLoadAssignmentUtility.GetQueuesNameAndId();
            System.debug('rv_MapOfQueueNameByQueueID ========>' + rv_MapOfQueueNameByQueueID);

            rv_MapOfAGIdByAG = SobjectLoadAssignmentUtility.GetassigmentGroup();
            System.debug('rv_MapOfAGIdByAG ========>' + rv_MapOfAGIdByAG);
            System.debug('r111 ========>' + rv_MapOfAGIdByAG.values());

            for (Assignment_Group__c rv_AGRec : rv_MapOfAGIdByAG.values()) {
                if (rv_AGRec.Execution_SOQL__c != null) {
                    rv_AGRec.Execution_SOQL__c += ' LIMIT ' + limitSize;

                    Id queueId = rv_MapOfQueueNameByQueueID.get(rv_AGRec.Round_Robin_Queue_Name__c);

                    System.enqueueJob(new SobjectAssignmentQueueable(
                        rv_AGRec.Execution_SOQL__c,
                        String.valueOf(rv_AGRec.Id),
                        queueId
                    ));
                }
            }
        } catch (Exception e) {
            System.debug('Error Message =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
    }

    public class SobjectAssignmentQueueable implements Queueable, Database.AllowsCallouts {
        private String databaseQuery;
        private String groupId;
        private Id queueId;

        public SobjectAssignmentQueueable(String databaseQuery, String groupId, Id queueId) {
            this.databaseQuery = databaseQuery;
            this.groupId = groupId;
            this.queueId = queueId;
        }

        public void execute(QueueableContext context) {
            try {
                List<sObject> rv_SobjectRecDetails = Database.query(databaseQuery);

                if (!rv_SobjectRecDetails.isEmpty()) {
                    SobjectLoadAssignmentHelper.ExecuteSobjectOwnerAssignment(rv_SobjectRecDetails,groupId,queueId);
                }
            } catch (Exception e) {
                System.debug('Error Message =======> ' + e.getMessage() + 
                             ' at line number =======> ' + e.getLineNumber());
            }
        }
    }
}