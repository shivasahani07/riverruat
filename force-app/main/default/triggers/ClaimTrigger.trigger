trigger ClaimTrigger on Claim (after insert,after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ClaimTriggerHandler.handleAfterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        ClaimTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
  
}