public class BatchLogUtil {
    public static Id createSummary(String type, String objectName, Integer totalRecords) {
        Batch_Processing__c summary = new Batch_Processing__c(
            Start_Time__c = System.now(),
            Type__c = type,
            Object_Name__c = objectName,
            Total_Records__c = totalRecords
        );
        insert summary;
        return summary.Id;
    }
    
    public static void updateSummary(Id summaryId, Integer successCount, Integer failCount) {
        Batch_Processing__c updateLog = new Batch_Processing__c(
            Id = summaryId,
            End_Time__c = System.now(),
            Success_Records__c = successCount,
            Failed_Records__c = failCount
        );
        update updateLog;
    }
    
    public static void logDetails(List<Batch_Processing_Detail__c> details) {
        if (!details.isEmpty()) {
            insert details;
        }
    }
    
    public static void logError(String type, String objectName, List<String> vinList, Exception e) {
        Batch_Processing__c summary = new Batch_Processing__c(
            Start_Time__c = System.now(),
            End_Time__c = System.now(),
            Type__c = type,
            Object_Name__c = objectName,
            Total_Records__c = vinList != null ? vinList.size() : 0,
            Failed_Records__c = vinList != null ? vinList.size() : 0
        );
        insert summary;
        
        insert new Batch_Processing_Detail__c(
            Batch_Processing__c = summary.Id,
            Is_Success__c = false,
            Status__c ='Fail ',
            Stack_Trace__c = e.getMessage()
        );
    }
}