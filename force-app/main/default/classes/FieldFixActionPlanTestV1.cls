@isTest(seeAllData = true)
public class FieldFixActionPlanTestV1 {
    @isTest
    static void testAllFieldFixActionPlanScenarios() {
        Account testAccount = new Account(Name = 'Test Account', Type = 'Customer');
        insert testAccount;
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true, ProductCode = 'abcd', HSN_Code__c = 'abcd', Type__c = 'Vehicle');
        insert testProduct;
        
        Asset testAsset = new Asset(Name = 'Test Asset', AccountId = testAccount.Id, Product2Id = testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name = 'Test VehicleDefinition', ProductId = testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name = 'Test Software Version');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(
            Name = 'Test Vehicle',
            Account__c = testAccount.Id,
            AssetId = testAsset.Id,
            VehicleDefinitionId = testVD.Id,
            VehicleIdentificationNumber = 'A2B3',
            Software_Version__c = testSV.Id,
            Charger_PC_Number__c = 'abcd',
            PDI_Status_Pass__c = true
        );
        insert testVehicle;
        
        //ActionPlan
        
        // ActionPlanTemplate apt = new ActionPlanTemplate(Name = 'Test Template', TargetEntityType = 'Vehicle', ActionPlanType = 'Industries');
        //insert apt;
        
        //ActionPlanTemplateVersion  = new ActionPlanTemplateVersion(Name ='New Action Plan Version',ActionPlanTemplateId =apt.Id, Version= 1,Status='Final',ActivationDateTime=System.today());
        //insert aptVersion;
        
        
        ActionPlanTemplateVersion aptVersion = [SELECT Id, ActionPlanTemplateId, Status FROM ActionPlanTemplateVersion where  ActionPlanTemplate.TargetEntityType='Vehicle' LIMIT 1];
        aptVersion.Status = 'Final';
        update aptVersion;
        
        ActionPlanTemplate apt = [SELECT Id,ActionPlanType FROM ActionPlanTemplate WHERE Id = :aptVersion.ActionPlanTemplateId AND TargetEntityType ='Vehicle'];
        
        Field_Fix__c ff = new Field_Fix__c(
            Action_Plan_Template__c = apt.Id
        );
        insert ff;
        
        ActionPlan newAP = new ActionPlan(
            Name = 'Test Action Plan',
            ActionPlanTemplateVersionId = aptVersion.Id,
            TargetId = testVehicle.Id,
            StartDate = System.today().addDays(-1),
            To_be_Completed_in_JC__c = false,
            ActionPlanType =apt.ActionPlanType
        );
        insert newAP;
        
        //Field_Fix__c ff = new Field_Fix__c(Action_Plan_Template__c = apt.Id); 
        //insert ff;
        
        Test.startTest();
        String result1 = FieldFixActionPlanController.processVINs(testVehicle.VehicleIdentificationNumber, ff.Id);
        Test.stopTest();
        
        Batch_Processing__c batch = new Batch_Processing__c(Start_Time__c = System.now(), Type__c = 'TestType', Object_Name__c = 'TestObject', Total_Records__c = 10);
        insert batch;
        
        List<Batch_Processing_Detail__c> detailLogs = new List<Batch_Processing_Detail__c>{
            new Batch_Processing_Detail__c(Status__c = 'Skipped', Is_Success__c = false, Object_Record_Id__c = testVehicle.Id, Stack_Trace__c = 'Action Plan already exists for this VIN', Batch_Processing__c = batch.Id),
                new Batch_Processing_Detail__c(Status__c = 'Created', Is_Success__c = true, Object_Record_Id__c = testVehicle.Id, Stack_Trace__c = 'Success', Batch_Processing__c = batch.Id),
                new Batch_Processing_Detail__c(Status__c = 'Fail', Is_Success__c = true, Object_Record_Id__c = testVehicle.Id, Stack_Trace__c = 'Error', Batch_Processing__c = batch.Id)
                };
                    insert detailLogs;
        
        String result2 = FieldFixActionPlanController.processVINs(testVehicle.VehicleIdentificationNumber, ff.Id);
        String result3 = FieldFixActionPlanController.processVINs('', null);
        String result4 = FieldFixActionPlanController.processVINs('NONEXISTENTVIN', ff.Id);
        BaseVINProcessor processor = new BaseVINProcessor('VIN123', '001xx000003DHP0');
        String baseResult = processor.execute();
        FieldFixActionPlanController.processVINs(testVehicle.VehicleIdentificationNumber, ff.Id);
        FieldFixActionPlanController.sendCompletionNotification(20,new List<String>{'ABCD','ABCD','ABCD','ABCD'}, ff.Id);
        
        ff.Action_Plan_Template__c = null;
        update ff;
        
        String result5 = FieldFixActionPlanController.processVINs(testVehicle.VehicleIdentificationNumber, ff.Id);
        //List<Batch_Processing_Detail__c> errors = [SELECT Status__c FROM Batch_Processing_Detail__c WHERE Status__c = 'Error'];
        
        FieldFixActionPlanController.processVINsAsync(new List<String>{'VIN123456789'},apt.id);
    }
}