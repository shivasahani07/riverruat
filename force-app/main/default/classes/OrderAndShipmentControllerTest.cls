@IsTest
public class OrderAndShipmentControllerTest {
    @IsTest
    static void createShipmentMethod(){
        
        Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String poNumber = String.valueof(po.ProductRequestNumber); 
        System.debug('poNumber==>'+poNumber);
        req.requestBody = Blob.valueOf('{"shipment":{"sap_shipment_id":"SAP21Again",' +
                    '"sap_delivery_no":"Or2025",' +
                    '"ShipToName":"Aniket Rick",' +
                    '"status":"New",' +
                    '"po_number":"' + poNumber + '",' +
                    '"so_number":"198",' +
                    '"lineItems":[{"quantity":140,"item_code":"abcd"}]}}');
        
        RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.createOrderShipment();
        Test.stopTest();
    }
    
     @IsTest
    static void updateShipmentMethod(){
        
        Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
        Shipment s = new Shipment();
            s.Order__c=newOrder.Id;
            s.Status = 'New';
            //s.Purchase_Order__c=po.Id;
            s.SourceLocationId = testLocation.Id;
            s.DestinationLocationId = po.Destination_Location__c;
            s.ShipToName='Prathap Sir';
            s.sap_shipment_id__c='Ship-123';
        
        insert s;
        
        ShipmentItem sri = new ShipmentItem();
                sri.Product2Id = oi.Product2Id;
                sri.Quantity = oi.Quantity;
                sri.Parent_Shipment__c = s.Id;
                sri.Is_VOR__c = oi.Is_VOR__c;
                sri.Unit_Price__c = oi.UnitPrice;
                sri.SGST__c = oi.SGST__c;
                sri.CGST__c = oi.CGST__c;
                sri.IGST__c = oi.IGST__c;
                sri.Related_Order_Line_Item__c=oi.Id ; 
                sri.ShipmentId=s.Id;
        insert sri;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
         req.requestBody = Blob.valueOf('{' +
            '"sap_shipment_id":"Ship-123",' +
            '"status":"Dispatched",' +
            '"LR_Date":"06/07/2025",' +
            '"LR_no":"69695342",' +
            '"driver_name":"River",' +
            '"driver_phone":"1234543212",' +
            '"e_way_bill_no":"07863276",' +
            '"invoice_date":"10/07/2025",' +
            '"invoice_no":"87686",' +
            '"invoice_amount":5000' +
        '}');
        
         RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.updateOrderShipment();
        Test.stopTest();
        
    }
    @isTest
    static void createOnlyShipmentForExistingOrder(){
         Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
         RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String poNumber = String.valueof(po.ProductRequestNumber); 
        System.debug('poNumber==>'+poNumber);
        req.requestBody = Blob.valueOf('{"shipment":{"sap_shipment_id":"SAP21Again",' +
                    '"sap_delivery_no":"Test-123",' +
                    '"ShipToName":"Aniket Rick",' +
                    '"status":"New",' +
                    '"po_number":"' + poNumber + '",' +
                    '"so_number":"198",' +
                    '"lineItems":[{"quantity":140,"item_code":"abcd"}]}}');
        
        RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.createOrderShipment();
        Test.stopTest();

    }
     @isTest
    static void createOnlyShipmentForExistingOrderErrors1(){
         Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
         RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String poNumber = String.valueof(po.ProductRequestNumber); 
        System.debug('poNumber==>'+poNumber);
        req.requestBody = Blob.valueOf('{"shipment":{"sap_shipment_id":"SAP21Again",' +
                    '"sap_delivery_no":"",' +
                    '"ShipToName":"Aniket Rick",' +
                    '"status":"New",' +
                    '"po_number":"' + poNumber + '",' +
                    '"so_number":"198",' +
                    '"lineItems":[{"quantity":140,"item_code":"abcd"}]}}');
        
        RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.createOrderShipment();
        Test.stopTest();

    }
     @isTest
    static void createOnlyShipmentForExistingOrderErrors2(){
         Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
         RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String poNumber = String.valueof(po.ProductRequestNumber); 
        System.debug('poNumber==>'+poNumber);
        req.requestBody = Blob.valueOf('{"shipment":{"sap_shipment_id":"SAP21Again",' +
                    '"sap_delivery_no":"Test-123",' +
                    '"ShipToName":"Aniket Rick",' +
                    '"status":"NewT",' +
                    '"po_number":"' + poNumber + '",' +
                    '"so_number":"198",' +
                    '"lineItems":[{"quantity":140,"item_code":"abcd"}]}}');
        
        RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.createOrderShipment();
        Test.stopTest();

    }
    @isTest
    static void createOnlyShipmentForExistingOrderErrors3(){
         Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
         Shipment s = new Shipment();
            s.Order__c=newOrder.Id;
            s.Status = 'New';
            //s.Purchase_Order__c=po.Id;
            s.SourceLocationId = testLocation.Id;
            s.DestinationLocationId = po.Destination_Location__c;
            s.ShipToName='Prathap Sir';
            s.sap_shipment_id__c='Ship-123';
        
        insert s;
        
        ShipmentItem sri = new ShipmentItem();
                sri.Product2Id = oi.Product2Id;
                sri.Quantity = oi.Quantity;
                sri.Parent_Shipment__c = s.Id;
                sri.Is_VOR__c = oi.Is_VOR__c;
                sri.Unit_Price__c = oi.UnitPrice;
                sri.SGST__c = oi.SGST__c;
                sri.CGST__c = oi.CGST__c;
                sri.IGST__c = oi.IGST__c;
                sri.Related_Order_Line_Item__c=oi.Id ; 
                sri.ShipmentId=s.Id;
        insert sri;
        
        
         RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String poNumber = String.valueof(po.ProductRequestNumber); 
        System.debug('poNumber==>'+poNumber);
        req.requestBody = Blob.valueOf('{"shipment":{"sap_shipment_id":"Ship-123",' +
                    '"sap_delivery_no":"Test-123",' +
                    '"ShipToName":"Aniket Rick",' +
                    '"status":"New",' +
                    '"po_number":"' + poNumber + '",' +
                    '"so_number":"198",' +
                    '"lineItems":[{"quantity":140,"item_code":"abcd"}]}}');
        
        RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.createOrderShipment();
        Test.stopTest();

    }
     @IsTest
    static void updateShipmentMethodError1(){
        
        Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
        Shipment s = new Shipment();
            s.Order__c=newOrder.Id;
            s.Status = 'New';
            //s.Purchase_Order__c=po.Id;
            s.SourceLocationId = testLocation.Id;
            s.DestinationLocationId = po.Destination_Location__c;
            s.ShipToName='Prathap Sir';
            s.sap_shipment_id__c='Ship-123';
        
        insert s;
        
        ShipmentItem sri = new ShipmentItem();
                sri.Product2Id = oi.Product2Id;
                sri.Quantity = oi.Quantity;
                sri.Parent_Shipment__c = s.Id;
                sri.Is_VOR__c = oi.Is_VOR__c;
                sri.Unit_Price__c = oi.UnitPrice;
                sri.SGST__c = oi.SGST__c;
                sri.CGST__c = oi.CGST__c;
                sri.IGST__c = oi.IGST__c;
                sri.Related_Order_Line_Item__c=oi.Id ; 
                sri.ShipmentId=s.Id;
        insert sri;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
         req.requestBody = Blob.valueOf('{' +
            '"sap_shipment_id":"Ship-123",' +
            '"status":"Dispatched",' +
            '"LR_Date":"06-07-2025",' +
            '"LR_no":"69695342",' +
            '"driver_name":"River",' +
            '"driver_phone":"1234543212",' +
            '"e_way_bill_no":"07863276",' +
            '"invoice_date":"10/07/2025",' +
            '"invoice_no":"87686",' +
            '"invoice_amount":5000' +
        '}');
        
         RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.updateOrderShipment();
        Test.stopTest();
        
    }
         @IsTest
    static void updateShipmentMethodError2(){
        
        Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
        Shipment s = new Shipment();
            s.Order__c=newOrder.Id;
            s.Status = 'New';
            //s.Purchase_Order__c=po.Id;
            s.SourceLocationId = testLocation.Id;
            s.DestinationLocationId = po.Destination_Location__c;
            s.ShipToName='Prathap Sir';
            s.sap_shipment_id__c='Ship-123';
        
        insert s;
        
        ShipmentItem sri = new ShipmentItem();
                sri.Product2Id = oi.Product2Id;
                sri.Quantity = oi.Quantity;
                sri.Parent_Shipment__c = s.Id;
                sri.Is_VOR__c = oi.Is_VOR__c;
                sri.Unit_Price__c = oi.UnitPrice;
                sri.SGST__c = oi.SGST__c;
                sri.CGST__c = oi.CGST__c;
                sri.IGST__c = oi.IGST__c;
                sri.Related_Order_Line_Item__c=oi.Id ; 
                sri.ShipmentId=s.Id;
        insert sri;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
         req.requestBody = Blob.valueOf('{' +
            '"sap_shipment_id":"Ship-123",' +
            '"status":"Dispatched",' +
            '"LR_Date":"06/07/2025",' +
            '"LR_no":"69695342",' +
            '"driver_name":"River",' +
            '"driver_phone":"1234543212",' +
            '"e_way_bill_no":"07863276",' +
            '"invoice_date":"10-07-2025",' +
            '"invoice_no":"87686",' +
            '"invoice_amount":5000' +
        '}');
        
         RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.updateOrderShipment();
        Test.stopTest();
        
    }
     @IsTest
    static void updateShipmentMethodError3(){
        
        Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
        Shipment s = new Shipment();
            s.Order__c=newOrder.Id;
            s.Status = 'New';
          //  s.Purchase_Order__c=po.Id;
            s.SourceLocationId = testLocation.Id;
            s.DestinationLocationId = po.Destination_Location__c;
            s.ShipToName='Prathap Sir';
            s.sap_shipment_id__c='Ship-123';
        
        insert s;
        
        ShipmentItem sri = new ShipmentItem();
                sri.Product2Id = oi.Product2Id;
                sri.Quantity = oi.Quantity;
                sri.Parent_Shipment__c = s.Id;
                sri.Is_VOR__c = oi.Is_VOR__c;
                sri.Unit_Price__c = oi.UnitPrice;
                sri.SGST__c = oi.SGST__c;
                sri.CGST__c = oi.CGST__c;
                sri.IGST__c = oi.IGST__c;
                sri.Related_Order_Line_Item__c=oi.Id ; 
                sri.ShipmentId=s.Id;
        insert sri;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
         req.requestBody = Blob.valueOf('{' +
            '"sap_shipment_id":"Ship-123",' +
            '"status":"DispatchedT",' +
            '"LR_Date":"06/07/2025",' +
            '"LR_no":"69695342",' +
            '"driver_name":"River",' +
            '"driver_phone":"1234543212",' +
            '"e_way_bill_no":"07863276",' +
            '"invoice_date":"10/07/2025",' +
            '"invoice_no":"87686",' +
            '"invoice_amount":5000' +
        '}');
        
         RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.updateOrderShipment();
        Test.stopTest();
        
    }
      @IsTest
    static void updateShipmentMethodError4(){
        
        Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
        Shipment s = new Shipment();
            s.Order__c=newOrder.Id;
            s.Status = 'New';
            //s.Purchase_Order__c=po.Id;
            s.SourceLocationId = testLocation.Id;
            s.DestinationLocationId = po.Destination_Location__c;
            s.ShipToName='Prathap Sir';
            s.sap_shipment_id__c='Ship-123';
        
        insert s;
        
        ShipmentItem sri = new ShipmentItem();
                sri.Product2Id = oi.Product2Id;
                sri.Quantity = oi.Quantity;
                sri.Parent_Shipment__c = s.Id;
                sri.Is_VOR__c = oi.Is_VOR__c;
                sri.Unit_Price__c = oi.UnitPrice;
                sri.SGST__c = oi.SGST__c;
                sri.CGST__c = oi.CGST__c;
                sri.IGST__c = oi.IGST__c;
                sri.Related_Order_Line_Item__c=oi.Id ; 
                sri.ShipmentId=s.Id;
        insert sri;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
         req.requestBody = Blob.valueOf('{' +
            '"sap_shipment_id":"Ship-1234",' +
            '"status":"Dispatched",' +
            '"LR_Date":"06/07/2025",' +
            '"LR_no":"69695342",' +
            '"driver_name":"River",' +
            '"driver_phone":"1234543212",' +
            '"e_way_bill_no":"07863276",' +
            '"invoice_date":"10/07/2025",' +
            '"invoice_no":"87686",' +
            '"invoice_amount":5000' +
        '}');
        
         RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.updateOrderShipment();
        Test.stopTest();
        
    }
     @IsTest
    static void createShipmentMethodError1(){
        
        Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);
        String poN='PR-0000';

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String poNumber = String.valueof(po.ProductRequestNumber); 
        System.debug('poNumber==>'+poNumber);
        req.requestBody = Blob.valueOf('{"shipment":{"sap_shipment_id":"SAP21Again",' +
                    '"sap_delivery_no":"Or2025",' +
                    '"ShipToName":"Aniket Rick",' +
                    '"status":"New",' +
                    '"po_number":"' + poN + '",' +
                    '"so_number":"198",' +
                    '"lineItems":[{"quantity":140,"item_code":"abcd"}]}}');
        
        RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.createOrderShipment();
        Test.stopTest();
    }
     @isTest
    static void createOnlyShipmentForExistingOrderErrors4(){
         Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
         RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String poNumber = String.valueof(po.ProductRequestNumber); 
        System.debug('poNumber==>'+poNumber);
        req.requestBody = Blob.valueOf('{"shipment":{"sap_shipment_id":"SAP21Again089oyitgrfehtcdufti8gyubf7vgfur76iutygjiyf",' +
                    '"sap_delivery_no":"Test-123",' +
                    '"ShipToName":"Aniket Rick",' +
                    '"status":"New",' +
                    '"po_number":"' + poNumber + '",' +
                    '"so_number":"198",' +
                    '"lineItems":[{"quantity":140,"item_code":"abcd"}]}}');
        
        RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.createOrderShipment();
        Test.stopTest();

    }
    @IsTest
    static void createShipmentMethodError2(){
        
        Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String poNumber = String.valueof(po.ProductRequestNumber); 
        System.debug('poNumber==>'+poNumber);
        req.requestBody = Blob.valueOf('{"shipment":{"sap_shipment_id":"SAP21Againyuufguftg6rtciyfciyfjcutdifyjcutdi7yfutdiyfutdyf",' +
                    '"sap_delivery_no":"Or20259",' +
                    '"ShipToName":"Aniket Rick",' +
                    '"status":"New",' +
                    '"po_number":"' + poNumber + '",' +
                    '"so_number":"198",' +
                    '"lineItems":[{"quantity":140,"item_code":"abcd"}]}}');
        
        RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.createOrderShipment();
        Test.stopTest();
    }
     @IsTest
    static void updateShipmentMethodError5(){
        
        Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        
         Id stdPrBk = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',Price_Book__c=stdPrBk);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales',Email='test@gmail.com');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
       
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true,
            Dealer_List_Price__c=200.00    
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New',
            Destination_Location__c=testLocation.Id
        );
        insert po;
        po = [SELECT Id, ProductRequestNumber,ShipmentType,Destination_Location__c FROM ProductRequest WHERE Id = :po.Id];
        System.debug('poNumber==>' + po.ProductRequestNumber);

        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        Order newOrder = new Order();
            newOrder.AccountId = testAccount.Id;
            newOrder.Contact__c=con.Id;
            newOrder.Purchase_Order__c=po.Id;
            newOrder.Status='Draft';
            newOrder.ISVOR__c=po.ShipmentType != null && po.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=stdPrBk;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c='Test-123';
           // newOrder.OwnerId=UserInfo.getUserId();
            
           insert newOrder;
        
        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = testProduct.Id;
                        oi.PricebookEntryId = testPricebookEntry.Id;
                        oi.Quantity = 2;
                        oi.UnitPrice = testPricebookEntry.Dealer_List_Price__c != null ? testPricebookEntry.Dealer_List_Price__c : 0;
                        oi.SGST__c=testPricebookEntry.SGST_Percentage__c;
                        oi.CGST__c=testPricebookEntry.CGST_Percentage__c;
                        oi.IGST__c=testPricebookEntry.IGST_Percentage__c;
        
        insert oi;
        
       /* Shipment s = new Shipment();
            s.Order__c=newOrder.Id;
            s.Status = 'New';
            s.Purchase_Order__c=po.Id;
            s.SourceLocationId = testLocation.Id;
            s.DestinationLocationId = po.Destination_Location__c;
            s.ShipToName='Prathap Sir';
            s.sap_shipment_id__c='Ship-123';
        
        insert s;
        
        ShipmentItem sri = new ShipmentItem();
                sri.Product2Id = oi.Product2Id;
                sri.Quantity = oi.Quantity;
                sri.Parent_Shipment__c = s.Id;
                sri.Is_VOR__c = oi.Is_VOR__c;
                sri.Unit_Price__c = oi.UnitPrice;
                sri.SGST__c = oi.SGST__c;
                sri.CGST__c = oi.CGST__c;
                sri.IGST__c = oi.IGST__c;
                sri.Related_Order_Line_Item__c=oi.Id ; 
                sri.ShipmentId=s.Id;
        insert sri;*/
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
         req.requestBody = Blob.valueOf('{' +
            '"sap_shipment_id":"Ship-1234876345678908iuygfyu8976rer5678uhgfdr567uhgty7ujhgty67uhgfrtyhvftyhgftyujhgftyujhgyuj",' +
            '"status":"Dispatched",' +
            '"LR_Date":"06/07/2025",' +
            '"LR_no":"69695342",' +
            '"driver_name":"River",' +
            '"driver_phone":"1234543212",' +
            '"e_way_bill_no":"07863276",' +
            '"invoice_date":"10/07/2025",' +
            '"invoice_no":"87686",' +
            '"invoice_amount":5000' +
        '}');
        
         RestContext.request = req;
        RestContext.response = res;

        
        Test.startTest();
        OrderAndShipmentController.updateOrderShipment();
        Test.stopTest();
        
    }
    

}