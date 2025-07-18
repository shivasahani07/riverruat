public class VORTriggerHelper {
    
    public static void VORReasonDurationUpdate(List<VOR__c> newVORList,Map<Id,VOR__c> MapVORList){
        try{
            DateTime now = System.now();
            for (VOR__c acc : newVORList) {
                VOR__c oldAcc = MapVORList.get(acc.Id);
                system.debug('oldAcc == >'+oldAcc);
                if (acc.VOR_Reason__c != oldAcc.VOR_Reason__c) {
                    if (oldAcc.Reason_Entered_Date__c != null) {
                        Long durationInMillis = now.getTime() - oldAcc.Reason_Entered_Date__c.getTime();
                        Decimal totalMinutes = durationInMillis / (1000 * 60);
                        Decimal durationInHours = totalMinutes / 60;
                        Set<String> validReasons = new Set<String>{
                            'Awaiting Daignosis',
                                'Awaiting Parts',
                                'Insurance Stage 1',
                                'Insurance Stage 2',
                                'Awaiting Allotment',
                                'Customer Approval',
                                'Ready for Delivery'
                                };
                                    
                                    if (validReasons.contains(oldAcc.VOR_Reason__c)) {
                                        acc.VOR_Reason_Duration_Time__c = 
                                            (oldAcc.VOR_Reason_Duration_Time__c != null ? oldAcc.VOR_Reason_Duration_Time__c : 0) + durationInHours;
                                    }   
                    }
                    acc.Reason_Entered_Date__c = now;
                }
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
}