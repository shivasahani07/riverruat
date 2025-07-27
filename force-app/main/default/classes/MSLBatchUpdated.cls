/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-27-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global with sharing class MSLBatchUpdated implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<Id> consumedProductIds = new Set<Id>();

        
    for (AggregateResult ar : [SELECT Product__c FROM ProductConsumed WHERE Manual_Created_Date__c = LAST_N_MONTHS:6 AND Product__c != null GROUP BY Product__c]) {
         consumedProductIds.add((Id) ar.get('Product__c'));
      }

    for (AggregateResult ar : [SELECT Product__c FROM Sales_Consumption__c WHERE Manual_Date_Test__c = LAST_N_MONTHS:6 AND Product__c != null GROUP BY Product__c ]) {
         consumedProductIds.add((Id) ar.get('Product__c'));
     }

        System.debug('★ start() → Total unique Product IDs consumed: ' + consumedProductIds.size());
        System.debug('Products Ids Are==>'+consumedProductIds);
        return Database.getQueryLocator([
            SELECT Id, Name FROM Product2 WHERE Id IN :consumedProductIds
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        Date today = Date.today();
        Date startDate = today.addMonths(-6);
        Set<Id> productIdsInScope = new Set<Id>();

        for (SObject s : scope) productIdsInScope.add(s.Id);
        System.debug('Scope size: ' + productIdsInScope.size());

       
        List<ProductConsumed> pcList = [
            SELECT Product__c, Quantity_Consumed__c, Manual_Created_Date__c,
                   WorkOrder.Service_Center__c
            FROM ProductConsumed 
            WHERE Manual_Created_Date__c >= :startDate 
            AND Product__c IN :productIdsInScope
            AND WorkOrder.Service_Center__c != null
        ];
        System.debug('ProductConsumed records fetched==> ' + pcList.size());

        
        List<Sales_Consumption__c> scList = [
            SELECT Product__c, Quantity_Consumed__c, Manual_Date_Test__c,
                   Order__r.Dealer__c 
            FROM Sales_Consumption__c 
            WHERE Manual_Date_Test__c >= :startDate 
            AND Product__c IN :productIdsInScope
            AND Order__r.Dealer__c != null
        ];
        System.debug('Sales_Consumption__c records fetched===>' + scList.size());

       
        Map<Id, Map<Id, Map<Integer, Decimal>>> accountProductMonthQtyMap = new Map<Id, Map<Id, Map<Integer, Decimal>>>();

        
        for (ProductConsumed pc : pcList) {
            Id accountId = pc.WorkOrder.Service_Center__c;
            Id productId = pc.Product__c;
            Integer monthIndex = Math.abs(today.monthsBetween(pc.Manual_Created_Date__c)) + 1;
            if (monthIndex < 1 || monthIndex > 6) continue;

            Decimal qty = pc.Quantity_Consumed__c != null ? pc.Quantity_Consumed__c : 0;

            System.debug('Account=' + accountId + ', Product=' + productId + ', Month=' + monthIndex + ', Qty=' + qty);

            if (!accountProductMonthQtyMap.containsKey(accountId))
                accountProductMonthQtyMap.put(accountId, new Map<Id, Map<Integer, Decimal>>());

            Map<Id, Map<Integer, Decimal>> productMap = accountProductMonthQtyMap.get(accountId);
            if (!productMap.containsKey(productId)) {
                Map<Integer, Decimal> monthMap = new Map<Integer, Decimal>();
                for (Integer i = 1; i <= 6; i++) monthMap.put(i, 0);
                productMap.put(productId, monthMap);
            }

            Map<Integer, Decimal> monthMap = productMap.get(productId);
            monthMap.put(monthIndex, monthMap.get(monthIndex) + qty);
        }

        
        for (Sales_Consumption__c sc : scList) {
            Id accountId = sc.Order__r.Dealer__c;
            Id productId = sc.Product__c;
            Integer monthIndex = Math.abs(today.monthsBetween(sc.Manual_Date_Test__c)) + 1;
            if (monthIndex < 1 || monthIndex > 6) continue;

            Decimal qty = sc.Quantity_Consumed__c != null ? sc.Quantity_Consumed__c : 0;

            System.debug('Account=' + accountId + ', Product=' + productId + ', Month=' + monthIndex + ', Qty=' + qty);

            if (!accountProductMonthQtyMap.containsKey(accountId))
                accountProductMonthQtyMap.put(accountId, new Map<Id, Map<Integer, Decimal>>());

            Map<Id, Map<Integer, Decimal>> productMap = accountProductMonthQtyMap.get(accountId);
            if (!productMap.containsKey(productId)) {
                Map<Integer, Decimal> monthMap = new Map<Integer, Decimal>();
                for (Integer i = 1; i <= 6; i++) monthMap.put(i, 0);
                productMap.put(productId, monthMap);
            }

            Map<Integer, Decimal> monthMap = productMap.get(productId);
            monthMap.put(monthIndex, monthMap.get(monthIndex) + qty);
        }

        System.debug('Total Dealer ==> ' + accountProductMonthQtyMap.keySet().size());

       
        List<MSL__c> mslList = new List<MSL__c>();
        Map<Id, MSL__c> accountToMSL = new Map<Id, MSL__c>();

        for (Id accId : accountProductMonthQtyMap.keySet()) {
            MSL__c msl = new MSL__c(Dealer__c = accId);
            mslList.add(msl);
            accountToMSL.put(accId, msl);
        }

        insert mslList;
        System.debug('mslListSize==>' + mslList.size());

        
        List<MSL_Consumption__c> mslcList = new List<MSL_Consumption__c>();

        for (Id accId : accountProductMonthQtyMap.keySet()) {
            MSL__c msl = accountToMSL.get(accId);
            Map<Id, Map<Integer, Decimal>> prodMap = accountProductMonthQtyMap.get(accId);

            for (Id prodId : prodMap.keySet()) {
                Map<Integer, Decimal> m = prodMap.get(prodId);

                Decimal total = 0;
                for (Integer i = 1; i <= 6; i++) total += m.get(i);

                MSL_Consumption__c mslc = new MSL_Consumption__c(
                    MSL_Batch__c = msl.Id,
                    Product__c = prodId,
                    X1st_Month__c = m.get(1),
                    X2nd_Month__c = m.get(2),
                    X3rd_Month__c = m.get(3),
                    X4th_Month__c = m.get(4),
                    X5th_Month__c = m.get(5),
                    X6th_Month__c = m.get(6),
                    Average_Quantity__c = total / 6
                );

                mslcList.add(mslc);
                System.debug(' Acc=' + accId + ', Prod=' + prodId + ', Avg=' + (total / 6));
            }
        }

        insert mslcList;
        System.debug('mslcList==> ' + mslcList.size());
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Exit');
    }
}