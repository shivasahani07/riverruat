trigger PSFTrigger on Post_Service_Feedback__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        PostServiceFeedbackHandler.handleStatusCompleted(Trigger.new, Trigger.oldMap);
    }
}