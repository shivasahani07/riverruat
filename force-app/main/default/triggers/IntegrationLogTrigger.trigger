trigger IntegrationLogTrigger on Integration_Log__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        IntegrationLogTriggerHandler.handleAfterInsert(Trigger.new);
    }
}