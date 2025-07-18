trigger TriggerOnTFRSample on TFR_Sample__c (before insert,after Insert) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            TriggerOnTFRSampleHelper.BeforeInsert(Trigger.new);          
        }
    }
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            TriggerOnTFRSampleHelper.AfterInsert(Trigger.new);          
        }
    }
}