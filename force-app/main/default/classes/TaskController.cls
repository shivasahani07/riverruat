public with sharing class TaskController {
    @AuraEnabled(cacheable=true)
    public static Task getTaskDetails(Id taskId) {
        return [
            SELECT Id, Subject, Status, ActivityDate
            FROM Task
            WHERE Id = :taskId
            LIMIT 1
        ];
    }
}