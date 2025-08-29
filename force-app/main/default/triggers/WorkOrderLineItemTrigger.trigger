trigger WorkOrderLineItemTrigger on WorkOrderLineItem (after insert, after update, after delete, before Update, before Delete, before Insert) {
   // Handle "before insert" logic (if needed in the future)
   // if (Trigger.isBefore) {
        //if (Trigger.isInsert) {
            // Add any future logic for "before insert" here if required
       // } /*else if (Trigger.isUpdate) {
            // Add any future logic for "before update" here if required
        //}
    //} 

    // Handle "after insert" logic
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            WorkOrderLineItemTriggerHandler.handleInsert(Trigger.new);
            WorkOrderLineItemTriggerHandler.createProductConsumed(Trigger.new);
        } else if (Trigger.isUpdate) {
           WorkOrderLineItemTriggerHandler.handleUpdate(Trigger.new, Trigger.oldMap);
           WorkOrderLineItemTriggerHandler.createWarrantyAfterUpdate(Trigger.new,Trigger.oldMap); //added by Aniket on 22/05/2025
        }else if (Trigger.isDelete) {
           WorkOrderLineItemTriggerHandler.handleDelete(Trigger.old);
            
      }
    } 
    
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsUpdate){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    if(trigger.IsBefore && trigger.IsInsert){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }
}