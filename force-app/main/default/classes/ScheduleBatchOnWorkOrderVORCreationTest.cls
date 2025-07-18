@isTest
public class ScheduleBatchOnWorkOrderVORCreationTest {
     @isTest
    static void testBatchData(){
         Account acc = new Account();
        acc.Name = 'testing Account';
        acc.Type = 'Customer';
        acc.Phone = '9807654321';
        acc.Type = 'Service center';
        acc.Center_Code__c = '455677';
        insert acc;
         Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'Secondary',State__c = 'Karnataka',IsInventoryLocation=true);
        insert testLocation;
        
        Contact con = new Contact();
        con.LastName = 'testing Contact';
        con.AccountId = acc.Id;
        con.Phone = '9123456789';
        con.Email = 'test@test.com';
        con.Primary_Contact__c = true;
        con.Role_Type__c = 'Sales';
        con.Location__c = testLocation.id;
        insert con;
        
        Asset asst = new Asset();
        asst.Name = 'test Asset';
        asst.AccountId = acc.Id;
        asst.ContactId = con.Id;
        insert asst;
        
        Software_Version__c sv = new Software_Version__c();
        sv.Name = 'test version';
        sv.Latest_Software_Version__c = true;
        insert sv;
        
        Product2 prod = new Product2();
        prod.Name = 'test product';
        prod.HSN_Code__c = '123';
        prod.Type__c = 'Vehicle';
        prod.ProductCode = '2132132';
        insert prod;
        
        VehicleDefinition vd = new VehicleDefinition();
        vd.Name = 'test VehicleDefinition';
        vd.ProductId = prod.Id;
        insert vd;
        
        Vehicle vac = new Vehicle();
        vac.Name = 'test vehicle';
        vac.CurrentOwnerId = acc.Id;
        vac.Charger_PC_Number__c = '123CC';
        vac.VehicleRegistrationNumber = '123';
        vac.VehicleIdentificationNumber = 'NeoCity2022ZXi';
        vac.VehicleDefinitionId = vd.Id;
        vac.Software_Version__c = sv.Id;
        vac.AssetId = asst.Id;
        vac.Spare_Vehicle__c = false;
        insert vac;
        
        // Create a test Warehouse
        Warehouse__c testWarehouse = new Warehouse__c();
        testWarehouse.Name = 'Test Warehouse';
        
        
        
        insert testWarehouse;
        
        // Create a test WorkOrder with the required fields, including Warehouse__c
        WorkOrder testWorkOrder = new WorkOrder();
        testWorkOrder.Warehouse__c = testWarehouse.Id; // Set the Warehouse reference
        testWorkOrder.Vehicle__c = vac.Id;
        testWorkOrder.AccountId = acc.Id;
        testWorkOrder.Status = 'New';
        testWorkOrder.Service_Center__c = acc.id;
        insert testWorkOrder;
        Test.setCreatedDate(testWorkOrder.Id, Date.today().addDays(-1));
        
        String cronExp = '0 0 12 * * ?';
        Test.startTest();
        ScheduleBatchOnWorkOrderVORCreation scheduler = new ScheduleBatchOnWorkOrderVORCreation();
        String jobId = System.schedule('Test VOR Batch Scheduler', cronExp, scheduler);
        Test.stopTest();

        // Assert job was scheduled correctly
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger
                          WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression);
    }
}