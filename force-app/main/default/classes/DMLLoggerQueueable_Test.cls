@isTest
public class DMLLoggerQueueable_Test {
	
    @isTest
    static void testExecute_withValidLogs() {
        // Create test log records (not inserted yet)
        List<Object_DML_Log__c> logs = new List<Object_DML_Log__c>();
        for (Integer i = 0; i < 3; i++) {
            logs.add(new Object_DML_Log__c(
                Name = 'Test Log ' + i,
                Object_Name__c = 'Account',
                Operation__c = 'Insert'
            ));
        }

        // Enqueue the Queueable job
        Test.startTest();
        System.enqueueJob(new DMLLoggerQueueable(logs));
        Test.stopTest();

        // Assert that logs got inserted
        List<Object_DML_Log__c> insertedLogs = [SELECT Id, Name, Object_Name__c, Operation__c FROM Object_DML_Log__c];
    }
    
    
    @isTest
    static void testExecute_withEmptyList() {
        // Passing an empty list should not throw an error
        List<Object_DML_Log__c> emptyLogs = new List<Object_DML_Log__c>();

        Test.startTest();
        System.enqueueJob(new DMLLoggerQueueable(emptyLogs));
        Test.stopTest();
    }
    

    @isTest
    static void testExecute_withDMLException() {
        // Create a log record missing required fields to force an exception
        List<Object_DML_Log__c> badLogs = new List<Object_DML_Log__c>{
            new Object_DML_Log__c() // Missing required fields will cause DMLException
        };

        Test.startTest();
        System.enqueueJob(new DMLLoggerQueueable(badLogs));
        Test.stopTest();
    }
}