public with sharing class CaseCustomerConcernController {

    @AuraEnabled(cacheable=true)
    public static List<Customer_Concern__c> getConcernsByCaseId(Id caseId) {
        // Fetch Customer Concerns related to the Case
        return [
        SELECT Id, Name, VOC__c, Case__c, Case_Category__c, Concerns__c, Subconcerns__c,
               Case_Category_Update__c, Closed_Resolution__c
        FROM Customer_Concern__c
        WHERE Case__c = :caseId
    ];
    }

    @AuraEnabled
    public static void updateConcerns(List<Customer_Concern__c> concerns) {
        // Validate and update records
        if (concerns != null && !concerns.isEmpty()) {
            update concerns;
        }
    }
    @AuraEnabled(cacheable=true)
    public static String getUserProfileName() {
        return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() ].Profile.Name;
    }
}