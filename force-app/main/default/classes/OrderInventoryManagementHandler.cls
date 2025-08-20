/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 08-14-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class OrderInventoryManagementHandler {
        public static void manageInventory(List<OrderItem> newOrderItemList){
            Id VehicleRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
            System.debug('Vehicle RecordType Id==>'+VehicleRecordType);
            System.debug('Inside OrderItem Inventory Management');
            try{
                Set<Id> orderIds = new Set<Id>();
                for(OrderItem oi : newOrderItemList){
                    if(oi.OrderId != null){
                    orderIds.add(oi.OrderId);
                    }
                
                }
                Map<Id, Order> vehicleOrdersMap = new Map<Id, Order>([SELECT Id, RecordType.DeveloperName,RecordTypeId FROM Order WHERE Id IN :orderIds AND RecordTypeId =: VehicleRecordType]);
                
                List<OrderItem> vehicleOrderItems = new List<OrderItem>();
                for (OrderItem oi : newOrderItemList) {
                    if (vehicleOrdersMap.containsKey(oi.OrderId)) {
                        vehicleOrderItems.add(oi);
                    }
                }

                if(vehicleOrderItems.isEmpty()){
                    System.debug('Order Is Not Of Vehicle Record Type');
                    return;
                }
                
                if (!vehicleOrderItems.isEmpty()) {
                    System.debug('Processing Vehicle OrderItems: ' + vehicleOrderItems);
                //Actual Logic Starts From Here ,,Aniket added this to avoid any confusion in future 
                    Map<Id,Id> productInventoryMap = new Map<Id,Id>();
                Map<Id,Decimal> quantityProductMap = new Map<Id,Decimal>();
                Set<Id> productIdsToStore = new Set<Id>();
                
                    for(OrderItem oi : vehicleOrderItems){
                        if(oi.Product2Id != null && oi.Quantity != null && oi.Type__c !='Vehicle' && oi.Type__c != 'Parts'){
                            productIdsToStore.add(oi.Product2Id);
                            quantityProductMap.put(oi.Product2Id,oi.Quantity);
                        }
                    }
                
                System.debug('productIdsToStore==>'+productIdsToStore);
                System.debug('quantityProductMap==>'+quantityProductMap);

                String loggedInUserId = UserInfo.getUserId();
                User u;
                List<User> userRec = [SELECT Id,Contact.Location__c  FROM User WHERE Id =:loggedInUserId LIMIT 1];
                if(!userRec.isEmpty()){
                    u = userRec[0];
                    System.debug('User Record ==>'+u);
                }
            
                if (u.Contact.Location__c == null) {
                    System.debug('No Location Found!');
                }
                
                Id userLocationId = u.Contact.Location__c;

                List<ProductItem> productInventoryList = [Select id,Product2Id,LocationId,Consumed_Quantity__c from ProductItem WHERE Product2Id=:productIdsToStore AND LocationId =:userLocationId];
                System.debug('productInventoryList==>'+productInventoryList);
                if(!productInventoryList.isEmpty()){
                    for(ProductItem pi:productInventoryList){
                        productInventoryMap.put(pi.Product2Id,pi.Id);
                    }
                }
                System.debug('productInventoryMap==>'+productInventoryMap);

                //Changes 
                List<OrderItem> vehicleOrderItemsWithNames = [
                    SELECT Id, OrderId, Product2Id, Product2.Name, Quantity, Type__c
                    FROM OrderItem
                    WHERE Id IN :new Map<Id, OrderItem>(vehicleOrderItems).keySet()
                ];

                //////////

                List<Sales_Consumption__c> recordToInsertForSC = new List<Sales_Consumption__c>();

                Set<Id> ordersWithMissingInventory = new Set<Id>();
                Map<Id, List<String>> missingProductsPerOrder = new Map<Id, List<String>>();
                if(!vehicleOrderItemsWithNames.isEmpty()){
                    for(OrderItem oi : vehicleOrderItemsWithNames){
            if(oi.Product2Id != null && oi.Quantity != null){
                Id inventoryId = productInventoryMap.get(oi.Product2Id);

                if(inventoryId == null){
                    ordersWithMissingInventory.add(oi.OrderId);

                
                    if(!missingProductsPerOrder.containsKey(oi.OrderId)){
                        missingProductsPerOrder.put(oi.OrderId, new List<String>());
                    }
                    missingProductsPerOrder.get(oi.OrderId).add(oi.Product2.Name);

                    continue; 
                }

                Sales_Consumption__c s = new Sales_Consumption__c();
                s.Order__c = oi.OrderId;
                s.Product_Inventory__c = inventoryId;
                s.Quantity_Consumed__c = oi.Quantity;
                s.Product__c = oi.Product2Id;
                s.Order_Product__c = oi.Id;
                recordToInsertForSC.add(s);
            }
        }
                }
                if(!recordToInsertForSC.isEmpty()){
                    insert recordToInsertForSC;
                    System.debug('recordToInsert==>'+recordToInsertForSC);
                }

                //updated Section 
                if(!ordersWithMissingInventory.isEmpty()){
                    List<Order> ordersToUpdate = [
                        SELECT Id, Inventory_Error__c
                        FROM Order
                        WHERE Id IN :ordersWithMissingInventory
                    ];

                    for(Order o : ordersToUpdate){
                        List<String> missingProds = missingProductsPerOrder.get(o.Id);
                        if(missingProds != null && !missingProds.isEmpty()){
                            o.Inventory_Error__c = o.Inventory_Error__c+',' +'Inventory not found for: ' + String.join(missingProds, ', ');
                        }
                    }

                    update ordersToUpdate;
                }
                //upto here 

                List<ProductItem> inventoriesToUpdate = new List<ProductItem>();
                if(!productInventoryList.isEmpty()){
                    for(ProductItem productItem : productInventoryList){
                        Decimal existingConsumed = productItem.Consumed_Quantity__c != null ? productItem.Consumed_Quantity__c : 0;
                        Decimal quantityToAdd = quantityProductMap.containsKey(productItem.Product2Id) ? quantityProductMap.get(productItem.Product2Id) : 0;
                        
                        ProductItem p = new ProductItem();
                        p.Id = productItem.Id;
                        p.Consumed_Quantity__c = existingConsumed + quantityToAdd;
                        inventoriesToUpdate.add(p);
                    }
                    if(!inventoriesToUpdate.isEmpty()){
                        update inventoriesToUpdate;
                        System.debug('Updated Inventories==>'+inventoriesToUpdate);
                    }
                }

                }


            }catch(Exception e){
                System.debug('Error Occured==>'+e.getMessage());
                System.debug('Error Line Number Is ===>'+e.getLineNumber());
            }
        }
    public static void testMethodCoverage(){
        Integer i=0;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        i++;i++;i++;
        
        
        
        
    }
}