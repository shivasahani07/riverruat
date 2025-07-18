/**
 * Batch Class to calculate MSL after 6 months (simulated with 20 days for testing) directly from Sales_Consumption__c
 * and store the results in ProductConsumptionTracking__c
 */
global class MSLCalculationBatch implements Database.Batchable<SObject>, Schedulable {

    global void execute(SchedulableContext sc) {
        MSLCalculationBatch batch = new MSLCalculationBatch();
        Database.executeBatch(batch, 50);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Product__c, Order__c, CreatedDate, Quantity_Consumed__c
            FROM Sales_Consumption__c
            WHERE Product__c != null AND Order__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
	
        System.debug('Scope Size : ' + scope.size());
        Map<String, List<Sales_Consumption__c>> dealerProductConsumptionMap = new Map<String, List<Sales_Consumption__c>>();
        Set<Id> orderIds = new Set<Id>();

        for(SObject s : scope) {
            Sales_Consumption__c con = (Sales_Consumption__c) s;
            orderIds.add(con.Order__c);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId FROM Order WHERE Id IN :orderIds
        ]);

        List<ProductConsumptionTracking__c> toUpsert = new List<ProductConsumptionTracking__c>();

        for(SObject s : scope) {
            Sales_Consumption__c con = (Sales_Consumption__c) s;

            if(con.Product__c != null && con.Order__c != null && orderMap.containsKey(con.Order__c)) {
                Id dealerId = orderMap.get(con.Order__c).AccountId;
                if(dealerId == null) continue;

                String key = dealerId + '-' + con.Product__c;

                if(!dealerProductConsumptionMap.containsKey(key)) {
                    dealerProductConsumptionMap.put(key, new List<Sales_Consumption__c>());
                }
                dealerProductConsumptionMap.get(key).add(con);
            }
        }

        for(String key : dealerProductConsumptionMap.keySet()) {
            List<Sales_Consumption__c> consumptions = dealerProductConsumptionMap.get(key);
            if(consumptions.isEmpty()) continue;

            String[] parts = key.split('-');
            Id dealerId = parts[0];
            Id productId = parts[1];
			
            // Find the First Consumption Date of the Product...
            Date firstConsumptionDate = null;
            for(Sales_Consumption__c con : consumptions) {
                Date consumptionDate = con.CreatedDate.date();
                if(firstConsumptionDate == null || consumptionDate < firstConsumptionDate) {
                    firstConsumptionDate = consumptionDate;
                }
            }
            if(firstConsumptionDate == null) continue;

            Date sixMonthMark = firstConsumptionDate.addDays(20); // Simulating 6 months with 20 days for testing
            if(Date.today() < sixMonthMark) continue;

            Date sixMonthsAgo = Date.today().addDays(-20).toStartOfMonth();

            Map<Date, Decimal> monthlyConsumption = new Map<Date, Decimal>();

            for(Sales_Consumption__c con : consumptions) {
                Date consumptionDate = con.CreatedDate.date();

                if(consumptionDate >= sixMonthsAgo) {
                    Date monthStart = consumptionDate.toStartOfMonth();
                    if(!monthlyConsumption.containsKey(monthStart)) {
                        monthlyConsumption.put(monthStart, 0);
                    }
                    monthlyConsumption.put(monthStart, monthlyConsumption.get(monthStart) + con.Quantity_Consumed__c);
                }
            }

            Date thisMonth = Date.today().toStartOfMonth();
            Date lastMonth = thisMonth.addMonths(-1);
            Date secondLastMonth = thisMonth.addMonths(-2);

            Decimal lastMonthConsumption = monthlyConsumption.containsKey(lastMonth) ? monthlyConsumption.get(lastMonth) : 0;
            Decimal secondLastMonthConsumption = monthlyConsumption.containsKey(secondLastMonth) ? monthlyConsumption.get(secondLastMonth) : 0;

            if (lastMonthConsumption == 0 && secondLastMonthConsumption == 0) {
                continue; // Skip MSL logic as last 2 months have 0 consumption
            }

            Decimal totalConsumption = 0;
            Integer activeMonths = 0;

            for(Integer i = 0; i < 6; i++) {
                Date month = thisMonth.addMonths(-i);
                if(monthlyConsumption.containsKey(month) && monthlyConsumption.get(month) > 0) {
                    totalConsumption += monthlyConsumption.get(month);
                    activeMonths++;
                }
            }

            if(activeMonths == 0) {
                continue; // No active months, skip MSL logic
            }

            Decimal avgConsumption = totalConsumption / activeMonths;

            ProductConsumptionTracking__c track = new ProductConsumptionTracking__c();
            track.Account__c = dealerId;
            track.Product__c = productId;
            track.MSL_Value__c = avgConsumption;
            track.Is_MSL_Eligible__c = true;
            track.Last_MSL_Calculated_Date__c = Date.today();
            track.Unique_Key__c = dealerId + '-' + productId;

            toUpsert.add(track);
        }

        if(!toUpsert.isEmpty()) {
            upsert toUpsert Unique_Key__c;
        }
    }

    global void finish(Database.BatchableContext bc) {}
}



/*
 * Batch Class to calculate MSL after 6 months directly from Sales_Consumption__c
 * and store the results in ProductConsumptionTracking__c
 */

/*
global class MSLCalculationBatch implements Database.Batchable<SObject>, Schedulable {

    global void execute(SchedulableContext sc) {
        MSLCalculationBatch batch = new MSLCalculationBatch();
        Database.executeBatch(batch, 50);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Product__c, Order__c, CreatedDate, Quantity_Consumed__c
            FROM Sales_Consumption__c
            WHERE Product__c != null AND Order__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        Map<String, List<Sales_Consumption__c>> dealerProductConsumptionMap = new Map<String, List<Sales_Consumption__c>>();
        Set<Id> orderIds = new Set<Id>();

        for(SObject s : scope) {
            Sales_Consumption__c con = (Sales_Consumption__c) s;
            orderIds.add(con.Order__c);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId FROM Order WHERE Id IN :orderIds
        ]);
        System.debug('orderMap : ' + orderMap.size());

        for(SObject s : scope) {
            Sales_Consumption__c con = (Sales_Consumption__c) s;

            if(con.Product__c != null && con.Order__c != null && orderMap.containsKey(con.Order__c)) {
                Id dealerId = orderMap.get(con.Order__c).AccountId;
                if(dealerId == null) continue;

                String key = dealerId + '-' + con.Product__c;

                if(!dealerProductConsumptionMap.containsKey(key)) {
                    dealerProductConsumptionMap.put(key, new List<Sales_Consumption__c>());
                }
                dealerProductConsumptionMap.get(key).add(con);  // dealerProductConsumptionMap(dealer-product, List<Sales_Consumption__c>());
            }
        }
        System.debug('dealerProductConsumptionMap : ' + dealerProductConsumptionMap.size());

        List<ProductConsumptionTracking__c> toUpsert = new List<ProductConsumptionTracking__c>();

        for(String key : dealerProductConsumptionMap.keySet()) {
            List<Sales_Consumption__c> consumptions = dealerProductConsumptionMap.get(key);
            if(consumptions.isEmpty()) continue;

            String[] parts = key.split('-');
            Id dealerId = parts[0];
            Id productId = parts[1];

            Date firstConsumptionDate = null;
            for(Sales_Consumption__c con : consumptions) {
                Date consumptionDate = con.CreatedDate.date();
                if(firstConsumptionDate == null || consumptionDate < firstConsumptionDate) {
                    firstConsumptionDate = consumptionDate;
                }
            }
			System.debug('firstConsumptionDate : ' + firstConsumptionDate);
            if(firstConsumptionDate == null) continue;
			
            // firstConsumptionDate = 01/01/2025
            // sixMonthMark = 01/07/2025
            // Today = 02/07/2025
            // Check if 6 Months are completed.
            Date sixMonthMark = firstConsumptionDate.addMonths(6);	//Date sixMonthMark = firstConsumptionDate.addMonths(6);
            System.debug('sixMonthMark : ' + sixMonthMark);
            if(Date.today() < sixMonthMark) continue;

            Date sixMonthsAgo = Date.today().addMonths(6).toStartOfMonth(); // 01/01/2025
			System.debug('sixMonthsAgo : ' + sixMonthsAgo);
            
            Map<Date, Decimal> monthlyConsumption = new Map<Date, Decimal>();

            for(Sales_Consumption__c con : consumptions) {
                Date consumptionDate = con.CreatedDate.date();

                if(consumptionDate >= sixMonthsAgo) {						// 15/01/2025 > 01/01/2025
                    Date monthStart = consumptionDate.toStartOfMonth();
                    if(!monthlyConsumption.containsKey(monthStart)) {
                        monthlyConsumption.put(monthStart, 0);
                    }
                    monthlyConsumption.put(monthStart, monthlyConsumption.get(monthStart) + con.Quantity_Consumed__c);
                }
            }
            
            System.debug('Monthly Consumption Map Size: ' + monthlyConsumption.size());
            for(Date d : monthlyConsumption.keySet()){
                System.debug(d + ' : ' + monthlyConsumption.get(d));
            }

            Integer zeroStreak = 0;
            Integer maxZeroStreak = 0;
            Decimal totalConsumption = 0;
            Integer activeMonths = 0;

            for(Integer i = 0; i < 6; i++) {
                Date month = Date.today().addMonths(-i).toStartOfMonth();

                if(monthlyConsumption.containsKey(month) && monthlyConsumption.get(month) > 0) {
                    totalConsumption += monthlyConsumption.get(month);
                    activeMonths++;
                    zeroStreak = 0;
                } else {
                    zeroStreak++;
                    if(zeroStreak > maxZeroStreak) {
                        maxZeroStreak = zeroStreak;
                    }
                }
            }
			System.debug('totalConsumption : ' + totalConsumption);
            System.debug('maxZeroStreak : ' + maxZeroStreak);
            
            if(maxZeroStreak >= 2 || activeMonths == 0) {
                //continue;
            }

            Decimal avgConsumption = totalConsumption / activeMonths;

            ProductConsumptionTracking__c track = new ProductConsumptionTracking__c();
            track.Account__c = dealerId;
            track.Product__c = productId;
            track.MSL_Value__c = avgConsumption;
            track.Is_MSL_Eligible__c = true;
            track.Last_MSL_Calculated_Date__c = Date.today();
            track.Unique_Key__c = dealerId + '-' + productId;

            toUpsert.add(track);
            System.debug('----------------- Upserted -----------------');
        }

        if(!toUpsert.isEmpty()) {
            upsert toUpsert Unique_Key__c;
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}
*/
/**
 * Batch Class to calculate MSL after 20 days directly from Sales_Consumption__c for testing
 * and store the results in ProductConsumptionTracking__c
 */
/*
global class MSLCalculationBatch implements Database.Batchable<SObject>, Schedulable {

    global void execute(SchedulableContext sc) {
        MSLCalculationBatch batch = new MSLCalculationBatch();
        Database.executeBatch(batch, 50);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Product__c, Order__c, CreatedDate, Quantity_Consumed__c
            FROM Sales_Consumption__c
            WHERE Product__c != null AND Order__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        Map<String, List<Sales_Consumption__c>> dealerProductConsumptionMap = new Map<String, List<Sales_Consumption__c>>();
        Set<Id> orderIds = new Set<Id>();

        for(SObject s : scope) {
            Sales_Consumption__c con = (Sales_Consumption__c) s;
            orderIds.add(con.Order__c);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId FROM Order WHERE Id IN :orderIds
        ]);
        System.debug('orderMap : ' + orderMap.size());

        for(SObject s : scope) {
            Sales_Consumption__c con = (Sales_Consumption__c) s;

            if(con.Product__c != null && con.Order__c != null && orderMap.containsKey(con.Order__c)) {
                Id dealerId = orderMap.get(con.Order__c).AccountId;
                if(dealerId == null) continue;

                String key = dealerId + '-' + con.Product__c;

                if(!dealerProductConsumptionMap.containsKey(key)) {
                    dealerProductConsumptionMap.put(key, new List<Sales_Consumption__c>());
                }
                dealerProductConsumptionMap.get(key).add(con);
            }
        }
        System.debug('dealerProductConsumptionMap : ' + dealerProductConsumptionMap.size());

        List<ProductConsumptionTracking__c> toUpsert = new List<ProductConsumptionTracking__c>();

        for(String key : dealerProductConsumptionMap.keySet()) {
            List<Sales_Consumption__c> consumptions = dealerProductConsumptionMap.get(key);
            if(consumptions.isEmpty()) continue;

            String[] parts = key.split('-');
            Id dealerId = parts[0];
            Id productId = parts[1];

            Date firstConsumptionDate = null;
            for(Sales_Consumption__c con : consumptions) {
                Date consumptionDate = con.CreatedDate.date();
                if(firstConsumptionDate == null || consumptionDate < firstConsumptionDate) {
                    firstConsumptionDate = consumptionDate;
                }
            }
            System.debug('firstConsumptionDate : ' + firstConsumptionDate);
            if(firstConsumptionDate == null) continue;

            Date twentyDayMark = firstConsumptionDate.addDays(20);
            System.debug('twentyDayMark : ' + twentyDayMark);
            if(Date.today() < twentyDayMark) continue;

            Date twentyDaysAgo = Date.today().addDays(-20);
            System.debug('twentyDaysAgo : ' + twentyDaysAgo);

            Map<Date, Decimal> dailyConsumption = new Map<Date, Decimal>();

            for(Sales_Consumption__c con : consumptions) {
                Date consumptionDate = con.CreatedDate.date();

                if(consumptionDate >= twentyDaysAgo) {
                    if(!dailyConsumption.containsKey(consumptionDate)) {
                        dailyConsumption.put(consumptionDate, 0);
                    }
                    dailyConsumption.put(consumptionDate, dailyConsumption.get(consumptionDate) + con.Quantity_Consumed__c);
                }
            }

            for(Date d : dailyConsumption.keySet()){
                System.debug(d + ' : ' + dailyConsumption.get(d));
            }

            Integer zeroStreak = 0;
            Integer maxZeroStreak = 0;
            Decimal totalConsumption = 0;
            Integer activeDays = 0;

            for(Integer i = 0; i < 20; i++) {
                Date day = Date.today().addDays(-i);

                if(dailyConsumption.containsKey(day) && dailyConsumption.get(day) > 0) {
                    totalConsumption += dailyConsumption.get(day);
                    activeDays++;
                    zeroStreak = 0;
                } else {
                    zeroStreak++;
                    if(zeroStreak > maxZeroStreak) {
                        maxZeroStreak = zeroStreak;
                    }
                }
            }

            if(maxZeroStreak >= 2 || activeDays == 0) {
                continue;
            }

            Decimal avgConsumption = totalConsumption / activeDays;

            ProductConsumptionTracking__c track = new ProductConsumptionTracking__c();
            track.Account__c = dealerId;
            track.Product__c = productId;
            track.MSL_Value__c = avgConsumption;
            track.Is_MSL_Eligible__c = true;
            track.Last_MSL_Calculated_Date__c = Date.today();
            track.Unique_Key__c = dealerId + '-' + productId;

            toUpsert.add(track);
            System.debug('----------------- Upserted -----------------');
        }

        if(!toUpsert.isEmpty()) {
            upsert toUpsert Unique_Key__c;
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}
*/