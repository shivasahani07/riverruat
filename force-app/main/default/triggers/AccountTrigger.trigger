/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-09-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger AccountTrigger on Account (before insert,after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        AccountTriggerHandler.sendDataToRiverWebsiteAfterUpdate(Trigger.new,Trigger.oldMap);
    }
}