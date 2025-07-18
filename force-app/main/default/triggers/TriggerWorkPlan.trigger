/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 02-14-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger TriggerWorkPlan on WorkPlan (After insert, after Update,after delete,After Undelete, Before Update, Before Delete) {
    
    // Handle after insert separately to ensure proper handling of WorkPlan insert logic
    if (trigger.isAfter && trigger.isInsert) {
        WorkOrderTriggerHandler.handleWorkPlanInsert(trigger.new);
    }
    
    if(trigger.isAfter && (trigger.Isinsert || trigger.isUndelete || trigger.isUpdate)){
        WorkOrderTriggerHandler.handleTrigger(trigger.new);
    }
    
    if(trigger.isAfter && (trigger.Isdelete)){
        WorkOrderTriggerHandler.handleTrigger(trigger.old);
        WorkPlanTriggerHandler.handleAfterDelete(Trigger.Old);
    }
    
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && (trigger.IsUpdate)){
        WorkPlanTriggerHandler.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        WorkPlanTriggerHandler.PreventUpdateForJobCardStatus(trigger.old);
    }
}