/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger TestDriveTrigger on Test_Drive__c (before insert, after insert,after Update) {
    
    /*if(Trigger.isBefore && Trigger.isInsert){
        for(Test_Drive__c td : trigger.new){
            td.Name = td.Lead__r.Name +'- Test Drive';
        }
    } */
    if(trigger.isBefore && trigger.isUpdate){
       // TestDriveTriggerHandler.dontCOnvertTheLeadIfTheTestRideIsNotScheduled(Trigger.new,Trigger.oldMap);
    }
    
    if(trigger.isafter && trigger.isInsert){
        TestDriveTriggerHandler.afterInsert(Trigger.new);
       // TestDriveTriggerHandler.convertLeadIfStatusIsScheduled(Trigger.new);
       TestDriveTriggerHandler.sendLeadToDealerOnTestRideScheduled(Trigger.new,Trigger.oldMap);
        
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        //Once Test Ride is completed
        //TestDriveTriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap);//commented By Aniket to disable the Jotform link
        TestDriveTriggerHandler.ifTestRideCancelled(Trigger.new,Trigger.oldMap);
        TestDriveTriggerHandler.sendLeadToDealerOnTestRideScheduled(Trigger.new,Trigger.oldMap);
        //TestDriveTriggerHandler.convertLeadIfStatusIsScheduledUpdated(Trigger.new,Trigger.oldMap);
    }     
}