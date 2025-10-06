trigger OrderItemTrigger on OrderItem (before insert, after insert, after Delete, After Update, Before Update) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        //OrderItemTriggerHandler.calculateRollupValues(Trigger.new);
        OrderItemTriggerHandler.preventAddingOrderItemForInvoicedOrders(trigger.new);
    }
    
    if (Trigger.isBefore && Trigger.IsUpdate) {
       // OrderItemTriggerHandler.calculateRollupValues(Trigger.new);
       OrderItemTriggerHandler.preventAddingOrderItemForInvoicedOrders(trigger.new);
    }
    if(Trigger.isBefore && trigger.isDelete){
        OrderItemTriggerHandler.preventAddingOrderItemForInvoicedOrders(trigger.old);
    }
     
    if(Trigger.isAfter && Trigger.isInsert) {
        OrderItemTriggerHandler.handleAfterInsert(Trigger.new);
        OrderItemTriggerHandler.updateOrderStatusIfTheOrderProductIsAddedOrUpdated(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
        OrderItemTriggerHandler.handleAfterInsert(Trigger.old);
    } 
    
    if (Trigger.isAfter && Trigger.IsUpdate) {
        OrderItemTriggerHandler.handleAfterInsert(Trigger.new);
        OrderItemTriggerHandler.updateOrderStatusIfTheOrderProductIsAddedOrUpdated(Trigger.new);
    } 
    
    
}