@isTest
public class TestQueueableForCreateProductInOrder {
     public class MockRiverCreateOrderCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"code":200,"success":true,"data":{"order_items":[{"id":"a39d43ac-124f-40c8-ad85-1ae27f9bd3c4","sku":"RINDIE-MB-9","product_type":"Accessories"}]}}');
            res.setStatusCode(200);
            return res;
        }
     
    }
    @isTest
    static void testQueueableWithCallout() {
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
        
        Order oldOrder = new Order( AccountId = testAccount.Id, Status__c = 'Draft',Status='Draft',Assigned_Vehicle__c = testVehicle.Id,EffectiveDate = Date.today(),Pricebook2Id = stdPrBk,Payment_Status__c = 'Completed', Contact__c = con.id,Website_Order_Id__c='98762ze');
        insert oldOrder;
        
       /* OrderItem testOrderItem = new OrderItem( OrderId = oldOrder.Id, Product2Id = testProduct.Id, UnitPrice = 100.0,Quantity = 1, PricebookEntryId = testPricebookEntry.Id,Offer_Amount__c=45,Offer_Description__c='Test123');
        insert testOrderItem;*/
        
        Payment__c p = new Payment__c(Mode_Of_Payment__c='Cash',Payment_Status__c='Success',Source_Of_Payment__c='Website',Transaction_Id__c='4wby5v');
        insert p;
        
        Order_Payment__c opp = new Order_Payment__c(Payments__c=p.Id,Type__c='Booking Amount',Order__c=oldOrder.Id);
        insert opp;
        
        Website_Creds__c rwd = new Website_Creds__c(Name='Website Creds', BaseURL__c='https://dummywebsite.com');
        insert rwd;

        
        Test.setMock(HttpCalloutMock.class, new MockRiverCreateOrderCallout());
       
        Test.startTest();
   
        OrderItem testOrderItem = new OrderItem( OrderId = oldOrder.Id, Product2Id = testProduct.Id, UnitPrice = 100.0,Quantity = 1, PricebookEntryId = testPricebookEntry.Id,Offer_Amount__c=45,Offer_Description__c='Test123');
        insert testOrderItem;
        
        QueueableForCreateProductInOrder queueableForUpdate = new QueueableForCreateProductInOrder(new List<Id>{testOrderItem.Id});
        System.enqueueJob(queueableForUpdate);
        
        OrderItemTriggerHandler.OrderItemDeleteDTO dto = new OrderItemTriggerHandler.OrderItemDeleteDTO();
        dto.orderId = oldOrder.Id;
        dto.accountId=testACcount.Id;
        dto.websiteResponseId = 'WebsiteResp123';

        
        QueueableForDeleteOrderItemOnWebsite q = new QueueableForDeleteOrderItemOnWebsite(new List<OrderItemTriggerHandler.OrderItemDeleteDTO>{ dto });
        System.enqueueJob(q);
        
        
        Test.stopTest();
    }
}