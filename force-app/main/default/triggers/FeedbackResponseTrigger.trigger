/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger FeedbackResponseTrigger on Feedback_Response__c (before insert,after update,before update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        AverageCalculationOnFeedbackPSF.calculateAverageRating(Trigger.new,Trigger.oldmap);
    }
     if(Trigger.isBefore && Trigger.isInsert){
         AverageCalculationOnFeedbackPSF.populateFormName(Trigger.new);
    }

}