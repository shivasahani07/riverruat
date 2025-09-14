/**
* @author Ram Kumar
* @email ram.k@utilitarainlabs.com
* @create 26 june 2025
* @modify 
* @desc
*/
trigger CustomerVoiceTrigger on RR_Customer_Voice__c (before update, before delete, before insert) {
	
    //Added By Ram 22/08/2025
    if(trigger.IsBefore && trigger.IsUpdate){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 22/08/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }
    if(trigger.IsBefore && trigger.IsInsert){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
}