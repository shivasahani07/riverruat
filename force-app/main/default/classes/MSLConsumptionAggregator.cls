// Batch 1: Consumption Aggregator
global without sharing class MSLConsumptionAggregator implements Database.Batchable<SObject>, Database.Stateful {
    global Map<String, Decimal> dealerProductMonthlyQty = new Map<String, Decimal>();
    global Map<String, Date> dealerProductFirstConsumption = new Map<String, Date>();
    global Map<String, Date> dealerProductLastConsumption = new Map<String, Date>();
    global Date today = Date.today();
    global Date sixMonthsAgo = today.addMonths(-6).toStartOfMonth();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Product__c, Quantity_Consumed__c, Manual_Created_Date__c,
                   WorkOrder.Service_Center__c 
            FROM ProductConsumed
            WHERE Manual_Created_Date__c >= :sixMonthsAgo
            AND WorkOrder.Service_Center__c != null
            AND Product__c != null AND Quantity_Consumed__c !=null
            ALL ROWS
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<ProductConsumed> scope) {
        for (ProductConsumed pc : scope) {
            processRecord(
                pc.WorkOrder.Service_Center__c,
                pc.Product__c,
                pc.Quantity_Consumed__c,
                pc.Manual_Created_Date__c
            );
        }
        
        // Process Sales Consumption
        List<Sales_Consumption__c> scList = [
            SELECT Product__c, Quantity_Consumed__c, Manual_Date_Test__c,
                   Order__r.Dealer__c
            FROM Sales_Consumption__c
            WHERE Manual_Date_Test__c >= :sixMonthsAgo
            AND Order__r.Dealer__c != null AND Quantity_Consumed__c !=null
            AND Product__c != null AND Manual_Date_Test__c !=null
        ];
        
        for (Sales_Consumption__c sc : scList) {
            processRecord(
                sc.Order__r.Dealer__c,
                sc.Product__c,
                sc.Quantity_Consumed__c,
                sc.Manual_Date_Test__c
            );
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Start MSL Calculation Batch
        Database.executeBatch(new MSLPOCalculationBatch(
            dealerProductMonthlyQty,
            dealerProductFirstConsumption,
            dealerProductLastConsumption
        ), 50);
    }
    
    private void processRecord(Id dealerId, Id productId, Decimal quantity, Date transDate) {
        String key = dealerId + '_' + productId;
        String monthKey = key + '_' + transDate.year() + '-' + transDate.month();
        
        // Update monthly quantity
        dealerProductMonthlyQty.put(monthKey, 
            dealerProductMonthlyQty.containsKey(monthKey) ? 
            dealerProductMonthlyQty.get(monthKey) + quantity : quantity);
        
        // Update first consumption date
        if (!dealerProductFirstConsumption.containsKey(key) || 
            transDate < dealerProductFirstConsumption.get(key)) {
            dealerProductFirstConsumption.put(key, transDate);
        }
        
        // Update last consumption date
        if (!dealerProductLastConsumption.containsKey(key) || 
            transDate > dealerProductLastConsumption.get(key)) {
            dealerProductLastConsumption.put(key, transDate);
        }
    }
}