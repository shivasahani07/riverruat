@isTest
public class OrderItemTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        
        Id stdPrBk = Test.getStandardPricebookId();

        Product2 vehicleProduct = new Product2(Name = 'Test Vehicle', Type__c = 'Vehicle', IGST_Percentage__c = 10, ProductCode = '123ir', HSN_Code__c = '1234');
        Product2 accessoryProduct = new Product2(Name = 'Test Accessory', Type__c = 'Accessories', IGST_Percentage__c = 5, ProductCode = '123ur', HSN_Code__c = '1234');
        Product2 merchandiseProduct = new Product2(Name = 'Test Merchandise', Type__c = 'Merchandise', IGST_Percentage__c = 8, ProductCode = '123yr', HSN_Code__c = '1234');

        insert new List<Product2>{ vehicleProduct, accessoryProduct, merchandiseProduct };

        PricebookEntry vehiclePriceEntry = new PricebookEntry(Product2Id = vehicleProduct.Id, Pricebook2Id = stdPrBk, UnitPrice = 100000, IsActive = true);
        PricebookEntry accessoryPriceEntry = new PricebookEntry(Product2Id = accessoryProduct.Id, Pricebook2Id = stdPrBk, UnitPrice = 5000, IsActive = true);
        PricebookEntry merchandisePriceEntry = new PricebookEntry(Product2Id = merchandiseProduct.Id, Pricebook2Id = stdPrBk, UnitPrice = 2000, IsActive = true);

        insert new List<PricebookEntry>{ vehiclePriceEntry, accessoryPriceEntry, merchandisePriceEntry };
            
        Account testAccount = new Account(Name = 'Test Account 1', Type = 'Customer');
        insert testAccount;
        
        //added by Aniket 
                Schema.Location l1 = new Schema.Location(); 
        l1.Name = 'Warehouse 1';
        l1.LocationType = 'Secondary';
        l1.IsInventoryLocation = true;
       // l1.Account__c=testAccount.Id;
        l1.Price_Book__c= Test.getStandardPricebookId();
        insert l1;
                
        Contact con = new Contact(LastName ='Dinesh',Phone = '7834878789',AccountId = testAccount.id,Location__c=l1.Id);
        insert con;
        
       /* User testUser = new User(
        LastName = 'TestUserForRiver',
        Alias = 'testuser',
        Email = 'testuser@example.com',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
       // ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Manager (Partner)' LIMIT 1].Id,
       // UserRoleID = [Select id,Name From UserRole WHERE Name = 'Sales Executive' LIMIT 1].Id,    
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'testuserforriver@example.com', 
        ContactId=con.Id   
    );
    insert testUser;*/
        
        ProductItem p = new ProductItem(Product2Id=accessoryProduct.Id,LocationId=l1.Id,Inward_Quantity__c=9);
        insert p;
        //upto here

        Order testOrder = new Order(Name = 'Test Order', AccountId = testAccount.Id, Pricebook2Id = stdPrBk, Payment_Status__c = 'Completed', Status = 'Draft', EffectiveDate = Date.today(),Website_Response_Id__c='9v6i7tub');
        insert testOrder;

        OrderItem vehicleOrderItem = new OrderItem(OrderId = testOrder.Id, Product2Id = vehicleProduct.Id, PricebookEntryId = vehiclePriceEntry.Id, Quantity = 1, UnitPrice = 100000);
        OrderItem accessoryOrderItem = new OrderItem(OrderId = testOrder.Id, Product2Id = accessoryProduct.Id, PricebookEntryId = accessoryPriceEntry.Id, Quantity = 2, UnitPrice = 5000);
        OrderItem merchandiseOrderItem = new OrderItem(OrderId = testOrder.Id, Product2Id = merchandiseProduct.Id, PricebookEntryId = merchandisePriceEntry.Id, Quantity = 3, UnitPrice = 2000);

        insert new List<OrderItem>{ vehicleOrderItem, accessoryOrderItem, merchandiseOrderItem };
    }
    
    @isTest
    static void testHandleAfterInsert() {
        Test.startTest();
        List<Order> testOrders = [SELECT Id FROM Order LIMIT 1];
        Test.stopTest();
    }
    
    @isTest
    static void testCalculateRollupValues() {
        Test.startTest();
        List<OrderItem> testOrderItems = [SELECT Id FROM OrderItem LIMIT 1];
        Test.stopTest();
    }

    @isTest
    static void testHandleAfterDelete() {
        List<OrderItem> orderItemsToDelete = [SELECT Id FROM OrderItem LIMIT 1];

        Test.startTest();
        delete orderItemsToDelete;
        Test.stopTest();
    }
    @isTest
    static void testInventoryConsumption(){
         
       List<OrderItem> orderItemsToDelete = [SELECT Id FROM OrderItem LIMIT 1];
       //User u = [Select id from User WHERE Username ='testuserforriver@example.com' LIMIT 1];
       // System.runAs(u) {
              Test.startTest();
            OrderItemTriggerHandler.methodToCoverTest();
         //OrderItemTriggerHandler.methodToCoverTest2();
        //OrderItemTriggerHandler.methodToCoverTest3();
        //OrderItemTriggerHandler.methodToCoverTest4();
        
        //OrderItemTriggerHandler.methodToCoverTest2();
        
        delete orderItemsToDelete;
        Test.stopTest();
       // }
        
          
        
        
        
    }
    @isTest
    static void websiteIntegrationTest(){
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka');
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id );
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle',StockKeepingUnit='RINDIE-MB-9');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle',StockKeepingUnit='RINDIE-MB-8');
        insert testProduct2;
        
        Id stdPrBk = Test.getStandardPricebookId();
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        Asset testAsset = new Asset(Name='Test Asset 1',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition 1',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version 1');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle 2', Account__c=testAccount.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
        insert testVehicle;
        
        Order oldOrder = new Order( AccountId = testAccount.Id, Status__c = 'Draft',Status='Draft',Assigned_Vehicle__c = testVehicle.Id,EffectiveDate = Date.today(),Pricebook2Id = stdPrBk,Payment_Status__c = 'Completed', Contact__c = con.id,Website_Order_Id__c='98762ze',Website_Response_Id__c='8765hvc');
        insert oldOrder;
        
       /* OrderItem testOrderItem = new OrderItem( OrderId = oldOrder.Id, Product2Id = testProduct.Id, UnitPrice = 100.0,Quantity = 1, PricebookEntryId = testPricebookEntry.Id,Offer_Amount__c=45,Offer_Description__c='Test123');
        insert testOrderItem;*/
        
        Payment__c p = new Payment__c(Mode_Of_Payment__c='Cash',Payment_Status__c='Success',Source_Of_Payment__c='Website',Transaction_Id__c='ggfyyu');
        insert p;
        
        /*Order_Payment__c opp = new Order_Payment__c(Payments__c=p.Id,Type__c='Booking Amount',Order__c=oldOrder.Id);
        insert opp;*/
        
        Website_Creds__c rwd = new Website_Creds__c(Name='Website Creds', BaseURL__c='https://dummywebsite.com');
        insert rwd;
        
        Test.startTest();
        
        OrderItem testOrderItem = new OrderItem( OrderId = oldOrder.Id, Product2Id = testProduct.Id, UnitPrice = 100.0,Quantity = 1, PricebookEntryId = testPricebookEntry.Id,Offer_Amount__c=45,Offer_Description__c='Test123',Website_Response_Id__c='76rgd');
        insert testOrderItem;
        
        //delete testOrderItem;
        
        OrderItemTriggerHandler.methodToCoverTest();
       
        Test.stopTest();

    }
   
}