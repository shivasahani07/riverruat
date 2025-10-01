public without sharing class ValidationOfEWForVehicleOrder {
    public static void preventEWForCertainCriteria(List<OrderItem> orderProductList) {
        try {
            Id vehicleTRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
            
            Set<Id> orderIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();

            for (OrderItem o : orderProductList) {
                if (o.OrderId != null) {
                    orderIds.add(o.OrderId);
                }
                if (o.Product2Id != null) {
                    productIds.add(o.Product2Id);
                }
            }

            // Fetch Orders with RecordTypeId
            Map<Id, Order> orderMap = new Map<Id, Order>(
                [SELECT Id, RecordTypeId FROM Order WHERE Id IN :orderIds]
            );

            // Fetch Product details
            Map<Id, Product2> productMap = new Map<Id, Product2>(
                [SELECT Id, ProductCode FROM Product2 WHERE Id IN :productIds]
            );

            // Existing EW in Orders
            List<OrderItem> existingOrderProdList = [
                SELECT Id, OrderId, Product2.ProductCode 
                FROM OrderItem 
                WHERE OrderId IN :orderIds 
                AND Product2.ProductCode LIKE '%RV-EW%'
            ];

            Map<Id, List<OrderItem>> existingEWByOrder = new Map<Id, List<OrderItem>>();
            for (OrderItem ewOI : existingOrderProdList) {
                if (!existingEWByOrder.containsKey(ewOI.OrderId)) {
                    existingEWByOrder.put(ewOI.OrderId, new List<OrderItem>());
                }
                existingEWByOrder.get(ewOI.OrderId).add(ewOI);
            }

            
            for (OrderItem oi : orderProductList) {
                Order parentOrder = orderMap.get(oi.OrderId);
                if (parentOrder != null && parentOrder.RecordTypeId == vehicleTRecordType) {
                    
                    String productCode = productMap.get(oi.Product2Id).ProductCode;

                    if (productCode != null && productCode.contains('RV-EW')) {
                        if (productCode != 'RV-EW-1' && productCode != 'RV-EW-4') {
                        oi.addError('Only RV-EW-1 and RV-EW-4 can be added to Vehicle Orders.');
                    }

                    if (existingEWByOrder.containsKey(oi.OrderId) && existingEWByOrder.get(oi.OrderId).size() > 0) {
                        oi.addError('Extended Warranty is already present for this Order.');
                    }
                    }
                    
                }
            }
        } catch (Exception e) {
            System.debug('Error Occurred ==> ' + e.getMessage());
            System.debug('Error Line Number ==> ' + e.getLineNumber());
        }
    }
}