trigger TriggerOnActionPlan on ActionPlan (before insert,before delete,after insert,after update,Before update ) {
    if(trigger.isdelete && trigger.isbefore){
        actionPlanHandler.getTheCountOfTheActionPlansOfaFieldFix(trigger.old);
    }
    if(trigger.isupdate && trigger.isafter){
      actionPlanHandler.createProductAndlabour(Trigger.new, Trigger.oldMap);
      //actionPlanHandler.checkInventoryValidation(Trigger.new, Trigger.oldMap);
     
    }
    if(trigger.isupdate && trigger.isBefore){
      actionPlanHandler.checkInventoryValidation(Trigger.new, Trigger.oldMap);
     
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