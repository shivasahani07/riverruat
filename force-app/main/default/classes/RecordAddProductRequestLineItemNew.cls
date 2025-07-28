public class RecordAddProductRequestLineItemNew {
    
    @AuraEnabled(Cacheable = true)
    public static void getrecomendedProducts(String loggedInUserId, String productTypeFilter) {
        Date today = Date.today();
        
       user logedUser = [SELECT Id, Contact.Name, ContactId,Contact.accountId FROM User WHERE Id = :loggedInUserId LIMIT 1];
       list<MSL_Batch_Summary__c> LASTBATCH =[SELECT Id ,Batch_Start_Date__c,Batch_End_Date__c ,Batch_Run_Date__c,Dealer__c FROM MSL_Batch_Summary__c WHERE Dealer__c =:logedUser.Contact.accountId order by createddate desc];
       list<Month_Split__c> LBRPS =[SELECT Id ,Start_Date__c,End_Date__c,Month_Name__c,Month_Sequence__c,Product__r.Name,MSL_Batch_Summary__c,quantity__c,Quantity_Orderd__c FROM Month_Split__c where MSL_Batch_Summary__c =:LASTBATCH[0].id ];
    }
    
}