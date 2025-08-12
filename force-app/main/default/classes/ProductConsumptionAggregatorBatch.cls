global class ProductConsumptionAggregatorBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Fetch the control record
        MSL_Batch_Control__mdt control = [
            SELECT Enable_Batch__c 
            FROM MSL_Batch_Control__mdt 
            WHERE DeveloperName = 'ProductConsumptionAggregator_Control'
            LIMIT 1
        ];
        
        for(ProductItem itm : [SELECT Id, Product2Id, Product2.Name, Product2.Type__c, Product_Type__c
            //FROM ProductItem WHERE Manual_Created_Date__c >= :System.today().addDays(15).addMonths(-6)]){
            FROM ProductItem WHERE Manual_Created_Date__c >= :System.today().addMonths(-6)
			AND (Product_Type__c = 'Accessories' OR Product_Type__c = 'Parts')
         ]) {
            System.debug(itm.Product2.Name);
        }
        
        if (!control.Enable_Batch__c) {
            System.debug('Batch execution disabled via Custom Metadata.');
            return Database.getQueryLocator([SELECT Id FROM ProductItem WHERE Id = null]);
        }
        
        return Database.getQueryLocator([
            SELECT Id, Product2Id, Product2.Name, Product2.Type__c, Product_Type__c
            //FROM ProductItem WHERE Manual_Created_Date__c >= :System.today().addDays(15).addMonths(-6)]){
            FROM ProductItem WHERE Manual_Created_Date__c >= :System.today().addMonths(-6)
            AND (Product_Type__c = 'Accessories' OR Product_Type__c = 'Parts')
        ]);        
    }

    global void execute(Database.BatchableContext bc, List<ProductItem> items) {
        Set<Id> productIds = new Set<Id>();
        for(ProductItem pi : items) {
            productIds.add(pi.Product2Id);    
        }
        
        // --------------------------------------------------- STORE THE VERY FIRST CONSUMPTION DATE ----------------------------------------------------- //
		/*
        Map<String, Date> trueFirstConsumptionMap = new Map<String, Date>();
        
        for (Sales_Consumption__c sale : [
            SELECT Order__r.AccountId, Product__c, Manual_Date_Test__c
            FROM Sales_Consumption__c
            WHERE Order__r.Dealer__r.Type != 'Customer'
              AND Order__r.Account.Type != 'Customer'
              AND Manual_Date_Test__c != NULL
        ]) {
            String key = sale.Order__r.AccountId + '|' + sale.Product__c;
            Date dateVal = sale.Manual_Date_Test__c;
        
            if (!trueFirstConsumptionMap.containsKey(key) || dateVal < trueFirstConsumptionMap.get(key)) {
                trueFirstConsumptionMap.put(key, dateVal);
            }
        }
        
        for (ProductConsumed pc : [
            SELECT WorkOrder.Service_Center__c, Product2Id, CreatedDate
            FROM ProductConsumed
            WHERE WorkOrder.Service_Center__r.Type != 'Customer'
        ]) {
            String key = pc.WorkOrder.Service_Center__c + '|' + pc.Product2Id;
            Date dateVal = pc.CreatedDate.date();
        
            if (!trueFirstConsumptionMap.containsKey(key) || dateVal < trueFirstConsumptionMap.get(key)) {
                trueFirstConsumptionMap.put(key, dateVal);
            }
        }
		*/
		// ---------------------------------------------- QUERY FOR SIX MONTHS CONSUMPTION ------------------------------------------------------- //
        List<ConsumptionRecord> allConsumption = new List<ConsumptionRecord>();
        
        // Fetch Sales Consumption
        for (Sales_Consumption__c sale : [
            SELECT Id, CreatedDate, Quantity_Consumed__c, Dealer__c, Product__c, Product__r.Type__c,
                   Product_Inventory__r.Product2Id, Manual_Date_Test__c,
                   Product_Inventory__r.Account__c, Order__r.AccountId
            FROM Sales_Consumption__c
            WHERE Product__c IN :productIds
            AND Manual_Date_Test__c >= :System.today().addMonths(-6)
            //AND Manual_Date_Test__c >= :System.today().addDays(15).addMonths(-6)
            AND Order__r.Dealer__r.Type != 'Customer' AND Order__r.Account.Type != 'Customer'
            //AND Order__r.Dealer__r.Type != NULL AND Order__r.Dealer__r.Type != 'Customer'  
            //AND Order__r.Account.Type !=  NULL AND Order__r.Account.Type != 'Customer'
            //AND Order__r.Dealer__r.Type != NULL AND Order__r.Dealer__r.Type = 'Service Center'
            //AND Order__r.Account.Type !=  NULL AND Order__r.Account.Type = 'Service Center'
            AND (Product__r.Type__c = 'Parts' OR Product__r.Type__c = 'Accessories')
        ]) {
            allConsumption.add(new ConsumptionRecord(
                sale.Order__r.AccountId,
                sale.Product__c,
                sale.Manual_Date_Test__c,
                sale.Quantity_Consumed__c
            ));
        }

        // Fetch Product Consumed
        for (ProductConsumed consumed : [
            SELECT Id, ProductItemId, Quantity_Consumed__c, QuantityConsumed, Product2Id, Product2.Type__c, WorkOrder.Service_Center__c,
                   CreatedDate
            FROM ProductConsumed
            WHERE Product2Id IN :productIds
            AND Manual_Created_Date__c >= :System.today().addMonths(-6)
            //AND Manual_Created_Date__c >= :System.today().addDays(15).addMonths(-6)
            AND WorkOrder.Service_Center__r.Type != 'Customer'
            //AND WorkOrder.Service_Center__r.Type != NULL AND WorkOrder.Service_Center__r.Type = 'Service Center'
            AND (Product2.Type__c = 'Parts' OR Product2.Type__c = 'Accessories')
        ]) {
            allConsumption.add(new ConsumptionRecord(
                consumed.WorkOrder.Service_Center__c,
                consumed.Product2Id,
                consumed.CreatedDate.date(),
                consumed.QuantityConsumed
            ));
        }
        
        /*
        // Fetch Sales Consumption
        for (Sales_Consumption__c sale : [
            SELECT Id, CreatedDate, Quantity_Consumed__c, Dealer__c, Product__c,
                   Product_Inventory__r.Product2Id, Manual_Date_Test__c,
                   Product_Inventory__r.Account__c, Order__r.AccountId
            FROM Sales_Consumption__c
            //WHERE Manual_Date_Test__c >= :System.today().addMonths(-6)
            WHERE Manual_Date_Test__c >= :System.today().addDays(15).addMonths(-6)
            AND Order__r.Dealer__r.Type != 'Customer' AND Order__r.Account.Type != 'Customer'
        ]) {
            allConsumption.add(new ConsumptionRecord(
                sale.Order__r.AccountId,
                sale.Product__c,
                sale.Manual_Date_Test__c,
                sale.Quantity_Consumed__c
            ));
        }

        // Fetch Product Consumed
        for (ProductConsumed consumed : [
            SELECT Id, ProductItemId, Quantity_Consumed__c, QuantityConsumed, Product2Id, WorkOrder.Service_Center__c,
                   CreatedDate
            FROM ProductConsumed
            //WHERE Manual_Created_Date__c >= :System.today().addMonths(-6)
            WHERE Manual_Created_Date__c >= :System.today().addDays(15).addMonths(-6)
            AND WorkOrder.Service_Center__r.Type != 'Customer'
        ]) {
            allConsumption.add(new ConsumptionRecord(
                consumed.WorkOrder.Service_Center__c,
                consumed.Product2Id,
                consumed.CreatedDate.date(),
                consumed.QuantityConsumed
            ));
        }
        */
        
        // ========== NEW DYNAMIC PERIOD LOGIC ==========
        Map<String, Date> firstConsumptionMap = new Map<String, Date>();
        Map<String, List<ConsumptionRecord>> consumptionByKey = new Map<String, List<ConsumptionRecord>>();
        Map<String, List<Decimal>> monthlyConsumptionMap = new Map<String, List<Decimal>>();
        Map<String, Decimal> totalConsumptionMap = new Map<String, Decimal>();

        // Group records by account+product and find first consumption date
        for (ConsumptionRecord rec : allConsumption) {
            if (rec.DealerId == null || rec.ProductId == null || rec.ConsumedDate == null) continue;
            
            String key = rec.DealerId + '|' + rec.ProductId;
            
            // Initialize maps
            if (!firstConsumptionMap.containsKey(key)) {
                firstConsumptionMap.put(key, rec.ConsumedDate);
                consumptionByKey.put(key, new List<ConsumptionRecord>());
                monthlyConsumptionMap.put(key, new List<Decimal> {0,0,0,0,0,0});
                totalConsumptionMap.put(key, 0);
            }
            
            // Update first consumption date if earlier
            if (rec.ConsumedDate < firstConsumptionMap.get(key)) {
                firstConsumptionMap.put(key, rec.ConsumedDate);
            }
            
            consumptionByKey.get(key).add(rec);
        }
            
        /*
        // Calculate consumption for dynamic periods
        for (String key : consumptionByKey.keySet()) {
            Date firstDate = firstConsumptionMap.get(key);
            List<Decimal> monthlyQtys = monthlyConsumptionMap.get(key);
            Decimal totalQty = 0;
            
            for (ConsumptionRecord rec : consumptionByKey.get(key)) {
                // Calculate period index (0-5) based on months from first date
                Integer monthsDiff = firstDate.monthsBetween(rec.ConsumedDate);
                
                // Ensure we only consider last 6 periods
                if (monthsDiff >= 0 && monthsDiff < 6) {
                    monthlyQtys[monthsDiff] += rec.Qty;
                    totalQty += rec.Qty;
                }
            }
            
            totalConsumptionMap.put(key, totalQty);
        }
        */
        
        // Calculate consumption for dynamic periods
        for (String key : consumptionByKey.keySet()) {
            Date firstDate = firstConsumptionMap.get(key);
            List<Decimal> monthlyQtys = monthlyConsumptionMap.get(key);
            Decimal totalQty = 0;
        
            // Build explicit rolling periods
            List<Date> periodStarts = new List<Date>();
            List<Date> periodEnds = new List<Date>();
            Date start = firstDate;
        
            for (Integer i = 0; i < 6; i++) {
                //Date endDate = start.addMonths(1).addDays(-1);
                Date endDate = start.addMonths(1);
                periodStarts.add(start);
                periodEnds.add(endDate);
                start = endDate.addDays(1);
            }
        
            // Assign consumption to correct bucket based on actual dates
            for (ConsumptionRecord rec : consumptionByKey.get(key)) {
                for (Integer i = 0; i < 6; i++) {
                    if (rec.ConsumedDate >= periodStarts[i] && rec.ConsumedDate <= periodEnds[i]) {
                        monthlyQtys[i] += rec.Qty;
                        totalQty += rec.Qty;
                        break; // once added, stop checking further buckets
                    }
                }
            }
        
            totalConsumptionMap.put(key, totalQty);
        }

        // Create ProductConsumptionTracking records
        List<ProductConsumptionTracking__c> trackingToInsert = new List<ProductConsumptionTracking__c>();

        for (String key : firstConsumptionMap.keySet()) {
            //Date trueFirstDate = trueFirstConsumptionMap.get(key);
            
            List<Decimal> monthlyQtys = monthlyConsumptionMap.get(key);
            String[] parts = key.split('\\|');
            Id accountId = (Id)parts[0];
            Id productId = (Id)parts[1];
            Date firstDate = firstConsumptionMap.get(key);
            
            Date previousEnd = null;

            for (Integer i = 0; i < 6; i++) {
                
                Date periodStart;
                if (i == 0) {
                    periodStart = firstDate; // first period starts at first consumption date
                } else {
                    periodStart = previousEnd.addDays(1); // start next day after last period end
                }
                
                //Date periodEnd = periodStart.addMonths(1).addDays(-1);
                Date periodEnd = periodStart.addMonths(1);
                previousEnd = periodEnd;
            
                // Define dynamic halves
                Date firstHalfEnd = periodStart.addDays(14);
                if (firstHalfEnd > periodEnd) firstHalfEnd = periodEnd;
                
                Date firstHalfStart = periodStart;
                Date secondHalfStart = firstHalfEnd.addDays(1);
                Date secondHalfEnd = periodEnd;
            
                // Month Name as Date Range
                String monthName = Datetime.newInstance(periodStart, Time.newInstance(0, 0, 0, 0)).format('dd MMM yyyy') 
                                 + ' - ' +
                                   Datetime.newInstance(periodEnd, Time.newInstance(0, 0, 0, 0)).format('dd MMM yyyy');
            
                // Calculate qty only for this rolling window
                Decimal totalQty = 0;
                Decimal firstHalfQty = 0;
                Decimal secondHalfQty = 0;
                
                for (ConsumptionRecord rec : consumptionByKey.get(key)) {
                    if (rec.ConsumedDate >= periodStart && rec.ConsumedDate <= periodEnd) {
                        totalQty += rec.Qty;
                        if (rec.ConsumedDate <= firstHalfEnd) {
                            firstHalfQty += rec.Qty;
                        } else {
                            secondHalfQty += rec.Qty;
                        }
                    }
                }
                
                // Create Product Consumption Tracking Records
                ProductConsumptionTracking__c pct = new ProductConsumptionTracking__c(
                    Account__c = accountId,
                    Product__c = productId,
                    Month_Name__c = monthName, 
                    Month_Start_Date__c = periodStart,
                    Month_End_Date__c = periodEnd,
                    Total_Month_Qty__c = Math.roundToLong(totalQty),
                    //First_Consumption_Date__c = trueFirstDate,					// This is the date of first ever consumption
                    //First_Consumption_Date__c = mslFirstDateMap.get(key),
                    Six_Month_First_Consumption_Date__c = firstDate,			// This is the first date of consumption in last six months
                    First_Half_Start_Date__c = firstHalfStart,
                    First_Half_End_Date__c = firstHalfEnd,
                    Second_Half_Start_Date__c = secondHalfStart,
                    Second_Half_End_Date__c = secondHalfEnd,
                    First_Half_Qty__c = firstHalfQty,
                    Second_Half_Qty__c = secondHalfQty,
                    Batch_Executed_Date__c = System.today()
                );
                
                trackingToInsert.add(pct);
            }
        }
        insert trackingToInsert;
		
        // ----------------------------------------------------- CAPTURE DEALER EXISTING INVENTORY ------------------------------------------------------------ //
        Set<Id> accountIds = new Set<Id>();
        for(String key : firstConsumptionMap.keySet()) {
            accountIds.add((Id) key.split('\\|')[0]);
        }
		
        Map<Id, Id> accountToLocation = new Map<Id, Id>();
        for(Account acc : [SELECT Id, Location__c FROM Account WHERE Id IN :accountIds]) {
            if(acc.Location__c != null) {
                accountToLocation.put(acc.Id, acc.Location__c);
            }
        }
        
        Set<Id> locationIds = new Set<Id>(accountToLocation.values());
        Set<Id> productIdsForQuery = new Set<Id>();
        
        for(String key : firstConsumptionMap.keySet()) {
            productIdsForQuery.add((Id) key.split('\\|')[1]);
        }
        
        Map<String, Decimal> inventoryMap = new Map<String, Decimal>();

        for(ProductItem pi : [
            SELECT Id, LocationId, Product2Id, Quantity_In_Hand__c
            FROM ProductItem
            WHERE LocationId IN :locationIds
            AND Product2Id IN :productIdsForQuery
        ]) {
            String mapKey = pi.LocationId + '|' + pi.Product2Id;
            
            if(!inventoryMap.containsKey(mapKey)) {
                inventoryMap.put(mapKey, 0);
            }
            inventoryMap.put(mapKey, inventoryMap.get(mapKey) + (pi.Quantity_In_Hand__c != null ? pi.Quantity_In_Hand__c : 0));
        }
                
        // ----------------------------------------------------- Create FortnightlyForecastInventory records ----------------------------------------------------- //
        List<FortnightlyForecastInventory__c> forecastToInsert = new List<FortnightlyForecastInventory__c>();
        Set<Id> productIdSet = new Set<Id>();
        
        for (String key : firstConsumptionMap.keySet()) {
            productIdSet.add((Id) key.split('\\|')[1]);
        }
        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, Minimum_Order_Qty__c FROM Product2 WHERE Id IN :productIdSet
        ]);
        
        for (String key : firstConsumptionMap.keySet()) {
            //Date trueFirstDate = trueFirstConsumptionMap.get(key);
            
            String[] parts = key.split('\\|');
            Id accountId = (Id)parts[0];
            Id productId = (Id)parts[1];
            List<Decimal> monthlyQtys = monthlyConsumptionMap.get(key);
            Decimal totalQty = totalConsumptionMap.get(key);
            
            Id locId = accountToLocation.get(accountId);
            Decimal availableQty = 0;
            
            if(locId != null) {
                String invKey = locId + '|' + productId;
                if(inventoryMap.containsKey(invKey)) {
                    availableQty = inventoryMap.get(invKey);
                }
            }
            // ----------------------------MSL Logic------------------------------ //
            // Condition 1: Last 2 Months should not be 0
            if (monthlyQtys[4] == 0 && monthlyQtys[5] == 0) continue;
            
            Integer validMonths = 0;
            Decimal totalValid = 0;
            for (Decimal qty : monthlyQtys) {
                if (qty > 0) {
                    validMonths++;
                    totalValid += qty;
                }
            }
            
            // Condition 2: Atleast in 4 months consumption should be there
            if (validMonths < 4) continue;
            
            Decimal avg = totalValid / validMonths;
            Decimal moq = productMap.containsKey(productId) 
                ? productMap.get(productId).Minimum_Order_Qty__c : 1;
                        
            // Condition 3: If MOQ is more than Average Quantity, then apply MOQ as finalQty & make checkbox TRUE
            Boolean isMOQApplied = false;
            Decimal finalQty;
            
            if (moq > avg && avg > 0) {
                finalQty = moq;
                isMOQApplied = true;
            } else {
                finalQty = avg;
            }
            
            // If finalQty is less than 0, skip
            if (finalQty <= 0) continue;
            
            
            forecastToInsert.add(new FortnightlyForecastInventory__c(
                Account__c = accountId,
                Product__c = productId,
                First_Consumed_Date__c = firstConsumptionMap.get(key),
                //Very_First_Consumption_Date__c = trueFirstDate,
                Six_Months_Average_Consumption__c = Math.roundToLong(finalQty),
                Total_6_Month_Consumption__c = totalQty,
                Batch_Executed_Date__c = System.today(),
                //Batch_Executed_Date__c = System.today().addDays(-10),
                Total_Consumption_Months__c = validMonths,
                MOQ_Applied__c = isMOQApplied,
                Available_Inventory_Qty__c = availableQty
            ));
        }
        
        if (!forecastToInsert.isEmpty()) insert forecastToInsert;
    }

    global void finish(Database.BatchableContext bc) {
        // Database.executeBatch(new POGenerationBatchForMSL(), 200);
    }
    
    
    // Helper Classes
    class ConsumptionRecord {
        @AuraEnabled public Id DealerId;
        @AuraEnabled public Id ProductId;
        @AuraEnabled public Date ConsumedDate;
        @AuraEnabled public Decimal Qty;

        public ConsumptionRecord(Id dealerId, Id productId, Date consumedDate, Decimal qty) {
            this.DealerId = dealerId;
            this.ProductId = productId;
            this.ConsumedDate = consumedDate;
            this.Qty = qty != null ? qty : 0;
        }
    }
}