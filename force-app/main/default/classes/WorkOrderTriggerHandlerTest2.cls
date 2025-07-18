@isTest
public class WorkOrderTriggerHandlerTest2 {
    @testSetup
    static void setupTestData() {
         // Create test Account
        Account testAccount = new Account(Name = 'Test Account 1', Type='Customer');
        insert testAccount;
        
        // Create test Location
        Schema.Location testLocation = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'State',
            State__c = 'Karnataka',
            IsInventoryLocation = true
        );
        insert testLocation;
        
        // Create test Contact
        Contact con = new Contact(
            LastName = 'Dinesh 1',
            Phone = '7834878789',
            AccountId = testAccount.id,
            Location__c = testLocation.id
        );
        insert con;
        
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product 1',
            IsActive = true,
            ProductCode = 'abcd',
            HSN_Code__c = 'abcd',
            Type__c = 'Vehicle'
        );
        insert testProduct;
        
        // Create Pricebook Entry
        Id stdPrBk = Test.getStandardPricebookId();
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        // Create test Asset
        Asset testAsset = new Asset(
            Name = 'Test Asset 1',
            AccountId = testAccount.Id,
            Product2Id = testProduct.Id
        );
        insert testAsset;
        
        // Create Vehicle Definition
        VehicleDefinition testVD = new VehicleDefinition(
            Name = 'Test VehicleDefinition 1',
            ProductId = testProduct.Id
        );
        insert testVD;
        
        // Create Software Version
        Software_Version__c testSV = new Software_Version__c(
            Name = 'Test Software Version 1'
        );
        insert testSV;
        
        // Create Vehicle
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
        
        // Create test Product for parts
        Product2 testPartProduct = new Product2(
            Name = 'Test Part Product',
            ProductCode = 'PART123',
            IsActive = true,
            HSN_Code__c='R112081466',
            Type__c='Parts'
        );
        insert testPartProduct;
        
        // Create test ProductItem (Inventory)
        ProductItem testInventory = new ProductItem(
            Product2Id = testPartProduct.Id,
            LocationId = testLocation.Id
        );
        insert testInventory;
        
        // Create test Job Card (WorkOrder)
        WorkOrder testJobCard = new WorkOrder(
            AccountId = testAccount.Id,
            Vehicle__c = testVehicle.Id,
            Location__c = testLocation.Id,
            Vehicle_Registration_Number__c = 'REG123',
            Odometer_Reading__c = 1000,
            Status = 'In Progress',
            ContactId = con.Id
        );
        insert testJobCard;
        
        // ActionPlanTemplateVersion
        ActionPlanTemplateVersion aptv = [
            SELECT Id, ActionPlanTemplateId, Status 
            FROM ActionPlanTemplateVersion
            LIMIT 1
        ];
        aptv.Status = 'Final';
        update aptv;
        
        // ActionPlanTemplate
        ActionPlanTemplate apt = [
            SELECT Id 
            FROM ActionPlanTemplate 
            WHERE Id = :aptv.ActionPlanTemplateId AND TargetEntityType ='Vehicle'
        ];
        
        // Create Field Fix
        Field_Fix__c testFieldFix = new Field_Fix__c(
            Action_Plan_Template__c = apt.Id
        );
        insert testFieldFix;
        
        // Create ActionPlan
        ActionPlan newAP = new ActionPlan(
            Name = 'Test Action Plan',
            ActionPlanTemplateVersionId = aptv.Id,
            TargetId = testVehicle.Id,
            StartDate = System.today().addDays(-1),
            To_be_Completed_in_JC__c = false,
            ActionPlanType = 'Industries',
            Job_Card__c = testJobCard.Id,
            Field_Fix__c = testFieldFix.Id
        );
        insert newAP;
        
        // Check for Before Update ActionPlan to trigger logic
        newAP.To_be_Completed_in_JC__c = true;
        // Record Types
        Id vehiclePdiRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Vehicle_PDI').getRecordTypeId();
        
                
          // Asset Milestones
        AssetMilestone asm = new AssetMilestone(
            Name = 'Test Milestone', 
            MilestoneDate = Date.today().addMonths(2),  
            Stage = 'Active', 
            AssetId = testAsset.Id, 
            UsageType = 'Automotive', 
            MilestoneType = 'PDI', 
            VehicleId = testVehicle.Id
        );
        insert asm;
        
        // Warehouses
        Warehouse__c testWarehouse = new Warehouse__c(Name = 'Test Warehouse');
        insert testWarehouse;
        
        // Work Orders
        WorkOrder testWorkOrder = new WorkOrder(
            RecordTypeId = vehiclePdiRtId,
            Warehouse__c = testWarehouse.Id,
            Vehicle__c = testVehicle.Id,
            Odometer_Reading__c = 100,
            Status = 'New',
            Subject = 'Test Work Order', 
            RR_Technician__c = con.Id,
            Total_Duration_Min__c = 0,
            Total_Duration_Hour__c = 0,
            Labour_Charge__c = 0,
            SGST_on_Labour_Charges__c = 0,
            IGST_on_Labour_Charges__c = 0,
            CGST_on_Labour_Charges__c = 0
        );
        insert testWorkOrder;
        
        // Work Types
        WorkType testWorkType = new WorkType(
            Name = 'Test Work Type',
            Amount__c = 100.0,
            EstimatedDuration = 2,
            DurationType = 'Hours'
        );
        insert testWorkType;
        
        // Work Plans
        WorkPlan testWorkPlan = new WorkPlan(
            Name = 'Test Workplan',
            Labour_Charge__c = 100.0,
            Duration_Min__c = 130, 
            Duration_Hour__c = 2,
            Discount__c = 10,
            Work_Type__c = testWorkType.Id,
            WorkOrderId = testWorkOrder.Id,
            IGST_Percentage__c = 18.00,
            SGST_Percentage__c = 9.00,
            CGST_Percentage__c = 9.00
        );
        insert testWorkPlan;
        
        
        // Pre-Delivery Inspections
        Pre_Delivery_Inspection__c pdi = new Pre_Delivery_Inspection__c(
            Parameter__c = 'Test Parameter',
            Attribute__c = 'Accessories', 
            Description__c = 'Test Description'
        );
        insert pdi;
        
        // Pre-Delivery Inspection Items
        Pre_Delivery_Inspection_Item__c pdiItem = new Pre_Delivery_Inspection_Item__c(
            Asset_Milestone__c = asm.Id, 
            Pre_Delivery_Inspection__c = pdi.Id, 
            Check__c = false
        );
        insert pdiItem;
        
        // Warranties
        Warranty_Prior__c warranty = new Warranty_Prior__c(
            Job_Card__c = testWorkOrder.Id,
            Status__c = 'Approved'
        );
        insert warranty;
    }
    
    @isTest
    static void testPreventClosingWithIncompleteActionPlans() {
        WorkOrder wo = [SELECT Id, Status FROM WorkOrder LIMIT 1];
        ActionPlan ap = [SELECT Id FROM ActionPlan LIMIT 1];
        
        Test.startTest();
        wo.Status = 'Ready for Delivery';
        update wo;
        
        wo.Status = 'Completed';
        Database.SaveResult result = Database.update(wo, false);
        Test.stopTest();
        
        System.assert(!result.isSuccess(), 'Should prevent closing');
        System.assert(result.getErrors()[0].getMessage().contains('All Action Plans are not completed'));
    }
    
    @isTest
    static void testWorkPlanAggregation() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        WorkPlan wp = [SELECT Id FROM WorkPlan LIMIT 1];
        
        Test.startTest();
        WorkOrderTriggerHandler.handleTrigger(new List<WorkPlan>{wp});
        Test.stopTest();
        
        WorkOrder updatedWo = [SELECT Total_Duration_Min__c, Total_Duration_Hour__c, Labour_Charge__c 
                              FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(10, updatedWo.Total_Duration_Min__c, 'Minutes should wrap to hours');
        System.assertEquals(4, updatedWo.Total_Duration_Hour__c, 'Hours should aggregate');
        System.assertEquals(100, updatedWo.Labour_Charge__c, 'Charges should sum');
    }
    
    @isTest
    static void testWarrantyCreationOnWorkPlanInsert() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        
        Test.startTest();
        WorkPlan newWp = new WorkPlan(
            Name = 'New Warranty Workplan',
            Labour_Charge__c = 200.0,
            Work_Type__c = wt.Id,
            WorkOrderId = wo.Id
        );
        insert newWp;
        Test.stopTest();
        
        WorkPlan updatedWp = [SELECT Warranty_Prior__c FROM WorkPlan WHERE Id = :newWp.Id];
        System.assertNotEquals(null, updatedWp.Warranty_Prior__c, 'Should have warranty linked');
    }
    
    @isTest
    static void testPDIResetOnJobCardClose() {
        WorkOrder wo = [SELECT Id, Status FROM WorkOrder LIMIT 1];
        Pre_Delivery_Inspection_Item__c pdiItem = [SELECT Id, Check__c FROM Pre_Delivery_Inspection_Item__c LIMIT 1];
        
        Test.startTest();
        pdiItem.Check__c = true;
        update pdiItem;
        
        wo.Status = 'Completed';
        update wo;
        Test.stopTest();
        
        Pre_Delivery_Inspection_Item__c updatedPDI = [SELECT Check__c FROM Pre_Delivery_Inspection_Item__c WHERE Id = :pdiItem.Id];
        System.assertEquals(false, updatedPDI.Check__c, 'PDI check should be reset');
    }
    
    @isTest
    static void testActionPlanReassignment() {
        WorkOrder oldWo = [SELECT Id, Status, Vehicle__c FROM WorkOrder LIMIT 1];
        ActionPlan ap = [SELECT Id FROM ActionPlan LIMIT 1];
        
        Test.startTest();
        // Create new job card for same vehicle
        WorkOrder newWo = new WorkOrder(
            RecordTypeId = oldWo.RecordTypeId,
            Warehouse__c = oldWo.Warehouse__c,
            Vehicle__c = oldWo.Vehicle__c,
            Status = 'New',
            Subject = 'New Job Card'
        );
        insert newWo;
        Test.stopTest();
        
        ActionPlan updatedAp = [SELECT Job_Card__c FROM ActionPlan WHERE Id = :ap.Id];
        System.assertEquals(newWo.Id, updatedAp.Job_Card__c, 'Should reassign to new Job Card');
    }
    
    @isTest
    static void testActionPlanCompletion() {
        WorkOrder wo = [SELECT Id, Status FROM WorkOrder LIMIT 1];
        ActionPlan ap = [SELECT Id FROM ActionPlan LIMIT 1];
        ap.To_be_Completed_in_JC__c = true;
        update ap;
        
        Test.startTest();
        wo.Status = 'Completed';
        update wo;
        Test.stopTest();
        
        ActionPlan completedAp = [SELECT ActionPlanState FROM ActionPlan WHERE Id = :ap.Id];
        System.assertEquals('Completed', completedAp.ActionPlanState, 'Should complete action plan');
    }
    
    @isTest
    static void testCancellationApprovalProcess() {
        User manager = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Manager',
            Email = 'manager@test.com',
            Username = 'manager@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'Title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert manager;
        
        User tech = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Tech',
            Email = 'tech@test.com',
            Username = 'tech@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'Title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ManagerId = manager.Id
        );
        insert tech;
        
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        wo.OwnerId = tech.Id;
        update wo;
        
        System.runAs(tech) {
            Test.startTest();
            wo.Status = 'Cancellation Requested';
            update wo;
            Test.stopTest();
        }
        
        ProcessInstance approval = [SELECT Status FROM ProcessInstance WHERE TargetObjectId = :wo.Id];
        System.assertEquals('Pending', approval.Status, 'Approval should be triggered');
    }
    
    @isTest
    static void testFieldFixJobCount() {
        WorkOrder wo = [SELECT Id, Status FROM WorkOrder LIMIT 1];
        ActionPlan ap = [SELECT Id FROM ActionPlan LIMIT 1];
        
        Field_Fix__c ff = new Field_Fix__c();
        insert ff;
        
        ap.Field_Fix__c = ff.Id;
        update ap;
        
        Test.startTest();
        wo.Status = 'Completed';
        update wo;
        Test.stopTest();
        
        Field_Fix__c updatedFF = [SELECT Total_Job_Card_Completed__c FROM Field_Fix__c WHERE Id = :ff.Id];
        System.assertEquals(1, updatedFF.Total_Job_Card_Completed__c, 'Should increment completed job count');
    }
    
    @isTest
    static void testSkippedActionPlanCreation() {
        WorkOrder wo = [SELECT Id, Approved_By_Process__c FROM WorkOrder LIMIT 1];
        ActionPlan ap = [SELECT Id FROM ActionPlan LIMIT 1];
        
        Test.startTest();
        wo.Approved_By_Process__c = true;
        update wo;
        Test.stopTest();
        
        Skipped_Action_Plan__c skipped = [SELECT Id FROM Skipped_Action_Plan__c LIMIT 1];
        System.assertNotEquals(null, skipped, 'Skipped record should be created');
        
        ActionPlan updatedAp = [SELECT Job_Card__c FROM ActionPlan WHERE Id = :ap.Id];
        System.assertEquals(null, updatedAp.Job_Card__c, 'ActionPlan should be unassigned');
    }
    
    @isTest
    static void testWorkOrderLifecycle() {
        WorkOrder wo = [SELECT Id, Status FROM WorkOrder LIMIT 1];
        Warranty_Prior__c warranty = [SELECT Id, Status__c FROM Warranty_Prior__c LIMIT 1];
        
        Test.startTest();
        // Test cancellation workflow
        wo.Cancellation_Reason__c = 'Test cancellation';
        wo.Status = 'Cancellation Requested';
        update wo;
        
        // Test status transitions
        wo.Status = 'New';
        update wo;
        
        wo.Status = 'In Progress';
        update wo;
        
        wo.Status = 'Ready for Delivery';
        update wo;
        
        // Complete with incomplete action plans (should fail)
        wo.Status = 'Completed';
        Database.SaveResult result = Database.update(wo, false);
        System.assert(!result.isSuccess(), 'Should prevent closing with incomplete action plans');
        
        // Complete successfully
        ActionPlan ap = [SELECT Id FROM ActionPlan LIMIT 1];
        ap.To_be_Completed_in_JC__c = true;
        update ap;
        
        wo.Status = 'Completed';
        update wo;
        Test.stopTest();
        
        // Verify post-completion states
        WorkOrder updatedWo = [SELECT Status FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('Completed', updatedWo.Status);
        
        warranty = [SELECT Status__c FROM Warranty_Prior__c WHERE Id = :warranty.Id];
        System.assertEquals('Approved', warranty.Status__c);
    }
}