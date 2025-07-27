/**
* @description       : 
* @author            : Aniket Karmakar
* @group             : 
* @last modified on  : 07-27-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global without sharing class MSLAggregatorBatchClass implements Database.Batchable<SObject>, Database.Stateful {
    
    Map<Id, Map<String, Decimal>> dealerMonthProductQtyMap = new Map<Id, Map<String, Decimal>>();
    Set<Id> allActiveProductIds = new Set<Id>();
    Date today = Date.today();
    Boolean isMidMonthRun = today.day() >= 16;
    List<Date> monthStartDates = new List<Date>();
    Date sixMonthsAgo;
    Date runStartDate;
    Date runEndDate;
    Id batchSummaryId;
    
    global MSLAggregatorBatchClass() {
        if (isMidMonthRun) {
            runStartDate = Date.newInstance(today.year(), today.month(), 1);
            runEndDate = Date.newInstance(today.year(), today.month(), 15);
        } else {
            runStartDate = Date.newInstance(today.year(), today.month(), 1).addMonths(-1);
            runEndDate = runStartDate.addMonths(1).addDays(-1);
        }
        
        sixMonthsAgo = Date.newInstance(today.year(), today.month(), 1).addMonths(-5);
        for (Integer i = 0; i < 6; i++) {
            Date monthStart = Date.newInstance(today.year(), today.month(), 1).addMonths(-i);
            monthStartDates.add(monthStart);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        Set<Id> consumedProductIds = new Set<Id>();
        
        for (AggregateResult ar : [
            SELECT Product__c FROM ProductConsumed
            WHERE Manual_Created_Date__c = LAST_N_MONTHS:6
            AND Product__c != null
            GROUP BY Product__c
        ]) {
            consumedProductIds.add((Id) ar.get('Product__c'));
        }
        
        for (AggregateResult ar : [
            SELECT Product__c FROM Sales_Consumption__c
            WHERE Manual_Date_Test__c = LAST_N_MONTHS:6
            AND Product__c != null
            GROUP BY Product__c
        ]) {
            consumedProductIds.add((Id) ar.get('Product__c'));
        }
        
        return Database.getQueryLocator([SELECT Id FROM Product2 WHERE Id IN :consumedProductIds]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Id> productIds = new List<Id>();
        for (SObject sObj : scope) {
            productIds.add(sObj.Id);
        }
        
        
        List<Date> monthStartDates = new List<Date>();
        Date today = Date.today();
        for (Integer i = 0; i < 6; i++) {
            monthStartDates.add(Date.newInstance(today.year(), today.month(), 1).addMonths(-i));
        }
        
        
        Set<Id> allDealerIds = new Set<Id>();
        List<Account> allDealers = [SELECT Id,Type FROM Account WHERE Type IN('Dealer')];
        for (Account acc : allDealers) {
            allDealerIds.add(acc.Id);
            dealerMonthProductQtyMap.put(acc.Id, new Map<String, Decimal>());
        }
        
        
        List<ProductConsumed> pcList = [
            SELECT Product__c, Quantity_Consumed__c, WorkOrder.Service_Center__c, CreatedDate
            FROM ProductConsumed
            WHERE Product__c IN :productIds
            AND WorkOrder.Service_Center__c != null
            AND CreatedDate = LAST_N_MONTHS:6
        ];
        
        for (ProductConsumed pc : pcList) {
            Id dealerId = pc.WorkOrder.Service_Center__c;
            Date createdDate = pc.CreatedDate.date();
            Date monthStart = Date.newInstance(createdDate.year(), createdDate.month(), 1);
            String paddedMonth = monthStart.month() < 10 ? '0' + String.valueOf(monthStart.month()) : String.valueOf(monthStart.month());
            String monthKey = monthStart.year() + '-' + paddedMonth;
            String key = pc.Product__c + '_' + monthKey;
            
            if (!dealerMonthProductQtyMap.containsKey(dealerId)) {
                dealerMonthProductQtyMap.put(dealerId, new Map<String, Decimal>());
            }
            Map<String, Decimal> innerMap = dealerMonthProductQtyMap.get(dealerId);
            innerMap.put(key, (innerMap.containsKey(key) ? innerMap.get(key) : 0) + pc.Quantity_Consumed__c);
        }
        
        
        List<Sales_Consumption__c> scList = [
            SELECT Product__c, Quantity_Consumed__c, Order__r.Dealer__c, CreatedDate
            FROM Sales_Consumption__c
            WHERE Product__c IN :productIds
            AND Order__r.Dealer__c != null
            AND CreatedDate = LAST_N_MONTHS:6
        ];
        
        for (Sales_Consumption__c sc : scList) {
            Id dealerId = sc.Order__r.Dealer__c;
            Date createdDate = sc.CreatedDate.date();
            Date monthStart = Date.newInstance(createdDate.year(), createdDate.month(), 1);
            String paddedMonth = monthStart.month() < 10 ? '0' + String.valueOf(monthStart.month()) : String.valueOf(monthStart.month());
            String monthKey = monthStart.year() + '-' + paddedMonth;
            String key = sc.Product__c + '_' + monthKey;
            
            if (!dealerMonthProductQtyMap.containsKey(dealerId)) {
                dealerMonthProductQtyMap.put(dealerId, new Map<String, Decimal>());
            }
            Map<String, Decimal> innerMap = dealerMonthProductQtyMap.get(dealerId);
            innerMap.put(key, (innerMap.containsKey(key) ? innerMap.get(key) : 0) + sc.Quantity_Consumed__c);
        }
        
        
        for (Id dealerId : dealerMonthProductQtyMap.keySet()) {
            Map<String, Decimal> innerMap = dealerMonthProductQtyMap.get(dealerId);
            for (Id productId : productIds) {
                for (Date monthStart : monthStartDates) {
                    String paddedMonth = monthStart.month() < 10 ? '0' + String.valueOf(monthStart.month()) : String.valueOf(monthStart.month());
                    String monthStr = monthStart.year() + '-' + paddedMonth;
                    String key = productId + '_' + monthStr;
                    
                    if (!innerMap.containsKey(key)) {
                        innerMap.put(key, 0);
                    }
                }
            }
        }
        
        
        List<MSL_Batch_Summary__c> summariesToInsert = new List<MSL_Batch_Summary__c>();
        List<Month_Split__c> monthSplitsToInsert = new List<Month_Split__c>();
        
        for (Id dealerId : dealerMonthProductQtyMap.keySet()) {
            MSL_Batch_Summary__c summary = new MSL_Batch_Summary__c(Dealer__c = dealerId,Batch_Run_Date__c=runStartDate,Batch_Start_Date__c=runStartDate,Batch_End_Date__c=runEndDate);
            summariesToInsert.add(summary);
        }
        
        insert summariesToInsert;
        
        
        Map<Id, Id> dealerToSummaryIdMap = new Map<Id, Id>();
        for (MSL_Batch_Summary__c summary : summariesToInsert) {
            dealerToSummaryIdMap.put(summary.Dealer__c, summary.Id);
        }
        
        
        List<Month_Split__c> monthSplitsToInsert2 = new List<Month_Split__c>();
        
        for (Id dealerId : dealerMonthProductQtyMap.keySet()) {
            Id summaryId = dealerToSummaryIdMap.get(dealerId);
            if (summaryId == null) continue;
            
            Map<String, Decimal> innerMap = dealerMonthProductQtyMap.get(dealerId);
            for (String key : innerMap.keySet()) {
                List<String> parts = key.split('_');
                if (parts.size() != 2) continue;
                
                Id productId = Id.valueOf(parts[0]);
                String monthStr = parts[1]; 
                
                List<String> dateParts = monthStr.split('-');
                if (dateParts.size() != 2) continue;
                
                Integer year = Integer.valueOf(dateParts[0]);
                Integer month = Integer.valueOf(dateParts[1]);
                
                Date startDate = Date.newInstance(year, month, 1);
                Date endDate = startDate.addMonths(1).addDays(-1);
                
                String label = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)).format('MMMM');
                
                monthSplitsToInsert2.add(new Month_Split__c(
                    Product__c = productId,
                    Month_Name__c = label,
                    Quantity__c = innerMap.get(key),
                    MSL_Batch_Summary__c = summaryId,
                    Start_Date__c = startDate,
                    End_Date__c = endDate,
                    Month_Sequence__c = isMidMonthRun ? 'Partial' : 'Full'
                ));
            }
        }
        
        
        List<Month_Split__c> chunkList = new List<Month_Split__c>();
        
        for (Month_Split__c split : monthSplitsToInsert2) {
            chunkList.add(split);
            if (chunkList.size() == 200) {
                insert chunkList;
                chunkList.clear();
            }
        }
        
        
        if (!chunkList.isEmpty()) {
            insert chunkList;
        }
    }
    global void finish(Database.BatchableContext BC) {
        System.debug('batch Process Completed at 6:21 am ,,,' + 'Good Night');
    }
}