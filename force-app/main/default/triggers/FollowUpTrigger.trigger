trigger FollowUpTrigger on Follow_Up__c (before insert,before update,after insert,after update, after delete) {
    if (Trigger.isBefore && Trigger.isInsert){
        //FollowUpTriggerController.updateFollowUpName(Trigger.new);
        //FollowUpTriggerController.Limitfolwupsforlead(trigger.new);
        //FollowUpTriggerController.previousfeedback(trigger.new);
        //FollowUpTriggerController.folowuptype(trigger.new);
    }
    
    if(Trigger.isBefore && Trigger.isUpdate){
        //FollowUpTriggerController.updateFeedBack(Trigger.new,Trigger.oldMap);
    }

    if(trigger.isafter && trigger.isinsert){
        //FollowUpTriggerController.updateleadstatus(trigger.new);
        FollowUpTriggerController.showFollowUpCount(trigger.new);
        FollowUpTriggerController.deleteOldNotCompletedFollowUp(trigger.new);
    }

    if(trigger.isafter && trigger.isUpdate){
        //FollowUpTriggerController.previousfeedback(trigger.new);
        FollowUpTriggerController.createNewFollowUpIfTheNextFollowUpIsNotNullOrChanged(trigger.new,Trigger.oldMap);
    }

    if(trigger.isafter && trigger.isDelete){
        FollowUpTriggerController.showFollowUpCount(trigger.old);
    }
    if(trigger.isBefore && trigger.isInsert){
        //FollowUpTriggerController.assignSameOwnerOfLeadAndOppToTestDriveOwner(trigger.new);
    }
    
}