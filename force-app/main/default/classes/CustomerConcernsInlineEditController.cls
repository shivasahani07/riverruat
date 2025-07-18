public with sharing class CustomerConcernsInlineEditController {
    @AuraEnabled
    public static List<Customer_Concern__c> customerConcernList(Id caseId) {
        system.debug('caseId: ' + caseId);
        try {
           		return [SELECT Id, Name, Concerns__c,Case_Category__c, Subconcerns__c, VOC__c, Closed_Resolution__c, Case__c  FROM Customer_Concern__c WHERE Case__c = :caseId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}