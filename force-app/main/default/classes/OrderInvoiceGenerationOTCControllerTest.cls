@IsTest
public class OrderInvoiceGenerationOTCControllerTest {
    @IsTest
    static void testCoverageMethod(){
        Account testAccount = new Account(Name = 'Test Account',Center_Code__c = '291002',Email__c = 'test@example.com',Phone='0987654321');
        insert testAccount;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'RV-EW001', IsActive = true, HSN_Code__c = '12345', Type__c= 'Accessories');
        insert testProduct;
        
        Product2 rsaProduct = new Product2(Name = 'Road Side Assistance', ProductCode = 'RSA-G2', IsActive = true, HSN_Code__c = '12345', Type__c= 'Accessories');
        insert rsaProduct;
        
        RecordType otcRecordType = [
            SELECT Id FROM RecordType
            WHERE DeveloperName = 'OTC' AND SObjectType = 'Order'
            LIMIT 1
        ];
        Asset testAsset = new Asset(Name='Test Asset 1',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition 1',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version 1');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle 2', Account__c=testAccount.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3bhjkoiuytrewqwer',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true,VehicleRegistrationNumber='098765',RSA_Activation__c=false);
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
        
        PricebookEntry pbeRSA = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = rsaProduct.Id,
            UnitPrice = 999,
            IsActive = true
        );
        insert pbeRSA;
        
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.id,
            Type__c = 'Accessories'
        );
        insert orderItem;
        
        OrderItem rsaItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = rsaProduct.Id,
            Quantity = 1,
            UnitPrice = 999,
            PricebookEntryId = pbeRSA.id,
            Type__c = 'Accessories'
        );
        insert rsaItem;
        
        Order_Invoice__c o1 = new Order_Invoice__c();
        o1.Name='Accessories Invoice';
        o1.Invoice_Type__c='Accessories Invoice';
        o1.Invoice_Number__c='Test1234';
        o1.Order__c=order.Id;
        insert o1;
        
        DateTime mockCreatedDate = DateTime.Now().addMinutes(-2);
        
        Test.setCreatedDate(order.Id,mockCreatedDate);
        
        Test.setCreatedDate(orderItem.Id,mockCreatedDate);
        
        Test.setCreatedDate(rsaItem.Id,mockCreatedDate);
        
        Test.startTest();
        order.Status='Invoice Generation';
        update order;
        Test.stopTest();
    }

}