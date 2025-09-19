trigger TriggerOnTFRLabourEffect on TFR_Labour_Effect__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            //TriggerOnFailureCodeHelperv2.BeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            //TriggerOnFailureCodeHelperv2.BeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } 
}