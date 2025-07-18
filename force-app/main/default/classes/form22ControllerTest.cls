@isTest
public class form22ControllerTest {
    
    @testSetup
    static void setupData() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;

        Order vehicleDeliveredOrder = new Order(
            Name = 'Vehicle Delivered Order',
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = System.today()
        );

        Order rtoOrder = new Order(
            Name = 'RTO Registration Order',
            AccountId = testAccount.Id,
            Status = 'Pre Invoice', // Initial status before RTO Registration
            EffectiveDate = System.today()
        );

        Order rtoOrder2 = new Order(
            Name = 'Second RTO Registration Order',
            AccountId = testAccount.Id,
            Status = 'Processing', // Initial status before RTO Registration
            EffectiveDate = System.today()
        );

        insert new List<Order>{vehicleDeliveredOrder, rtoOrder, rtoOrder2};

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id
        );
        insert testAsset;

        Product2 testProduct = new Product2(
            Name = 'Test Vehicle Product',
            ProductCode = 'PROD123',
            HSN_Code__c = 'test123',
            Type__c = 'Vehicle',
            IsActive = true
        );
        insert testProduct;

        VehicleDefinition testVehicleDef = new VehicleDefinition(
            Name = 'Test Vehicle Definition',
            ProductId = testProduct.Id
        );
        insert testVehicleDef;

        Software_Version__c testSoftwareVersion = new Software_Version__c(
            Name = '1.0.0'
        );
        insert testSoftwareVersion;

        Vehicle testVehicle = new Vehicle(
            Name = 'Test Vehicle',
            VehicleIdentificationNumber = 'VIN123456789',
            EngineNumber = 'ENG123456',
            AssetId = testAsset.Id,
            PDI_Status_Pass__c = true,
            VehicleDefinitionId = testVehicleDef.Id,
            Software_Version__c = testSoftwareVersion.Id,
            Charger_PC_Number__c = 'CHARGER123'
        );
        insert testVehicle;

        vehicleDeliveredOrder.Assigned_Vehicle__c = testVehicle.Id;
        rtoOrder.Assigned_Vehicle__c = testVehicle.Id;
        rtoOrder2.Assigned_Vehicle__c = testVehicle.Id;
        update new List<Order>{vehicleDeliveredOrder, rtoOrder, rtoOrder2};
    }

    @isTest
    static void testHandleOrderUpdate() {
        List<Order> orders = [SELECT Id, Status FROM Order];
        Order vehicleDeliveredOrder = orders[0];
        Order rtoOrder = orders[1];
        Order rtoOrder2 = orders[2];

        vehicleDeliveredOrder.Status = 'Vehicle Delivered';
        rtoOrder.Status = 'RTO Registration';
        rtoOrder2.Status = 'RTO Registration';

        Map<Id, Order> oldOrderMap = new Map<Id, Order>{
            vehicleDeliveredOrder.Id => new Order(Id = vehicleDeliveredOrder.Id, Status = 'Draft'),
            rtoOrder.Id => new Order(Id = rtoOrder.Id, Status = 'Pre Invoice'), // Previously not 'RTO Registration'
            rtoOrder2.Id => new Order(Id = rtoOrder2.Id, Status = 'Processing') // Another transition case
        };

        Test.startTest();
        form22Controller.handleOrderUpdate(new List<Order>{vehicleDeliveredOrder, rtoOrder, rtoOrder2}, oldOrderMap);
        Test.stopTest();

        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE ParentId IN :orders];
    }
}