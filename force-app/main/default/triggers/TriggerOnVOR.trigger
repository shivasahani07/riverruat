trigger TriggerOnVOR on VOR__c (before update, before insert, before delete) {
    if(trigger.isBefore && trigger.isUpdate){
        if(system.label.ActiveVORTrigger == 'True'){
            VORTriggerHelper.VORReasonDurationUpdate(trigger.new,Trigger.oldMap);       
        }
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
     if(trigger.isBefore && trigger.isUpdate){
        if(system.label.ActiveVORTrigger == 'True'){
            VORReasonDurationHelper.VORReasonDurationUpdate(trigger.new,Trigger.oldMap);       
        }
    }
    
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && (trigger.IsInsert)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }
}