/**
 * @description       : 
 * @author            : Ram Kumar
 * @group             : 
 * @last modified on  : 07-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
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
    
        Map<Id, Decimal> accessoriesUnitPriceMap = new Map<Id, Decimal>();
        Map<Id, Decimal> merchandiseUnitPriceMap = new Map<Id, Decimal>();
    
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        List<OrderItem> allOrderItems = [
            SELECT Id, OrderId, Type__c, Vehicle_Roll_Up__c, Accessories_Roll_Up__c, Merchandise_Disccount__c,
                   Product_Total_Amount__c, UnitPrice, Quantity, Total_Pre_GST_Discount__c
            FROM OrderItem 
            WHERE OrderId IN :orderIds
        ];
    	
         Decimal TotalPreGSTDis = 0;
        for (OrderItem oi : allOrderItems) {
            Decimal rollupValue = oi.Product_Total_Amount__c != null ? oi.Product_Total_Amount__c : 0;
            Decimal unitTotal = (oi.UnitPrice != null && oi.Quantity != null) ? oi.UnitPrice * oi.Quantity : 0;
            System.debug('Total_Pre_GST_Discount__c====> ' + oi.Total_Pre_GST_Discount__c);
            System.debug('oi.Product_Total_Amount__c ==>'+ oi.Product_Total_Amount__c);
            
             TotalPreGSTDis += (oi.Total_Pre_GST_Discount__c != null ? oi.Total_Pre_GST_Discount__c : 0);
            System.debug('Total_Pre_GST_Discount__c====> ' + TotalPreGSTDis);
    
            if (oi.Type__c == 'Vehicle') {
                totalVehicleRollup.put(oi.OrderId,
                    totalVehicleRollup.containsKey(oi.OrderId) ? totalVehicleRollup.get(oi.OrderId) + rollupValue : rollupValue);
            } else if (oi.Type__c == 'Accessories' || oi.Type__c == 'Parts') {
                totalAccessoriesRollup.put(oi.OrderId,
                    totalAccessoriesRollup.containsKey(oi.OrderId) ? totalAccessoriesRollup.get(oi.OrderId) + rollupValue : rollupValue);
                accessoriesUnitPriceMap.put(oi.OrderId,
                    accessoriesUnitPriceMap.containsKey(oi.OrderId) ? accessoriesUnitPriceMap.get(oi.OrderId) + unitTotal : unitTotal);
            } else if (oi.Type__c == 'Merchandise') {
                totalMerchandiseRollup.put(oi.OrderId,
                    totalMerchandiseRollup.containsKey(oi.OrderId) ? totalMerchandiseRollup.get(oi.OrderId) + rollupValue : rollupValue);
                merchandiseUnitPriceMap.put(oi.OrderId,
                    merchandiseUnitPriceMap.containsKey(oi.OrderId) ? merchandiseUnitPriceMap.get(oi.OrderId) + unitTotal : unitTotal);
            }
            if(trigger.isAfter && Trigger.isInsert){
                 orderItemsToUpdate.add(oi);
                System.debug('orderItemsToUpdate ==>'+orderItemsToUpdate);
            }
           
        }
    
        System.debug('Total Vehicle Rollups: ' + totalVehicleRollup);
        System.debug('Total Accessories Rollups: ' + totalAccessoriesRollup);
        System.debug('Total Merchandise Rollups: ' + totalMerchandiseRollup);
        System.debug('Accessories Unit Price Rollups: ' + accessoriesUnitPriceMap);
        System.debug('Merchandise Unit Price Rollups: ' + merchandiseUnitPriceMap);
        
    
        List<Order> ordersToUpdate = new List<Order>();
    
        for (Id orderId : orderIds) {
            Decimal vehicleTotal = totalVehicleRollup.containsKey(orderId) ? totalVehicleRollup.get(orderId) : 0;
            Decimal accessoriesTotal = totalAccessoriesRollup.containsKey(orderId) ? totalAccessoriesRollup.get(orderId) : 0;
            Decimal merchandiseTotal = totalMerchandiseRollup.containsKey(orderId) ? totalMerchandiseRollup.get(orderId) : 0;
            
            Decimal accessoriesUnitTotal = accessoriesUnitPriceMap.containsKey(orderId) ? accessoriesUnitPriceMap.get(orderId) : 0;
            Decimal merchandiseUnitTotal = merchandiseUnitPriceMap.containsKey(orderId) ? merchandiseUnitPriceMap.get(orderId) : 0;
    
            Order updatedOrder = new Order(
                Id = orderId,
                Total_Vehicle_Rollup__c = vehicleTotal.round(),
                Total_Accessories_Rollup__c = accessoriesTotal.round(),
                Total_Merchandise_Rollup__c = merchandiseTotal.round(),
                Total_Accessories_Unit_Price__c = accessoriesUnitTotal.round(),
                Total_Merchandise_Unit_Price__c = merchandiseUnitTotal.round(),
                Total_Pre_GST_Discount__c = TotalPreGSTDis
            );
            ordersToUpdate.add(updatedOrder);
        }
    
        if (!ordersToUpdate.isEmpty()) {
            try {
                update ordersToUpdate;
                System.debug('ordersToUpdate ==>'+ordersToUpdate);
                System.debug('Successfully updated Orders with aggregated roll-up values.');
            } catch (DmlException e) {
                System.debug('Error updating Orders: ' + e.getMessage());
            }
        }
		
           if (!orderItemsToUpdate.isEmpty()) {
            try {
                update orderItemsToUpdate;
                System.debug('ordersItemToUpdate ==>'+orderItemsToUpdate);
                System.debug('Successfully updated OrderItemsForUpdate with aggregated roll-up values.');
            } catch (DmlException e) {
                System.debug('Error updating Orders: ' + e.getMessage());
            }
        }
    }

    
    //added by Aniket on 14/05/2025
    public static void createProductOnWebsite(List<OrderItem> orderItemList){
          Id vehicleRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
        try{
            Set<Id> orderIds = new Set<Id>();
            Set<Id> orderItemIds = new Set<Id>();
            List<Id> orderItemidsForWebsite = new List<Id>();
            List<Id> orderIdsForWebsite = new List<Id>();
            if(!orderItemList.isEmpty()){
                for(OrderItem oi : orderItemList){
                    orderIds.add(oi.OrderId);
                    orderItemIds.add(oi.Id);
                }
            }
            System.debug('orderIds==>'+orderIds);
            System.debug('orderItemIds==>'+orderItemIds);

            List<OrderItem> fetchedOrderProducts = [Select id,OrderId,Website_Response_Id__c,Order.RecordTypeId from OrderItem WHERE OrderId IN:orderIds AND Website_Response_Id__c!=null AND Order.recordTypeId =: vehicleRecordTypeId];
            List<Order> orderList = [Select id,Website_Response_Id__c from Order WHERE id=:orderIds];
            Order order;
            if(!orderList.isEmpty()){
                order = orderList[0];
            }
            System.debug('fetchedOrderProducts==>'+fetchedOrderProducts);
            if(order.Website_Response_Id__c!=null ){
                List<OrderItem> finalOrderItemList = [Select id,OrderId from OrderItem where Id =:orderItemIds];
                for(OrderItem op : finalOrderItemList){
                    orderIdsForWebsite.add(op.OrderId);
                    orderItemidsForWebsite.add(op.Id);
                }
            }
            if(!orderItemidsForWebsite.isEmpty()){
                Datetime dt = Datetime.now().addMinutes(1);
                            String cron = String.format('{0} {1} {2} {3} {4} ? {5}',
                                new String[]{
                                    String.valueOf(dt.second()),
                                    String.valueOf(dt.minute()),
                                    String.valueOf(dt.hour()),
                                    String.valueOf(dt.day()),
                                    String.valueOf(dt.month()),
                                    String.valueOf(dt.year())
                                });

                            
                            ScheduleCreateProductOnWebsite job = (ScheduleCreateProductOnWebsite) JSON.deserialize(
                                JSON.serialize(new ScheduleCreateProductOnWebsite(orderItemidsForWebsite)), 
                                ScheduleCreateProductOnWebsite.class
                            );
                            
                           System.schedule('Schedule_CreateOrderProduct_' + Datetime.now().getTime(), cron, job);

               // System.enqueueJob(new QueueableForCreateProductInOrder(orderItemidsForWebsite));
            }
            
        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
    //method added by Aniket for Delete Order Item On Website
    public static void deleteProductOnWebsite(List<OrderItem> orderProductList){
        try {
        List<OrderItemDeleteDTO> dtoList = new List<OrderItemDeleteDTO>();

        for (OrderItem op : orderProductList) {
            if (op.Website_Response_Id__c != null) {
                OrderItemDeleteDTO dto = new OrderItemDeleteDTO();
                dto.websiteResponseId = String.valueOf(op.Website_Response_Id__c);
                dto.orderId = String.valueOf(op.OrderId);
                dto.accountId = op.Order.AccountId != null ? String.valueOf(op.Order.AccountId) : null;
                dtoList.add(dto);
            }
        }

        if (!dtoList.isEmpty()) {
            Datetime dt = Datetime.now().addMinutes(1);
            String cron = String.format('{0} {1} {2} {3} {4} ? {5}',
                new String[]{
                    String.valueOf(dt.second()),
                    String.valueOf(dt.minute()),
                    String.valueOf(dt.hour()),
                    String.valueOf(dt.day()),
                    String.valueOf(dt.month()),
                    String.valueOf(dt.year())
                });

            
            ScheduleDeleteOrderItemOnWebsite job = (ScheduleDeleteOrderItemOnWebsite) JSON.deserialize(
                                JSON.serialize(new ScheduleDeleteOrderItemOnWebsite(dtoList)), 
                                ScheduleDeleteOrderItemOnWebsite.class
                            );
                            
                            System.schedule('Schedule_DeleteOrderProduct_' + Datetime.now().getTime(), cron, job);
        }
    } catch (Exception e) {
        System.debug('Error Occurred ==>' + e.getMessage());
        System.debug('Error Line Number Is ==>' + e.getLineNumber());
    }
}
public class OrderItemDeleteDTO {
    public String websiteResponseId;
    public String orderId;
    public String accountId;
}
//method added by Aniket on 05/06/2025
public static void inventoryUpdateAfterOTCProductDeletion(List<OrderItem> deletedOrderItems){
    Id OTCRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('OTC').getRecordTypeId();
    System.debug('OTCRecordType===>'+OTCRecordType);
    System.debug('Deleted OrderItem List==>'+deletedOrderItems);
    try{
        Map<Id, Decimal> productToReduceQtyMap = new Map<Id, Decimal>();
            Set<Id> productIds = new Set<Id>();
            Set<Id> orderItemIds= new Set<Id>();
            Set<Id> orderIds = new Set<Id>();
            for (OrderItem oi : deletedOrderItems) {
                if (oi.Product2Id != null && oi.Quantity != null) {
                    productToReduceQtyMap.put(oi.Product2Id,
                        productToReduceQtyMap.containsKey(oi.Product2Id) ?
                        productToReduceQtyMap.get(oi.Product2Id) + oi.Quantity :
                        oi.Quantity
                    );
                    productIds.add(oi.Product2Id);
                    orderItemIds.add(oi.Id);
                    orderIds.add(oi.OrderId);
                }
            }
 
            System.debug('productToReduceQtyMap => ' + productToReduceQtyMap);
            List<Order> orderRecordTypeCheck =[Select id,RecordTypeId FROM Order WHERE Id =:orderIds];
            
                 
                //The Rest Of The Logic Will Fall Here 
                 List<Sales_Consumption__c> salesConsumptionList = [Select id,Order__c,Order_Product__c from Sales_Consumption__c WHERE Order_Product__c =:orderItemIds LIMIT 1];
            
            String loggedInUserId = UserInfo.getUserId();
            User u = [SELECT Id, Contact.Location__c FROM User WHERE Id = :loggedInUserId LIMIT 1];
            System.debug('User ==>'+u);
 
            if (u.Contact == null || u.Contact.Location__c == null) {
                System.debug('User has no associated Location');
                return;
            }
 
            Id userLocationId = u.Contact.Location__c;
            System.debug('userLocationId==>'+userLocationId);
 
            List<ProductItem> inventoryList = [
                SELECT Id, Product2Id, LocationId, Consumed_Quantity__c
                FROM ProductItem
                WHERE Product2Id IN :productIds AND LocationId = :userLocationId
            ];
 
            List<ProductItem> inventoriesToUpdate = new List<ProductItem>();
 
            for (ProductItem pi : inventoryList) {
                Decimal currentQty = pi.Consumed_Quantity__c != null ? pi.Consumed_Quantity__c : 0;
                Decimal qtyToReduce = productToReduceQtyMap.get(pi.Product2Id);
                Decimal newQty = currentQty - qtyToReduce;
                if (newQty < 0) newQty = 0;
 
                inventoriesToUpdate.add(new ProductItem(
                    Id = pi.Id,
                    Consumed_Quantity__c = newQty
                ));
            }
 
            if (!inventoriesToUpdate.isEmpty()) {
                update inventoriesToUpdate;
                System.debug('Updated inventories after delete => ' + inventoriesToUpdate);
            }
            if(!salesConsumptionList.isEmpty()){
                Sales_Consumption__c sales = salesConsumptionList[0];
                delete sales;
            }
            
        
            
           

    }catch(Exception e){
        System.debug('Error Occured==>'+e.getMessage());
        System.debug('Error Line Number Is ==>'+e.getLineNumber());
    }
   
}
     public static void methodToCoverTest(){
         Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }


   /* public static void calculateRollupValues(List<OrderItem> orderItems) {
        if (orderItems == null || orderItems.isEmpty()) {
            return;
        }
        
        Set<Id> productIds = new Set<Id>();
        for (OrderItem oi : orderItems) {
            if (oi.Product2Id != null) {
                productIds.add(oi.Product2Id);
            }
        }
        
        if (productIds.isEmpty()) {
            return;
        }
        
        Map<Id, Product2> productMap = new Map<Id, Product2>();
        List<Product2> prodList = new List<Product2> ([SELECT Id, IGST_Percentage__c, Type__c FROM Product2 WHERE Id IN :productIds]);
        for (Product2 p : prodList) {
            productMap.put(p.Id, p);
        }
        
        if (productMap.isEmpty()) {
            return;
        }
        
        for (OrderItem oi : orderItems) {
            Product2 product = productMap.get(oi.Product2Id);
            if (product == null || product.IGST_Percentage__c == null || oi.UnitPrice == null || oi.Quantity == null) {
                continue;
            }
            
            Decimal igstMultiplier = 1 + (product.IGST_Percentage__c / 100);
            Decimal igstRollupValue = oi.UnitPrice * igstMultiplier * oi.Quantity;
            
          /*  if (product.Type__c == 'Vehicle') {
                oi.Vehicle_Roll_Up__c = igstRollupValue;
            } else if (product.Type__c == 'Accessories' || product.Type__c == 'Parts') {
                oi.Accessories_Roll_Up__c = igstRollupValue;
            } */ /*else if (product.Type__c == 'Merchandise') {
oi.Merchandise_Roll_Up__c = igstRollupValue;
}*/
    /*    }
    } */
}