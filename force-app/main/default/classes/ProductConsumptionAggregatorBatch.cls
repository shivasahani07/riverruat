global class ProductConsumptionAggregatorBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Product2Id 
            FROM ProductItem 
            WHERE Manual_Created_Date__c >= :System.today().addMonths(-6)]);
    }

    global void execute(Database.BatchableContext bc, List<ProductItem> items) {
        Set<Id> productItemIds = new Map<Id, ProductItem>(items).keySet();
        Set<Id> productIds = new Set<Id>();
        
        for(ProductItem pi : items){
        	productIds.add(pi.Product2Id);    
        }
        System.debug('productIds : ' + productIds);
        
        List<ConsumptionRecord> allConsumption = new List<ConsumptionRecord>();

        // Query Sales Consumption
        for (Sales_Consumption__c sale : [
            SELECT Id, CreatedDate, Quantity_Consumed__c, Dealer__c, Product__c, Product_Inventory__r.Product2Id, 
            Product_Inventory__r.Account__c, Order__c, Order__r.AccountId
            FROM Sales_Consumption__c
            WHERE Product__c IN :productIds
            AND Manual_Date_Test__c >= :System.today().addMonths(-6)
            //WHERE Product_Inventory__c IN :productItemIds
        ]) {
            allConsumption.add(new ConsumptionRecord(
                sale.Order__r.AccountId,
                sale.Product__c,
                sale.CreatedDate.date(),
                sale.Quantity_Consumed__c
            ));
        }
        System.debug('Sales Consumption Records Size : ' + allConsumption.size());

        // Query Product Consumed
        for (ProductConsumed consumed : [
            SELECT Id, CreatedDate, ProductItemId, Quantity_Consumed__c, QuantityConsumed, Product2Id, WorkOrder.Service_Center__c
            FROM ProductConsumed
            WHERE Product2Id IN :productIds
            AND CreatedDate >= :System.today().addMonths(-6)
            //WHERE ProductItemId IN :productItemIds
        ]) {
            allConsumption.add(new ConsumptionRecord(
                consumed.WorkOrder.Service_Center__c,
                consumed.Product2Id,
                consumed.CreatedDate.date(),
                consumed.QuantityConsumed
            ));
        }
        System.debug('Product Consumed Records Size : ' + allConsumption.size());
        
        /*
        // Query Product Transfers
        for (ProductTransfer transfer : [
            SELECT Id, CreatedDate, QuantitySent, Product2Id, Product_Inventory__c
            FROM ProductTransfer
            WHERE Product2Id IN: productIds
            AND CreatedDate >= :System.today().addMonths(-6)
            //WHERE Product_Inventory__c IN :productItemIds
        ]) {
            allConsumption.add(new ConsumptionRecord(
                null,
                transfer.Product2Id,
                transfer.CreatedDate.date(),
                transfer.QuantitySent
            ));
        }
        System.debug('Product Transfer Records Size : ' + allConsumption.size());
        */

        // Now group and aggregate into ProductConsumptionTracking__c
        Map<String, ProductConsumptionTracking__c> trackingMap = new Map<String, ProductConsumptionTracking__c>();
        Map<String, Date> firstConsumptionMap = new Map<String, Date>();

        Integer skippingCount = 0;
        for (ConsumptionRecord rec : allConsumption) {
            System.debug('Inside For');
            if (rec.DealerId == null || rec.ProductId == null || rec.ConsumedDate == null) {
                skippingCount++;
                continue;
            }
            System.debug('skippingCount : ' + skippingCount);

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

                new debugMethodCall(t.Account__c, t.Product__c, t.Month_Name__c, t.Month_Start_Date__c, t.First_Half_Start_Date__c);
                System.debug('************ New PCT *************');
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
        System.debug('trackingMap.values() : ' + trackingMap.values().size());
    }

    global void finish(Database.BatchableContext bc) {

        //Calling the POGenerationBatchForMSL to create PO
        //Database.executeBatch(new POGenerationBatchForMSL(), 200);
    }

    // Helper class
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

    public class debugMethodCall{

        public debugMethodCall(String accId, String productId, String monthName, Date monthStartDate, Date firstHalfStartDate){
            System.debug('-----------------------------------------------------');
            System.debug('AccId : ' + accId);
            System.debug('productId : ' + productId);
            System.debug('Month_Name__c : ' + monthName);
            System.debug('Month_Start_Date__c : ' + monthStartDate);
            System.debug('First_Half_Start_Date__c : ' + firstHalfStartDate);
            System.debug('-----------------------------------------------------');
        }
    }
}