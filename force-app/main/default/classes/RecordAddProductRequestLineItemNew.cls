/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class RecordAddProductRequestLineItemNew {
    public class MonthSplitWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal quantityOrdered;
        @AuraEnabled public String monthName;
        @AuraEnabled public String monthSequence;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public Boolean poSubmitted;
    }

    
    @AuraEnabled(Cacheable = true)
    public static list<RecordAddProductRequestLineItemNew.MonthSplitWrapper> getrecomendedProducts(String loggedInUserId, String productTypeFilter) {
        System.debug('productTypeFilter==>'+productTypeFilter);
        Date today = Date.today();

        Set<String> ProductTypeNotToShow = new Set<String>();

        if (productTypeFilter == 'Service') {
                    ProductTypeNotToShow = new Set<String>{'Vehicle', 'Merchandise'};
                        System.debug('ProductTypeNotToShow 0==>'+ProductTypeNotToShow);
                } else if (productTypeFilter == 'Sales') {
                    ProductTypeNotToShow = new Set<String>{'Parts'};
                        System.debug('ProductTypeNotToShow 00==>'+ProductTypeNotToShow);
                } else if (productTypeFilter == 'Merchandise') {
                    ProductTypeNotToShow = new Set<String>{'Vehicle', 'Parts', 'Accessories', 'Extended Warranty', 'Add-ons', 'Road Side Assistance'};
                        System.debug('ProductTypeNotToShow 000==>'+ProductTypeNotToShow);
                } else if (productTypeFilter == 'Accessories') {
                    ProductTypeNotToShow = new Set<String>{'Vehicle', 'Parts', 'Merchandise', 'Extended Warranty', 'Add-ons', 'Road Side Assistance'};
                        System.debug('ProductTypeNotToShow 000==>'+ProductTypeNotToShow);
                }
           
             user loggedUser = [SELECT Id, Contact.Name, ContactId,Contact.accountId FROM User WHERE Id = :loggedInUserId LIMIT 1];


                List<MSL_Batch_Summary__c> lastBatchList = [
            SELECT Id, Batch_Start_Date__c, Batch_End_Date__c, Batch_Run_Date__c, Dealer__c 
            FROM MSL_Batch_Summary__c 
            WHERE Dealer__c = :loggedUser.Contact.AccountId 
            ORDER BY CreatedDate DESC 
            LIMIT 2
        ];

        if (lastBatchList.size() < 1) return new List<MonthSplitWrapper>();
        
       if (lastBatchList.size() < 1) return new List<MonthSplitWrapper>();

        Map<Id, Month_Split__c> lbrps2Map = new Map<Id, Month_Split__c>();
        Map<Id, Decimal> productIdToQtyFromLBRPS2 = new Map<Id, Decimal>();

        if (lastBatchList.size() > 1) {
            for (Month_Split__c ms : [
                SELECT Id, Product__c, Quantity__c 
                FROM Month_Split__c 
                WHERE MSL_Batch_Summary__c = :lastBatchList[1].Id 
                AND Product__r.Type__c NOT IN :ProductTypeNotToShow 
                AND PO_Submitted__c = false
            ]) {
                productIdToQtyFromLBRPS2.put(ms.Product__c, ms.Quantity__c);
                lbrps2Map.put(ms.Product__c, ms);
            }
        }

        List<Month_Split__c> lbrps = [
            SELECT Id, Start_Date__c, End_Date__c, Month_Name__c, Month_Sequence__c,
                   Product__r.Name, Product__c, MSL_Batch_Summary__c, Quantity__c,
                   Quantity_Orderd__c, Product__r.ProductCode, PO_Submitted__c
            FROM Month_Split__c 
            WHERE MSL_Batch_Summary__c = :lastBatchList[0].Id AND PO_Submitted__c = false
            AND Product__r.Type__c NOT IN :ProductTypeNotToShow
        ];

        List<MonthSplitWrapper> result = new List<MonthSplitWrapper>();

        for (Month_Split__c ms : lbrps) {
            MonthSplitWrapper wrap = new MonthSplitWrapper();
            wrap.id = ms.Product__r.Id;
            wrap.productName = ms.Product__r.Name;
            wrap.productCode = ms.Product__r.ProductCode;
            wrap.quantity = ms.Quantity__c;

            if (productIdToQtyFromLBRPS2.containsKey(ms.Product__c)) {
                wrap.quantity += productIdToQtyFromLBRPS2.get(ms.Product__c);
            }

            wrap.quantityOrdered = ms.Quantity_Orderd__c;
            wrap.monthName = ms.Month_Name__c;
            wrap.monthSequence = ms.Month_Sequence__c;
            wrap.startDate = ms.Start_Date__c;
            wrap.endDate = ms.End_Date__c;
            wrap.poSubmitted = ms.PO_Submitted__c;
            result.add(wrap);
        }

        
        for (Id productId : productIdToQtyFromLBRPS2.keySet()) {
            Boolean exists = false;
            for (Month_Split__c ms : lbrps) {
                if (ms.Product__c == productId) {
                    exists = true;
                    break;
                }
            }
            if (!exists && lbrps2Map.containsKey(productId)) {
                Month_Split__c ms = lbrps2Map.get(productId);
                MonthSplitWrapper wrap = new MonthSplitWrapper();
                wrap.id = ms.Product__r.Id;
                wrap.productName = ms.Product__r.Name;
                wrap.productCode = ms.Product__r.ProductCode;
                wrap.quantity = ms.Quantity__c;
                wrap.quantityOrdered = ms.Quantity_Orderd__c;
                wrap.monthName = ms.Month_Name__c;
                wrap.monthSequence = ms.Month_Sequence__c;
                wrap.startDate = ms.Start_Date__c;
                wrap.endDate = ms.End_Date__c;
                wrap.poSubmitted = ms.PO_Submitted__c;
                result.add(wrap);
            }
        }

        return result;
    }
     @AuraEnabled(Cacheable = true)
     public static List<RecordAddProductRequestLineItemNew.ForecastWrapper> getAllForcastQuantity(String loggedInUserId, String productTypeFilter){
        System.debug('productTypeFilter==>'+productTypeFilter);
        Date today = Date.today();

        Set<String> ProductTypeNotToShow = new Set<String>();

        if (productTypeFilter == 'Service') {
                    ProductTypeNotToShow = new Set<String>{'Vehicle', 'Merchandise'};
                        System.debug('ProductTypeNotToShow 0==>'+ProductTypeNotToShow);
                } else if (productTypeFilter == 'Sales') {
                    ProductTypeNotToShow = new Set<String>{'Parts'};
                        System.debug('ProductTypeNotToShow 00==>'+ProductTypeNotToShow);
                } else if (productTypeFilter == 'Merchandise') {
                    ProductTypeNotToShow = new Set<String>{'Vehicle', 'Parts', 'Accessories', 'Extended Warranty', 'Add-ons', 'Road Side Assistance'};
                        System.debug('ProductTypeNotToShow 000==>'+ProductTypeNotToShow);
                } else if (productTypeFilter == 'Accessories') {
                    ProductTypeNotToShow = new Set<String>{'Vehicle', 'Parts', 'Merchandise', 'Extended Warranty', 'Add-ons', 'Road Side Assistance'};
                        System.debug('ProductTypeNotToShow 000==>'+ProductTypeNotToShow);
                }
           
             user loggedUser = [SELECT Id, Contact.Name, ContactId,Contact.accountId FROM User WHERE Id = :loggedInUserId LIMIT 1];

        List<FortnightlyForecastInventory__c> fortnightList = [SELECT ID,Account__c,Account__r.Name,Product__c,Product__r.ProductCode,Product__r.Name,Six_Months_Average_Consumption__c,Product__r.Type__c,CreatedDate,Batch_Executed_Date__c,PO_Status__c FROM FortnightlyForecastInventory__c
                                                              WHERE Account__c=:loggedUser.Contact.accountId AND Product__r.Type__c NOT IN :ProductTypeNotToShow AND PO_Status__c IN('') ORDER BY Batch_Executed_Date__c DESC];

       if (fortnightList.isEmpty()) return new List<RecordAddProductRequestLineItemNew.ForecastWrapper>();                                                              
        
        Date baseDate = fortnightList[0].Batch_Executed_Date__c;

       
        Date startDate = baseDate.addDays(-30);
        Date endDate = baseDate.addDays(-15);                                                 

        List<FortnightlyForecastInventory__c> fortnightList2 = [SELECT ID,Account__c,Account__r.Name,Product__c,Product__r.ProductCode,Product__r.Name,Six_Months_Average_Consumption__c,Product__r.Type__c,CreatedDate,Batch_Executed_Date__c,PO_Status__c FROM FortnightlyForecastInventory__c
                                                              WHERE Account__c=:loggedUser.Contact.accountId AND Product__r.Type__c NOT IN :ProductTypeNotToShow AND Batch_Executed_Date__c >= :startDate
          AND Batch_Executed_Date__c <= :endDate
          AND PO_Status__c IN ('')
    ORDER BY Batch_Executed_Date__c DESC];  
                                                              
                                                              

       Map<Id, FortnightlyForecastInventory__c> previousDataMap = new Map<Id, FortnightlyForecastInventory__c>();
    for (FortnightlyForecastInventory__c rec : fortnightList2) {
        previousDataMap.put(rec.Product__c, rec);
    }

    List<RecordAddProductRequestLineItemNew.ForecastWrapper> result = new List<RecordAddProductRequestLineItemNew.ForecastWrapper>();
    for (FortnightlyForecastInventory__c rec : fortnightList) {
        Decimal adjustedConsumption = rec.Six_Months_Average_Consumption__c;
        if (previousDataMap.containsKey(rec.Product__c)) {
            Decimal oldConsumption = previousDataMap.get(rec.Product__c).Six_Months_Average_Consumption__c;
            adjustedConsumption = rec.Six_Months_Average_Consumption__c - oldConsumption;
        }
        RecordAddProductRequestLineItemNew.ForecastWrapper wrapper = new RecordAddProductRequestLineItemNew.ForecastWrapper();
        wrapper.productId = rec.Product__c;
        wrapper.productName = rec.Product__r.Name;
        wrapper.productCode = rec.Product__r.ProductCode;
        wrapper.productType = rec.Product__r.Type__c;
        wrapper.accountId = rec.Account__c;
        wrapper.accountName = rec.Account__r.Name;
        wrapper.batchDate = rec.Batch_Executed_Date__c;
        wrapper.adjustedConsumption = adjustedConsumption;
        result.add(wrapper);
    }

    return result;                                                       
                                                              
                                                              
        // return  fortnightList;                                    
     }
     public class ForecastWrapper {
    @AuraEnabled public Id productId;
    @AuraEnabled public String productName;
    @AuraEnabled public String productCode;
    @AuraEnabled public String productType;
    @AuraEnabled public Id accountId;
    @AuraEnabled public String accountName;
    @AuraEnabled public Date batchDate;
    @AuraEnabled public Decimal adjustedConsumption;
    }
}