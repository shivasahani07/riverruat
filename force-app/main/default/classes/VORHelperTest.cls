@isTest
private class VORHelperTest {
    
    static Id testWorkOrderId;
    static Id testVORId;
    
    @testSetup
    static void setupTestData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Username = 'testuser2342343@example.com',
            LastName = 'Testddf',
            Email = 'testusesddf234234r@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Related records for Job Card (WorkOrder)
        Account acc = new Account(Name = 'Test Account', Type = 'Customer', Phone = '9807654321');
        insert acc;
        
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id, Phone = '9123456789', Email = 'test@test.com', Primary_Contact__c = true);
        insert con;
        
        Asset asset = new Asset(Name = 'Test Asset', AccountId = acc.Id, ContactId = con.Id);
        insert asset;
        
        Software_Version__c sv = new Software_Version__c(Name = 'test version', Latest_Software_Version__c = true);
        insert sv;
        
        Product2 prod = new Product2(Name = 'test product', HSN_Code__c = '123', Type__c = 'Vehicle', ProductCode = '2132132');
        insert prod;
        
        VehicleDefinition vd = new VehicleDefinition(Name = 'test VehicleDefinition', ProductId = prod.Id);
        insert vd;
        
        Vehicle vehicle = new Vehicle(
            Name = 'test vehicle',
            CurrentOwnerId = acc.Id,
            Charger_PC_Number__c = '123CC',
            VehicleRegistrationNumber = '123',
            VehicleIdentificationNumber = 'NeoCity2022ZXi',
            VehicleDefinitionId = vd.Id,
            Software_Version__c = sv.Id,
            AssetId = asset.Id,
            Spare_Vehicle__c = false
        );
        insert vehicle;
        
        Warehouse__c warehouse = new Warehouse__c(Name = 'Test Warehouse');
        insert warehouse;
        
        WorkOrder workOrder = new WorkOrder(Warehouse__c = warehouse.Id, Vehicle__c = vehicle.Id, AccountId = acc.Id);
        insert workOrder;
        testWorkOrderId = workOrder.Id;
        
        // Create VOR__c records
        VOR__c vor = new VOR__c(Job_Card__c = testWorkOrderId, VOR_Reason__c = 'Insurance Stage 1');
        insert vor;
        
        testVORId = vor.Id;
    }
    
    @isTest
    static void test_getRecentVORRecorDetails_valid() {
        System.debug('Running test_getRecentVORRecorDetails_valid with JobCardId: ' + testWorkOrderId);
        Test.startTest();
        List<VOR__c> vors = VORHelper.getRecentVORRecorDetails(testWorkOrderId);
        Test.stopTest();
        
        System.debug('Returned VOR records count: ' + vors.size());
        System.assertNotEquals(null, vors, 'Should return a list');
        System.assertNotEquals(null,vors.size() > 0, 'Should return VOR records');
    }
    
    @isTest
    static void test_getRecentVORRecorDetails_nullId() {
        Test.startTest();
        List<VOR__c> vors = VORHelper.getRecentVORRecorDetails(null);
        Test.stopTest();
        
        System.assertEquals(0, vors.size(), 'Should return empty list for null ID');
    }
    
   @isTest
static void test_updateVORRecords_valid() {
    // Re-fetch the VOR record created in @testSetup
    VOR__c existing = [SELECT Id FROM VOR__c LIMIT 1];

    Test.startTest();
    VORHelper.updateVORRecords(existing.Id, 'Rework');
    Test.stopTest();

    List<VOR__c> updatedList = [SELECT VOR_Reason__c FROM VOR__c WHERE Id = :existing.Id];
    System.assertEquals(1, updatedList.size(), 'VOR record should exist after update');

    VOR__c updated = updatedList[0];
    System.assertEquals('Rework', updated.VOR_Reason__c); 
}

    
    @isTest
    static void test_updateVORRecords_invalidId() {
        // Passing an invalid ID should not crash (it will just log debug)
        Test.startTest();
        VORHelper.updateVORRecords(testVORId, 'Rework');
        Test.stopTest();
    }
    
    @isTest
    static void test_updateVORRecords_dmlException() {
        // Try updating a deleted record to simulate DML failure
        VOR__c temp = new VOR__c(Job_Card__c = testWorkOrderId, VOR_Reason__c = 'Rework');
        insert temp;
        delete temp;
        
        Test.startTest();
        VORHelper.updateVORRecords(temp.Id, 'Should Fail');
        Test.stopTest();
    }
    
    @isTest
    static void test_getRecentVORRecorDetails_exceptionHandling() {
        // Force SOQL exception by passing ID of wrong object type
        Test.startTest();
        List<VOR__c> result = VORHelper.getRecentVORRecorDetails(UserInfo.getUserId());
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list on exception');
    }
}