trigger TriggerWorkPlane on WorkPlan (After insert, after Update,after delete,After Undelete) {

   /* if(trigger.isAfter && (trigger.Isinsert || trigger.isUndelete || trigger.isUpdate)){
        WorkOrderTriggerHandler.handleTrigger(trigger.new);
    }
    
    if(trigger.isAfter && (trigger.Isdelete)){
        WorkOrderTriggerHandler.handleTrigger(trigger.old);
    } */
}