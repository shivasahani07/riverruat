/**
* @File Name : ActionPlanCheckerController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 30, 2025 |   | Initial Version
**/

public class ActionPlanCheckerController {
    @AuraEnabled(cacheable=true)
    public static List<ActionPlan> getActionPlansForJobCard(Id jobCardId) {
        List<ActionPlan> actionPlans = new List<ActionPlan>();
        try {
            System.debug('Fetching Action Plans for Job Card Id: ' + jobCardId);
            actionPlans = [
                SELECT Id, Name,To_be_Completed_in_JC__c,ActionPlanTemplateVersion.Name
                FROM ActionPlan
                WHERE Job_Card__c = :jobCardId
				AND To_be_Completed_in_JC__c = false
            ];
            System.debug('Retrieved Action Plans: ' + actionPlans);
        } catch (Exception e) {
            System.debug('Error in getActionPlansForJobCard: ' + e.getMessage());
        }
        return actionPlans;
    }
}