public with sharing class CaseFileUploadController {
    @AuraEnabled
    public static void updateCaseAttachmentFlag(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case Id is required');
        }

        Case cs = [SELECT Id, Is_Attachment__c FROM Case WHERE Id = :caseId LIMIT 1];
        cs.Is_Attachment__c = true;
        update cs;
    }
}