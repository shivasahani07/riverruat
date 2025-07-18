trigger TriggeronBatchProcessing on Batch_Processing__c (after insert) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            TriggeronBatchProcessingHelper.AfterInsert(Trigger.NewMap); 
        }
    }

}