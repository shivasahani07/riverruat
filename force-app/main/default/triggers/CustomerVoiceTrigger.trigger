/**
* @author Ram Kumar
* @email ram.k@utilitarainlabs.com
* @create 26 june 2025
* @modify 
* @desc
*/
trigger CustomerVoiceTrigger on RR_Customer_Voice__c (before update, before delete) {
	
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsUpdate){
        CustomerVoiceTriggerHandler.PreventUpdateForJobCardStatus(trigger.new);
        System.debug('method called');
    }
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        CustomerVoiceTriggerHandler.PreventUpdateForJobCardStatus(trigger.old);
    }
}