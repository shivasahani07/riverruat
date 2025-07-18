@isTest
public class TestScheduleOrderCreationOnWebsite {
    @isTest
    static void testSchedule(){
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
        
        OrderItem testOrderItem = new OrderItem( OrderId = oldOrder.Id, Product2Id = testProduct.Id, UnitPrice = 100.0,Quantity = 1, PricebookEntryId = testPricebookEntry.Id,Offer_Amount__c=45,Offer_Description__c='Test123');
        insert testOrderItem;
        
        Payment__c p = new Payment__c(Mode_Of_Payment__c='Cash',Payment_Status__c='Success',Source_Of_Payment__c='Website',Transaction_Id__c='ev46vt35');
        insert p;
        
        Order_Payment__c opp2 = new Order_Payment__c(Payments__c=p.Id,Type__c='Down Payment',Order__c=oldOrder.Id);
        insert opp2;        
        
        Website_Creds__c rwd = new Website_Creds__c(Name='Website Creds', BaseURL__c='https://dummywebsite.com');
        insert rwd;
        
        List<Id> orderIds = new List<Id>{ oldOrder.Id };
        List<Id> orderItemIds = new List<Id>{ testOrderItem.Id }; 
        List<Id> orderPaymentIds = new List<Id>{opp2.Id};     

        
        ScheduleOrderCreationOnWebsite schedClass = new ScheduleOrderCreationOnWebsite(orderIds);

        ScheduleCreateProductOnWebsite s = new ScheduleCreateProductOnWebsite(orderItemIds);
        
        OrderItemTriggerHandler.OrderItemDeleteDTO dto = new OrderItemTriggerHandler.OrderItemDeleteDTO();
        dto.orderId = oldOrder.Id;
        dto.accountId=testACcount.Id;
        dto.websiteResponseId = 'WebsiteResp123';
        
       ScheduleDeleteOrderItemOnWebsite s1 = new ScheduleDeleteOrderItemOnWebsite(new List<OrderItemTriggerHandler.OrderItemDeleteDTO>{ dto });
        
        
      ScheduleCreatePaymentOnWebsite s2 = new ScheduleCreatePaymentOnWebsite(orderPaymentIds);  
        
        OrderPaymentTriggerHandler.wrapperForDeletePayment  aa = new OrderPaymentTriggerHandler.wrapperForDeletePayment();
        aa.orderId=oldOrder.Id;
        aa.paymentId=p.Id;
        
        ScheduleDeletePaymentOnWebsite s3 = new ScheduleDeletePaymentOnWebsite(new List<OrderPaymentTriggerHandler.wrapperForDeletePayment>{aa});

        Test.startTest();
        schedClass.execute(null);
        s.execute(null);
        s1.execute(null);
        s2.execute(null);
        s3.execute(null);
        Test.stopTest();
    }

}