global class RVR_New_MSLBatch implements Database.Batchable<SObject>, Database.Stateful {

    Date today = Date.today();
    Date runStartDate = today.addMonths(-6).toStartOfMonth();
    Date runEndDate = today;

    Map<Id, Map<String, Map<Id, Decimal>>> dealerMonthProductQtyMap = new Map<Id, Map<String, Map<Id, Decimal>>>();
    List<MSL_Batch_Summary__c> summaries = new List<MSL_Batch_Summary__c>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id FROM Account WHERE Type = 'Dealer'
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Account> dealers) {
        for (Account dealer : dealers) {
            Map<String, Map<Id, Decimal>> monthProductQtyMap = new Map<String, Map<Id, Decimal>>();

            List<ProductConsumed> prodRecords = [
                SELECT Product__c, Quantity_Consumed__c, Manual_Created_Date__c, WorkOrder.Service_Center__c
                FROM ProductConsumed
                WHERE Manual_Created_Date__c >= :runStartDate
                  AND WorkOrder.Service_Center__c = :dealer.Id
            ];

            List<Sales_Consumption__c> salesRecords = [
                SELECT Product__c, Quantity_Consumed__c, Manual_Date_Test__c,Order__r.Dealer__c
                FROM Sales_Consumption__c
                WHERE Manual_Date_Test__c >= :runStartDate and Quantity_Consumed__c !=null
                  AND   Order__r.Dealer__c = :dealer.Id
            ];

            // Group ProductConsumed
            for (ProductConsumed pc : prodRecords) {
                String monthKey = pc.Manual_Created_Date__c.year() + '-' + String.valueOf(pc.Manual_Created_Date__c.month()).leftPad(2, '0');
                if (!monthProductQtyMap.containsKey(monthKey)) monthProductQtyMap.put(monthKey, new Map<Id, Decimal>());
                Map<Id, Decimal> prodMap = monthProductQtyMap.get(monthKey);
                prodMap.put(pc.Product__c, (prodMap.containsKey(pc.Product__c) ? prodMap.get(pc.Product__c) : 0) + pc.Quantity_Consumed__c);
            }

            // Group Sales_Consumption
            for (Sales_Consumption__c sc : salesRecords) {
                String monthKey = sc.Manual_Date_Test__c.year() + '-' + String.valueOf(sc.Manual_Date_Test__c.month()).leftPad(2, '0');
                if (!monthProductQtyMap.containsKey(monthKey)) monthProductQtyMap.put(monthKey, new Map<Id, Decimal>());
                Map<Id, Decimal> prodMap = monthProductQtyMap.get(monthKey);
                prodMap.put(sc.Product__c, (prodMap.containsKey(sc.Product__c) ? prodMap.get(sc.Product__c) : 0) + sc.Quantity_Consumed__c);
            }

            dealerMonthProductQtyMap.put(dealer.Id, monthProductQtyMap);
        }
    }

    global void finish(Database.BatchableContext BC) {
        List<Month_Split__c> monthSplits = new List<Month_Split__c>();
        Map<Id, Id> dealerToSummaryId = new Map<Id, Id>();

        for (Id dealerId : dealerMonthProductQtyMap.keySet()) {
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

        for (Id dealerId : dealerMonthProductQtyMap.keySet()) {
            Id summaryId = dealerToSummaryId.get(dealerId);
            Map<String, Map<Id, Decimal>> monthMap = dealerMonthProductQtyMap.get(dealerId);
            System.debug('monthMap: ' + monthMap);

            // Build product → monthly quantities
            Map<Id, List<Decimal>> productQtyListMap = new Map<Id, List<Decimal>>();
            Map<Id, String> productLastMonthKey = new Map<Id, String>();
            Map<Id, String> productFirstMonthKey = new Map<Id, String>();

            for (String monthKey : monthMap.keySet()) {
                Map<Id, Decimal> productQtyMap = monthMap.get(monthKey);
                for (Id productId : productQtyMap.keySet()) {
                    Decimal qty = productQtyMap.get(productId);
                    if (!productQtyListMap.containsKey(productId)) {
                        productQtyListMap.put(productId, new List<Decimal>());
                    }
                    productQtyListMap.get(productId).add(qty);
                    // track latest monthKey (string-wise sorting = chronological)
                    if (!productLastMonthKey.containsKey(productId) || monthKey > productLastMonthKey.get(productId)) {
                        productLastMonthKey.put(productId, monthKey);
                    }
                    // track earliest monthKey (string-wise sorting = chronological)
                    if (!productFirstMonthKey.containsKey(productId) || monthKey < productFirstMonthKey.get(productId)) {
                        productFirstMonthKey.put(productId, monthKey);
                    }
                }
            }

            for (Id productId : productQtyListMap.keySet()) {
                List<Decimal> quantities = productQtyListMap.get(productId);
                Decimal totalQty = 0;
                Integer validMonths = 0;
                Integer consecutiveZeroMonths = 0;
                Integer maxConsecutiveZeroMonths = 0;

                for (Decimal q : quantities) {
                    if (q > 0) {
                        totalQty += q;
                        validMonths++;
                        consecutiveZeroMonths = 0; // Reset counter
                    } else {
                        consecutiveZeroMonths++;
                        if (consecutiveZeroMonths > maxConsecutiveZeroMonths) {
                            maxConsecutiveZeroMonths = consecutiveZeroMonths;
                        }
                    }
                }

                // Skip products with more than 3 consecutive months of zero quantity
                if (maxConsecutiveZeroMonths > 3) continue;
                if (validMonths == 0) continue;

                Decimal avgQty = totalQty / validMonths;

                // Get latest month of sale
                String lastMonthKey = productLastMonthKey.get(productId);
                String firstMonthKey = productFirstMonthKey.get(productId);
                System.debug('lastMonthKey: ' + lastMonthKey);
                System.debug('firstMonthKey: ' + firstMonthKey);
                
                // Parse the monthKey (format: YYYY-MM) to create a proper date
                List<String> monthParts = lastMonthKey.split('-');
                Integer year = Integer.valueOf(monthParts[0]);
                Integer month = Integer.valueOf(monthParts[1]);
                Date monthDate = Date.newInstance(year, month, 1);

                // Check if this is the first month (earliest month where product was sold)
                Boolean isFirstMonth = (lastMonthKey == firstMonthKey);
                
                Date startDate, endDate;
                
                if (isFirstMonth) {
                    // For first month: start from today's date in that month, end at end of month
                    startDate = Date.newInstance(year, month, today.day());
                    endDate = monthDate.addMonths(1).addDays(-1);
                } else {
                    // For other months: start from 1st of month, end at end of month
                    startDate = monthDate;
                    endDate = monthDate.addMonths(1).addDays(-1);
                }
                
                // For last month (most recent month), end date should be today's date
                if (isFirstMonth == false) {
                    // Check if this is the current month (last month)
                    Boolean isCurrentMonth = (year == today.year() && month == today.month());
                    if (isCurrentMonth) {
                        endDate = today;
                    }
                }

                // Get month name from the date
                String monthName = getMonthName(month);

                Month_Split__c split = new Month_Split__c(
                    Product__c = productId,
                    Quantity__c = avgQty.setScale(0),
                    MSL_Batch_Summary__c = summaryId,
                    Start_Date__c = startDate,
                    End_Date__c = endDate,
                    Month_Sequence__c = '1',
                    Month_Name__c = monthName
                );

                monthSplits.add(split);
            }

        }

        insert monthSplits;
    }


    
    private String getMonthName(Integer month) {
        Map<Integer, String> monthNames = new Map<Integer, String>{
            1 => 'January',
            2 => 'February', 
            3 => 'March',
            4 => 'April',
            5 => 'May',
            6 => 'June',
            7 => 'July',
            8 => 'August',
            9 => 'September',
            10 => 'October',
            11 => 'November',
            12 => 'December'
        };
        return monthNames.get(month);
    }
}