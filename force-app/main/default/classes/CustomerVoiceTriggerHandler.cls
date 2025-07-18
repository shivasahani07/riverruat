/**
* @author Ram Kumar
* @email ram.k@utilitarainlabs.com
* @create 26 june 2025
* @modify 
* @desc
*/
public class CustomerVoiceTriggerHandler {

    //Added By Ram 24/06/2025
    public static void PreventUpdateForJobCardStatus(List<RR_Customer_Voice__c> customerVoiceRecords) {
        
        try{
            Set<Id> JobcardIds = new Set<Id>();
            if (customerVoiceRecords == null || customerVoiceRecords.isEmpty()) {
                return;
            }
            for (RR_Customer_Voice__c ctv : customerVoiceRecords) {
                if (ctv.RR_Work_Order__c != null) {
                    JobcardIds.add(ctv.RR_Work_Order__c);
                }
            }
            if (JobcardIds.isEmpty()) {
                return;
            }
            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
                [SELECT Id, Status FROM WorkOrder WHERE Id IN :JobcardIds AND Status IN :ConstantData.blockedStatuses]
            );            
            for (RR_Customer_Voice__c ctv : customerVoiceRecords) {
                if (ctv.RR_Work_Order__c != null && workOrderMap.containsKey(ctv.RR_Work_Order__c)) {
                    WorkOrder wrkord = workOrderMap.get(ctv.RR_Work_Order__c);
                    if (wrkord.Status != null && ConstantData.blockedStatuses.contains(wrkord.Status)) {
                        ctv.addError(
                            'You cannot update or delete Customer Voice because the related Job Card status is "' + wrkord.Status + '". ' +
                            'Please change the status of the Job Card to new or In progress for any modifications or deletions.'
                        );
                    }
                }
            }
        }catch(Exception e){
            System.debug('Error Message ==> ' + e.getMessage() + ' | Error Line ==> ' + e.getLineNumber());
        }
    }
}