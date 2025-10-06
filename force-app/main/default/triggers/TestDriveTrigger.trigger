/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger TestDriveTrigger on Test_Drive__c (before insert, after insert,after Update,before update) {
    
    /*if(Trigger.isBefore && Trigger.isInsert){
        for(Test_Drive__c td : trigger.new){
            td.Name = td.Lead__r.Name +'- Test Drive';
        }
    } */
    if(trigger.isBefore && trigger.isUpdate){
       TestDriveTriggerHandler.dontCOnvertTheLeadIfTheTestRideIsNotScheduled(Trigger.new,Trigger.oldMap);
    }
    if(trigger.isBefore && trigger.isInsert){
       TestDriveTriggerHandler.assignSameOwnerOfLeadAndOppToTestDriveOwner(trigger.new);
    }
    
    if(trigger.isafter && trigger.isInsert){
       TestDriveTriggerHandler.afterInsert(Trigger.new);
       TestDriveTriggerHandler.convertLeadIfStatusIsScheduled(Trigger.new,Trigger.oldMap);
       TestDriveTriggerHandler.sendLeadToDealerOnTestRideScheduled(Trigger.new,Trigger.oldMap);
    //    TestDriveTriggerHandler.onCreationOfTestDriveUpdateOppAndOnCompletionOfTestDrive(Trigger.new);
       TestDriveTriggerHandler.convertLeadIfTheRideTypeIsStoreTestRideAndLeadHomeTestdriveIsTrue(Trigger.new);
       TestDriveTriggerHandler.deleteOldNotCompletedTestDrive(Trigger.new);
       
       
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        TestDriveTriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap);
        TestDriveTriggerHandler.ifTestRideCancelled(Trigger.new,Trigger.oldMap);
        TestDriveTriggerHandler.sendLeadToDealerOnTestRideScheduled(Trigger.new,Trigger.oldMap);
        TestDriveTriggerHandler.convertLeadIfStatusIsScheduled(Trigger.new,Trigger.oldMap);
        TestDriveTriggerHandler.deleteNotesAndAttachmentsOnTestRideCompletion(Trigger.new,Trigger.oldMap);
        // TestDriveTriggerHandler.onCreationOfTestDriveUpdateOppAndOnCompletionOfTestDrive(Trigger.new);
        TestDriveTriggerHandler.updateOpportunityStatusOnTestRideStatusUpdate(Trigger.new,Trigger.oldMap);
        TestDriveTriggerHandler.createFollowUpOnTestRideCompletion(Trigger.new);
    }     
}