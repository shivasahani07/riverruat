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
            // For mid-month run (16th), get:
            // - Current month: 1st to 15th
            // - Previous months: 16th to end of month
            runStartDate = Date.newInstance(today.year(), today.month(), 16);
            runEndDate = Date.newInstance(today.year(), today.month(), 1).addMonths(1).addDays(-1);
        } else {
            // For start-of-month run (1st), get full months
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
        
        Set<Id> allDealerIds = new Set<Id>();
        List<Account> allDealers = [SELECT Id,Type FROM Account WHERE Type IN('Dealer')];
        for (Account acc : allDealers) {
            allDealerIds.add(acc.Id);
            dealerMonthProductQtyMap.put(acc.Id, new Map<String, Decimal>());
        }
        
        // Process ProductConsumed records with date filtering
        // Process ProductConsumed records with date filtering
        // Process ProductConsumed records with date filtering
        // Process ProductConsumed records with date filtering
        // Process ProductConsumed records with date filtering
        // Process ProductConsumed records with date filtering
        // Process ProductConsumed records with date filtering
        String pcQuery = 'SELECT Product__c, Quantity_Consumed__c, WorkOrder.Service_Center__c, CreatedDate, Manual_Created_Date__c ' +
            'FROM ProductConsumed ' +
            'WHERE Product__c IN :productIds ' +
            'AND WorkOrder.Service_Center__c != null ';
        
        if (isMidMonthRun) {
            // For mid-month run, get:
            // - Current month: 1st to 15th
            // - Previous months: 16th to end of month
            Date currentMonthStart = Date.newInstance(today.year(), today.month(), 1);
            Date currentMonthMid = Date.newInstance(today.year(), today.month(), 15);
            Date prevMonthMid = Date.newInstance(today.year(), today.month(), 1).addMonths(-1).addDays(15);
            Date prevMonthEnd = Date.newInstance(today.year(), today.month(), 1).addDays(-1);
            
            // Format dates in YYYY-MM-DD format with proper string conversion
            String currentMonthStartStr = String.valueOf(currentMonthStart.year()) + '-' + 
                (currentMonthStart.month() < 10 ? '0' + String.valueOf(currentMonthStart.month()) : String.valueOf(currentMonthStart.month())) + '-' + 
                (currentMonthStart.day() < 10 ? '0' + String.valueOf(currentMonthStart.day()) : String.valueOf(currentMonthStart.day()));
            String currentMonthMidStr = String.valueOf(currentMonthMid.year()) + '-' + 
                (currentMonthMid.month() < 10 ? '0' + String.valueOf(currentMonthMid.month()) : String.valueOf(currentMonthMid.month())) + '-' + 
                (currentMonthMid.day() < 10 ? '0' + String.valueOf(currentMonthMid.day()) : String.valueOf(currentMonthMid.day()));
            String prevMonthMidStr = String.valueOf(prevMonthMid.year()) + '-' + 
                (prevMonthMid.month() < 10 ? '0' + String.valueOf(prevMonthMid.month()) : String.valueOf(prevMonthMid.month())) + '-' + 
                (prevMonthMid.day() < 10 ? '0' + String.valueOf(prevMonthMid.day()) : String.valueOf(prevMonthMid.day()));
            String prevMonthEndStr = String.valueOf(prevMonthEnd.year()) + '-' + 
                (prevMonthEnd.month() < 10 ? '0' + String.valueOf(prevMonthEnd.month()) : String.valueOf(prevMonthEnd.month())) + '-' + 
                (prevMonthEnd.day() < 10 ? '0' + String.valueOf(prevMonthEnd.day()) : String.valueOf(prevMonthEnd.day()));
            
            pcQuery += 'AND ((Manual_Created_Date__c >= ' + currentMonthStartStr + 
                ' AND Manual_Created_Date__c <= ' + currentMonthMidStr + ')' +
                ' OR (Manual_Created_Date__c >= ' + prevMonthMidStr + 
                ' AND Manual_Created_Date__c <= ' + prevMonthEndStr + '))';
        } else {
            // For start-of-month run, get full months
            pcQuery += 'AND Manual_Created_Date__c = LAST_N_MONTHS:6';
        }
        
        System.debug('PC Query: ' + pcQuery);
        List<ProductConsumed> pcList = Database.query(pcQuery);
        
        for (ProductConsumed pc : pcList) {
            Id dealerId = pc.WorkOrder.Service_Center__c;
            Date manualCreatedDate = pc.Manual_Created_Date__c;
            
            // Skip if date doesn't match our specific ranges
            if (isMidMonthRun) {
                if (manualCreatedDate.month() == today.month() && manualCreatedDate.day() > 15) continue;
                if (manualCreatedDate.month() != today.month() && manualCreatedDate.day() < 16) continue;
            }
            
            Date monthStart = Date.newInstance(manualCreatedDate.year(), manualCreatedDate.month(), 1);
            String paddedMonth = monthStart.month() < 10 ? '0' + String.valueOf(monthStart.month()) : String.valueOf(monthStart.month());
            String monthKey = monthStart.year() + '-' + paddedMonth;
            String key = pc.Product__c + '_' + monthKey;
            
            if (!dealerMonthProductQtyMap.containsKey(dealerId)) {
                dealerMonthProductQtyMap.put(dealerId, new Map<String, Decimal>());
            }
            Map<String, Decimal> innerMap = dealerMonthProductQtyMap.get(dealerId);
            innerMap.put(key, (innerMap.containsKey(key) ? innerMap.get(key) : 0) + pc.Quantity_Consumed__c);
        }
        
        // Process Sales_Consumption__c records with date filtering
        // Process Sales_Consumption__c records with date filtering
        // Process Sales_Consumption__c records with date filtering
        // Process Sales_Consumption__c records with date filtering
        // Process Sales_Consumption__c records with date filtering
        // Process Sales_Consumption__c records with date filtering
        // Process ProductConsumed records with date filtering
        // Process Sales_Consumption__c records with date filtering
        // Process Sales_Consumption__c records with date filtering
        String scQuery = 'SELECT Product__c, Quantity_Consumed__c, Order__r.Dealer__c, CreatedDate, Manual_Date_Test__c ' +
            'FROM Sales_Consumption__c ' +
            'WHERE Product__c IN :productIds ' +
            'AND Order__r.Dealer__c != null ';
        
        if (isMidMonthRun) {
            Date currentMonthStart = Date.newInstance(today.year(), today.month(), 1);
            Date currentMonthMid = Date.newInstance(today.year(), today.month(), 15);
            Date prevMonthMid = Date.newInstance(today.year(), today.month(), 1).addMonths(-1).addDays(15);
            Date prevMonthEnd = Date.newInstance(today.year(), today.month(), 1).addDays(-1);
            
            // Format dates in YYYY-MM-DD format with proper string conversion
            String currentMonthStartStr = String.valueOf(currentMonthStart.year()) + '-' + 
                (currentMonthStart.month() < 10 ? '0' + String.valueOf(currentMonthStart.month()) : String.valueOf(currentMonthStart.month())) + '-' + 
                (currentMonthStart.day() < 10 ? '0' + String.valueOf(currentMonthStart.day()) : String.valueOf(currentMonthStart.day()));
            String currentMonthMidStr = String.valueOf(currentMonthMid.year()) + '-' + 
                (currentMonthMid.month() < 10 ? '0' + String.valueOf(currentMonthMid.month()) : String.valueOf(currentMonthMid.month())) + '-' + 
                (currentMonthMid.day() < 10 ? '0' + String.valueOf(currentMonthMid.day()) : String.valueOf(currentMonthMid.day()));
            String prevMonthMidStr = String.valueOf(prevMonthMid.year()) + '-' + 
                (prevMonthMid.month() < 10 ? '0' + String.valueOf(prevMonthMid.month()) : String.valueOf(prevMonthMid.month())) + '-' + 
                (prevMonthMid.day() < 10 ? '0' + String.valueOf(prevMonthMid.day()) : String.valueOf(prevMonthMid.day()));
            String prevMonthEndStr = String.valueOf(prevMonthEnd.year()) + '-' + 
                (prevMonthEnd.month() < 10 ? '0' + String.valueOf(prevMonthEnd.month()) : String.valueOf(prevMonthEnd.month())) + '-' + 
                (prevMonthEnd.day() < 10 ? '0' + String.valueOf(prevMonthEnd.day()) : String.valueOf(prevMonthEnd.day()));
            
            scQuery += 'AND ((Manual_Date_Test__c >= ' + currentMonthStartStr + 
                ' AND Manual_Date_Test__c <= ' + currentMonthMidStr + ')' +
                ' OR (Manual_Date_Test__c >= ' + prevMonthMidStr + 
                ' AND Manual_Date_Test__c <= ' + prevMonthEndStr + '))';
        } else {
            scQuery += 'AND Manual_Date_Test__c = LAST_N_MONTHS:6';
        }
        
        List<Sales_Consumption__c> scList = Database.query(scQuery);
        
        for (Sales_Consumption__c sc : scList) {
            Id dealerId = sc.Order__r.Dealer__c;
            Date manualDate = sc.Manual_Date_Test__c;
            
            // Skip if date doesn't match our specific ranges
            if (isMidMonthRun) {
                if (manualDate.month() == today.month() && manualDate.day() > 15) continue;
                if (manualDate.month() != today.month() && manualDate.day() < 16) continue;
            }
            
            Date monthStart = Date.newInstance(manualDate.year(), manualDate.month(), 1);
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
        
        // Create batch summaries
        List<MSL_Batch_Summary__c> summariesToInsert = new List<MSL_Batch_Summary__c>();
        for (Id dealerId : dealerMonthProductQtyMap.keySet()) {
            MSL_Batch_Summary__c summary = new MSL_Batch_Summary__c(
                Dealer__c = dealerId,
                Batch_Run_Date__c = today,
                Batch_Start_Date__c = runStartDate,
                Batch_End_Date__c = runEndDate
            );
            summariesToInsert.add(summary);
        }
        
        insert summariesToInsert;
        
        // Map dealers to their summary IDs
        Map<Id, Id> dealerToSummaryIdMap = new Map<Id, Id>();
        for (MSL_Batch_Summary__c summary : summariesToInsert) {
            dealerToSummaryIdMap.put(summary.Dealer__c, summary.Id);
        }
        
        // Create month splits
        List<Month_Split__c> monthSplitsToInsert = new List<Month_Split__c>();
        
        for (Id dealerId : dealerMonthProductQtyMap.keySet()) {
            Id summaryId = dealerToSummaryIdMap.get(dealerId);
            if (summaryId == null) continue;
            
            Map<String, Decimal> innerMap = dealerMonthProductQtyMap.get(dealerId);
            for (String key : innerMap.keySet()) {
                List<String> parts = key.split('_');
                if (parts.size() != 2) continue;
                
                // Skip if product ID is not valid
                if (!(parts[0] instanceOf Id)) continue;
                
                Id productId = Id.valueOf(parts[0]);
                String monthStr = parts[1];
                
                List<String> dateParts = monthStr.split('-');
                if (dateParts.size() != 2) continue;
                
                Integer year = Integer.valueOf(dateParts[0]);
                Integer month = Integer.valueOf(dateParts[1]);
                
                Date startDate = Date.newInstance(year, month, 1);
                Date endDate = startDate.addMonths(1).addDays(-1);
                
                // Determine if this is for a full month or partial month
                String monthSequence;
                Date currentMonthStart = Date.newInstance(today.year(), today.month(), 1);
                
                if (startDate == currentMonthStart) {
                    // Current month - check if we're in mid-month run
                    if (isMidMonthRun) {
                        monthSequence = 'Partial (' + runStartDate.day() + '-' + runEndDate.day() + ')';
                    } else {
                        monthSequence = 'Full (1-' + endDate.day() + ')';
                    }
                } else {
                    // Previous months - always full month
                    monthSequence = 'Full (1-' + endDate.day() + ')';
                }
                
                String label = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)).format('MMMM');
                
                monthSplitsToInsert.add(new Month_Split__c(
                    Product__c = productId,
                    Month_Name__c = label,
                    Quantity__c = innerMap.get(key),
                    MSL_Batch_Summary__c = summaryId,
                    Start_Date__c = startDate,
                    End_Date__c = endDate,
                    Month_Sequence__c = monthSequence
                ));
            }
        }
        
        // Insert in chunks to avoid governor limits
        List<Month_Split__c> chunkList = new List<Month_Split__c>();
        for (Month_Split__c split : monthSplitsToInsert) {
            chunkList.add(split);
            if (chunkList.size() == 200) {
                insert chunkList;
                chunkList.clear();
            }
        }
        
        if (!chunkList.isEmpty()) {
            insert chunkList;
        }
        // Rest of the execute method remains the same...
        // [Previous code for creating summaries and month splits]
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Batch Process Completed');
    }
}