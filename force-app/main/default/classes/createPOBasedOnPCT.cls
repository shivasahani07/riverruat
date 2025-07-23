global class createPOBasedOnPCT implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date baseMonth = Date.today().toStartOfMonth();
        Date startDate = baseMonth.addMonths(-6);
        Date endDate = baseMonth;

        String query = 'SELECT Id, Account__c, Product__c, Total_Month_Qty__c, Month_Start_Date__c ' +
            'FROM ProductConsumptionTracking__c ' +
            'WHERE Account__c != null AND Product__c != null AND ' +
            'Month_Start_Date__c >= :startDate AND Month_Start_Date__c <= :endDate';

        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ProductConsumptionTracking__c> listOfPCT) {
        // 1. Calculate 6-month date range
        Date baseMonth = Date.today().toStartOfMonth();
        Set<Date> monthStarts = new Set<Date>();
        for (Integer i = -5; i <= 0; i++) {
            monthStarts.add(baseMonth.addMonths(i));
        }

        // 2. Group data by Account → Product → Month
        Map<Id, Map<Id, Map<Date, Decimal>>> accountProductQtyMap = new Map<Id, Map<Id, Map<Date, Decimal>>>();
        
        for (ProductConsumptionTracking__c pct : listOfPCT) {
            Id accId = pct.Account__c;
            Id prodId = pct.Product__c;
            Date monthStart = pct.Month_Start_Date__c;

            if (!accountProductQtyMap.containsKey(accId)) {
                accountProductQtyMap.put(accId, new Map<Id, Map<Date, Decimal>>());
            }
            if (!accountProductQtyMap.get(accId).containsKey(prodId)) {
                accountProductQtyMap.get(accId).put(prodId, new Map<Date, Decimal>());
            }
            accountProductQtyMap.get(accId).get(prodId).put(monthStart, pct.Total_Month_Qty__c);
        }

        // 3. Create POs (one per account)
        List<ProductRequest> poList = new List<ProductRequest>();
        for (Id accId : accountProductQtyMap.keySet()) {
            poList.add(new ProductRequest(
                AccountId = accId,
                Status = 'Draft',
                ShipmentType = 'STK',
                Is_Forcasted_PO__c = true
            ));
        }
        insert poList;

        // 4. Map Accounts to new POs
        Map<Id, Id> accountToPOId = new Map<Id, Id>();
        for (ProductRequest pr : poList) {
            accountToPOId.put(pr.AccountId, pr.Id);
        }

        // 5. Create Line Items (one per product with summed quantities)
        List<ProductRequestLineItem> lineItems = new List<ProductRequestLineItem>();
        
        for (Id accId : accountProductQtyMap.keySet()) {
            Id poId = accountToPOId.get(accId);
            Map<Id, Map<Date, Decimal>> productData = accountProductQtyMap.get(accId);
            
            for (Id prodId : productData.keySet()) {
                Map<Date, Decimal> monthlyQty = productData.get(prodId);
                Decimal totalQty = 0;
                
                // Sum quantities across all 6 months
                for (Date monthStart : monthStarts) {
                    totalQty += monthlyQty.get(monthStart) != null 
                        ? monthlyQty.get(monthStart) 
                        : 0;
                }
                
                // Only create line item if total quantity > 0
                if (totalQty > 0) {
                    lineItems.add(new ProductRequestLineItem(
                        ParentId = poId,
                        Product2Id = prodId,
                        QuantityRequested = totalQty
                    ));
                }
            }
        }
        
        // 6. Insert line items in bulk
        if (!lineItems.isEmpty()) {
            insert lineItems;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Optional post-processing
    }
}