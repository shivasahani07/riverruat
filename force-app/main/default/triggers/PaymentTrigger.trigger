trigger PaymentTrigger on Payment__c (after insert, after update, after delete, after unDelete,before insert,before update, before delete) {
    
    If(trigger.isInsert || trigger.isUpdate || trigger.isUndelete){
        PaymentTriggerHandler.insertHandler(trigger.new);    
    }
    
    If(trigger.isUpdate){
        PaymentTriggerHandler.updateHandler(trigger.new, trigger.oldMap);
    }

    if(trigger.isInsert && trigger.isAfter){
        PaymentTriggerHandler.onCreationOfPaymentUnderOpportunityCreateOrderAndOrderPayment(trigger.newMap);
    }

    if(trigger.isBefore && trigger.isInsert ){
        PaymentTriggerHandler.throwErrorIfTheOppProductsAreNull(trigger.new);
    }

    if(trigger.isBefore && (trigger.isInsert || trigger.isupdate) ){
        EnquiryRecordLock.PreventUpdateForEnquiryStage(trigger.new);
    }
    if(trigger.isBefore && trigger.isdelete ){
        EnquiryRecordLock.PreventUpdateForEnquiryStage(trigger.old);
    }
}