global class MonthlyProductConsumptionBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('================== MonthlyProductConsumptionBatch ==================== ');
        return Database.getQueryLocator([
            SELECT Product__c, WorkOrder.Service_Center__c, Quantity_Consumed__c, CreatedDate
            FROM ProductConsumed
            WHERE CreatedDate >= :Date.today().addMonths(-6)
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        Map<String, List<ProductConsumed>> grouped = new Map<String, List<ProductConsumed>>();

        for (SObject s : scope) {
            ProductConsumed rec = (ProductConsumed)s;
            if (rec.Product__c == null || rec.WorkOrder.Service_Center__c == null) continue;

            String key = rec.Product__c + '|' + rec.WorkOrder.Service_Center__c;
            if (!grouped.containsKey(key)) grouped.put(key, new List<ProductConsumed>());
            grouped.get(key).add(rec);
        }

        List<ProductConsumptionTracking__c> trackingRecords = new List<ProductConsumptionTracking__c>();

        for (String key : grouped.keySet()) {
            List<ProductConsumed> records = grouped.get(key);

            // Wrap and sort
            List<ProductConsumedWrapper> wrapped = new List<ProductConsumedWrapper>();
            for (ProductConsumed pc : records) {
                wrapped.add(new ProductConsumedWrapper(pc));
            }
            wrapped.sort();

            if (wrapped.isEmpty()) continue;

            // Unwrap sorted records
            List<ProductConsumed> sortedRecords = new List<ProductConsumed>();
            for (ProductConsumedWrapper w : wrapped) {
                sortedRecords.add(w.record);
            }

            Date firstDate = sortedRecords[0].CreatedDate.date();
            Date lastDate = sortedRecords[sortedRecords.size() - 1].CreatedDate.date();

            List<String> parts = key.split('\\|');
            Id productId = Id.valueOf(parts[0]);
            Id dealerId = Id.valueOf(parts[1]);

            Date windowStart = firstDate;

            while (windowStart <= lastDate) {
                Date windowEnd = windowStart.addDays(29);
                Decimal totalQty = 0;

                for (ProductConsumed rec : sortedRecords) {
                    Date recDate = rec.CreatedDate.date();
                    if (recDate >= windowStart && recDate <= windowEnd) {
                        totalQty += (rec.Quantity_Consumed__c != null) ? rec.Quantity_Consumed__c : 0;
                    }
                }

                trackingRecords.add(new ProductConsumptionTracking__c(
                    Product__c = productId,
                    Account__c = dealerId,
                    First_Consumption_Date__c = windowStart,
                    Bucket_Start_Date__c = windowStart,
                    Bucket_End_Date__c = windowEnd,
                    Quantity_Consumed__c = totalQty,
                    Forecast_Quantity__c = totalQty,
                    MSL_Value__c = totalQty,
                    Last_MSL_Calculated_Date__c = System.today()
                ));

                windowStart = windowStart.addDays(30);
            }
        }

        if (!trackingRecords.isEmpty()) {
            upsert trackingRecords;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Chaining the POGenerationBatchForMSL Batch Class
	    Database.executeBatch(new POGenerationBatchForMSL(), 200);						
    }

    public class ProductConsumedWrapper implements Comparable {
        public ProductConsumed record;

        public ProductConsumedWrapper(ProductConsumed r) {
            this.record = r;
        }

        public Integer compareTo(Object o) {
            ProductConsumedWrapper other = (ProductConsumedWrapper)o;
            return this.record.CreatedDate.date().daysBetween(other.record.CreatedDate.date()) * -1;
        }
    }
}