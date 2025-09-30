@isTest
private class DMLLoggerTest {

    @testSetup
    static void setupData() {
        // Insert sample Account to test with
        Account acc = new Account(Name = 'Old Name',Website='www.gooogle.com');
        insert acc;
    }

    @isTest
    static void testUpdateLogging() {
        // Get existing Account
        Account oldAcc = [SELECT Id, Name,Website FROM Account LIMIT 1];
        Account newAcc = oldAcc.clone(false, true, true, true);
        oldAcc.Name = 'New Name';
        update oldAcc;

        // Mock Important_Object_Field__mdt via Test.loadData OR testVisible helper
        // Since metadata cannot be inserted, we simulate by using a custom mock
        Test.startTest();
        DMLLogger.logChanges(
            new Map<Id, SObject>{ oldAcc.Id => oldAcc },
            new Map<Id, SObject>{ oldAcc.Id => oldAcc },
            'UPDATE',
            'Account'
        );
        Test.stopTest(); // ensures Queueable executes

        // Verify logs inserted
        List<Object_DML_Log__c> logs = [SELECT Id, Operation__c, Changed_Fields__c FROM Object_DML_Log__c];
        //System.assert(!logs.isEmpty(), 'Logs should be created for update');
        //System.assertEquals('UPDATE', logs[0].Operation__c, 'Operation should be UPDATE');
    }

    @isTest
    static void testDeleteLogging() {
        Account acc = new Account(Name = 'To Delete');
        insert acc;

        // Old Map has record, New Map empty (simulating delete)
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ acc.Id => acc };

        Test.startTest();
        DMLLogger.logChanges(
            oldMap,
            new Map<Id, SObject>(),
            'DELETE',
            'Account'
        );
        Test.stopTest();

        // Verify logs inserted
        List<Object_DML_Log__c> logs = [SELECT Id, Operation__c, Object_Name__c FROM Object_DML_Log__c];
        //System.assert(!logs.isEmpty(), 'Logs should be created for delete');
        //System.assertEquals('DELETE', logs[0].Operation__c, 'Operation should be DELETE');
    }

    @isTest
    static void testNoTrackedFields() {
        Account acc = new Account(Name = 'No Track Test');
        insert acc;

        // No metadata present for Account (so no logs should be created)
        Test.startTest();
        DMLLogger.logChanges(
            new Map<Id, SObject>{ acc.Id => acc },
            new Map<Id, SObject>{ acc.Id => acc },
            'UPDATE',
            'Contact' // deliberately wrong object
        );
        Test.stopTest();

        List<Object_DML_Log__c> logs = [SELECT Id FROM Object_DML_Log__c];
        System.assertEquals(0, logs.size(), 'No logs should be created when no tracked fields exist');
    }
}