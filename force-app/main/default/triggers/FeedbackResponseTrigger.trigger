/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger FeedbackResponseTrigger on Feedback_Response__c (before insert,after update,before update, before delete) {
    if(Trigger.isAfter && Trigger.isUpdate){
        AverageCalculationOnFeedbackPSF.calculateAverageRating(Trigger.new,Trigger.oldmap);
        AverageCalculationOnFeedbackPSF.createAnswerChildObject(Trigger.new,Trigger.oldmap);
        //AverageCalculationOnFeedbackPSF.createAnswerForPost7Days(Trigger.new,Trigger.oldmap);
    }
     if(Trigger.isBefore && Trigger.isInsert){
         AverageCalculationOnFeedbackPSF.populateFormName(Trigger.new);
          //JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    
     //Added By Ram 24/06/2025
    if(trigger.IsBefore && (trigger.IsUpdate)){
        //JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        //JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }

}