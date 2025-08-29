trigger PurchaseOrderTrigger on ProductRequest (after insert, after update,Before update,before Delete, before insert) {
    try {
        if (Trigger.isAfter) {
            // Notify Store Manager for high-value Purchase Orders
            PurchaseOrderTriggerHandler.sendHighValueNotification(Trigger.new);
            
            // Notify Warehouse for new Purchase Orders requiring allotment
            if (Trigger.isInsert) {
                //   PurchaseOrderTriggerHandler.notifyWarehouseForAllotment(Trigger.new);
            }           
        }
        
        if(trigger.IsBefore && trigger.isUpdate){
           //PurchaseOrderTriggerHandler.throwErrorIftheRecordIsUpdatedByDMSUserWhenParentRecordIsNotInNewStatus(trigger.new,trigger.oldmap);
        }
        if(trigger.IsBefore && trigger.isDelete){
            //PurchaseOrderTriggerHandler.throwErrorIftheRecordIsDeletedByDMSUserWhenParentRecordIsNotInNewStatus(trigger.old);
        }
        
    } catch (Exception ex) {
        // Log the exception to debug logs for troubleshooting
        System.debug('Error in PurchaseOrderTrigger: ' + ex.getMessage());
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
    }
}