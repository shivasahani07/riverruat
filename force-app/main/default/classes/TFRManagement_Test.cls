@isTest
private class TFRManagement_Test {
    
    
    @TestSetup
    static void setupData() {
        // Create a sample Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            IsActive = true,
            HSN_Code__c = 'HSN-3849',
            Type__c = 'Accessories'
        );
        insert prod;
        
        // Create a sample TFR (VIN cutoff)
        TFR__c tfr = new TFR__c(
            VIN_Start__c = '1HGCM82633A123456',
            Is_Active__c = true
        );
        insert tfr;
        
        // Create a sample CodeSet
        CodeSet cs = new CodeSet(
            Name = 'Test CodeSet',
            Code = 'CS-001',
            CodeSetType = 'Labour',
            IsActive = true
        );
        insert cs;
        
        // Create a TFR_Part_Effect__c record
        TFR_Part_Effect__c partEffect = new TFR_Part_Effect__c(
            Product__c = prod.Id,
            TFR__c = tfr.Id
        );
        insert partEffect;
        
        // Create a TFR_Labour_Effect__c record
        TFR_Labour_Effect__c labourEffect = new TFR_Labour_Effect__c(
            Code_Set__c = cs.Id,
            Active__c = true
        );
        insert labourEffect;
        
        // Create Failure_Code__c record
        Failure_Code__c fc = new Failure_Code__c(
            Name = 'FC-Test',
            Batch_Size__c = 5,
            Sample_Collected__c = 6,
            Is_Active__c = true,
            TFR_Part_Effect__c = partEffect.Id,
            TFR_Labour_Effect__c = labourEffect.Id,
            VIN_Cut_off__c = tfr.Id,
            Type__c = 'Part' // 'Labour'
        );
        insert fc;
        
        
        
        Id vehiclePdiRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Vehicle PDI').getRecordTypeId();
        
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Center_Code__c='098765');
        insert testAccount;
        
        Account serviceCenter = new Account(Name = 'Test Account 1',Type='Service Center',Center_Code__c='123456', GST_City__c='Bangalore', GST_State__c='Karnataka', GST_Street__c='KN020', GST_Zip_Postal_Code__c='451109');
        insert serviceCenter;//Added By Aniket on 03/09/2025 For Test Coverage Validation
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka');
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id );
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
        insert testProduct;
        
        Asset testAsset = new Asset(Name='Test Asset 1',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        Asset testAsset2 = new Asset(Name='Test Asset 2',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset2;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition 1',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version 1');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle 2', Account__c=testAccount.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
        insert testVehicle;
        
        Vehicle testVehicle2 = new Vehicle(Name='Test Vehicle 3', Account__c=testAccount.Id, AssetId=testAsset2.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3C56',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
        insert testVehicle2;
        
        AssetMilestone asm = new AssetMilestone(Name = 'ASM1', MilestoneDate = Date.today().addMonths(2),  Stage = 'Active', AssetId = testAsset.Id, UsageType = 'Automotive', MilestoneType = 'PDI', VehicleId = testVehicle.Id);
        insert asm;
        
        Warehouse__c testWarehouse = new Warehouse__c(Name = 'Test Warehouse');
        insert testWarehouse;
        
        WorkOrder testWorkOrder = new WorkOrder(
            RecordTypeId = vehiclePdiRtId,
            Warehouse__c = testWarehouse.Id,
            Vehicle__c = testVehicle.Id,
            Odometer_Reading__c = 100,
            Status = 'New',
            Subject = 'Test Work Order', 
            RR_Technician__c = con.Id,
            RR_SOC_Level__c = true,
            RR_Front_Axle_Nut__c = true,
            RR_Brake_Play__c = true,
            RR_Tyre_Pressure__c = true,
            RR_GUI_Checks__c = true,
            RR_Tyre_Condition__c = true,
            RR_Socket_Cover_Opening__c = true,
            RR_Tank_Badge__c = true,
            RR_Suspnsion_Play__c = true,
            RR_Fork_Seal__c = true,
            RR_Brake_Oil_Level__c = true,
            RR_Rear_Axle_Nut__c = true,
            RR_Brake_Pads__c = true,
            RR_Steering_Top_Nut__c = true,
            RR_Brake_Sponginess__c = true,
            RR_Check_all_requested_work_completed__c = 'Done',
            RR_Pending_Field_Fix__c = 'Done',
            RR_Ensure_latest_Firmware_is_flashed__c = 'Done',
            RR_Status_of_Side_Stand_switch_in_parked__c = 'Done',
            RR_Electrical_Component_Functioning__c = 'Done',
            RR_Check_for_outstanding_Fault_Codes__c = 'Done',
            RR_Washing_Polishing__c= 'Done',
            Total_Duration_Min__c = 0,
            Total_Duration_Hour__c = 0,
            Labour_Charge__c = 0,
            SGST_on_Labour_Charges__c = 0,
            IGST_on_Labour_Charges__c = 0,
            CGST_on_Labour_Charges__c = 0,
            Service_Center__c=serviceCenter.Id

        );
        insert testWorkOrder;
        
        WorkOrder closedWO = new WorkOrder(
            RecordTypeId = vehiclePdiRtId,
            Warehouse__c = testWarehouse.Id,
            Vehicle__c = testVehicle2.Id,
            Odometer_Reading__c = 100,
            Status = 'Completed',
            Mode_Of_Payment__c = 'UPI',
            Subject = 'Test Work Order', 
            RR_Technician__c = con.Id,
            RR_SOC_Level__c = true,
            RR_Front_Axle_Nut__c = true,
            RR_Brake_Play__c = true,
            RR_Tyre_Pressure__c = true,
            RR_GUI_Checks__c = true,
            RR_Tyre_Condition__c = true,
            RR_Socket_Cover_Opening__c = true,
            RR_Tank_Badge__c = true,
            RR_Suspnsion_Play__c = true,
            RR_Fork_Seal__c = true,
            RR_Brake_Oil_Level__c = true,
            RR_Rear_Axle_Nut__c = true,
            RR_Brake_Pads__c = true,
            RR_Steering_Top_Nut__c = true,
            RR_Brake_Sponginess__c = true,
            RR_Check_all_requested_work_completed__c = 'Done',
            RR_Pending_Field_Fix__c = 'Done',
            RR_Ensure_latest_Firmware_is_flashed__c = 'Done',
            RR_Status_of_Side_Stand_switch_in_parked__c = 'Done',
            RR_Electrical_Component_Functioning__c = 'Done',
            RR_Check_for_outstanding_Fault_Codes__c = 'Done',
            RR_Washing_Polishing__c= 'Done',
            Total_Duration_Min__c = 0,
            Total_Duration_Hour__c = 0,
            Labour_Charge__c = 0,
            SGST_on_Labour_Charges__c = 0,
            IGST_on_Labour_Charges__c = 0,
            CGST_on_Labour_Charges__c = 0,
            Service_Center__c=serviceCenter.Id

        );
        insert closedWO;
        
        // Create Failure_Code__c record
        TFR_Sample__c tfrSample = new TFR_Sample__c(
			Job_Card__c = closedWO.Id,
            Failure_Code__c = fc.Id
        );
        insert tfrSample;
    }
    
    // Test Method for getFailureCodes()
    @IsTest
    static void test_getFailureCodes() {
        Test.startTest();
        List<Failure_Code__c> fcList = TFRManagement.getFailureCodes();
        Test.stopTest();
    }
    
    // Test Method for deleteFailureCode()
    @IsTest
    static void test_deleteFailureCode() {
        // Fetch one Failure Code to delete
        Failure_Code__c fcToDelete = [SELECT Id FROM Failure_Code__c LIMIT 1];
        
        Test.startTest();
        TFRManagement.deleteFailureCode(fcToDelete.Id);
        Test.stopTest();
    }
    
    // Test Method for checkTFRValidation()
    @IsTest
    static void test_checkTFRValidation() {
        Failure_Code__c fc = [SELECT Id FROM Failure_Code__c LIMIT 1];
        
        Test.startTest();
        TFRManagement.checkTFRValidation('1HGCM82633A123456', fc.Id);
        TFRManagement.checkTFRValidation('', fc.Id);
        Test.stopTest();
    }
    
    // Test Method for VeripartWithActionWithPlanApex()
    @IsTest
    static void test_VeripartWithActionWithPlanApex() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        TFRManagement.VeripartWithActionWithPlanApex(wo.Id);
        Test.stopTest();
    }
    
    // Test Method for VeripartWithActionWithPlanApex()
    @IsTest
    static void test_addSampleSizeONjcCloser() {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Status = 'Completed' LIMIT 1 ];
	
        List<Id> jobIds = new List<Id>{wo.Id};
            
        Test.startTest();
        TFRManagement.addSampleSizeONjcCloser(jobIds);
        Test.stopTest();
    }
    
}