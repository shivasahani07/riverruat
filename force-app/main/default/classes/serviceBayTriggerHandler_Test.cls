@isTest
private class serviceBayTriggerHandler_Test {

    @isTest
    static void testHandleBayCount_InsertBelowLimit() {
        // Create Account
        Account acc = new Account(Name = 'Test Service Center');
        insert acc;

        // Create 3 existing Service Bays (below limit)
        List<Service_Bay__c> existingBays = new List<Service_Bay__c>();
        for (Integer i = 0; i < 3; i++) {
            existingBays.add(new Service_Bay__c(Service_Center__c = acc.Id, Is_Active__c = true));
        }
        insert existingBays;

        // Insert 1 more (total 4 → allowed)
        Service_Bay__c newBay = new Service_Bay__c(Service_Center__c = acc.Id, Is_Active__c = true);
        insert newBay;
    }

    @isTest
    static void testHandleBayCount_InsertExceedLimit() {
        // Create another Account
        Account acc2 = new Account(Name = 'Another Service Center');
        insert acc2;

        // Create 4 existing Service Bays (max allowed)
        List<Service_Bay__c> existingBays2 = new List<Service_Bay__c>();
        for (Integer i = 0; i < 4; i++) {
            existingBays2.add(new Service_Bay__c(Service_Center__c = acc2.Id, Is_Active__c = true));
        }
        insert existingBays2;

        // Attempt to insert one more → should trigger addError
        Service_Bay__c exceedBay = new Service_Bay__c(Service_Center__c = acc2.Id, Is_Active__c = true);
        try {
            insert exceedBay;
        } catch (DmlException e) {
            // expected
        }
    }

    @isTest
    static void testHandleBayCount_UpdateScenario() {
        // Create Account
        Account acc3 = new Account(Name = 'Update Test Center');
        insert acc3;

        // Create one Service Bay
        Service_Bay__c sb = new Service_Bay__c(Service_Center__c = acc3.Id, Is_Active__c = true);
        insert sb;

        // Update the same record → triggers handler (Trigger.isUpdate false case)
        sb.Is_Active__c = false;
        update sb;
    }
}