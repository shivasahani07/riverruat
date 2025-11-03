@IsTest
public class TriggerOnTFRSampleHelper_Test {
	
    @IsTest
    static void testAfterInsertLogic() {
        // Step 1: Create sample Failure_Code__c records
        List<Failure_Code__c> failureCodes = new List<Failure_Code__c>{
            new Failure_Code__c(Name = 'Code A', Batch_Size__c = 2, Is_Active__c = true, Status__c = 'New'),
            new Failure_Code__c(Name = 'Code B', Batch_Size__c = 1, Is_Active__c = true, Status__c = 'New')
        };
        insert failureCodes;
        
        // Step 2: Create TFR_Sample__c records
        // One with 'Completed' status and valid Failure_Code__c
        List<TFR_Sample__c> samples = new List<TFR_Sample__c>{
            new TFR_Sample__c(Failure_Code__c = failureCodes[0].Id, jc_Status__c = 'Completed'),
            new TFR_Sample__c(Failure_Code__c = failureCodes[0].Id, jc_Status__c = 'In Progress'),
            new TFR_Sample__c(Failure_Code__c = failureCodes[1].Id, jc_Status__c = 'Completed')
        };
        insert samples;
        
        samples[1].jc_Status__c = 'Completed';
        update samples[1];
    }
}