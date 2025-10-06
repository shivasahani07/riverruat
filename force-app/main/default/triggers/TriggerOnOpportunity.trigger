trigger TriggerOnOpportunity on Opportunity (before insert,after Insert, after update, before update,before delete) {
    
    
    if(Trigger.isBefore && Trigger.isUpdate){
        //OpportunityTriggerHandler.thresholdCallAttempt(Trigger.new,Trigger.oldMap);
        //OpportunityTriggerHandler.onClosedWonShowErrorIfOppLineItemsAreNotThere(Trigger.new,Trigger.oldMap);
        OpportunityTriggerHandler.onClosedWonShowErrorIfBookingAmountIsNull(Trigger.new,Trigger.oldMap);
        OpportunityTriggerHandler.lockTheRecordAfterClosedWon(trigger.new,Trigger.oldMap);    
    }

    if(Trigger.isBefore && Trigger.isdelete){
        OpportunityTriggerHandler.lockTheRecordAfterClosedWon(trigger.old,Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        //OpportunityTriggerHandler.createTaskWhenOppAssignedToUser(Trigger.new,Trigger.oldMap);
        //OpportunityTriggerHandler.createTaskWhenOppIsInFollowup(Trigger.new,Trigger.oldMap);
        //OpportunityTriggerHandler.createOrderIfOppIsClosedWon(Trigger.new,Trigger.oldMap);
        
        // I add this for ps app where the owner os changing then the related record owners is not changing
        OpportunityTriggerHandler.changeOwnerOfTestDriveAndFollowUpIsOppOwnerIsChanged(Trigger.new,Trigger.oldMap);
        OpportunityTriggerHandler.tagPricebookToOwner(Trigger.new,Trigger.oldMap);
        OpportunityTriggerHandler.getThePreferredSellerOfAccount(Trigger.new,Trigger.oldMap);
    }   

    if(Trigger.isAfter && Trigger.isInsert){
        //OpportunityTriggerHandler.createTaskWhenOppAssignedToUser(Trigger.new,Trigger.oldMap);
        //OpportunityTriggerHandler.createTaskWhenOppIsInFollowup(Trigger.new,Trigger.oldMap);
        // OpportunityTriggerHandler.createFollowUpOnOppCreated(Trigger.new);
        OpportunityTriggerHandler.getThePreferredSellerOfAccount(Trigger.new,null);
        OpportunityTriggerHandler.tagPricebookToOwner(Trigger.new,null);
        GenericRecordSharer.shareRecordsWithHierarchy(Trigger.NewMap, 'Opportunity', 'Edit', 'Manual');
    }   
}