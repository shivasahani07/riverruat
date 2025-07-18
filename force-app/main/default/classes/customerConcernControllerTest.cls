@isTest
private class customerConcernControllerTest {
  @testSetup
    static void testCustomerConcern(){
        Account testAccount = new Account(Name = 'Test Account',Type='Customer',Center_Code__c='1234',Phone='0987654321');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka');
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh',Phone = '7834878789',AccountId = testAccount.id,Location__c=testLocation.id,Role_Type__c='Sales');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
        insert testProduct;
        
        Id stdPrBk = Test.getStandardPricebookId();
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,	
            IsActive = true
        );
        insert testPricebookEntry;
        
        Asset testAsset = new Asset(Name='Test Asset',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version');
        insert testSV;
        
         Vehicle testVehicle = new Vehicle(
            Name = 'Test Vehicle',
            AssetId = testAsset.Id,
            VehicleDefinitionId = testVD.Id,
            VehicleIdentificationNumber = 'VIN12345',
            VehicleRegistrationNumber = 'VRN12345', 
            Software_Version__c = testSV.Id,
            //Dealer__c = testDealer.Id,
            Purchased_Date__c = System.today(),
            ChassisNumber = 'CH1234',
            EngineNumber = 'ENG5678',
            RR_Battery_Number__c = 'BATT999',
            Charger_PC_Number__c = 'CHG1011',
            EW_Submitted__c = false,
            //CurrentOwnerId=testAccount.Id,
            Account__c=testAccount.Id
        );
        insert testVehicle;
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Vehicle__c = testVehicle.Id
        );
        insert testCase;

        
        WorkOrder testWorkOrder = new WorkOrder(
            Vehicle__c = testVehicle.Id,
            Status = 'New'
        );
        insert testWorkOrder;
        
        
    }
    
   @isTest
    static void testGetAllVehicle() {
        List<Vehicle> results = customerConcernController.getAllVehicle('1234567890', 'VRN12345','VIN12345');
       
    }

    @isTest
    static void testGetRecentCases() {
        Vehicle v = [SELECT Id FROM Vehicle LIMIT 1];
        List<Case> recentCases = customerConcernController.getRecentCases(v.Id);
       
    }

    @isTest
    static void testGetJobCardList() {
        Vehicle v = [SELECT Id FROM Vehicle LIMIT 1];
        List<WorkOrder> jobCards = customerConcernController.getJobCardList(v.Id);
       
    }

    @isTest
    static void testGetAccountList() {
        List<Account> accounts = customerConcernController.getAccountList('Customer');
      
    }
    
}