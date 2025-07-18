public class PSFQuestionnaireWrapperApex {
	
    @AuraEnabled
    public static Id getPsfIdFromTask(Id taskId) {
        Task t = [SELECT Id, WhatId FROM Task WHERE Id = :taskId LIMIT 1];
        
        System.debug('Task : ' + t);
        return t.WhatId;
    }
}