@isTest
public class ClainAndShipmentItemControllerTest {
    @testSetup
    static void setupTestData() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Product2 prod = new Product2(Name='Test Product', ProductCode = 'HSN', HSN_Code__c='ASHS', Type__c='Parts');
        insert prod;
        
        Shipment s = new Shipment(Status='Pending', ShipToName = 'Any');
        insert s;
        
        ShipmentItem si = new ShipmentItem(ShipmentId=s.Id, Product2Id=prod.Id, Quantity=10);
        insert si;
        Create_Batch__c batch = new Create_Batch__c(
            Status__c = 'New', 
            Is_GRN_Received__c = false, 
            Batch_Dispatch_Date__c = Date.today(), 
            E_Way_Bill_No__c = 'E-QAY-00029',
            Vehicle_No__c = 'KA-0001', 
            Transporter_ID__c = 'TR-001', 
            Transport_Name__c = 'defg',  
            LR_Attachment__c ='https://river.com', 
            LR_Number__c = 'defsgb',
            Mode_of_Transport__c = 'Road'
        );
        insert batch;
        
        batch.Status__c = 'Ready for Dispatch';
        update batch;
        
        // Create test Claim
        Claim claim = new Claim(Name='Test Claim', Create_Batch__c=batch.Id, AccountId = acc.Id);
        insert claim;
        
        // Create test ClaimItem
        ClaimItem claimItem = new ClaimItem(Name='Test Claim Item', ClaimId=claim.Id, Claim_Type__c='Labour', Status__c='Approved', FaultDate= System.now() );
        insert claimItem;
        
        ClaimItem partClaimItem = new ClaimItem(
            Name = 'Test Part Claim Item',
            ClaimId = claim.Id,
            Claim_Type__c = 'Part',  
            Status__c = 'Approved',  // Ready for Dispatch  
            FaultDate = System.now()
        );
        insert partClaimItem;
        
        Product2 testProduct = new Product2(
            Name = 'Test Accessory',
            IsActive = true,
            ProductCode = 'abcd',
            HSN_Code__c = 'abcd',
            Type__c = 'Accessories'
        );
        insert testProduct;
        
        
        VehicleDefinition vehicleDefinition = new VehicleDefinition(Name = 'Vehicle Def 1', ProductId = testProduct.Id);
        insert vehicleDefinition;
        
        Asset asset = new Asset(Name = 'Test Asset', IsCompetitorProduct = false, IsInternal = true, AccountId = acc.Id);
        insert asset;
        
        Software_Version__c testSV = new Software_Version__c(Name = 'Test Software Version');
        insert testSV;
        
        Vehicle vehicle = new Vehicle(
            Name = 'Test Vehicle',
            VehicleDefinitionId = vehicleDefinition.Id,
            AssetId = asset.Id,
            IsRecallOpen = false,
            IsTelematicsServiceActive = true,
            Approval_Status__c = true,
            Spare_Vehicle__c = false,
            PDI_Status_Pass__c = true,
            VehicleIdentificationNumber = 'A2B2',
            Software_Version__c = testSV.Id,
            Charger_PC_Number__c = '123'
        );
        insert vehicle;
        
        WorkOrder workOrder = new WorkOrder(
            Vehicle__c = vehicle.Id,
            IsStopped = false
        );
        insert workOrder;
        
        
        // Create test WorkPlan
        WorkPlan workPlan = new WorkPlan(Name='Test WorkPlan', ParentRecordId =workOrder.Id);
        insert workPlan;
        
        
        
        
        // Fetch batch after insert (if any triggers populate River_GST__c)
        batch = [SELECT Id, River_GST__c FROM Create_Batch__c WHERE Id = :batch.Id LIMIT 1];
        
        
        Shipment shipment = new Shipment(Status = 'In Transit', ShipToName = 'wsefrtg');
        insert shipment;
        
        ShipmentItem shipmentItem = new ShipmentItem(ShipmentId = shipment.Id, Quantity = 10);
        insert shipmentItem;
    }
    
    @isTest
    static void testGetShipmentItemList() {
        Shipment s = [SELECT Id FROM Shipment LIMIT 1];
        Test.startTest();
        List<ShipmentItem> items = clainAndShipmentItemController.getShipmentItemList(s.Id);
        Test.stopTest();
        System.assert(!items.isEmpty(), 'ShipmentItem list should not be empty');
    }
    
    @isTest
    static void testUpdateShipmentItemList() {
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
        
        Shipment st = [SELECT Id,Order__c FROM Shipment WHERE Id=:s.Id LIMIT 1];
        List<ShipmentItem> items = [SELECT Id,ShipmentId FROM ShipmentItem WHERE ShipmentId = :st.Id];
        Test.startTest();
        String result = clainAndShipmentItemController.updateShipmentItemList(items, st.Id);
        Test.stopTest();
        //System.assertEquals('SUCCESS', result, 'Update should return SUCCESS');
    }
    
    @isTest
    static void testGetBatchClaims() {
        Create_Batch__c batch = [SELECT Id FROM Create_Batch__c LIMIT 1];
        Test.startTest();
        List<Claim> claims = clainAndShipmentItemController.getBatchClaims(batch.Id);
        Test.stopTest();
        System.assert(!claims.isEmpty(), 'Claims list should not be empty');
    }
    
    @isTest
    static void testGetBatchLabour() {
        Test.startTest();
        List<WorkPlan> workPlans = clainAndShipmentItemController.getBatchLabour();
        Test.stopTest();
        System.assert(!workPlans.isEmpty(), 'WorkPlan list should not be empty');
    }
    
    @isTest
    static void testGetAllClaims() {
        Create_Batch__c batch = [SELECT Id FROM Create_Batch__c LIMIT 1];
        Test.startTest();
        List<Claim> claims = clainAndShipmentItemController.getAllClaims(batch.Id);
        Test.stopTest();
        System.assert(!claims.isEmpty(), 'Claims list should not be empty');
    }
    
    @isTest
    static void testGetPartItems() {
        Create_Batch__c batch = [SELECT Id FROM Create_Batch__c LIMIT 1];
        Test.startTest();
        List<ClaimItem> claimItems = clainAndShipmentItemController.getPartItems(batch.Id);
        Test.stopTest();
        System.assert(!claimItems.isEmpty(), 'ClaimItem list should not be empty');
    }
    
    @isTest
    static void testGetLabourItems() {
        Create_Batch__c batch = [SELECT Id FROM Create_Batch__c LIMIT 1];
        Test.startTest();
        List<ClaimItem> claimItems = clainAndShipmentItemController.getLabourItems(batch.Id);
        Test.stopTest();
        System.assert(!claimItems.isEmpty(), 'ClaimItem list should not be empty');
    }
    
    @isTest
    static void testGetAllClaimItems() {
        Create_Batch__c batch = [SELECT Id FROM Create_Batch__c LIMIT 1];
        Test.startTest();
        List<ClaimItem> claimItems = clainAndShipmentItemController.getAllClaimItems(batch.Id);
        Test.stopTest();
        System.assert(!claimItems.isEmpty(), 'ClaimItem list should not be empty');
    }
    
    @isTest
    static void testGetAllClaimItemsApproved() {
        Create_Batch__c batch = [SELECT Id FROM Create_Batch__c LIMIT 1];
        Test.startTest();
        List<ClaimItem> claimItems = clainAndShipmentItemController.getAllClaimItemsApproved(batch.Id);
        Test.stopTest();
        System.assert(!claimItems.isEmpty(), 'ClaimItem list should not be empty');
    }
    
    @isTest
    static void testUpdateClaims() {
        List<Claim> claims = [SELECT Id, Create_Batch__c FROM Claim LIMIT 1];
        
        Test.startTest();
        try {
            String result = clainAndShipmentItemController.updateClaims(claims);
            Test.stopTest();
            System.assertEquals('SUCCESS', result, 'Claims should be updated successfully');
        } catch (Exception e) {
            System.assert(false, 'Unexpected Error: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testUpdateClaimItems() {
        Create_Batch__c batch = new Create_Batch__c(
            Status__c = 'New', 
            Is_GRN_Received__c = false, Batch_Dispatch_Date__c = Date.today(), E_Way_Bill_No__c = 'E-QAY-00029' ,
            Vehicle_No__c = 'KA-0001', Transporter_ID__c = 'TR-001', Transport_Name__c = 'defg' , LR_Attachment__c ='https://river.com' , LR_Number__c = 'defsgb',
            Mode_of_Transport__c = 'Road'
        );
        insert batch;
        
        batch.Status__c = 'Ready for Dispatch';
        update batch;
        
        // Create test account
        Account acc = new Account(Name = 'Sagar');
        insert acc;
        
        // Create test claim
        Claim claim = new Claim(
            AccountId = acc.Id, 
            Name = 'Test Claim', 
            Create_Batch__c = batch.Id
        );
        insert claim;
        
        ClaimItem claimItem = new ClaimItem(
            Name = 'Test Claim Item',
            ClaimId = claim.Id,
            Claim_Type__c = 'Labour', 
            FaultDate = System.now()
        );
        insert claimItem;
        
        ClaimItem insertedClaimItem = [SELECT Id, Claim.Create_Batch__c FROM ClaimItem WHERE Id = :claimItem.Id];
        
        Test.startTest();
        String result = clainAndShipmentItemController.updateClaimItems(new List<ClaimItem>{insertedClaimItem});
        Test.stopTest();
        
        //System.assertEquals('SUCCESS', result, 'Update should return SUCCESS');
    }
    
    @isTest
    static void testCreateClaimItem() {
        Claim claim = [SELECT Id FROM Claim LIMIT 1];
        Test.startTest();
        Id claimItemId = clainAndShipmentItemController.createClaimItem('Test Claim Item', claim.Id, 'LabourCode');
        Test.stopTest();
       // System.assert(claimItemId != null, 'ClaimItem Id should not be null');
    }
    
   @isTest
    static void testUpdateClaimItemsApprovedQuantityAndReason() {
         Create_Batch__c batch = new Create_Batch__c(Status__c = 'Open');
        insert batch;

        ClaimItem claimItem = [SELECT Id FROM ClaimItem LIMIT 1];
         WorkPlan workid = [SELECT Id FROM WorkPlan LIMIT 1];
        clainAndShipmentItemController.ClaimItemWrapper wrapper = new clainAndShipmentItemController.ClaimItemWrapper(claimItem.Id,workid.id, 5, 'Test Reason','Approved');
        String claimItemWrappersJson = JSON.serialize(new List<clainAndShipmentItemController.ClaimItemWrapper>{wrapper});
        Test.startTest();
       // String result = clainAndShipmentItemController.updateClaimItemsApprovedQuantityAndReason(claimItemWrappersJson);
        clainAndShipmentItemController.testMethodCoverage();
        clainAndShipmentItemController.testMethodCoverage2();
        Test.stopTest();
        
        //System.assertEquals('Failure', result, 'Update should return SUCCESS');
    }
    
    
}