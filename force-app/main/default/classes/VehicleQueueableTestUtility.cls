public class VehicleQueueableTestUtility {
    public static Account createAccount(){
        Account testAccount = new Account(Name = 'Test Account',Type='Customer',Phone='0987654321',Center_Code__c='292001',Email__c='test@eaxmple.com');
        insert testAccount;
        return testAccount;
    }
    public static Schema.Location createLocation(){
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka');
        insert testLocation;
        return testLocation;
    }
   
    public static Contact createContact(Id acccountId,Id locationId){
        Contact con = new Contact(LastName ='Dinesh',Phone = '7834878789',AccountId = acccountId,Location__c=locationId,Role_Type__c='Sales');
        insert con;
        return con;
    }    
    public static Product2 createProduct(){
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true,ProductCode='RV-EW-1',HSN_Code__c='abcd',Type__c='Vehicle',Colour__c='Black');
        insert testProduct;
        return testProduct;
    }
    public static PricebookEntry createPricebookEntry(Id stdPrBk,Id productId){
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = productId,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,	
            IsActive = true
        );
        insert testPricebookEntry;
        return testPricebookEntry;
    }
    public static Asset createAsset(Id accountId,Id productId){
        Asset testAsset = new Asset(Name='Test Asset',AccountId=accountId,Product2Id=productId);
        insert testAsset;
        return testAsset;
        
    }
    public static VehicleDefinition createVehicleDef(Id productId){
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition',ProductId=productId);
        insert testVD;
        return testVD;
    }
    public static Software_Version__c createSoftwareVersion(){
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version');
        insert testSV;
        return testSV;

    }
    public static Vehicle createVehicle(Id accId,Id assetId,Id vdId,Id softVer){
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle', Account__c=accId, AssetId=assetId,  VehicleDefinitionId=vdId, VehicleIdentificationNumber='A2B3',  Software_Version__c=softVer, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true,Purchased_Date__c = System.Today(),ChassisNumber='5342',Vehicle_Details__c='B123',EngineNumber='E321',CurrentOwnerId=accId);
        insert testVehicle;        
        return testVehicle;
    }
    public static AssetMilestone createAssetMileStone(Id assetId,Id vehicleId){
        AssetMilestone asm = new AssetMilestone(Name = 'ASM1', MilestoneDate = Date.today().addMonths(2),  Stage = 'Active', AssetId = assetId, UsageType = 'Automotive', MilestoneType = 'PDI', VehicleId = vehicleId);
        insert asm;
        return asm;
    }
    public static Order createOrder(Id accId,Id vehicleId, Id pricebookId, Id conId){
        Order oldOrder = new Order( AccountId = accId, Status__c = 'Processing',Status='Processing',Assigned_Vehicle__c = vehicleId,EffectiveDate = Date.today(),Pricebook2Id = pricebookId,Payment_Status__c = 'Completed', Contact__c = conId,Booking_Form_File_URL__c='test.pdf',Website_Order_Id__c='TestABC!@#',Allotment_In_Process_File_URL__c='testInvoice.pdf');
        insert oldOrder;
        return oldOrder;
    }
    public static OrderItem createOrderItem(Id orderId, Id productId,Id pricebookEntryId){
        OrderItem testOrderItem = new OrderItem( OrderId = orderId, Product2Id = productId, UnitPrice = 100.0, Quantity = 1, PricebookEntryId = pricebookEntryId,Type__c='Vehicle');
        insert testOrderItem;
        return testOrderItem;
    }
    public static Order_Invoice__c createInvoice(Id orderId){
        Order_Invoice__c o = new Order_Invoice__c (Invoice_Type__c='Vehicle Invoice',Order__c=orderId,Name='test',Invoice_Number__c='ab1cd2');
        insert o;
        return o;
    }
    
    

}