/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-21-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger OrderPaymentTrigger on Order_Payment__c (before insert, before update, after update, after insert,after delete) {
     
    If(trigger.isBefore){ 
        If(trigger.isInsert){            
            OrderPaymentTriggerHandler.checkDuplicateOnInsert(trigger.new, false);            
            OrderPaymentTriggerHandler.insertHandler(trigger.new);
        }    
        if(trigger.isUpdate){
            OrderPaymentTriggerHandler.checkDuplicateOnInsert(trigger.new, true);
        }
    }
    
    if(trigger.isAfter){
        If(trigger.isInsert){
            OrderPaymentTriggerHandler.updateOrderOnInsert(trigger.new);
            OrderStatusHandler.sendPreOrderReceipt01(trigger.new); 
            //new on 12/02/2025
            //addeds by Aniket on 07/04/2025 for Website Integration
            Trigger_Handler__mdt  TriggerInstancee = Trigger_Handler__mdt.getInstance('OrderPaymentTriggerHandler_sendDataToRiv');
             if(TriggerInstancee.isActive__c == true){
           OrderPaymentTriggerHandler.sendDataToRiverWebsite(Trigger.new);
             }
        }
        
        If(trigger.isUpdate){
            OrderPaymentTriggerHandler.updateOrderOnUpdate(trigger.new, trigger.oldMap);
            OrderPaymentTriggerHandler.populatePDFInOrder(trigger.new,Trigger.oldMap);
        }
    }
    if(Trigger.isAfter && Trigger.isDelete){
        Trigger_Handler__mdt  TriggerInstancee = Trigger_Handler__mdt.getInstance('OrderPaymentTriggerHandler_deletePayment');
             if(TriggerInstancee.isActive__c == true){
           OrderPaymentTriggerHandler.deletePaymentOnWebsite(Trigger.old);//added by Aniket on 20/05/2025
             }
        
    }
}