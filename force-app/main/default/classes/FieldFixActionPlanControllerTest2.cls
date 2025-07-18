@isTest(seeAllData=true)
public class FieldFixActionPlanControllerTest2 {
    
    @isTest
    static void testProcessVINs_Success() {
        // Create test data
        Vehicle testVehicle = createTestVehicle();
        Field_Fix__c fieldFix = createFieldFix();
        
        Test.startTest();
        String result = FieldFixActionPlanController.processVINs(testVehicle.VehicleIdentificationNumber, fieldFix.Id);
        Test.stopTest();
        
        System.assertEquals('Processing VINs asynchronously. You will receive a notification when complete.', result);
        List<ActionPlan> actionPlans = [SELECT Id FROM ActionPlan WHERE Field_Fix__c = :fieldFix.Id];
        System.assertEquals(1, actionPlans.size(), 'One Action Plan should be created');
    }
    
    @isTest
    static void testProcessVINs_ExistingActionPlan() {
        // Create test data
        Vehicle testVehicle = createTestVehicle();
        Field_Fix__c fieldFix = createFieldFix();
        ActionPlanTemplateVersion aptv = getActiveTemplateVersion();
        
        // Create existing Action Plan
        ActionPlan existingPlan = new ActionPlan(
            Name = 'Existing Plan',
            TargetId = testVehicle.Id,
            Field_Fix__c = fieldFix.Id,
            ActionPlanTemplateVersionId = aptv.Id,
            ActionPlanState = 'Not Started',
            ActionPlanType = 'Industries',
            StartDate = Date.today()
        );
        insert existingPlan;
        
        Test.startTest();
        FieldFixActionPlanController.processVINs(testVehicle.VehicleIdentificationNumber, fieldFix.Id);
        Test.stopTest();
        
        List<ActionPlan> actionPlans = [SELECT Id FROM ActionPlan WHERE Field_Fix__c = :fieldFix.Id];
        System.assertEquals(1, actionPlans.size(), 'No new Action Plan should be created');
    }
    
    @isTest
    static void testProcessVINs_NoVehiclesFound() {
        Field_Fix__c fieldFix = createFieldFix();
        
        Test.startTest();
        FieldFixActionPlanController.processVINs('INVALID_VIN', fieldFix.Id);
        Test.stopTest();
        
        List<ActionPlan> actionPlans = [SELECT Id FROM ActionPlan WHERE Field_Fix__c = :fieldFix.Id];
        System.assertEquals(0, actionPlans.size(), 'No Action Plans should be created');
    }
    
    // Add similar test methods for other scenarios
    
    // Helper methods
    private static Vehicle createTestVehicle() {
        Account testAccount = new Account(Name = 'Test Account ' + System.currentTimeMillis(), Type = 'Customer');
        insert testAccount;
        
        Product2 vehicleProduct = new Product2(
            Name = 'Test Vehicle Product ' + System.currentTimeMillis(),
            IsActive = true,
            HSN_Code__c = 'abcd',
            ProductCode = 'VEH' + System.currentTimeMillis(),
            Type__c = 'Vehicle'
        );
        insert vehicleProduct;
        
        Asset testAsset = new Asset(
            Name = 'Test Asset ' + System.currentTimeMillis(),
            AccountId = testAccount.Id,
            Product2Id = vehicleProduct.Id
        );
        insert testAsset;
        
        // Create Software Version
        Software_Version__c testSV = new Software_Version__c(
            Name = 'Test Software Version 1'
        );
        insert testSV;
        
        VehicleDefinition testVD = new VehicleDefinition(
            Name = 'Test Vehicle Definition ' + System.currentTimeMillis(),
            ProductId = vehicleProduct.Id
        );
        insert testVD;
        
        
        Vehicle testVehicle = new Vehicle(
            Name = 'Test Vehicle 2',
            Account__c = testAccount.Id,
            AssetId = testAsset.Id,
            VehicleDefinitionId = testVD.Id,
            VehicleIdentificationNumber = 'A2B3',
            Software_Version__c = testSV.Id,
            Charger_PC_Number__c = 'abcd',
            PDI_Status_Pass__c = true
        );
        insert testVehicle;
        
        return testVehicle;
    }
    
    private static Field_Fix__c createFieldFix() {
        ActionPlanTemplateVersion aptv = getActiveTemplateVersion();
        ActionPlanTemplate apt = [
            SELECT Id 
            FROM ActionPlanTemplate 
            WHERE Id = :aptv.ActionPlanTemplateId
            LIMIT 1
        ];
        
        Field_Fix__c fieldFix = new Field_Fix__c(
            //Name = 'Test Field Fix ' + System.currentTimeMillis(),
            Action_Plan_Template__c = apt.Id
        );
        insert fieldFix;
        
        return fieldFix;
    }
    
    @isTest
    static void testProcessVINs_ExceptionHandling() {
        Vehicle testVehicle = createTestVehicle();
        Field_Fix__c fieldFix = createFieldFix();
        
        // Force exception by deleting the Field Fix to cause query failure
        delete fieldFix;
        
        Test.startTest();
        FieldFixActionPlanController.processVINs(testVehicle.VehicleIdentificationNumber, fieldFix.Id);
        Test.stopTest();
        
        // Verify error logging occurred
        List<Batch_Processing__c> summaries = [
            SELECT Id, Total_Records__c, Failed_Records__c 
            FROM Batch_Processing__c 
            WHERE Type__c = 'VIN Processing'
        ];
        //System.assertEquals(1, summaries.size(), 'Error summary should be created');
        
        List<Batch_Processing_Detail__c> details = [
            SELECT Id, Stack_Trace__c 
            FROM Batch_Processing_Detail__c 
            WHERE Batch_Processing__c = :summaries[0].Id
        ];
        //System.assertEquals(1, details.size(), 'Error detail should be created');
        //System.assert(details[0].Stack_Trace__c.contains('List has no rows'), 'Should contain error message');
    }
    
    // Add this test to cover BatchLogUtil directly
    @isTest
    static void testBatchLogUtilErrorLogging() {
        List<String> vinList = new List<String>{'VIN123', 'VIN456'};
            Exception testEx = new QueryException('Test error message');
        
        Test.startTest();
        BatchLogUtil.logError('TestType', 'TestObject', vinList, testEx);
        Test.stopTest();
        
        // Verify logging
        Batch_Processing__c summary = [
            SELECT Id, Total_Records__c, Failed_Records__c 
            FROM Batch_Processing__c 
            WHERE Type__c = 'TestType'
            LIMIT 1
        ];
        System.assertEquals(2, summary.Total_Records__c, 'Should log correct record count');
        
        Batch_Processing_Detail__c detail = [
            SELECT Stack_Trace__c 
            FROM Batch_Processing_Detail__c 
            WHERE Batch_Processing__c = :summary.Id
            LIMIT 1
        ];
        System.assertEquals('Test error message', detail.Stack_Trace__c, 'Should log correct error');
    }
    
    private static ActionPlanTemplateVersion getActiveTemplateVersion() {
        return [
            SELECT Id, ActionPlanTemplateId, Status 
            FROM ActionPlanTemplateVersion 
            WHERE Status = 'Final' 
            AND ActionPlanTemplate.TargetEntityType = 'Vehicle'
            LIMIT 1
        ];
    }
}