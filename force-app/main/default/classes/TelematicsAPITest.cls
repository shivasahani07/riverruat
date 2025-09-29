@IsTest
public class TelematicsAPITest {
    
    @testSetup
    static void setupData() {
        Account testAccount = new Account(
            Name = 'Test Account 1',
            Type = 'Customer',
            Phone = '0987654321'
        );
        insert testAccount;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product 1',
            IsActive = true,
            ProductCode = 'abcd',
            HSN_Code__c = 'abcd',
            Type__c = 'Vehicle'
        );
        insert testProduct;
        
        Id stdPrBk = Test.getStandardPricebookId();
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        Asset testAsset = new Asset(
            Name = 'Test Asset 1',
            AccountId = testAccount.Id,
            Product2Id = testProduct.Id
        );
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(
            Name = 'Test VehicleDefinition 1',
            ProductId = testProduct.Id
        );
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(
            Name = 'Test Software Version 1'
        );
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(
            Name = 'Test Vehicle 2',
            Account__c = testAccount.Id,
            AssetId = testAsset.Id,
            VehicleDefinitionId = testVD.Id,
            VehicleIdentificationNumber = 'A2B3',
            Software_Version__c = testSV.Id,
            Charger_PC_Number__c = 'abcd',
            PDI_Status_Pass__c = true,
            CurrentOwnerId = testAccount.Id
        );
        insert testVehicle;
    }

    @IsTest
    static void coverMethod() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getCustomerDetails/A2B3';
        RestContext.request = req;
        RestContext.response = res;

        TelematicsAPI.getCustomerDetails();
    }

    @IsTest
    static void coverErrorMethod() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getCustomerDetails/A2B3@';
        RestContext.request = req;
        RestContext.response = res;

        TelematicsAPI.getCustomerDetails();
    }

    @IsTest
    static void coverErrorMethod2() {
        Vehicle veh = [SELECT Id FROM Vehicle WHERE VehicleIdentificationNumber = 'A2B3' LIMIT 1];
        veh.CurrentOwnerId = null;
        update veh;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getCustomerDetails/A2B3';
        RestContext.request = req;
        RestContext.response = res;

        TelematicsAPI.getCustomerDetails();
    }
}