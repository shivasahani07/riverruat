global with sharing class MSLBatchUpdated implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Existing query logic remains unchanged
        Set<Id> consumedProductIds = new Set<Id>();
        
        for (AggregateResult ar : [SELECT Product__c FROM ProductConsumed WHERE QuantityConsumed != null AND Manual_Created_Date__c != null AND Manual_Created_Date__c = LAST_N_MONTHS:6 AND Product__c != null GROUP BY Product__c]) {
            consumedProductIds.add((Id) ar.get('Product__c'));
        }
        
        for (AggregateResult ar : [SELECT Product__c FROM Sales_Consumption__c WHERE Quantity_Consumed__c != null AND  Manual_Date_Test__c != null AND Manual_Date_Test__c = LAST_N_MONTHS:6 AND Product__c != null GROUP BY Product__c ]) {
            consumedProductIds.add((Id) ar.get('Product__c'));
        }
        
        return Database.getQueryLocator([
            SELECT Id, Name FROM Product2 WHERE Id IN :consumedProductIds
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        Date referenceDate = Date.today();
        Date startDate = referenceDate.addMonths(-6);
        Set<Id> productIdsInScope = new Set<Id>();
        for (SObject s : scope) productIdsInScope.add(s.Id);
        
        // Fetch consumption data
        List<ProductConsumed> pcList = [
            SELECT Product__c, Quantity_Consumed__c, Manual_Created_Date__c, WorkOrder.Service_Center__c
            FROM ProductConsumed 
            WHERE Manual_Created_Date__c >= :startDate 
            AND Product__c IN :productIdsInScope
            AND WorkOrder.Service_Center__c != null
        ];
        
        List<Sales_Consumption__c> scList = [
            SELECT Product__c, Quantity_Consumed__c, Manual_Date_Test__c, Order__r.Dealer__c 
            FROM Sales_Consumption__c 
            WHERE Manual_Date_Test__c >= :startDate 
            AND Product__c IN :productIdsInScope
            AND Order__r.Dealer__c != null
        ];
        
        // Build consumption map
        Map<Id, Map<Id, Map<Integer, Decimal>>> accountProductMonthQtyMap = new Map<Id, Map<Id, Map<Integer, Decimal>>>();
        
        // Process ProductConsumed records
        for (ProductConsumed pc : pcList) {
            processConsumptionRecord(
                accountProductMonthQtyMap,
                pc.WorkOrder.Service_Center__c,
                pc.Product__c,
                pc.Manual_Created_Date__c,
                pc.Quantity_Consumed__c,
                referenceDate
            );
        }
        
        // Process Sales_Consumption__c records
        for (Sales_Consumption__c sc : scList) {
            processConsumptionRecord(
                accountProductMonthQtyMap,
                sc.Order__r.Dealer__c,
                sc.Product__c,
                sc.Manual_Date_Test__c,
                sc.Quantity_Consumed__c,
                referenceDate
            );
        }
        
        // Filter products that meet criteria
        Map<Id, Map<Id, Map<Integer, Decimal>>> filteredAccountProductMonthQtyMap = new Map<Id, Map<Id, Map<Integer, Decimal>>>();
        for (Id accountId : accountProductMonthQtyMap.keySet()) {
            Map<Id, Map<Integer, Decimal>> filteredProducts = new Map<Id, Map<Integer, Decimal>>();
            Map<Id, Map<Integer, Decimal>> productMap = accountProductMonthQtyMap.get(accountId);
            
            for (Id productId : productMap.keySet()) {
                Map<Integer, Decimal> monthMap = productMap.get(productId);
                if (isProductQualified(monthMap)) {
                    filteredProducts.put(productId, monthMap);
                }
            }
            
            if (!filteredProducts.isEmpty()) {
                filteredAccountProductMonthQtyMap.put(accountId, filteredProducts);
            }
        }
        
        // Create MSL records only for qualified data
        List<MSL__c> mslList = new List<MSL__c>();
        Map<Id, MSL__c> accountToMSL = new Map<Id, MSL__c>();
        
        for (Id accId : filteredAccountProductMonthQtyMap.keySet()) {
            MSL__c msl = new MSL__c(Dealer__c = accId);
            mslList.add(msl);
        }
        insert mslList;
        
        // Create mapping for MSL Consumption records
        for (MSL__c msl : mslList) {
            accountToMSL.put(msl.Dealer__c, msl);
        }
        
        // Create MSL Consumption records
        List<MSL_Consumption__c> mslcList = new List<MSL_Consumption__c>();
        for (Id accId : filteredAccountProductMonthQtyMap.keySet()) {
            MSL__c msl = accountToMSL.get(accId);
            Map<Id, Map<Integer, Decimal>> prodMap = filteredAccountProductMonthQtyMap.get(accId);
            
            for (Id prodId : prodMap.keySet()) {
                Map<Integer, Decimal> m = prodMap.get(prodId);
                Decimal total = sumMonthlyConsumption(m);
                
                mslcList.add(new MSL_Consumption__c(
                    MSL_Batch__c = msl.Id,
                    Product__c = prodId,
                    X1st_Month__c = m.get(1),
                    X2nd_Month__c = m.get(2),
                    X3rd_Month__c = m.get(3),
                    X4th_Month__c = m.get(4),
                    X5th_Month__c = m.get(5),
                    X6th_Month__c = m.get(6),
                    Average_Quantity__c = total / 6
                ));
            }
        }
        
        insert mslcList;
    }
    
    global void finish(Database.BatchableContext BC) {
        // Optional: Add notification logic here
    }
    
    // Helper method to process consumption records
    private void processConsumptionRecord(
        Map<Id, Map<Id, Map<Integer, Decimal>>> accountProductMonthQtyMap,
        Id accountId,
        Id productId,
        Date consumptionDate,
        Decimal quantity,
        Date referenceDate
    ) {
        if (accountId == null || productId == null) return;
        
        Integer monthIndex = Math.abs(referenceDate.monthsBetween(consumptionDate)) + 1;
        if (monthIndex < 1 || monthIndex > 6) return;
        
        Decimal qty = quantity != null ? quantity : 0;
        
        // Initialize data structure if needed
        if (!accountProductMonthQtyMap.containsKey(accountId)) {
            accountProductMonthQtyMap.put(accountId, new Map<Id, Map<Integer, Decimal>>());
        }
        
        Map<Id, Map<Integer, Decimal>> productMap = accountProductMonthQtyMap.get(accountId);
        if (!productMap.containsKey(productId)) {
            Map<Integer, Decimal> monthMap = new Map<Integer, Decimal>();
            for (Integer i = 1; i <= 6; i++) monthMap.put(i, 0);
            productMap.put(productId, monthMap);
        }
        
        // Add quantity to the specific month
        Map<Integer, Decimal> monthMap = productMap.get(productId);
        monthMap.put(monthIndex, monthMap.get(monthIndex) + qty);
    }
    
    // Helper method to check if product meets criteria
    private Boolean isProductQualified(Map<Integer, Decimal> monthMap) {
        // 1. Last two months must have consumption
        if (monthMap.get(1) <= 0 || monthMap.get(2) <= 0) {
            return false;
        }
        
        // 2. At least 4 months must have consumption
        Integer monthsWithConsumption = 0;
        for (Integer i = 1; i <= 6; i++) {
            if (monthMap.get(i) > 0) {
                monthsWithConsumption++;
            }
        }
        
        return monthsWithConsumption >= 4;
    }
    
    // Helper method to sum monthly consumption
    private Decimal sumMonthlyConsumption(Map<Integer, Decimal> monthMap) {
        Decimal total = 0;
        for (Integer i = 1; i <= 6; i++) {
            total += monthMap.get(i);
        }
        return total;
    }
}