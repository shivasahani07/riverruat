trigger PurchaseOrderTrigger on ProductRequest (after insert, after update,Before update,before Delete) {
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
}