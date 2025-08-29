trigger TriggerOnSubscription on Subscription__c (before insert,before update,after update, after insert) {
    if(trigger.isBefore){
        if(Trigger.isInsert)
        {
            
        }else if(Trigger.IsUpdate)
        {
            
        }
    }
    
}