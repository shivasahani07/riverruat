/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 08-26-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger TriggerWorkPlan on WorkPlan (After insert, after Update,after delete,After Undelete, Before Update, Before Delete, Before Insert) {
    
    // Handle after insert separately to ensure proper handling of WorkPlan insert logic
    if (trigger.isAfter && trigger.isInsert) {
        WorkOrderTriggerHandler.handleWorkPlanInsert(trigger.new);
    }
    
    if(trigger.isAfter && (trigger.Isinsert || trigger.isUndelete || trigger.isUpdate)){
        WorkOrderTriggerHandler.handleTrigger(trigger.new);
    }
    //added By Aniket on 26/08/2025
    if(trigger.isAfter && trigger.isUpdate){
        WorkOrderTriggerHandler.handleWorkPlanUpdateCategory(Trigger.new,Trigger.oldMap);
    }
    
    if(trigger.isAfter && (trigger.Isdelete)){
        WorkOrderTriggerHandler.handleTrigger(trigger.old);
        WorkPlanTriggerHandler.handleAfterDelete(Trigger.Old);
    }
    
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && (trigger.IsUpdate)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    if(trigger.IsBefore && (trigger.IsInsert)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }
}