trigger CaseTrigger on Case (before insert, before Update,after Insert,after update) {

    if(trigger.isAfter && trigger.isInsert){
        CaseTriggerHandler.fireEmailBasedOnCaseTypeAndItsStagesAfterInsert(trigger.new);
        // CaseTriggerHandler.sendAccountEmail(Trigger.new);
    }
    if(trigger.isAfter && trigger.isUpdate){
        CaseTriggerHandler.createTaskForCaseOwnerWhenCaseClosed(trigger.new);
        CaseTriggerHandler.fireEmailBasedOnCaseTypeAndItsStagesAfterUpdate(trigger.new,trigger.oldMap);
       // CaseTriggerHandler.sendClosureEmail(Trigger.new, Trigger.oldMap);
    }
    if(trigger.isbefore && (trigger.isupdate || trigger.isInsert)){
        CaseTriggerHandler.esclationIsManadatory(trigger.new);
    }
}