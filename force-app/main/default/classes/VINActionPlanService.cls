public with sharing class VINActionPlanService {
    @InvocableMethod(label='Create Action Plans from VINs')
    public static void createActionPlans(List<RequestWrapper> requests) {
        for (RequestWrapper request : requests) {
            if (String.isBlank(request.vinCSV) || String.isBlank(request.fieldFixId)) continue;

            List<String> vinList = new List<String>();
            for (String v : request.vinCSV.split('[\\n,]+')) {
                if (!String.isBlank(v.trim())) {
                    vinList.add(v.trim());
                }
            }

            Field_Fix__c ff = [SELECT Id, Action_Plan_Template__c FROM Field_Fix__c WHERE Id = :request.fieldFixId LIMIT 1];
              /*  
			for (String vin : vinList) {
                ActionPlan ap = new ActionPlan();
                ap.Name = 'VIN: ' + vin;
                //ap.VIN__c = vin;
                ap.Field_Fix__c = ff.Id;
                ap.Action_Plan_Template__c = ff.Action_Plan_Template__c;
                ap.StartDate = Date.Today();
                ap.ActionPlanState = 'Not Started';
                actionPlansToInsert.add(ap);
            }*/
        }
    }

    public class RequestWrapper {
        @InvocableVariable(required=true) public String vinCSV;
        @InvocableVariable(required=true) public String fieldFixId;
    }
}