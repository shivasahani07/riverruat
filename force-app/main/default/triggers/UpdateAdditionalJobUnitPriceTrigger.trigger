trigger UpdateAdditionalJobUnitPriceTrigger on RR_Additional_Job_Recommended__c (before insert, before update, before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            RR_Additional_Job_Recommended_Handler.handleUnitPriceUpdate(Trigger.new);
            JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
        }
    }
    
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }
}