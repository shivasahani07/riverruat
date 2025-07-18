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
}