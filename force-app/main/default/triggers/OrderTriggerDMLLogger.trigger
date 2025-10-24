trigger OrderTriggerDMLLogger on Order (after update, before delete) {

    if(Trigger.isAfter && Trigger.isUpdate){
        DMLLogger.logChanges(Trigger.oldMap, Trigger.newMap, 'UPDATE', 'Order');
    }
    
    if(Trigger.isBefore && Trigger.isDelete){
        DMLLogger.logChanges(Trigger.oldMap, null, 'DELETE', 'Order');
    }
}