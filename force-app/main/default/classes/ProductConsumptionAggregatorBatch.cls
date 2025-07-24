global class ProductConsumptionAggregatorBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Product2Id
            FROM ProductItem 
            WHERE Manual_Created_Date__c >= :System.today().addMonths(-6)
        ]);
    }

    global void execute(Database.BatchableContext bc, List<ProductItem> items) {

        Set<Id> productItemIds = new Map<Id, ProductItem>(items).keySet();
        Set<Id> productIds = new Set<Id>();

        for(ProductItem pi : items){
            productIds.add(pi.Product2Id);    
        }

        List<ConsumptionRecord> allConsumption = new List<ConsumptionRecord>();

        // --- Fetch Sales Consumption ---
        for (Sales_Consumption__c sale : [
            SELECT Id, CreatedDate, Quantity_Consumed__c, Dealer__c, Product__c,
                   Product_Inventory__r.Product2Id, Manual_Date_Test__c,
                   Product_Inventory__r.Account__c, Order__r.AccountId
            FROM Sales_Consumption__c
            WHERE Product__c IN :productIds
            AND Manual_Date_Test__c >= :System.today().addMonths(-6)
            AND Order__r.Dealer__r.Type != 'Customer' AND Order__r.Account.Type != 'Customer'
        ]) {
            allConsumption.add(new ConsumptionRecord(
                sale.Order__r.AccountId,
                sale.Product__c,
                sale.Manual_Date_Test__c,
                sale.Quantity_Consumed__c
            ));
        }

        // --- Fetch Product Consumed ---
        for (ProductConsumed consumed : [
            SELECT Id, ProductItemId, Quantity_Consumed__c, QuantityConsumed, Product2Id, WorkOrder.Service_Center__c,
                   CreatedDate
            FROM ProductConsumed
            WHERE Product2Id IN :productIds
            AND Manual_Created_Date__c >= :System.today().addMonths(-6)
            AND WorkOrder.Service_Center__r.Type != 'Customer'
        ]) {
            allConsumption.add(new ConsumptionRecord(
                consumed.WorkOrder.Service_Center__c,
                consumed.Product2Id,
                consumed.CreatedDate.date(),
                consumed.QuantityConsumed
            ));
        }

        // ========== Existing Monthly Logic ==========

        Map<String, ProductConsumptionTracking__c> trackingMap = new Map<String, ProductConsumptionTracking__c>();
        Map<String, Date> firstConsumptionMap = new Map<String, Date>();

        for (ConsumptionRecord rec : allConsumption) {
            if (rec.DealerId == null || rec.ProductId == null || rec.ConsumedDate == null) continue;

            Date created = rec.ConsumedDate;
            Integer day = created.day();
            Date monthStart = Date.newInstance(created.year(), created.month(), 1);
            String[] monthNames = new List<String>{ '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' };
            String monthLabel = monthNames[monthStart.month()] + ' ' + monthStart.year();
            String key = rec.DealerId + '-' + rec.ProductId + '-' + monthLabel;

            if (!trackingMap.containsKey(key)) {
                ProductConsumptionTracking__c t = new ProductConsumptionTracking__c();
                t.Account__c = rec.DealerId;
                t.Product__c = rec.ProductId;
                t.Month_Name__c = monthLabel;
                t.Month_Start_Date__c = monthStart;
                t.Bucket_Start_Date__c = monthStart;
                t.First_Half_Start_Date__c = monthStart;
                t.First_Half_End_Date__c = monthStart.addDays(14);
                t.Second_Half_Start_Date__c = monthStart.addDays(15);
                t.Second_Half_End_Date__c = monthStart.addMonths(1).addDays(-1);
                t.First_Half_Qty__c = 0;
                t.Second_Half_Qty__c = 0;
                trackingMap.put(key, t);
                firstConsumptionMap.put(key, created);
            }

            ProductConsumptionTracking__c tracking = trackingMap.get(key);
            if (day <= 15) tracking.First_Half_Qty__c += rec.Qty;
            else tracking.Second_Half_Qty__c += rec.Qty;

            if (created < firstConsumptionMap.get(key)) {
                firstConsumptionMap.put(key, created);
            }
        }

        for (ProductConsumptionTracking__c record : trackingMap.values()) {
            String key = record.Account__c + '-' + record.Product__c + '-' + record.Month_Name__c;
            record.First_Consumption_Date__c = firstConsumptionMap.get(key);
            record.Total_Month_Qty__c = record.First_Half_Qty__c + record.Second_Half_Qty__c;
        }

        insert trackingMap.values();

        // ========== New Fortnightly Forecast Inventory Logic ==========
 
        Map<String, FortnightlyForecastInventory__c> forecastMap = new Map<String, FortnightlyForecastInventory__c>();

        for (ConsumptionRecord rec : allConsumption) {
            if (rec.DealerId == null || rec.ProductId == null || rec.ConsumedDate == null) continue;

            String key = rec.DealerId + '-' + rec.ProductId;

            if (!forecastMap.containsKey(key)) {
                FortnightlyForecastInventory__c forecast = new FortnightlyForecastInventory__c();
                forecast.Account__c = rec.DealerId;
                forecast.Product__c = rec.ProductId;
                forecast.First_Consumed_Date__c = rec.ConsumedDate;
                forecast.Total_6_Month_Consumption__c = 0;
                forecast.Batch_Executed_Date__c = System.today();
                forecastMap.put(key, forecast);
            }

            FortnightlyForecastInventory__c f = forecastMap.get(key);
			
            if (rec.ConsumedDate < f.First_Consumed_Date__c) {
                f.First_Consumed_Date__c = rec.ConsumedDate; // Update earliest date
            }
            f.Total_6_Month_Consumption__c += rec.Qty;
        }

        insert forecastMap.values();
    }

    global void finish(Database.BatchableContext bc) {
        // Database.executeBatch(new POGenerationBatchForMSL(), 200);
    }

    // ========== Helper Classes ==========

    class ConsumptionRecord {
        public Id DealerId;
        public Id ProductId;
        public Date ConsumedDate;
        public Decimal Qty;

        public ConsumptionRecord(Id dealerId, Id productId, Date consumedDate, Decimal qty) {
            this.DealerId = dealerId;
            this.ProductId = productId;
            this.ConsumedDate = consumedDate;
            this.Qty = qty != null ? qty : 0;
        }
    }
}