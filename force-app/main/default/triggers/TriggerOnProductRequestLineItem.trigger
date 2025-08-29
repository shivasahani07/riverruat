trigger TriggerOnProductRequestLineItem on ProductRequestLineItem (After insert, After Update,Before update,before Delete, before insert) {
    if (trigger.IsAfter && (trigger.IsInsert || trigger.IsUpdate)) {
        ProductRequestLineItemHandler.productLineItemUnitPrice(trigger.new);
    }
 /*   if(trigger.IsBefore && trigger.isUpdate){
      // ProductRequestLineItemHandler.throwErrorIftheRecordIsUpdatedByDMSUserWhenParentRecordIsNotInNewStatus(trigger.new);
    }
    if(trigger.IsBefore && trigger.isDelete){
      //  ProductRequestLineItemHandler.throwErrorIftheRecordIsUpdatedByDMSUserWhenParentRecordIsNotInNewStatus(trigger.old);
    } */
    
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