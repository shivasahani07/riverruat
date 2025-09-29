trigger serviceBayTrigger on Service_Bay__c (before insert ) {
    // Collect all Account Ids from records being inserted/updated
    if(trigger.IsInsert && trigger.IsBefore){
        serviceBayTriggerHandler.handleBayCount(Trigger.New);
    }
}