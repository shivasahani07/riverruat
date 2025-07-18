public class TriggeronBatchProcessingHelper {
    
    public static void AfterInsert(Map<Id,Batch_Processing__c> insertsMap){
        
        CustomProfileHandler.shareRecordsWithHierarchy(insertsMap);
        
    }
    
}