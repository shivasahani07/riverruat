trigger TriggerOnProductRequestLineItem on ProductRequestLineItem (After insert, After Update,Before update,before Delete) {
    if (trigger.IsAfter && (trigger.IsInsert || trigger.IsUpdate)) {
        ProductRequestLineItemHandler.productLineItemUnitPrice(trigger.new);
    }
    if(trigger.IsBefore && trigger.isUpdate){
      // ProductRequestLineItemHandler.throwErrorIftheRecordIsUpdatedByDMSUserWhenParentRecordIsNotInNewStatus(trigger.new);
    }
    if(trigger.IsBefore && trigger.isDelete){
      //  ProductRequestLineItemHandler.throwErrorIftheRecordIsUpdatedByDMSUserWhenParentRecordIsNotInNewStatus(trigger.old);
    }
}