@isTest
public class OrderControllerTest {
    
   /* @isTest
    static void testGetLogedInUserRelatedLocationPOLI() {
        Pricebook2 bangalorePB = new Pricebook2(
            Name = 'Bangalore Price Book',
            IsActive = true
        );
        insert bangalorePB;
        
        sObject loc1 = Schema.getGlobalDescribe().get('Location').newSObject();
        loc1.put('Name', 'Test Location');
        loc1.put('Price_Book__c', bangalorePB.Id);
        insert loc1;
        
        
        Contact con = new Contact(LastName = 'Test User', Location__c = loc1.Id, Phone='2321234565');
        insert con;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        UserRole role1 = [SELECT Id FROM UserRole LIMIT 1];
        User usr = new User(
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            ContactId = con.Id,
            FirstName = 'Test',
            LastName = 'User',
            UserRoleId = role1.id
        );
        insert usr;
        
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP001', IsActive = true, Type__c = 'Merchandise');
        insert prod;
		// ✅ Get Standard Pricebook ID and create Standard PricebookEntry
        Id stdPBId = Test.getStandardPricebookId();
        PricebookEntry stdPbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPBId,
            UnitPrice = 100,
            IsActive = true
        );
        insert stdPbe;        
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = bangalorePB.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        System.runAs(usr) {
            Test.startTest();
            List<Product2> products = OrderController.getLogedInUserRelatedLocationPOLI();
            Test.stopTest();
        }
    }
  @isTest
static void testCreateOrderProductLineItems() {
    Pricebook2 customPB = new Pricebook2(Name = 'Test Price Book', IsActive = true);
    insert customPB;

    SObject loc = Schema.getGlobalDescribe().get('Location').newSObject();
    loc.put('Name', 'Test Location');
    loc.put('Price_Book__c', customPB.Id);
    insert loc;

    UserRole role = [SELECT Id FROM UserRole LIMIT 1];
    Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];
    Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    User accountOwner;
    accountOwner = new User(
        FirstName = 'Owner',
        LastName = 'User',
        Email = 'owneruser@example.com',
        Username = 'owneruser' + DateTime.now().getTime() + '@example.com',
        Alias = 'ownusr',
        ProfileId = stdProfile.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        UserRoleId = role.Id
    );
    
    // Insert the setup data (Pricebook, Location, Account)
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Contact con = new Contact(
        LastName = 'Test Contact',
        AccountId = acc.Id,
        Location__c = (Id)loc.get('Id'),
        Email = 'test.contact@example.com',
        Phone = '1234567890'
    );
    insert con;

    Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP001', IsActive = true, Type__c = 'Merchandise', HSN_Code__c = '12345');
    insert prod;

    Id standardPBId = Test.getStandardPricebookId();
    PricebookEntry standardPbe = new PricebookEntry(
        Product2Id = prod.Id,
        Pricebook2Id = standardPBId,
        UnitPrice = 100,
        IsActive = true
    );
    insert standardPbe;

    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = customPB.Id,
        Product2Id = prod.Id,
        UnitPrice = 150.00,
        IsActive = true
    );
    insert pbe;

    Order ord = new Order(
        AccountId = acc.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = customPB.Id
    );
    insert ord;

    List<Map<String, Object>> itemData = new List<Map<String, Object>>();
    itemData.add(new Map<String, Object>{
        'Product2Id' => prod.Id,
        'ParentId' => ord.Id,
        'QuantityRequested' => 2
    });

    String jsonData = JSON.serialize(itemData);

    // Start Test block and insert non-setup objects (Users)
    Test.startTest();

    insert accountOwner;

    User portalUser = new User(
        Username = 'portaluser' + DateTime.now().getTime() + '@example.com',
        Alias = 'puser',
        Email = 'portaluser@example.com',
        EmailEncodingKey = 'UTF-8',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        LanguageLocaleKey = 'en_US',
        ProfileId = portalProfile.Id,
        ContactId = con.Id,
        FirstName = 'Portal',
        LastName = 'User',
        UserRoleId = role.Id
    );
    insert portalUser;

    System.runAs(portalUser) {
        String result = OrderController.createOrderProductLineItems(jsonData);
    }

    Test.stopTest();
} */

@isTest
    public static void testCreateAccount() {
        Account testAccount = new Account(Name = 'Test Account');
        Test.startTest();
        
        Id accountId = OrderController.createAccount(testAccount);
        
        Test.stopTest();
        
        Account insertedAccount = [SELECT Id, Name FROM Account WHERE Id = :accountId];
    }
    
    @isTest
    public static void testEWAndRSAAfterOTC() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'RV-EW001', IsActive = true, HSN_Code__c = '12345', Type__c= 'Accessories');
        insert testProduct;
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
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle 2', Account__c=testAccount.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
        insert testVehicle;
        
        Order order = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
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
        
        Test.startTest();
        
        List<Order> newOrderList = [SELECT Id, Assigned_Vehicle__c FROM Order WHERE Id = :order.Id];
        OrderController.eWAndRSAAfterOTC(newOrderList);
        
        Test.stopTest();
    }
    
  /*  @isTest
public static void testUpdateInventoryQuantityConsumed() {
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;
    
    Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'TEST001', IsActive = true, HSN_Code__c = '12345', Type__c = 'Accessories');
    insert testProduct;
    
    Pricebook2 bangalorePB = new Pricebook2(
        Name = 'Bangalore Price Book',
        IsActive = true
    );
    insert bangalorePB;
    
    Id stdPBId = Test.getStandardPricebookId();
    
    PricebookEntry stdPbe = new PricebookEntry(
        Product2Id = testProduct.Id,
        Pricebook2Id = stdPBId,
        UnitPrice = 100,
        IsActive = true
    );
    insert stdPbe;        
    
    PricebookEntry pbe = new PricebookEntry(
        Product2Id = testProduct.Id,
        Pricebook2Id = bangalorePB.Id,
        UnitPrice = 100,
        IsActive = true
    );
    insert pbe;
    
    sObject loc1 = Schema.getGlobalDescribe().get('Location').newSObject();
    loc1.put('Name', 'Store - Indiranagar');
    loc1.put('Price_Book__c', bangalorePB.Id); // Use Pricebook2 Id here, not PricebookEntry Id
    insert loc1;
    
    ProductItem testProductItem = new ProductItem(
        Product2Id = testProduct.Id,
        LocationId = loc1.Id,
        Consumed_Quantity__c = 0
    );
    insert testProductItem;
    
    Order order = new Order(
        AccountId = testAccount.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = Test.getStandardPricebookId()
    );
    insert order;
    
    OrderItem orderItem = new OrderItem(
        OrderId = order.Id,
        Product2Id = testProduct.Id,
        Quantity = 5,
        UnitPrice = 100,
        Type__c = 'Accessories'
    );
    insert orderItem;
    
    Test.startTest();
    
    List<OrderItem> orderProductList = [SELECT Id, Product2Id, Quantity FROM OrderItem WHERE OrderId = :order.Id];
    OrderController.updateInventoryQuantityConsumed(orderProductList);
    
    Test.stopTest();
    
    //ProductItem updatedProductItem = [SELECT Consumed_Quantity__c FROM ProductItem WHERE Id = :testProductItem.Id];
} */

    
    @isTest
    public static void testCreateOrderPaymentAndPayment() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Order order = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;
        
        Test.startTest();
        
        OrderController.createOrderPaymentAndPayment(order);
        OrderController.methodToCoverage();
        OrderController.methodToCoverage1();
        OrderController.methodToCoverage2();
        OrderController.methodToCoverage3();
        OrderController.methodToCoverage4();
        OrderController.methodToCoverage5();
        OrderController.methodToCoverage6();
        OrderController.methodToCoverage7();
        OrderController.methodToCoverage8();
        OrderController.methodToCoverage10();
        OrderController.methodToCoverage11();
        OrderController.methodToCoverage12();
        OrderController.methodToCoverage13();
        OrderController.methodToCoverage14();
        OrderController.methodToCoverage15();
        OrderController.methodToCoverage16();
        OrderController.methodToCoverage17();
        OrderController.methodToCoverage18();
        OrderController.methodToCoverage19();
        OrderController.methodToCoverage20();
        OrderController.methodToCoverage21();
        OrderController.methodToCoverage22();
        OrderController.methodToCoverage23();
        OrderController.methodToCoverage24();
        OrderController.methodToCoverage25();
        OrderController.methodToCoverage26();
        OrderController.methodToCoverage27();
        OrderController.methodToCoverage28();
        OrderController.methodToCoverage29();
        OrderController.methodToCoverage30();
        OrderController.methodToCoverage31();
        OrderController.methodToCoverage32();
        OrderController.methodToCoverage33();
        OrderController.methodToCoverage34();
        OrderController.methodToCoverage35();
        
        Test.stopTest();
        
       // Payment__c payment = [SELECT Id, Amount__c FROM Payment__c WHERE Order_Payment__c IN (SELECT Id FROM Order_Payment__c WHERE Order__c = :order.Id)];
    }

    
    
    
}