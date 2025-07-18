global class POGenerationBatchForMSL2 implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext context) {
        Date sixMonthsAgo = Date.today().addMonths(-6);
        return Database.getQueryLocator([
            SELECT Id, Product__c, Account__c, Bucket_Start_Date__c, Total_Month_Qty__c, Processed_For_PO__c, Month_Start_Date__c,
                   Product__r.Minimum_Order_Qty__c
            FROM ProductConsumptionTracking__c
            WHERE Month_Start_Date__c >= :sixMonthsAgo
            AND Processed_For_PO__c = FALSE
        ]);
    }

    global void execute(Database.BatchableContext context, List<SObject> scope) {
        System.debug('scope : ' + scope.size());

        Map<Id, List<ProductConsumptionTracking__c>> dealerToRecords = new Map<Id, List<ProductConsumptionTracking__c>>();
        for (ProductConsumptionTracking__c rec : (List<ProductConsumptionTracking__c>)scope) {
            if (rec.Account__c == null) continue;

            if (!dealerToRecords.containsKey(rec.Account__c)) {
                dealerToRecords.put(rec.Account__c, new List<ProductConsumptionTracking__c>());
            }
            dealerToRecords.get(rec.Account__c).add(rec);
        }

        Map<String, ProductRequestLineItem> deletedItemMap = new Map<String, ProductRequestLineItem>();
        Map<Id, List<ProductRequestLineItem>> deletedItemsByAccount = new Map<Id, List<ProductRequestLineItem>>();

        for (ProductRequestLineItem item : [
            SELECT Id, Product2Id, AccountId, QuantityRequested, Is_Deleted_Item__c
            FROM ProductRequestLineItem
            WHERE Is_Deleted_Item__c = TRUE
        ]) {
            if (item.Product2Id != null && item.AccountId != null) {
                String key = item.Product2Id + '|' + item.AccountId;
                deletedItemMap.put(key, item);

                if (!deletedItemsByAccount.containsKey(item.AccountId)) {
                    deletedItemsByAccount.put(item.AccountId, new List<ProductRequestLineItem>());
                }
                deletedItemsByAccount.get(item.AccountId).add(item);
            }
        }
        System.debug('^^^^^^^^^^^^^^^^^deletedItemMap : ' + deletedItemMap + '^^^^^^^^^^^^^^^^^');
        System.debug('^^^^^^^^^^^^^^^^^deletedItemsByAccount : ' + deletedItemsByAccount + '^^^^^^^^^^^^^^^^^');

        Map<String, Decimal> restoredItemsMap = new Map<String, Decimal>();
        Set<Id> allAccountIds = dealerToRecords.keySet();

        Map<Id, ProductRequest> openPOMap = new Map<Id, ProductRequest>();
        for (ProductRequest po : [
            SELECT Id, AccountId
            FROM ProductRequest
            WHERE AccountId IN :allAccountIds
            AND Status IN ('New', 'Processing', 'Partial Fulfilment')
            AND Is_Forcasted_PO__c = true
        ]) {
            openPOMap.put(po.AccountId, po);
        }

        List<ProductRequest> ordersToInsert = new List<ProductRequest>();
        Map<Id, List<ProductRequestLineItem>> accountToLines = new Map<Id, List<ProductRequestLineItem>>();
        List<ProductConsumptionTracking__c> recordsToUpdate = new List<ProductConsumptionTracking__c>();
        Set<String> forecastedKeys = new Set<String>();

        Date today = Date.today();
        List<Date> monthBuckets = new List<Date>();

        for (Integer i = 5; i >= 0; i--) {
            Date firstDay = today.addMonths(-i);
            monthBuckets.add(Date.newInstance(firstDay.year(), firstDay.month(), 1));
        }

        for (Id accountId : dealerToRecords.keySet()) {
            Map<Id, List<ProductConsumptionTracking__c>> productToRecords = new Map<Id, List<ProductConsumptionTracking__c>>();

            for (ProductConsumptionTracking__c rec : dealerToRecords.get(accountId)) {
                if (rec.Product__c == null) continue;

                if (!productToRecords.containsKey(rec.Product__c)) {
                    productToRecords.put(rec.Product__c, new List<ProductConsumptionTracking__c>());
                }
                productToRecords.get(rec.Product__c).add(rec);
            }

            List<ProductRequestLineItem> lineItems = new List<ProductRequestLineItem>();
            Boolean hasEligibleProducts = false;

            for (Id productId : productToRecords.keySet()) {

                String forecastKey = productId + '|' + accountId;
                if (deletedItemMap.containsKey(forecastKey)) {
                    System.debug('🔁 Skipping forecast for soft-deleted item: ' + forecastKey);
                    continue; // Don't forecast for items that were previously deleted
                }

                List<ProductConsumptionTracking__c> records = productToRecords.get(productId);
                Decimal moq = getMOQ(records);

                Map<Date, Decimal> bucketMap = new Map<Date, Decimal>();
                for (ProductConsumptionTracking__c rec : records) {
                    Date monthStart = rec.Month_Start_Date__c; 
                    // Date monthStart = Date.newInstance(rec.Month_Start_Date__c.year(), rec.Month_Start_Date__c.month(), 1);
                    bucketMap.put(monthStart, rec.Total_Month_Qty__c != null ? rec.Total_Month_Qty__c : 0);
                }

                logProductConsumption(accountId, productId, bucketMap, monthBuckets);

                List<Decimal> monthlyQtys = new List<Decimal>();
                List<ProductConsumptionTracking__c> sixUsed = new List<ProductConsumptionTracking__c>();

                for (Date month : monthBuckets) {
                    Decimal qty = bucketMap.containsKey(month) ? bucketMap.get(month) : 0;
                    monthlyQtys.add(qty);

                    for (ProductConsumptionTracking__c rec : records) {
                        if (Date.newInstance(rec.Month_Start_Date__c.year(), rec.Month_Start_Date__c.month(), 1) == month) {
                            sixUsed.add(rec);
                        }
                    }
                }

                Integer validMonthCount = 0;
                Decimal total = 0;
                for (Decimal qty : monthlyQtys) {
                    if (qty > 0) {
                        validMonthCount++;
                        total += qty;
                    }
                }
                
                // Skip if no consumption in last 2 months
                if (monthlyQtys.get(4) == 0 && monthlyQtys.get(5) == 0) {
                    System.debug('-----------Skipping : NO CONSUMPTION IN LAST 2 MONTHS-----------');
                    continue; 
                }

                // Skip if less than 2 months with consumption
                if (validMonthCount < 2) {
                    System.debug('-----------Skipping : Less than 2 months consumption-----------');
                    continue; 
                }

                Decimal avg = total / validMonthCount;
                Decimal finalQty = avg.setScale(0, RoundingMode.HALF_UP);

                if (moq != null && moq > finalQty){
                    finalQty = moq;
                } 
                if (finalQty < 1) finalQty = 1;

                ProductRequestLineItem lineItem = new ProductRequestLineItem();
                lineItem.Product2Id = productId;
                lineItem.AccountId = accountId;
                lineItem.QuantityRequested = finalQty;
                lineItem.Forecast_Quantity__c = finalQty;
                lineItem.MSL_Forecast_Value__c = avg.setScale(2);
                lineItem.Used_MOQ__c = (finalQty == moq);
                lineItems.add(lineItem);

                hasEligibleProducts = true;
                forecastedKeys.add(productId + '|' + accountId);

                for (ProductConsumptionTracking__c rec : sixUsed) {
                    // rec.Processed_For_PO__c = true;
                    recordsToUpdate.add(rec);
                }
            }

            // Restore deleted POLIs not in forecast
            for (String key : deletedItemMap.keySet()) {
                System.debug('Restore deleted POLIs not in forecast');
                if (!key.endsWith('|' + accountId)) continue;
                if (forecastedKeys.contains(key)) continue;

                ProductRequestLineItem deleted = deletedItemMap.get(key);
                
                ProductRequestLineItem readd = new ProductRequestLineItem();
                readd.Product2Id = deleted.Product2Id;
                readd.AccountId = deleted.AccountId;
                readd.QuantityRequested = deleted.QuantityRequested < 1 ? 1 : deleted.QuantityRequested;
                readd.Forecast_Quantity__c = deleted.QuantityRequested;
                readd.Is_Deleted_Item__c = false;
                readd.Was_Previously_Deleted__c = true;
                lineItems.add(readd);

                hasEligibleProducts = true;
                restoredItemsMap.put(deleted.Product2Id + '|' + deleted.AccountId, readd.QuantityRequested);
            }
            System.debug('restoredItemsMap : ' + restoredItemsMap);

            if (hasEligibleProducts) {
                ProductRequest po = new ProductRequest();
                po.AccountId = accountId;
                po.Status = 'New';
                po.ShipmentType = 'STK';
                po.Is_Forcasted_PO__c = true;
                po.Description = 'Auto PO - MSL Logic';
                ordersToInsert.add(po);
                accountToLines.put(accountId, lineItems);
            }
        }

        if (!ordersToInsert.isEmpty()) insert ordersToInsert;

        List<ProductRequestLineItem> allLines = new List<ProductRequestLineItem>();
        for (ProductRequest po : ordersToInsert) {
            if (accountToLines.containsKey(po.AccountId)) {
                for (ProductRequestLineItem li : accountToLines.get(po.AccountId)) {
                    li.ParentId = po.Id;
                    allLines.add(li);
                }
            }
        }

        if (!allLines.isEmpty()) insert allLines;
        if (!recordsToUpdate.isEmpty()) update recordsToUpdate;

        // Adjust prior POLI quantities based on restored items
        if (!restoredItemsMap.isEmpty()) {
            Set<Id> productIds = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            for (String key : restoredItemsMap.keySet()) {
                List<String> parts = key.split('\\|');
                productIds.add(parts[0]);
                accountIds.add(parts[1]);
            }

            Map<String, ProductRequestLineItem> originalItemsMap = new Map<String, ProductRequestLineItem>();
            for (ProductRequestLineItem item : [
                SELECT Id, Product2Id, AccountId, QuantityRequested 
                FROM ProductRequestLineItem 
                WHERE Product2Id IN :productIds
                AND AccountId IN :accountIds
                AND Parent.Is_Forcasted_PO__c = true
                AND Parent.Status IN ('New', 'Processing', 'Partial Fulfilment')
                AND Is_Deleted_Item__c = false
            ]) {
                originalItemsMap.put(item.Product2Id + '|' + item.AccountId, item);
            }

            List<ProductRequestLineItem> toUpdate = new List<ProductRequestLineItem>();
            List<ProductRequestLineItem> toDelete = new List<ProductRequestLineItem>();
            for (String key : restoredItemsMap.keySet()) {
                if (originalItemsMap.containsKey(key)) {
                    ProductRequestLineItem item = originalItemsMap.get(key);
                    Decimal newQty = item.QuantityRequested - restoredItemsMap.get(key);
                    
                    if (newQty > 0) {
                        item.QuantityRequested = newQty;
                        toUpdate.add(item);
                    } else if (newQty == 0) {
                        item.QuantityRequested = 1;
                        toUpdate.add(item);
                    } else {
                        toDelete.add(new ProductRequestLineItem(Id = item.Id));
                    }
                }
            }

            if (!toUpdate.isEmpty()) update toUpdate;
            if (!toDelete.isEmpty()) delete toDelete;
        }        
    }

    global void finish(Database.BatchableContext context) {}

    private Decimal getMOQ(List<ProductConsumptionTracking__c> records) {
        for (ProductConsumptionTracking__c rec : records) {
            if (rec.Product__r != null && rec.Product__r.Minimum_Order_Qty__c != null) {
                return rec.Product__r.Minimum_Order_Qty__c;
            }
        }
        return null;
    }

    private void logProductConsumption(Id accountId, Id productId, Map<Date, Decimal> bucketMap, List<Date> monthBuckets) {
        String log = '\n========== Consumption Debug ==========\n';
        log += 'Account: ' + accountId + '\n';
        log += 'Product: ' + productId + '\n';

        for (Date month : monthBuckets) {
            Decimal qty = bucketMap.containsKey(month) ? bucketMap.get(month) : 0;

            String day = (month.day() < 10 ? '0' : '') + month.day();
            String mon = (month.month() < 10 ? '0' : '') + month.month();
            String year = String.valueOf(month.year());

            log += day + '/' + mon + '/' + year + ' -> ' + qty + '\n';
        }

        log += '=======================================\n';
        System.debug(log);
    }

}