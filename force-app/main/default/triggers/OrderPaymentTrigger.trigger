/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger OrderPaymentTrigger on Order_Payment__c (before insert, before update,before delete, after update, after insert,after delete) {
     
    If(trigger.isBefore){ 
        If(trigger.isInsert){            
            OrderPaymentTriggerHandler.checkDuplicateOnInsert(trigger.new, false);            
            OrderPaymentTriggerHandler.insertHandler(trigger.new);
            OrderPaymentTriggerHandler.dontAllowUserToAddOrderPaymentIfOrderIsInInvoice(trigger.new);
        }    
        if(trigger.isUpdate){
            OrderPaymentTriggerHandler.checkDuplicateOnInsert(trigger.new, true);
            OrderPaymentTriggerHandler.dontAllowUserToAddOrderPaymentIfOrderIsInInvoice(trigger.new);
        }
        if(trigger.isDelete){
            OrderPaymentTriggerHandler.dontAllowUserToAddOrderPaymentIfOrderIsInInvoice(trigger.old);
        }
    }
    
    if(trigger.isAfter){
        If(trigger.isInsert){
            //OrderPaymentTriggerHandler.updateOrderOnInsert(trigger.new);
            OrderStatusHandler.sendPreOrderReceipt01(trigger.new); 
            OrderPaymentTriggerHandler.updateOrderStatus(trigger.new);
            //new on 12/02/2025
            //
            Trigger_Handler__mdt  TriggerInstancee = Trigger_Handler__mdt.getInstance('OrderPaymentTriggerHandler_sendDataToRiv');
             if(TriggerInstancee.isActive__c == true){
           OrderPaymentTriggerHandler.sendDataToRiverWebsite(Trigger.new);
             }
        }
        
        If(trigger.isUpdate){
            OrderPaymentTriggerHandler.updateOrderOnUpdate(trigger.new, trigger.oldMap);//Uncommented by Aniket on 09/10/2025
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