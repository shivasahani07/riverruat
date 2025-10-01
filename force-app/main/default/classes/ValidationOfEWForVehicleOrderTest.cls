@IsTest
public class ValidationOfEWForVehicleOrderTest {
    @IsTest
    static void coverMethod(){
        Account testAccount = new Account(Name = 'Test Account',Center_Code__c = '291002',Email__c = 'test@example.com',Phone='0987654321');
        insert testAccount;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'RV-EW-1', IsActive = true, HSN_Code__c = '12345', Type__c= 'Accessories');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product', ProductCode = 'RV-EW-2', IsActive = true, HSN_Code__c = '12345', Type__c= 'Accessories');
        insert testProduct2;
       
        
        RecordType otcRecordType = [
            SELECT Id FROM RecordType
            WHERE DeveloperName = 'Vehicle' AND SObjectType = 'Order'
            LIMIT 1
        ];
        Asset testAsset = new Asset(Name='Test Asset 1',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition 1',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version 1');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle 2', Account__c=testAccount.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3C4D5E6F7G8H9I',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true,VehicleRegistrationNumber='098765',RSA_Activation__c=false);
        insert testVehicle;
        
        Order order = new Order(
            AccountId = testAccount.Id,
            Status = 'New',
            RecordTypeId = otcRecordType.Id,
            EffectiveDate = Date.today(),
            Assigned_Vehicle__c = testVehicle.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;
        
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
         
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.id,
            Type__c = 'Accessories'
        );
        insert orderItem;
        
        
        
        Order_Invoice__c o1 = new Order_Invoice__c();
        o1.Name='Accessories Invoice';
        o1.Invoice_Type__c='Accessories Invoice';
        o1.Invoice_Number__c='Test1234';
        o1.Order__c=order.Id;
        insert o1;
        
        OrderItem orderItem2 = new OrderItem(
            OrderId = order.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.id,
            Type__c = 'Accessories'
        );
        
        
        Test.startTest();
        Boolean gotError1 = false;
        try{
            insert orderItem2;
        }catch (DmlException e) {
            gotError1 = true;
            //System.assert(e.getDmlMessage(0).contains('Only RV-EW-1 and RV-EW-4 can be added to Vehicle Orders.'), 'Unexpected error: ' + e.getMessage());
        }
        
        Test.stopTest();
        
    }
   @IsTest
    static void coverMethod2(){
        Account testAccount = new Account(Name = 'Test Account',Center_Code__c = '291002',Email__c = 'test@example.com',Phone='0987654321');
        insert testAccount;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'ABCD', IsActive = true, HSN_Code__c = '12345', Type__c= 'Merchandise',StockKeepingUnit='ABCD');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product', ProductCode = 'RV-EW-2', IsActive = true, HSN_Code__c = '12345', Type__c= 'Accessories');
        insert testProduct2;
       
        
        RecordType otcRecordType = [
            SELECT Id FROM RecordType
            WHERE DeveloperName = 'Vehicle' AND SObjectType = 'Order'
            LIMIT 1
        ];
        Asset testAsset = new Asset(Name='Test Asset 1',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition 1',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version 1');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle 2', Account__c=testAccount.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3C4D5E6F7G8H9I',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true,VehicleRegistrationNumber='098765',RSA_Activation__c=false);
        insert testVehicle;
        
        Order order = new Order(
            AccountId = testAccount.Id,
            Status = 'New',
            RecordTypeId = otcRecordType.Id,
            EffectiveDate = Date.today(),
            Assigned_Vehicle__c = testVehicle.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;
        
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
         
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.id,
            Type__c = 'Merchandise',
            Website_Response_Id__c='v5y45et4'
        );
        //insert orderItem;
        
        
        
        Order_Invoice__c o1 = new Order_Invoice__c();
        o1.Name='Accessories Invoice';
        o1.Invoice_Type__c='Accessories Invoice';
        o1.Invoice_Number__c='Test1234';
        o1.Order__c=order.Id;
        insert o1;
        
        OrderItem orderItem2 = new OrderItem(
            OrderId = order.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.id,
            Type__c = 'Accessories'
        );
        Website_Creds__c rwd = new Website_Creds__c(Name='Website Creds', BaseURL__c='https://dummywebsite.com');
        insert rwd;
        
        //Trigger_Handler__mdt  TriggerInstancee = Trigger_Handler__mdt.getInstance('OrderItemTriggerHandler_deleteProductOnW');
        Trigger_Handler__mdt t = new Trigger_Handler__mdt(DeveloperName='OrderItemTriggerHandler_deleteProductOnW',IsActive__c=true);
        //TriggerInstancee.IsActive__c=true;
        
        Test.startTest();
        Boolean gotError1 = false;
        try{
            insert orderItem;
            //delete orderItem;
        }catch (DmlException e) {
            gotError1 = true;
            //System.assert(e.getDmlMessage(0).contains('Only RV-EW-1 and RV-EW-4 can be added to Vehicle Orders.'), 'Unexpected error: ' + e.getMessage());
        }
        
        Test.stopTest();
        
    }
   
    
    
    @IsTest
    static void coverMethod3(){
        Account testAccount = new Account(Name = 'Test Account',Center_Code__c = '291002',Email__c = 'test@example.com',Phone='0987654321');
        insert testAccount;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'ABCD', IsActive = true, HSN_Code__c = '12345', Type__c= 'Merchandise',StockKeepingUnit='ABCD');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product', ProductCode = 'RV-EW-2', IsActive = true, HSN_Code__c = '12345', Type__c= 'Accessories');
        insert testProduct2;
       
        
        RecordType otcRecordType = [
            SELECT Id FROM RecordType
            WHERE DeveloperName = 'Vehicle' AND SObjectType = 'Order'
            LIMIT 1
        ];
        Asset testAsset = new Asset(Name='Test Asset 1',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition 1',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version 1');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle 2', Account__c=testAccount.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3C4D5E6F7G8H9I',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true,VehicleRegistrationNumber='098765',RSA_Activation__c=false);
        insert testVehicle;
        
        Order order = new Order(
            AccountId = testAccount.Id,
            Status = 'New',
            RecordTypeId = otcRecordType.Id,
            EffectiveDate = Date.today(),
            Assigned_Vehicle__c = testVehicle.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;
        
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
         
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.id,
            Type__c = 'Merchandise',
            Website_Response_Id__c='v5y45et4'
        );
        insert orderItem;
        
        
        
        Order_Invoice__c o1 = new Order_Invoice__c();
        o1.Name='Accessories Invoice';
        o1.Invoice_Type__c='Accessories Invoice';
        o1.Invoice_Number__c='Test1234';
        o1.Order__c=order.Id;
        insert o1;
        
        Website_Creds__c rwd = new Website_Creds__c(Name='Website Creds', BaseURL__c='https://dummywebsite.com');
        insert rwd;
        
        //Trigger_Handler__mdt  TriggerInstancee = Trigger_Handler__mdt.getInstance('OrderItemTriggerHandler_deleteProductOnW');
        Trigger_Handler__mdt t = new Trigger_Handler__mdt(DeveloperName='OrderItemTriggerHandler_deleteProductOnW',IsActive__c=true);
        //TriggerInstancee.IsActive__c=true;
        
        Test.startTest();
        Boolean gotError1 = false;
        try{
            
            delete orderItem;
        }catch (DmlException e) {
            gotError1 = true;
            //System.assert(e.getDmlMessage(0).contains('Only RV-EW-1 and RV-EW-4 can be added to Vehicle Orders.'), 'Unexpected error: ' + e.getMessage());
        }
        
        Test.stopTest();
        
    }

}