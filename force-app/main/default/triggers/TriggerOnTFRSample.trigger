trigger TriggerOnTFRSample on TFR_Sample__c (before insert,after Insert, before update, before delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            TriggerOnTFRSampleHelper.BeforeInsert(Trigger.new); 
            JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
        }
    }
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            TriggerOnTFRSampleHelper.AfterInsert(Trigger.new);          
        }if(Trigger.isUpdate){
            TriggerOnTFRSampleHelper.AfterInsert(Trigger.new);          
        }
    }
    
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && (trigger.IsUpdate)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }
}