@isTest
public class ExtendedWarrantyForVehicleOrderTest {
    @IsTest
    static void coverMethods(){
        Account testAccount = new Account(Name = 'Test Account',Center_Code__c = '291002',Email__c = 'test@example.com',Phone='0987654321');
        insert testAccount;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'RV-EW-001', IsActive = true, HSN_Code__c = '12345', Type__c= 'Accessories');
        insert testProduct;
       
        
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
        
        DateTime mockCreatedDate = DateTime.Now().addMinutes(-2);
        
        Test.setCreatedDate(order.Id,mockCreatedDate);
        
        Test.setCreatedDate(orderItem.Id,mockCreatedDate);
        
        
        Website_Creds__c rwd = new Website_Creds__c(Name='Website Creds', BaseURL__c='https://dummywebsite.com');
        insert rwd;

        
        Test.setMock(HttpCalloutMock.class, new MockRiverCreateOrderCallout());
        
        Test.startTest();
        order.Status='RTO Registration';
        update order;
        Test.stopTest();
    }
    public class MockRiverCreateOrderCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{\"code\":200,\"success\":true,\"data\":{\"order_id\":\"d95a36f4-f2c4-4252-89ed-8c8632db661f\",\"order_item\":[{\"id\":\"34cc9a9e-43ba-4101-87f0-084e04266ee1\",\"sku\":\"RINDIE-MB-9\",\"product_type\":\"Vehicle\"}]}}');
            res.setStatusCode(200);
            return res;
        }
    }

}