/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger OrderItemTrigger on OrderItem (before insert, after insert, after delete, after update, before update,before delete) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
      //  OrderItemTriggerHandler.calculateRollupValues(Trigger.new);
    }
    
    if (Trigger.isBefore && Trigger.IsUpdate) {
       // OrderItemTriggerHandler.calculateRollupValues(Trigger.new);
    }
     
    if(Trigger.isAfter && Trigger.isInsert) {
        OrderItemTriggerHandler.handleAfterInsert(Trigger.new);
        Trigger_Handler__mdt  TriggerInstancee = Trigger_Handler__mdt.getInstance('OrderItemTriggerHandler_createProductOnW');
             if(TriggerInstancee.isActive__c == true){
           OrderItemTriggerHandler.createProductOnWebsite(Trigger.new);//added by Aniket on 14/05/2025
             }
        
    }
    if (Trigger.isAfter && Trigger.isDelete) {
        OrderItemTriggerHandler.handleAfterInsert(Trigger.old);
       // OrderItemTriggerHandler.deleteProductOnWebsite(Trigger.old);//added by Aniket on 20/05/2025
    } 
    
    if (Trigger.isAfter && Trigger.IsUpdate) {
        OrderItemTriggerHandler.handleAfterInsert(Trigger.new);
    } 
    if(Trigger.isBefore && Trigger.isDelete){
        Trigger_Handler__mdt  TriggerInstancee = Trigger_Handler__mdt.getInstance('OrderItemTriggerHandler_deleteProductOnW');
             if(TriggerInstancee.isActive__c == true){
           OrderItemTriggerHandler.deleteProductOnWebsite(Trigger.old);////added by Aniket on 20/05/2025
             }
        
        OrderItemTriggerHandler.inventoryUpdateAfterOTCProductDeletion(Trigger.old);//added by Aniket on 05/06/2025
    }
    
    
}