trigger FailureCodeTrigger on Failure_Code__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            //TriggerOnFailureCodeHelperv2.BeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            //TriggerOnFailureCodeHelperv2.BeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            //TriggerOnFailureCodeHelperv2.AfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            //TriggerOnFailureCodeHelperv2.AfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}