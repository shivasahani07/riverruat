trigger ClaimItemTrigger on ClaimItem (after update, before insert, before update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        ClaimItemTriggerHandler.processClaimUpdates(Trigger.new);
    }
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        ClaimItemTriggerHandler.generateQRCodes(Trigger.new);
    }
}