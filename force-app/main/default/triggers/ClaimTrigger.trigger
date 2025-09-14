/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-25-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger ClaimTrigger on Claim (after insert,after update, before insert , before Update, before delete) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ClaimTriggerHandler.handleAfterInsert(Trigger.new);
    }  
    //Added By Ram 22/08/2025
  /*  if(trigger.IsBefore && trigger.IsUpdate){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 22/08/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }
    if(trigger.IsBefore && trigger.IsInsert){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    } */
  
}