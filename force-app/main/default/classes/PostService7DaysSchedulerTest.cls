@istest
public class PostService7DaysSchedulerTest {
   @isTest
    static void setupTestData(){
        Account acc = new Account(Name = 'Test Account',Center_Code__c='o87gt');
        insert acc;
        //accountId = acc.Id;

        // Create Service Center (as Account)
        Account serviceCenter = new Account(Name = 'Service Center',Type='Service Center',Center_Code__c='87t5g');
        insert serviceCenter;
       // serviceCenterId = serviceCenter.Id;

        // Create Contact with Primary_Contact__c = true
        Contact primaryContact = new Contact(
            FirstName = 'Primary',
            LastName = 'Contact',
            AccountId = acc.Id,
            Phone = '9876543210',
            Primary_Contact__c = true
        );
        insert primaryContact;

        // Create Vehicle
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
        insert testProduct;
        
        Asset testAsset = new Asset(Name='Test Asset 1',AccountId=acc.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition 1',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version 1');
        insert testSV;
        
        
        Vehicle vehicle = new Vehicle(Name='Test Vehicle 2', Account__c=acc.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
        insert vehicle;

        // Create WorkOrder
        WorkOrder workOrder = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id,
            Status = 'New',
            RR_Job_Type__c='Periodic maintenance',
            RR_Periodic_Maintenance_Type__c='3rd Service',
            Completed_Date__c=System.Now().addDays(-7),
            Vehicle__c = vehicle.Id,
            Service_Center__c = serviceCenter.Id
        );
        insert workOrder;

    }
    @isTest
    static void testSchedulerExecution() {
        setupTestData();

        Test.startTest();
        String jobId = System.schedule(
            'Test PostService7DaysScheduler',
            '0 0 12 * * ?', 
            new PostService7DaysScheduler()
        );
        Test.stopTest();

    }
}