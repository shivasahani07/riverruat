public class VORReasonDurationHelper {
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
                        //Decimal durationInHours = totalMinutes / 60;
                        //Decimal durationInDays = totalMinutes / 1440;
                         Decimal durationInDays = Math.floor(durationInMillis / (1000 * 60 * 60 * 24)); // rounds down

                        if (oldAcc.VOR_Reason__c == 'Awaiting Daignosis') {
                            acc.Awaiting_Diagnosis_in_Days__c	 = (oldAcc.Awaiting_Diagnosis_in_Days__c	 != null ? oldAcc.Awaiting_Diagnosis_in_Days__c	 : 0) + durationInDays;
                        }
                        if (oldAcc.VOR_Reason__c == 'Awaiting Parts') {
                            acc.Awaiting_Parts_in_Days__c = (oldAcc.Awaiting_Parts_in_Days__c != null ? oldAcc.Awaiting_Parts_in_Days__c : 0) + durationInDays;
                        }
                        if (oldAcc.VOR_Reason__c == 'Insurance Stage 1') {
                            acc.Insurance_Stage_1_in_Days__c = (oldAcc.Insurance_Stage_1_in_Days__c != null ? oldAcc.Insurance_Stage_1_in_Days__c : 0) + durationInDays;
                        }
                        if (oldAcc.VOR_Reason__c == 'Insurance Stage 2') {
                            acc.Insurance_Stage_2_in_Days__c = (oldAcc.Insurance_Stage_2_in_Days__c != null ? oldAcc.Insurance_Stage_2_in_Days__c : 0) + durationInDays;
                        }
                        if (oldAcc.VOR_Reason__c == 'Awaiting Allotment') {
                            acc.Awaiting_Allotment_in_Days__c	 = (oldAcc.Awaiting_Allotment_in_Days__c	 != null ? oldAcc.Awaiting_Allotment_in_Days__c	 : 0) + durationInDays;
                        }
                        if (oldAcc.VOR_Reason__c == 'Customer Approval') {
                            acc.Customer_Approval_in_Days__c = (oldAcc.Customer_Approval_in_Days__c != null ? oldAcc.Customer_Approval_in_Days__c : 0) + durationInDays;
                        }
                        if (oldAcc.VOR_Reason__c == 'Ready for Delivery') {
                            acc.Ready_for_Delivery_in_Days__c = (oldAcc.Ready_for_Delivery_in_Days__c != null ? oldAcc.Ready_for_Delivery_in_Days__c : 0) + durationInDays;
                        }
                         if (oldAcc.VOR_Reason__c == 'Rework') {
                            acc.Rework_in_Days__c = (oldAcc.Rework_in_Days__c != null ? oldAcc.Rework_in_Days__c : 0) + durationInDays;
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