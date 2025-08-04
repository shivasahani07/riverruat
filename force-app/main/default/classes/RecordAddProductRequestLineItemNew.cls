/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-01-2025
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
         //added by Aniket on 01/08/2025
         Date todayForQuery = Date.today();
                Integer dayOfMonth = today.day();

                //Date expectedBatchDate;
                 Date startDateForQuery;
                Date endDateForQuery;
                if (dayOfMonth <= 15) {
                
                   
                    startDateForQuery = Date.newInstance(todayForQuery.year(), today.month(), 1);
                   endDateForQuery = Date.newInstance(todayForQuery.year(), today.month(), 15);
                } else {
                    
                    startDateForQuery = Date.newInstance(todayForQuery.year(), today.month(), 16);
                    endDateForQuery = Date.newInstance(todayForQuery.year(), today.month(), Date.daysInMonth(today.year(), today.month()));
                }     
        //added by Aniket on 01/08/2025
        List<FortnightlyForecastInventory__c> fortnightList = [SELECT ID,Account__c,Account__r.Name,Product__c,Product__r.ProductCode,Product__r.Name,Six_Months_Average_Consumption__c,Product__r.Type__c,CreatedDate,Batch_Executed_Date__c,PO_Status__c,Quantity_Ordered__c, Pending_Forecast_Quantity__c FROM FortnightlyForecastInventory__c
                                                              WHERE Account__c=:loggedUser.Contact.accountId AND Product__r.Type__c NOT IN :ProductTypeNotToShow AND PO_Status__c IN('','Submitted') AND Batch_Executed_Date__c >= :startDateForQuery AND Batch_Executed_Date__c <= :endDateForQuery /*ORDER BY Batch_Executed_Date__c DESC*/];
      
       System.debug('fortnightList==>'+fortnightList);                                                       

       if (fortnightList.isEmpty()) return new List<RecordAddProductRequestLineItemNew.ForecastWrapper>();                                                              
        
        Date baseDate = fortnightList[0].Batch_Executed_Date__c;

       
        Date startDate = baseDate.addDays(-30);
        Date endDate = baseDate.addDays(-15);                                                 

        List<FortnightlyForecastInventory__c> fortnightList2 = [SELECT ID,Account__c,Account__r.Name,Product__c,Product__r.ProductCode,Product__r.Name,Six_Months_Average_Consumption__c,Product__r.Type__c,CreatedDate,Batch_Executed_Date__c,PO_Status__c,Quantity_Ordered__c, Pending_Forecast_Quantity__c FROM FortnightlyForecastInventory__c
                                                              WHERE Account__c=:loggedUser.Contact.accountId AND Product__r.Type__c NOT IN :ProductTypeNotToShow AND Batch_Executed_Date__c >= :startDate
          AND Batch_Executed_Date__c <= :endDate
          AND PO_Status__c IN ('Submitted','')
    ORDER BY Batch_Executed_Date__c DESC];  
                                                              
       System.debug('fortnightList2==>'+fortnightList2);                                                         
Map<Id, FortnightlyForecastInventory__c> previousDataMap = new Map<Id, FortnightlyForecastInventory__c>();
for (FortnightlyForecastInventory__c rec : fortnightList2) {
    if (!previousDataMap.containsKey(rec.Product__c)) {
        previousDataMap.put(rec.Product__c, rec);
    }
}

Set<Id> processedProductIds = new Set<Id>();
List<RecordAddProductRequestLineItemNew.ForecastWrapper> result = new List<RecordAddProductRequestLineItemNew.ForecastWrapper>();

for (FortnightlyForecastInventory__c rec : fortnightList) {
    if (processedProductIds.contains(rec.Product__c)) {
        continue;
    }

    Decimal adjustedConsumption = rec.Six_Months_Average_Consumption__c != null 
                                  ? rec.Six_Months_Average_Consumption__c : 0;

    // Check historical data only to adjust value
    if (previousDataMap.containsKey(rec.Product__c)) {
        FortnightlyForecastInventory__c previousRec = previousDataMap.get(rec.Product__c);

        if (previousRec.Quantity_Ordered__c != null && previousRec.Six_Months_Average_Consumption__c != null &&
            previousRec.Quantity_Ordered__c < previousRec.Six_Months_Average_Consumption__c) {
            
            Decimal oldOrdered = previousRec.Quantity_Ordered__c;
            adjustedConsumption = adjustedConsumption - oldOrdered;
        }
        // else: skip subtraction, but still include in result
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
    wrapper.pendingQty = rec.Pending_Forecast_Quantity__c;

    result.add(wrapper);
    processedProductIds.add(rec.Product__c);
}

System.debug('result==>' + result);
return result;


                                                     
                         
    
//     Map<Id, FortnightlyForecastInventory__c> previousDataMap = new Map<Id, FortnightlyForecastInventory__c>();
// for (FortnightlyForecastInventory__c rec : fortnightList2) {
//     if (!previousDataMap.containsKey(rec.Product__c)) {
//         previousDataMap.put(rec.Product__c, rec);
//     }
// }

// Set<Id> processedProductIds = new Set<Id>();
// List<RecordAddProductRequestLineItemNew.ForecastWrapper> result = new List<RecordAddProductRequestLineItemNew.ForecastWrapper>();

// for (FortnightlyForecastInventory__c rec : fortnightList) {
//     if (processedProductIds.contains(rec.Product__c)) {
//         continue; 
//     }

//     Decimal adjustedConsumption;
//     Decimal currentConsumption = rec.Six_Months_Average_Consumption__c != null ? rec.Six_Months_Average_Consumption__c : 0;

//     System.debug('currentConsumption==>'+currentConsumption);

//     if (previousDataMap.containsKey(rec.Product__c) && rec.Quantity_Ordered__c != null) {
//         Decimal oldOrdered = previousDataMap.get(rec.Product__c).Quantity_Ordered__c != null
//                              ? previousDataMap.get(rec.Product__c).Quantity_Ordered__c : 0;
//         adjustedConsumption = currentConsumption - oldOrdered;
//     } else {
//         adjustedConsumption = currentConsumption;
//     }
//     System.debug('adjustedConsumption==>'+adjustedConsumption);

//     RecordAddProductRequestLineItemNew.ForecastWrapper wrapper = new RecordAddProductRequestLineItemNew.ForecastWrapper();
//     wrapper.productId = rec.Product__c;
//     wrapper.productName = rec.Product__r.Name;
//     wrapper.productCode = rec.Product__r.ProductCode;
//     wrapper.productType = rec.Product__r.Type__c;
//     wrapper.accountId = rec.Account__c;
//     wrapper.accountName = rec.Account__r.Name;
//     wrapper.batchDate = rec.Batch_Executed_Date__c;
//     wrapper.adjustedConsumption = adjustedConsumption;

//     result.add(wrapper);
//     processedProductIds.add(rec.Product__c); // Mark product as processed
// }

// System.debug('result==>'+result);
// return result;
                                                              
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
    @AuraEnabled public Decimal pendingQty;
    }
}