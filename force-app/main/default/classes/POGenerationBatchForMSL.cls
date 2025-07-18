global class POGenerationBatchForMSL implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('================== POGenerationBatchForMSL ====================');
        Date sixMonthsAgo = Date.today().addMonths(-6);
        return Database.getQueryLocator([
            SELECT Id, Product__c, Account__c, Bucket_Start_Date__c, Quantity_Consumed__c, Processed_for_PO__c,
                   Product__r.Minimum_Order_Qty__c
            FROM ProductConsumptionTracking__c
            WHERE Bucket_Start_Date__c >= :sixMonthsAgo
            AND Processed_For_PO__c = FALSE
        ]);
    }

    global void execute(Database.BatchableContext context, List<SObject> scope) {
        System.debug('scope : ' + scope.size());

        Map<Id, List<ProductConsumptionTracking__c>> dealerToRecords = new Map<Id, List<ProductConsumptionTracking__c>>();
        for (SObject s : scope) {
            ProductConsumptionTracking__c rec = (ProductConsumptionTracking__c)s;
            if (rec.Account__c == null) continue;
            if (!dealerToRecords.containsKey(rec.Account__c)) {
                dealerToRecords.put(rec.Account__c, new List<ProductConsumptionTracking__c>());
            }
            dealerToRecords.get(rec.Account__c).add(rec);            
        }

        // NEW: Fetch all previously deleted line items
        Map<String, ProductRequestLineItem> deletedItemMap = new Map<String, ProductRequestLineItem>();
        Map<Id, List<ProductRequestLineItem>> deletedItemsByAccount = new Map<Id, List<ProductRequestLineItem>>();
        for (ProductRequestLineItem item : [
            SELECT Id, Product2Id, AccountId, QuantityRequested, Is_Deleted_Item__c
            FROM ProductRequestLineItem
            WHERE Is_Deleted_Item__c = TRUE
        ]) {
            if (item.Product2Id != null && item.AccountId != null) {
                deletedItemMap.put(item.Product2Id + '|' + item.AccountId, item);

                // Group deleted items by AccountId
                if (!deletedItemsByAccount.containsKey(item.AccountId)) {
                    deletedItemsByAccount.put(item.AccountId, new List<ProductRequestLineItem>());
                }
                deletedItemsByAccount.get(item.AccountId).add(item);
            }
        }
        System.debug('=================== deletedItemsByAccount =================== : ' + deletedItemsByAccount.size() + ' : ' + deletedItemsByAccount);

        // NEW: Fetch existing open POs (Status = 'New' or 'Processing' or 'Partial Fulfilment') to skip PO creation for these accounts
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
        System.debug('=================== openPOMap =================== : ' + openPOMap.size() + ' : ' + openPOMap);

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
            /*
            // ✅ NEW: Skip account if PO exists AND no soft-deleted line items
            if (openPOMap.containsKey(accountId) && !deletedItemsByAccount.containsKey(accountId)) {
                System.debug('⛔ Skipping Account: ' + accountId + ' → Open PO already exists with POID: ' + openPOMap.get(accountId).Id + ' and no soft-deleted items.');
                continue;
            }
            */
            
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
                List<ProductConsumptionTracking__c> records = productToRecords.get(productId);
                Decimal moq = getMOQ(records);

                Map<Date, Decimal> bucketMap = new Map<Date, Decimal>();
                for (ProductConsumptionTracking__c rec : records) {
                    Date monthStart = Date.newInstance(rec.Bucket_Start_Date__c.year(), rec.Bucket_Start_Date__c.month(), 1);
                    bucketMap.put(monthStart, rec.Quantity_Consumed__c != null ? rec.Quantity_Consumed__c : 0);
                }

                logMonthlyConsumption(accountId, productId, monthBuckets, bucketMap);

                List<Decimal> monthlyQtys = new List<Decimal>();
                List<ProductConsumptionTracking__c> sixUsed = new List<ProductConsumptionTracking__c>();
                for (Date month : monthBuckets) {
                    Decimal qty = bucketMap.containsKey(month) ? bucketMap.get(month) : 0;
                    monthlyQtys.add(qty);
                    
                    for (ProductConsumptionTracking__c rec : records) {
                        if (Date.newInstance(rec.Bucket_Start_Date__c.year(), rec.Bucket_Start_Date__c.month(), 1) == month) {
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

                if (monthlyQtys.get(4) == 0 && monthlyQtys.get(5) == 0) {
                    System.debug('Skipping Product: ' + productId + ' → Last 2 months had 0 consumption');
                    continue;
                }

                if (validMonthCount < 2) {
                    System.debug('Skipping Product: ' + productId + ' → Valid months with consumption: ' + validMonthCount);
                    continue;
                }

                if (moq == null || moq == 0) moq = 1;
                Decimal avg = total / validMonthCount;
                Decimal roundedAvg = avg.setScale(0, RoundingMode.HALF_UP);
                Decimal finalQty = (moq > roundedAvg) ? moq : roundedAvg;

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
                    rec.Processed_for_PO__c = true;
                    recordsToUpdate.add(rec);
                }

                System.debug('✅ Created Forecasted POLI → ' + productId + ' Qty: ' + finalQty);
            }

            // Include deleted items that did NOT meet forecast logic
            for (String key : deletedItemMap.keySet()) {
                if (!key.endsWith('|' + accountId)) continue;
                
                ProductRequestLineItem deleted = deletedItemMap.get(key);
                ProductRequestLineItem readd = new ProductRequestLineItem();
                readd.Product2Id = deleted.Product2Id;
                readd.AccountId = deleted.AccountId;
                readd.QuantityRequested = deleted.QuantityRequested;
                readd.Forecast_Quantity__c = deleted.QuantityRequested;
                readd.Is_Deleted_Item__c = false;
                readd.Was_Previously_Deleted__c = true;

                lineItems.add(readd);
                hasEligibleProducts = true;

                System.debug('♻️ Restored Soft-Deleted Item (No Forecast): ' + deleted.Product2Id);
            }

            if (hasEligibleProducts) {
                ProductRequest po = new ProductRequest();
                po.AccountId = accountId;
                po.Status = 'New';
                po.ShipmentType = 'STK';
                po.Is_Forcasted_PO__c = true;
                po.Description = 'Auto-generated PO for Dealer: ' + accountId;
                ordersToInsert.add(po);
                accountToLines.put(accountId, lineItems);
            }
        }

        if (!ordersToInsert.isEmpty()) insert ordersToInsert;

        List<ProductRequestLineItem> allLineItems = new List<ProductRequestLineItem>();
        for (ProductRequest po : ordersToInsert) {
            if (accountToLines.containsKey(po.AccountId)) {
                for (ProductRequestLineItem item : accountToLines.get(po.AccountId)) {
                    item.ParentId = po.Id;
                    allLineItems.add(item);
                }
            }
        }

        if (!allLineItems.isEmpty()) insert allLineItems;
        if (!recordsToUpdate.isEmpty()) update recordsToUpdate;
    }

    global void finish(Database.BatchableContext context) {
        // Optional logging or notifications
    }

    private Decimal getMOQ(List<ProductConsumptionTracking__c> records) {
        for (ProductConsumptionTracking__c rec : records) {
            if (rec.Product__r != null && rec.Product__r.Minimum_Order_Qty__c != null) {
                return rec.Product__r.Minimum_Order_Qty__c;
            }
        }
        return null;
    }

    private void logMonthlyConsumption(Id accountId, Id productId, List<Date> monthBuckets, Map<Date, Decimal> bucketMap) {
        String log = '\n-----------------------------\n';
        log += 'Dealer: ' + accountId + '\n';
        log += 'Product: ' + productId + '\n';
        log += 'Month Buckets: \n';
        for (Date month : monthBuckets) {
            String label = month.format();
            Decimal qty = bucketMap.containsKey(month) ? bucketMap.get(month) : 0;
            log += label + ' : ' + qty + '\n';
        }
        log += '-----------------------------\n';
        System.debug(log);
    }
}