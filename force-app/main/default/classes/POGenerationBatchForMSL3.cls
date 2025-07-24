global class POGenerationBatchForMSL3 implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('================== POGenerationBatchForMSL ====================');
                
        Date sixMonthsAgo = Date.today().addMonths(-6);
        return Database.getQueryLocator([
            SELECT Id, Product__c, Account__c, Bucket_Start_Date__c, Quantity_Consumed__c, Processed_for_PO__c, Month_Start_Date__c,
                   Product__r.Minimum_Order_Qty__c, Total_Month_Qty__c, First_Consumption_Date__c
            FROM ProductConsumptionTracking__c
            WHERE First_Consumption_Date__c >= :sixMonthsAgo
            AND Processed_For_PO__c = FALSE AND Account__r.type IN ('Dealer', 'Service Center')
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

        Set<Id> allAccountIds = dealerToRecords.keySet();
        Map<Id, ProductRequest> openPOMap = new Map<Id, ProductRequest>();
        
        for (ProductRequest po : [
            SELECT Id, AccountId 
            FROM ProductRequest 
            WHERE AccountId IN :allAccountIds 
            AND Status IN ('New') 
            AND Is_Forcasted_PO__c = true
        ]) {
            openPOMap.put(po.AccountId, po);
        }
        System.debug('=================== openPOMap =================== : ' + openPOMap.size() + ' : ' + openPOMap);

        Map<String, Decimal> openQtyMap = new Map<String, Decimal>();
        List<ProductRequestLineItem> openLineItems = [
            SELECT Product2Id, AccountId, QuantityRequested
            FROM ProductRequestLineItem
            WHERE Parent.Is_Forcasted_PO__c = TRUE
              AND Parent.Status = 'New'
              AND AccountId IN :allAccountIds
        ];

        for (ProductRequestLineItem item : openLineItems) {
            if (item.Product2Id == null || item.AccountId == null) continue;
            String key = item.Product2Id + '|' + item.AccountId;
            if (!openQtyMap.containsKey(key)) {
                openQtyMap.put(key, 0);
            }
            openQtyMap.put(key, openQtyMap.get(key) + item.QuantityRequested);
        }
        System.debug('=================== openQtyMap entries =================== : ' + openQtyMap.size());

        List<ProductRequest> ordersToInsert = new List<ProductRequest>();
        Map<Id, List<ProductRequestLineItem>> accountToLines = new Map<Id, List<ProductRequestLineItem>>();
        Set<Id> seenTrackingRecordIds = new Set<Id>();
        List<ProductConsumptionTracking__c> recordsToUpdate = new List<ProductConsumptionTracking__c>();
        Set<String> forecastedKeys = new Set<String>();

        Date today = Date.today();
        List<Date> monthBuckets = new List<Date>();
        for (Integer i = 5; i >= 0; i--) {
            Date firstDay = today.addMonths(-i);
            monthBuckets.add(Date.newInstance(firstDay.year(), firstDay.month(), 1));
        }
        
        List<ProductBatchAssignment__c> batchAssignmentsList = [SELECT Id, Account__c, Product__c, First_Consumption_Date__c 
                                                                FROM ProductBatchAssignment__c];
        Map<String, ProductBatchAssignment__c> batchAssignments = new Map<String, ProductBatchAssignment__c>();
        
        List<ProductBatchAssignment__c> newAssignmentsToInsert = new List<ProductBatchAssignment__c>();
        
        for(ProductBatchAssignment__c item : batchAssignmentsList){
            batchAssignments.put(item.Product__c + '|' + item.Account__c, item);
        }
        
        Set<Id> accountIds = new Set<Id>();
        for(Id accId : dealerToRecords.keySet()){
            accountIds.add(accId);
        }
        
        List<User> lstUsers = [SELECT Id, Name, Contact.AccountId FROM User WHERE Contact.AccountId IN : accountIds]; //  AND Contact.Designation__c = ''
        Map<String, List<User>> mapAccAndUsers = new Map<String, List<User>>();
        
        for(User u : lstUsers){
            if(!mapAccAndUsers.containskey(u.Contact.AccountId)){
                mapAccAndUsers.put(u.Contact.AccountId, new List<User>());
            }
            else{
                mapAccAndUsers.get(u.Contact.AccountId).add(u);
            }
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
                
                List<ProductConsumptionTracking__c> records = productToRecords.get(productId);

                // 1. Find earliest consumption date for this product+account combo
                Date earliestDate;
                for (ProductConsumptionTracking__c rec : records) {
                    if (rec.First_Consumption_Date__c != null) {
                        if (earliestDate == null || rec.First_Consumption_Date__c < earliestDate) {
                            earliestDate = rec.First_Consumption_Date__c;
                        }
                    }
                }
            
                // 2. Determine Batch Status
                String batchStatus;
                if (earliestDate != null) {
                    batchStatus = (earliestDate.day() <= 15) ? '2nd Batch' : '1st Batch';
                }
                
                String batchKey = productId + '|' + accountId;
                if (!batchAssignments.containsKey(batchKey) && earliestDate != null) {
                    ProductBatchAssignment__c newPBA = new ProductBatchAssignment__c();
                    newPBA.Account__c = accountId;
                    newPBA.Product__c = productId;
                    newPBA.First_Consumption_Date__c = earliestDate;
                    newPBA.Batch__c = (earliestDate.day() <= 15) ? '2nd Batch' : '1st Batch';
                    
                    newAssignmentsToInsert.add(newPBA);
                    batchAssignments.put(batchKey, newPBA); // So PO logic later works
                }

                Decimal moq = getMOQ(records);

                Map<Date, Decimal> bucketMap = new Map<Date, Decimal>();
                for (ProductConsumptionTracking__c rec : records) {
                    Date monthStart = Date.newInstance(rec.Month_Start_Date__c.year(), rec.Month_Start_Date__c.month(), 1);
                    bucketMap.put(monthStart, rec.Total_Month_Qty__c != null ? rec.Total_Month_Qty__c : 0);
                }

                logMonthlyConsumption(accountId, productId, monthBuckets, bucketMap);

                List<Decimal> monthlyQtys = new List<Decimal>();
                List<ProductConsumptionTracking__c> sixUsed = new List<ProductConsumptionTracking__c>();
                for (Date month : monthBuckets) {
                    Decimal qty = bucketMap.containsKey(month) ? bucketMap.get(month) : 0;
                    monthlyQtys.add(qty);
                    
                    for (ProductConsumptionTracking__c rec : records) {
                        if (Date.newInstance(rec.Month_Start_Date__c.year(), rec.Month_Start_Date__c.month(), 1) == month) {
                            if (!seenTrackingRecordIds.contains(rec.Id)) {
                                sixUsed.add(rec);
                                seenTrackingRecordIds.add(rec.Id);
                            }
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

                if (validMonthCount <= 4) {
                    System.debug('Skipping Product: ' + productId + ' → Valid months with consumption: ' + validMonthCount);
                    continue;
                }

                if (moq == null || moq == 0) moq = 1;
                Decimal avg = total / validMonthCount;
                Decimal roundedAvg = avg.setScale(0, RoundingMode.HALF_UP);

                Decimal openQty = openQtyMap.containsKey(forecastKey) ? openQtyMap.get(forecastKey) : 0;
                Decimal netQty = roundedAvg - openQty;

                if (netQty < 0) netQty = 0;

                Decimal finalQty = (moq > netQty && netQty > 0) ? moq : netQty;

                System.debug('Forecast for Product: ' + productId + ' | Account: ' + accountId + 
                             ' | Avg: ' + avg + ' | Rounded: ' + roundedAvg + 
                             ' | Open Qty: ' + openQty + ' | Net: ' + netQty + 
                             ' | Final: ' + finalQty);

                if (finalQty > 0) {
                    
                    // Get comma-separated Tracking record IDs
                    List<Id> trackingIds = new List<Id>();
                    for (ProductConsumptionTracking__c t : sixUsed) {
                        trackingIds.add(t.Id);
                    }
                    String trackingIdString = String.join(trackingIds, ',');
                    
                    ProductRequestLineItem lineItem = new ProductRequestLineItem();
                    lineItem.Product2Id = productId;
                    lineItem.AccountId = accountId;
                    lineItem.QuantityRequested = finalQty;
                    lineItem.Forecast_Quantity__c = finalQty;
                    lineItem.MSL_Forecast_Value__c = avg.setScale(2);
                    lineItem.Used_MOQ__c = (finalQty == moq);
                    lineItem.PO_Batch_Status__c = batchStatus;
                    lineItem.Related_Tracking_IDs_c__c = trackingIdString;

                    lineItems.add(lineItem);
                    hasEligibleProducts = true;

                    forecastedKeys.add(forecastKey);

                    for (ProductConsumptionTracking__c rec : sixUsed) {
                        rec.Processed_for_PO__c = true;
                        recordsToUpdate.add(rec);
                    }

                    System.debug('Created Forecasted POLI → ' + productId + ' Qty: ' + finalQty);
                } else {
                    /*
                    for (ProductConsumptionTracking__c rec : sixUsed) {
                        rec.Processed_for_PO__c = true;
                        recordsToUpdate.add(rec);
                    }
					*/
                    System.debug('Skipping POLI creation → ' + productId + ' | Account: ' + accountId + ' | FinalQty: 0');
                }
            }            

            if (hasEligibleProducts) {
                ProductRequest po = new ProductRequest();
                po.AccountId = accountId;
                System.debug('accountId==============> ' + accountId);
                po.Status = 'New';
                po.ShipmentType = 'STK';
                po.Is_Forcasted_PO__c = true;
                po.Description = 'Auto-generated PO for Dealer: ' + accountId;
                po.OwnerId = mapAccAndUsers.get(accountId)[0].Id;
                
                // Batch assignment logic here
                Date poBatchDate;
                for (ProductRequestLineItem item : lineItems) {
                    String key = item.Product2Id + '|' + accountId;
                    
                    if (batchAssignments.containsKey(key)) {
                        Date d = batchAssignments.get(key).First_Consumption_Date__c;
                        if (poBatchDate == null || d < poBatchDate) {
                            poBatchDate = d;
                        }
                    }
                }
            
                String poBatchStatus = (poBatchDate != null && poBatchDate.day() <= 15) ? '2nd Batch' : '1st Batch';
                po.Batch_Stage__c = poBatchStatus;
            
                // Add to orders list
                ordersToInsert.add(po);
                accountToLines.put(accountId, lineItems);
            
                System.debug('po added');
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
        
        if (!newAssignmentsToInsert.isEmpty()) {
            insert newAssignmentsToInsert;
        }
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