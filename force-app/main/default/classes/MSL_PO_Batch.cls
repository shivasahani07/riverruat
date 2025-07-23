global class MSL_PO_Batch implements Database.Batchable<SObject>, Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new MSL_PO_Batch(), 100);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date sixMonthsAgo = Date.today().addMonths(-6);

        // Query ProductConsumed records for last 6 months where required fields are populated
        return Database.getQueryLocator([
            SELECT Id, Product__c, Product2Id, WorkOrderId, WorkOrderLineItemId, WorkOrder.Service_Center__c, CreatedDate, Quantity_Consumed__c, QuantityConsumed
            FROM ProductConsumed
            WHERE Product2Id != null AND WorkOrderId != null AND WorkOrder.Service_Center__c != null AND CreatedDate >= :sixMonthsAgo
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('Scope Size : ' + scope.size());

        Set<Id> productIds = new Set<Id>();
        Set<Id> dealerIds = new Set<Id>();

        // Collect all Product Ids and Dealer Ids
        for (SObject s : scope) {
            ProductConsumed con = (ProductConsumed) s;
            productIds.add(con.Product2Id);
            dealerIds.add(con.WorkOrder.Service_Center__c);
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, Minimum_Order_Qty__c FROM Product2 WHERE Id IN :productIds
        ]);

        // Group ProductConsumed records by Dealer + Product
        Map<String, List<ProductConsumed>> dealerProductMap = new Map<String, List<ProductConsumed>>();

        for (SObject s : scope) {
            ProductConsumed con = (ProductConsumed) s;
            String key = con.WorkOrder.Service_Center__c + '_' + con.Product2Id;

            if (!dealerProductMap.containsKey(key)) {
                dealerProductMap.put(key, new List<ProductConsumed>());
            }
            dealerProductMap.get(key).add(con);
        }

        List<ProductConsumptionTracking__c> trackingRecords = new List<ProductConsumptionTracking__c>();

        for (String key : dealerProductMap.keySet()) {
            List<String> parts = key.split('_');
            Id dealerId = (Id) parts[0];
            Id productId = (Id) parts[1];
            List<ProductConsumed> consumptionList = dealerProductMap.get(key);

            // Sort using Comparator
            List<ProductConsumedWrapper> wrappers = new List<ProductConsumedWrapper>();
            for (ProductConsumed pc : consumptionList) {
                wrappers.add(new ProductConsumedWrapper(pc));
            }
            wrappers.sort();

            consumptionList.clear();
            for (ProductConsumedWrapper wrapper : wrappers) {
                consumptionList.add(wrapper.record);
            }
            
            System.debug('Sorted List');
            for(ProductConsumed pc : consumptionList){
                System.debug(pc);
            }

            if (consumptionList.isEmpty()) continue;

            Date currentStart = consumptionList[0].CreatedDate.date();
            Date currentEnd = currentStart.addDays(29);

            Decimal totalQty = 0;

            for (ProductConsumed con : consumptionList) {
                Date conDate = con.CreatedDate.date();

                // If record falls outside current bucket, close and start new bucket
                if (conDate > currentEnd) {
                    // Store last bucket
                    trackingRecords.add(new ProductConsumptionTracking__c(
                        Account__c = dealerId,
                        Product__c = productId,
                        Quantity_Consumed__c = totalQty,
                        Consumption_Month_Year__c = currentStart.year() + '-' + currentStart.month(),
                        Consumption_Month_Start_Date__c = currentStart,
                        Bucket_Start_Date__c = currentStart,
                        Bucket_End_Date__c = currentEnd
                    ));
                    System.debug('Tracking Record: ' + currentStart + ' to ' + currentEnd + ' Qty: ' + totalQty);

                    // Reset bucket
                    currentStart = conDate;
                    currentEnd = currentStart.addDays(29);
                    totalQty = 0;
                }

                totalQty += con.Quantity_Consumed__c;
            }

            // Final bucket
            if (totalQty > 0) {
                trackingRecords.add(new ProductConsumptionTracking__c(
                    Account__c = dealerId,
                    Product__c = productId,
                    Quantity_Consumed__c = totalQty,
                    Consumption_Month_Year__c = currentStart.year() + '-' + currentStart.month(),
                    Consumption_Month_Start_Date__c = currentStart,
                    Bucket_Start_Date__c = currentStart,
                    Bucket_End_Date__c = currentEnd
                ));
                System.debug('------ FINAL ----- Tracking Record: ' + currentStart + ' to ' + currentEnd + ' Qty: ' + totalQty);
            }
        }

        if (!trackingRecords.isEmpty()) {
            insert trackingRecords;
            System.debug('Inserted ProductConsumptionTracking__c records: ' + trackingRecords.size());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch Completed');
    }

    // Inner wrapper class to sort ProductConsumed by CreatedDate
    public class ProductConsumedWrapper implements Comparable {
        public ProductConsumed record;

        public ProductConsumedWrapper(ProductConsumed rec) {
            this.record = rec;
        }

        public Integer compareTo(Object obj) {
            ProductConsumedWrapper other = (ProductConsumedWrapper) obj;

            Date thisDate = this.record.CreatedDate.date();
            Date otherDate = other.record.CreatedDate.date();

            if (thisDate == otherDate) return 0;
            return thisDate < otherDate ? -1 : 1;
        }
    }

}