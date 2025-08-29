trigger ProductConsumedTrigger on ProductConsumed (before insert,after insert,after update,after delete, before update, before delete) {
    if(Trigger.isAfter && Trigger.isInsert){
        ProductConsumedTriggerHandler.rollUpOfQuantityConsumed(Trigger.new,null);
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        ProductConsumedTriggerHandler.rollUpOfQuantityConsumed(Trigger.new,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isDelete){
        
        ProductConsumedTriggerHandler.rollUpOfQuantityConsumed(Trigger.old,null);
    }
    
	//Added By Ram 24/06/2025
    if(trigger.IsBefore && (trigger.IsUpdate)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    if(trigger.IsBefore && (trigger.IsInsert)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }
}