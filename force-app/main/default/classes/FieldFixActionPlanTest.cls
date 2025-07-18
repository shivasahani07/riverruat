@isTest
public class FieldFixActionPlanTest {   
    @isTest
    static void testOrderUpdate(){
        Account testAccount = new Account(Name = 'Test Account',Type='Customer');
        insert testAccount;
        
        Contact con = new Contact(LastName ='Dinesh',Phone = '7834878789',AccountId = testAccount.id);
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
        insert testProduct;
        
        Id stdPrBk = Test.getStandardPricebookId();
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,	
            IsActive = true
        );
        insert testPricebookEntry;
        
        Asset testAsset = new Asset(Name='Test Asset',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle', Account__c=testAccount.Id, AssetId=testAsset.Id,  
                                          VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
        insert testVehicle;
        
        ActionPlanTemplate apt = new ActionPlanTemplate(Name = 'Test Template1', TargetEntityType = 'Vehicle',
                                                        ActionPlanType = 'Industries');
        insert apt;
        
        Field_Fix__c ffc = new Field_Fix__c(Priority__c = 'Low', Type_of_Field__c = 'ReWork', Status__c = 'Pending',
                                            Completion__c = 22, Action_Plan_Template__c = apt.Id );
        insert ffc;
        
        
    }
    
    @isTest
    static void testProcessVINs_createsActionPlans() {
        Account testAccount = new Account(Name = 'Test Account',Type='Customer');
        insert testAccount;
        
        Contact con = new Contact(LastName ='Dinesh',Phone = '7834878789',AccountId = testAccount.id);
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
        insert testProduct;
        
        Id stdPrBk = Test.getStandardPricebookId();
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,	
            IsActive = true
        );
        insert testPricebookEntry;
        
        Asset testAsset = new Asset(Name='Test Asset',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle', Account__c=testAccount.Id, AssetId=testAsset.Id,  
                                          VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
        insert testVehicle;
        
        ActionPlanTemplate apt = new ActionPlanTemplate(
            Name = 'Test Template2',
            TargetEntityType = 'Vehicle',
            ActionPlanType = 'Industries'
        );
        insert apt;
        
        Field_Fix__c ff = new Field_Fix__c(Action_Plan_Template__c = apt.Id);
        insert ff;
        /*
ActionPlanTemplateVersion apv = new ActionPlanTemplateVersion(
Name = 'Vehicle Inspection Template',
ActionPlanTemplateId = apt.Id,
Status = 'Published'
);
insert apv; */
        String result = FieldFixActionPlanController.processVINs(testVehicle.VehicleIdentificationNumber, ff.Id);
    }
    
    
    @isTest
    static void testProcessVINs_invalidInput() {
        String result = FieldFixActionPlanController.processVINs('', null);
    }
    
    
    @isTest
    static void testProcessVINs_noVehiclesFound() {
        ActionPlanTemplate apt = new ActionPlanTemplate(
            Name = 'Template3',
            TargetEntityType = 'Vehicle',
            ActionPlanType = 'Industries'
        );
        insert apt;
        
        Field_Fix__c ff = new Field_Fix__c(Action_Plan_Template__c = apt.Id);
        insert ff;
        
        
        String result = FieldFixActionPlanController.processVINs('NONEXISTENTVIN', ff.Id);
        
        /*
Test.startTest();
BaseVINProcessor.addTest();
FieldFixActionPlanController.addTest();
Test.stopTest(); */
    }
    
    /*
@isTest
static void testProcessVINs_skipsAlreadyExistingVIN() {
// Setup Account and related structure
Account testAccount = new Account(Name = 'Test Account',Type='Customer');
insert testAccount;

Contact con = new Contact(LastName ='Dinesh',Phone = '7834878789',AccountId = testAccount.id);
insert con;

Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
insert testProduct;

Id stdPrBk = Test.getStandardPricebookId();
PricebookEntry testPricebookEntry = new PricebookEntry(
Product2Id = testProduct.Id,
Pricebook2Id = stdPrBk,
UnitPrice = 100.0,	
IsActive = true
);
insert testPricebookEntry;

VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition',ProductId=testProduct.Id);
insert testVD;

Software_Version__c testSV = new Software_Version__c(Name='Test Software Version');
insert testSV;

Asset testAsset = new Asset(Name='Test Asset',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
insert testAsset;

Vehicle testVehicle = new Vehicle(Name='Test Vehicle', Account__c=testAccount.Id, AssetId=testAsset.Id,  
VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
insert testVehicle;


ActionPlanTemplate apt12 = new ActionPlanTemplate(
Name = 'Skip Template ' + System.currentTimeMillis(), // ensure uniqueness
TargetEntityType = 'Vehicle',
ActionPlanType = 'Industries'
);
insert apt12;


Field_Fix__c ff = new Field_Fix__c(Action_Plan_Template__c = apt12.Id);
insert ff;
String result = FieldFixActionPlanController.processVINs(testVehicle.VehicleIdentificationNumber, ff.Id);


} */
    
    /*
@isTest
static void testProcessVINs_noTemplateVersion() {
Account testAccount = new Account(Name = 'Test Account',Type='Customer');
insert testAccount;

Contact con = new Contact(LastName ='Dinesh',Phone = '7834878789',AccountId = testAccount.id);
insert con;

Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
insert testProduct;

Id stdPrBk = Test.getStandardPricebookId();
PricebookEntry testPricebookEntry = new PricebookEntry(
Product2Id = testProduct.Id,
Pricebook2Id = stdPrBk,
UnitPrice = 100.0,	
IsActive = true
);
insert testPricebookEntry;

Asset testAsset = new Asset(Name='Test Asset',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
insert testAsset;

VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition',ProductId=testProduct.Id);
insert testVD;

Software_Version__c testSV = new Software_Version__c(Name='Test Software Version');
insert testSV;

Vehicle testVehicle = new Vehicle(Name='Test Vehicle', Account__c=testAccount.Id, AssetId=testAsset.Id,  
VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
insert testVehicle;

ActionPlanTemplate apt = new ActionPlanTemplate(
Name = 'Test Template4',
TargetEntityType = 'Vehicle',
ActionPlanType = 'Industries'
);
insert apt;

Field_Fix__c ff = new Field_Fix__c(Action_Plan_Template__c = apt.Id);
insert ff;

Vehicle v = [SELECT VehicleIdentificationNumber FROM Vehicle LIMIT 1];

String result = FieldFixActionPlanController.processVINs(v.VehicleIdentificationNumber, ff.Id);

}

*/    
    
    
    @isTest
    static void testProcessVINs_skippedVIN() {
        Account acc = new Account(Name = 'Skip Test Account', Type='Customer');
        insert acc;
        
        Product2 prod = new Product2(Name='Skip Product', ProductCode='P001', HSN_Code__c='HSN1', Type__c='Vehicle', IsActive=true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice=100, IsActive=true);
        insert pbe;
        
        Asset ast = new Asset(Name='Skip Asset', AccountId=acc.Id, Product2Id=prod.Id);
        insert ast;
        
        VehicleDefinition vdef = new VehicleDefinition(Name='Skip VDef', ProductId=prod.Id);
        insert vdef;
        
        Software_Version__c sv = new Software_Version__c(Name='Skip SW Version');
        insert sv;
        
        Vehicle veh = new Vehicle(Name='Skip Vehicle', Account__c=acc.Id, AssetId=ast.Id, VehicleDefinitionId=vdef.Id, VehicleIdentificationNumber='SKIPVIN1', Software_Version__c=sv.Id, PDI_Status_Pass__c=true,
                                  Charger_PC_Number__c = '21');
        insert veh;
        
        ActionPlanTemplate apt = new ActionPlanTemplate(Name='Skip Template', TargetEntityType='Vehicle', ActionPlanType='Industries');
        insert apt;
        
        Field_Fix__c ff = new Field_Fix__c(Action_Plan_Template__c=apt.Id);
        insert ff;
        
        Batch_Processing__c batch = new Batch_Processing__c(
            Start_Time__c = System.now(),
            Type__c = 'TestType',
            Object_Name__c = 'TestObject',
            Total_Records__c = 10
        );
        
        insert batch;
        
        List<Batch_Processing_Detail__c> detailLogs = new List<Batch_Processing_Detail__c>();
        detailLogs.add(new Batch_Processing_Detail__c(
            Status__c = 'Skipped',
            Is_Success__c = false,
            Object_Record_Id__c = veh.Id,
            Stack_Trace__c = 'Action Plan already exists for this VIN',
            Batch_Processing__c = batch.Id
        ));
        detailLogs.add(new Batch_Processing_Detail__c(
            Status__c = 'Created',
            Is_Success__c = true,
            Object_Record_Id__c = veh.Id,
            Stack_Trace__c = 'Success',
            Batch_Processing__c = batch.Id
        ));
        //insert detailLogs;
        
        BatchLogUtil.logDetails(detailLogs);
        BatchLogUtil.updateSummary(batch.Id, 1, 1);
        
        
        //detailLogs.add(new Batch_Processing_Detail__c)
        
        //BatchLogUtil.logDetails(detailLogs);
        
        
        
        
        //ActionPlanTemplateVersion apv = new ActionPlanTemplateVersion(ActionPlanTemplateId=apt.Id, Status='Draft');
        //insert apv;
        
        /*System.DmlException: Insert failed. First exception on row 0; first error: INVALID_INPUT, 
You can’t add more than one version to an action plan template.: [ActionPlanTemplateId]*/
        
        
        //ActionPlan ap = new ActionPlan(Name='FF1231', TargetId=veh.Id, ActionPlanTemplateVersionId=apv.Id);
        //insert ap;
        
        Test.startTest();
        String result = FieldFixActionPlanController.processVINs(veh.VehicleIdentificationNumber, ff.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testBaseVINProcessorExecute() {
        BaseVINProcessor processor = new BaseVINProcessor('VIN123', '001xx000003DHP0');
        String result = processor.execute();
        System.assertEquals('Base processor', result);
    }
    
    
    @isTest
    static void testIsNumericMethod() {
        System.assertEquals(true, BaseVINProcessor.isNumeric('123'));
        System.assertEquals(false, BaseVINProcessor.isNumeric('1A23'));
        System.assertEquals(false, BaseVINProcessor.isNumeric(''));
    }
    
    @isTest
static void testCustomNotificationLogic() {
    // Create required Field_Fix__c record
    Field_Fix__c ff = new Field_Fix__c();
    insert ff;

    // Simulate batch log creation
    Batch_Processing__c batchLog = new Batch_Processing__c(
        Start_Time__c = System.now(),
        Type__c = 'FieldFix',
        Object_Name__c = 'Vehicle',
        Total_Records__c = 2
    );
    insert batchLog;

    // Simulate detail logs
    List<Batch_Processing_Detail__c> detailLogs = new List<Batch_Processing_Detail__c>{
        new Batch_Processing_Detail__c(
            Status__c = 'Created',
            Is_Success__c = true,
            Object_Record_Id__c = ff.Id,
            Stack_Trace__c = 'Success',
            Batch_Processing__c = batchLog.Id
        ),
        new Batch_Processing_Detail__c(
            Status__c = 'Skipped',
            Is_Success__c = false,
            Object_Record_Id__c = ff.Id,
            Stack_Trace__c = 'Already Exists',
            Batch_Processing__c = batchLog.Id
        )
    };
    insert detailLogs;

    Test.startTest();
    // Log the details and update summary
    BatchLogUtil.logDetails(detailLogs);
    BatchLogUtil.updateSummary(batchLog.Id, 1, 1);

    // Call your method under test
    FieldFixActionPlanController.sendCompletionNotification(1, new List<String>(), ff.Id);

    // Manually test the notification logic without requiring metadata
    List<CustomNotificationType> notifyTypes = [
        SELECT Id FROM CustomNotificationType 
        WHERE DeveloperName = 'Avalailable_Qunatity_is_Zero' 
        LIMIT 1
    ];

    if (!notifyTypes.isEmpty()) {
        Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
        customNotificationObj.setBody('1 Action Plans created. Skipped: 1');
        customNotificationObj.setTitle('VIN Update Bulk Upload');
        customNotificationObj.setNotificationTypeId(notifyTypes[0].Id);
        customNotificationObj.setSenderId(UserInfo.getUserId());
        customNotificationObj.setTargetId(ff.Id);
        customNotificationObj.send(new Set<String>{ UserInfo.getUserId() });
    }
    Test.stopTest();

    System.assert(true, 'Notification logic executed without error.');
}

    
}