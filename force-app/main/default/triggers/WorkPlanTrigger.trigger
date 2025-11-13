trigger WorkPlanTrigger on WorkPlan (after insert,after delete, before delete, after update) {
    // if (Trigger.isAfter && Trigger.isInsert) {
    //     WorkPlanTriggerHandler.handleInsert(Trigger.new);
    // }
    if(Trigger.isAfter && Trigger.isDelete){
         WorkPlanTriggerHandler.handleAfterDelete(Trigger.Old);
    }
    
    if(trigger.IsBefore && trigger.IsDelete){
        DMLLogger.logChanges(Trigger.oldMap, null, 'DELETE', 'WorkPlan');
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        DMLLogger.logChanges(Trigger.oldMap, Trigger.newMap, 'UPDATE', 'WorkPlan');
    }
}