global without sharing class shiva_MSLAggregatorBatchClass implements Database.Batchable<SObject>, Database.Stateful {
    
    global Map<Id, Map<String, Decimal>> dealerMonthProductQtyMap = new Map<Id, Map<String, Decimal>>();
    global Date today = Date.today();
    global Boolean isMidMonthRun = today.day() >= 16;
    global Date runStartDate;
    global Date runEndDate;
    global Set<Id> allDealerIds = new Set<Id>();

    global shiva_MSLAggregatorBatchClass() {
        // Calculate date ranges based on run type
        if (isMidMonthRun) {
            // For run on 16th: process current month (1-15) and previous month (16-end)
            runStartDate = Date.newInstance(today.year(), today.month(), 1).addMonths(-6).addDays(15);
            runEndDate = Date.newInstance(today.year(), today.month(), 15);
        } else {
            // For run on 1st: process full previous month
            runStartDate = Date.newInstance(today.year(), today.month(), 1).addMonths(-1);
            runEndDate = runStartDate.addMonths(1).addDays(-1);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Directly query consumption records in date range
        system.debug('runStartDate---'+runStartDate);
        system.debug('runEndDate---'+runEndDate);
        String query = 'SELECT Id, ' +
            'Manual_Created_Date__c, WorkOrder.Service_Center__c, Product__c, Quantity_Consumed__c ' +
            'FROM ProductConsumed ' +
            'WHERE Manual_Created_Date__c >= :runStartDate ';
            
            //'AND WorkOrder.Service_Center__c != null ' +
            //'ALL ROWS ';

//'AND Manual_Created_Date__c <= :runEndDate ' +        
        system.debug('ProductConsumed-query---'+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        // Process ProductConsumed records
        for (SObject sObj : scope) {
            ProductConsumed pc = (ProductConsumed)sObj;
            Id dealerId = pc.WorkOrder.Service_Center__c;
            processRecord(
                dealerId,
                pc.Product__c,
                pc.Quantity_Consumed__c,
                pc.Manual_Created_Date__c
            );
            allDealerIds.add(dealerId);
        }
        
        // Directly query Sales_Consumption__c in date range
        List<Sales_Consumption__c> scList = [
            SELECT Product__c, Quantity_Consumed__c, 
                   Order__r.Dealer__c, Manual_Date_Test__c 
            FROM Sales_Consumption__c 
            WHERE Manual_Date_Test__c >= :runStartDate
            //AND Manual_Date_Test__c <= :runEndDate
            AND Order__r.Dealer__c != null
        ];
         system.debug('scList---'+scList);
        // Process Sales_Consumption__c records
        for (Sales_Consumption__c sc : scList) {
            Id dealerId = sc.Order__r.Dealer__c;
            processRecord(
                dealerId,
                sc.Product__c,
                sc.Quantity_Consumed__c,
                sc.Manual_Date_Test__c
            );
            allDealerIds.add(dealerId);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Create batch summaries
        List<MSL_Batch_Summary__c> summaries = new List<MSL_Batch_Summary__c>();
        Map<Id, Id> dealerToSummaryId = new Map<Id, Id>();
        
        for (Id dealerId : allDealerIds) {
            MSL_Batch_Summary__c summary = new MSL_Batch_Summary__c(
                Dealer__c = dealerId,
                Batch_Run_Date__c = today,
                Batch_Start_Date__c = runStartDate,
                Batch_End_Date__c = runEndDate
            );
            summaries.add(summary);
        }
        insert summaries;
        
        for (MSL_Batch_Summary__c summary : summaries) {
            dealerToSummaryId.put(summary.Dealer__c, summary.Id);
        }
        
        // Create month splits
        List<Month_Split__c> monthSplits = new List<Month_Split__c>();
        
        for (Id dealerId : dealerMonthProductQtyMap.keySet()) {
            Map<String, Decimal> productQtyMap = dealerMonthProductQtyMap.get(dealerId);
            Id summaryId = dealerToSummaryId.get(dealerId);
            
            for (String key : productQtyMap.keySet()) {
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
                
                // Determine period type
                String monthSequence;
                if (startDate.month() == today.month() && isMidMonthRun) {
                    monthSequence = '1-15';
                } else if (startDate.month() == today.addMonths(-1).month() && isMidMonthRun) {
                    monthSequence = '16-' + endDate.day();
                } else {
                    monthSequence = '1-' + endDate.day();
                }
                
                monthSplits.add(new Month_Split__c(
                    Product__c = productId,
                    Month_Name__c = DateTime.newInstance(startDate, Time.newInstance(0,0,0,0)).format('MMMM'),
                    Quantity__c = productQtyMap.get(key),
                    MSL_Batch_Summary__c = summaryId,
                    Start_Date__c = startDate,
                    End_Date__c = endDate,
                    Month_Sequence__c = monthSequence
                ));
            }
        }
        
        // Insert in chunks
        List<Month_Split__c> chunk = new List<Month_Split__c>();
        for (Month_Split__c split : monthSplits) {
            chunk.add(split);
            if (chunk.size() == 200) {
                insert chunk;
                chunk.clear();
            }
        }
        if (!chunk.isEmpty()) insert chunk;
    }
    
    private void processRecord(Id dealerId, Id productId, Decimal quantity, Date transDate) {
        // Skip if date is outside processing range
        if (transDate < runStartDate || transDate > runEndDate) return;
        
        // Validate half-month periods
        if (isMidMonthRun) {
            // For mid-month runs:
            // - Current month: only process days 1-15
            // - Previous month: only process days 16+
            if (transDate.month() == today.month() && transDate.day() > 15) return;
            if (transDate.month() == today.addMonths(-1).month() && transDate.day() < 16) return;
        }
        
        // Generate period key (YYYY-MM format)
        String monthKey = transDate.year() + '-' + 
            (transDate.month() < 10 ? '0' + transDate.month() : String.valueOf(transDate.month()));
        
        String mapKey = productId + '_' + monthKey;
        
        if (!dealerMonthProductQtyMap.containsKey(dealerId)) {
            dealerMonthProductQtyMap.put(dealerId, new Map<String, Decimal>());
        }
        
        Map<String, Decimal> innerMap = dealerMonthProductQtyMap.get(dealerId);
        innerMap.put(mapKey, innerMap.get(mapKey) != null ? innerMap.get(mapKey) + quantity : quantity);
    }
}