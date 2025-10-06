public class OrderItemTriggerHandler {
    
    public static void handleAfterInsert(List<OrderItem> orderItems) {
        if (orderItems == null || orderItems.isEmpty()) {
            System.debug('No OrderItems found in Trigger.new');
            return;
        }
        
        Set<Id> orderIds = new Set<Id>();
        
        for (OrderItem oi : orderItems) {
            if (oi.OrderId != null) {
                orderIds.add(oi.OrderId);
            }
        }
        
        if (orderIds.isEmpty()) {
            System.debug('No valid Order IDs found.');
            return;
        }
        
        Map<Id, Decimal> totalVehicleRollup = new Map<Id, Decimal>();
        Map<Id, Decimal> totalAccessoriesRollup = new Map<Id, Decimal>();
        Map<Id, Decimal> totalMerchandiseRollup = new Map<Id, Decimal>();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        List<OrderItem> allOrderItems = [
            SELECT Id, OrderId, Type__c, Vehicle_Roll_Up__c, Accessories_Roll_Up__c,Merchandise_Disccount__c, Product_Total_Amount__c
            FROM OrderItem 
            WHERE OrderId IN :orderIds
        ];
        
       /* for (OrderItem oi : allOrderItems) {
            Decimal rollupValue = 0;
            if (oi.Type__c == 'Vehicle') {
                rollupValue = oi.Vehicle_Roll_Up__c != null ? oi.Vehicle_Roll_Up__c : 0;
                totalVehicleRollup.put(oi.OrderId, totalVehicleRollup.containsKey(oi.OrderId) ? totalVehicleRollup.get(oi.OrderId) + rollupValue : rollupValue);
            } else if (oi.Type__c == 'Accessories' || oi.Type__c == 'Parts') {
                rollupValue = oi.Accessories_Roll_Up__c != null ? oi.Accessories_Roll_Up__c : 0;
                totalAccessoriesRollup.put(oi.OrderId, totalAccessoriesRollup.containsKey(oi.OrderId) ? totalAccessoriesRollup.get(oi.OrderId) + rollupValue : rollupValue);
            } else if (oi.Type__c == 'Merchandise') {
                rollupValue = oi.Product_Total_Amount__c != null ? oi.Product_Total_Amount__c : 0;
                totalMerchandiseRollup.put(oi.OrderId, totalMerchandiseRollup.containsKey(oi.OrderId) ? totalMerchandiseRollup.get(oi.OrderId) + rollupValue : rollupValue);
            }
            //orderItemsToUpdate.add(oi);
        } */
        for (OrderItem oi : allOrderItems) {
            Decimal rollupValue = 0;
            if (oi.Type__c == 'Vehicle') {
                rollupValue = oi.Product_Total_Amount__c != null ? oi.Product_Total_Amount__c : 0;
                totalVehicleRollup.put(oi.OrderId, totalVehicleRollup.containsKey(oi.OrderId) ? totalVehicleRollup.get(oi.OrderId) + rollupValue : rollupValue);
            } else if (oi.Type__c == 'Accessories' || oi.Type__c == 'Parts') {
                rollupValue = oi.Product_Total_Amount__c != null ? oi.Product_Total_Amount__c : 0;
                totalAccessoriesRollup.put(oi.OrderId, totalAccessoriesRollup.containsKey(oi.OrderId) ? totalAccessoriesRollup.get(oi.OrderId) + rollupValue : rollupValue);
            } else if (oi.Type__c == 'Merchandise') {
                rollupValue = oi.Product_Total_Amount__c != null ? oi.Product_Total_Amount__c : 0;
                totalMerchandiseRollup.put(oi.OrderId, totalMerchandiseRollup.containsKey(oi.OrderId) ? totalMerchandiseRollup.get(oi.OrderId) + rollupValue : rollupValue);
            }
            //orderItemsToUpdate.add(oi);
        }
        
        
        System.debug('Total Vehicle Rollups: ' + totalVehicleRollup);
        System.debug('Total Accessories Rollups: ' + totalAccessoriesRollup);
        System.debug('Total Merchandise Rollups: ' + totalMerchandiseRollup);
        
        
        
        
        // Update Order fields with roll-up values
        List<Order> ordersToUpdate = new List<Order>();
        
        for (Id orderId : orderIds) {
            Decimal vehicleTotal = totalVehicleRollup.containsKey(orderId) ? totalVehicleRollup.get(orderId) : 0;
            Decimal accessoriesTotal = totalAccessoriesRollup.containsKey(orderId) ? totalAccessoriesRollup.get(orderId) : 0;
            Decimal merchandiseTotal = totalMerchandiseRollup.containsKey(orderId) ? totalMerchandiseRollup.get(orderId) : 0;
            
            Order updatedOrder = new Order(
                Id = orderId,
                Total_Vehicle_Rollup__c = vehicleTotal.round(),
                Total_Accessories_Rollup__c = accessoriesTotal.round(),
                Total_Merchandise_Rollup__c = merchandiseTotal.round()
            );
            ordersToUpdate.add(updatedOrder);
        }
        
        
        if (!ordersToUpdate.isEmpty()) {
            try {
                update ordersToUpdate;
                System.debug('Successfully updated Orders with aggregated roll-up values.');
            } catch (DmlException e) {
                System.debug('Error updating Orders: ' + e.getMessage());
            }
        }
    } 
    
    public static void preventAddingOrderItemForInvoicedOrders(List<OrderItem> newOrderItems) {
        try {
            Set<Id> orderIdsToCheck = new Set<Id>();

            for (OrderItem orderItem : newOrderItems) {
                if (orderItem.OrderId != null) {
                    orderIdsToCheck.add(orderItem.OrderId);
                }
            }

            if (!orderIdsToCheck.isEmpty()) {
                List<Order> invoicedOrders = [SELECT Id, Status FROM Order WHERE Id IN :orderIdsToCheck AND Status IN ('Invoice and Insurance', 'Ready For Delivery', 'Vehicle Delivered')];

                Set<Id> invoicedOrderIds = new Set<Id>();
                for (Order ord : invoicedOrders) {
                    invoicedOrderIds.add(ord.Id);
                }

                for (OrderItem orderItem : newOrderItems) {
                    if (invoicedOrderIds.contains(orderItem.OrderId)) {
                        orderItem.OrderId.addError(
                            'Cannot add or Update an Order Product to an Order that is already Invoiced.'
                        );
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in ==========> ' + e.getMessage() +' at line  number ==========>' + e.getLineNumber());
        }
    }

    public static void updateOrderStatusIfTheOrderProductIsAddedOrUpdated(List<OrderItem> newOrderItems){
        try{    
            set<Id> setOfOrderId = new Set<Id>();
            for (OrderItem orderItem : newOrderItems) {
                if (orderItem.OrderId != null) {
                    setOfOrderId.add(orderItem.OrderId);
                }
            }

            if (!setOfOrderId.isEmpty()) {
                List<Order> ordersToUpdate = [SELECT Id, Status,Vehicle_Assigned__c FROM Order WHERE Id IN :setOfOrderId AND Status IN ('Pre Invoice')];
                List<Order> listOfOrderToBeUpdate = new List<Order>();
                for(Order ord : ordersToUpdate){
                    order ordToUpdate = new order();
                    ordToUpdate.Id = ord.Id;
                    ordToUpdate.Status = 'Payment and Allocation';
                    ordToUpdate.Vehicle_Assigned__c = true;
                    ordToUpdate.IsOrderInvoicesGenerated__c = false;
                    listOfOrderToBeUpdate.add(ordToUpdate);
                }

                // List<Order_Invoice__c> orderInoviceList = [Select Id from Order_Invoice__c where Order__c IN :setOfOrderId];
                // if(!orderInoviceList.isEmpty()){
                //     delete orderInoviceList;
                // }
                if(!listOfOrderToBeUpdate.isEmpty()){
                    update listOfOrderToBeUpdate;
                }
            }
        }catch (Exception e) {
            System.debug('Error in ==========> ' + e.getMessage() +' at line  number ==========>' + e.getLineNumber());
        }
    }

}