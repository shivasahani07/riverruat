trigger TriggerOnOpportunity on Opportunity (before Update,before Insert, after insert, after update) {
    if(Trigger.isBefore && Trigger.isUpdate){
        OpportunityTriggerHandler.thresholdCallAttempt(Trigger.new,Trigger.oldMap);
    }if(Trigger.isBefore && Trigger.isInsert){
        OpportunityTriggerHandler.updateLeadOwner(Trigger.new);
    }if(Trigger.isAfter && Trigger.isUpdate){
        OpportunityTriggerHandler.createTaskWhenOppAssignedToUser(Trigger.new,Trigger.oldMap);
        OpportunityTriggerHandler.createTaskWhenOppIsInFollowup(Trigger.new,Trigger.oldMap);
    }
    
}