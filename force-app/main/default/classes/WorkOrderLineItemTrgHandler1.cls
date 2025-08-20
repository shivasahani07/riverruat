/**
* @author Ram Kumar
* @email ram.k@utilitarainlabs.com
* @create 26 june 2025
* @modify 
* @desc
*/

public class WorkOrderLineItemTrgHandler1 {
	
    //Added By Ram 24/06/2025
    public static void PreventUpdateForJobCardStatus(List<WorkOrderLineItem> partsRecords) {
        
        try{
            Set<Id> JobcardIds = new Set<Id>();
            if (partsRecords == null || partsRecords.isEmpty()) {
                return;
            }
            
            for (WorkOrderLineItem prts : partsRecords) {
                if (prts.WorkOrderId != null) {
                    JobcardIds.add(prts.WorkOrderId);
                }
            }
            
            if (JobcardIds.isEmpty()) {
                return;
            }
            
            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
                [SELECT Id, Status FROM WorkOrder WHERE Id IN :JobcardIds AND Status IN :ConstantData.blockedStatuses]
            );
            
            for (WorkOrderLineItem prts : partsRecords) {
                if (prts.WorkOrderId != null && workOrderMap.containsKey(prts.WorkOrderId)) {
                    WorkOrder wrkord = workOrderMap.get(prts.WorkOrderId);
                    if (wrkord.Status != null && ConstantData.blockedStatuses.contains(wrkord.Status)) {
                        prts.addError(
                            'You cannot update or delete Part because the related Job Card status is "' + wrkord.Status
                            //'Please change the status of the Job Card to "new" or "In progress" for any modifications or deletions.'
                        );
                    }
                }
            }
        }catch(Exception e){
            System.debug('Error Message ==> ' + e.getMessage() + ' | Error Line ==> ' + e.getLineNumber());
        }
    }
}