/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-28-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class RecordAddProductRequestLineItemNew {
    
    @AuraEnabled(Cacheable = true)
    public static list<Month_Split__c> getrecomendedProducts(String loggedInUserId, String productTypeFilter) {
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
        
       user logedUser = [SELECT Id, Contact.Name, ContactId,Contact.accountId FROM User WHERE Id = :loggedInUserId LIMIT 1];
       list<MSL_Batch_Summary__c> LASTBATCH =[SELECT Id ,Batch_Start_Date__c,Batch_End_Date__c ,Batch_Run_Date__c,Dealer__c FROM MSL_Batch_Summary__c WHERE Dealer__c =:logedUser.Contact.accountId order by createddate desc limit 1];
       list<Month_Split__c> LBRPS =[SELECT Id ,Start_Date__c,End_Date__c,Month_Name__c,Month_Sequence__c,Product__r.Name,MSL_Batch_Summary__c,Quantity__c,Quantity_Orderd__c,Product__r.ProductCode,PO_Submitted__c FROM Month_Split__c where MSL_Batch_Summary__c =:LASTBATCH[0].id AND Product__r.Type__c NOT IN:ProductTypeNotToShow];
       List<Month_Split__c> LBRPS2 = [SELECT Id ,Start_Date__c,End_Date__c,Month_Name__c,Month_Sequence__c,Product__r.Name,MSL_Batch_Summary__c,Quantity__c,Quantity_Orderd__c,Product__r.ProductCode,PO_Submitted__c FROM Month_Split__c where MSL_Batch_Summary__c =:LASTBATCH[1].id AND Product__r.Type__c NOT IN:ProductTypeNotToShow AND PO_Submitted__c = false];
       return LBRPS;
    }
    
    
}