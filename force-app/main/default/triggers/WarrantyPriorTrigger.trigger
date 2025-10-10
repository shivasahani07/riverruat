/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-25-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger WarrantyPriorTrigger on Warranty_Prior__c (before update,after update, before insert, before delete) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        //WarrantyPriorTriggerHandler.creatClaimLineItemPartJobsAdded(Trigger.new, Trigger.oldMap);//Commented by Aniket To Test
        //WarrantyPriorTriggerHandler.handleWarrantyApproval(Trigger.new, Trigger.oldMap);//Commented By Aniket To Test
       // WarrantyPriorTriggerHandler.createClaimAndClaimItem(Trigger.new, Trigger.oldMap);
        DMLLogger.logChanges(Trigger.oldMap, Trigger.newMap, 'UPDATE', 'Warranty_Prior__c');
        
        // WarrantyPriorTriggerHandler.sendNotificationToDealer(Trigger.new,Trigger.oldMap);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        // WarrantyPriorTriggerHandler.enforceCommentsOnRejection(Trigger.new,Trigger.oldMap);
    }
    
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && (trigger.IsUpdate)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    if(trigger.IsBefore && (trigger.IsInsert)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
        DMLLogger.logChanges(Trigger.oldMap, null, 'DELETE', 'Warranty_Prior__c');
    }
    
    
    
}