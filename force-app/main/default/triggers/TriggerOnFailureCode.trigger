trigger TriggerOnFailureCode on Failure_Code__c (before insert,before update) {
    
    if(trigger.isBefore){
        //TriggerOnFailureCodeHelper.BeforeInsert(trigger.new);
        if(trigger.isUpdate){
            //TriggerOnFailureCodeHelper.validateDataBeforeInsertUdate(trigger.oldmap,trigger.new);
        }
    }
}