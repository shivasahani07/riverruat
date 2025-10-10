trigger ClaimItemTrigger on ClaimItem (after update, before insert, before update, before delete) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        ClaimItemTriggerHandler.processClaimUpdates(Trigger.new);
        DMLLogger.logChanges(Trigger.oldMap, Trigger.newMap, 'UPDATE', 'ClaimItem');
    }
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        ClaimItemTriggerHandler.generateQRCodes(Trigger.new);
    }
    
    if(trigger.IsBefore && trigger.IsDelete){
        DMLLogger.logChanges(Trigger.oldMap, null, 'DELETE', 'ClaimItem');
    }
}

/*
//Deployed Code to Production

trigger ClaimItemTrigger on ClaimItem (after update, before delete) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        ClaimItemTriggerHandler.processClaimUpdates(Trigger.new);
        DMLLogger.logChanges(Trigger.oldMap, Trigger.newMap, 'UPDATE', 'ClaimItem');
    }
    
    if(trigger.IsBefore && trigger.IsDelete){
        DMLLogger.logChanges(Trigger.oldMap, null, 'DELETE', 'ClaimItem');
    }
}

*/