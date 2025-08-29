trigger PSFTrigger on Post_Service_Feedback__c (after update, before insert, before update, before delete) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        PostServiceFeedbackHandler.handleStatusCompleted(Trigger.new, Trigger.oldMap);
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