@isTest
public class WorkOrderTriggerHandlerTest {
    
    @isTest
    static void testHandleTrigger() {
        Id vehiclePdiRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Vehicle PDI').getRecordTypeId();
        
        
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer');
        insert testAccount;
        
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
            CGST_on_Labour_Charges__c = 0

        );
        insert testWorkOrder;
        
        WorkOrder testWorkOrder2 = new WorkOrder(
            RecordTypeId = vehiclePdiRtId,
            Warehouse__c = testWarehouse.Id,
            Vehicle__c = testVehicle2.Id,
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
            CGST_on_Labour_Charges__c = 0
        );
        insert testWorkOrder2;
        
       
        WorkType testWorkType = new WorkType(
            Name = 'Test Work Type',
            Amount__c = 100.0,
            EstimatedDuration = 2,
            DurationType = 'Hours'
        );
        insert testWorkType;
        
        WorkPlan testWorkPlan = new WorkPlan(
            Name = 'Test Workplan',
            Labour_Charge__c = 100.0,
            Duration_Min__c = 130, 
            Duration_Hour__c = 2,
            Discount__c = 10,
            Work_Type__c = testWorkType.Id,
            WorkOrderId = testWorkOrder.Id,
            IGST_Percentage__c=18.00,
            SGST_Percentage__c=9.00,
            CGST_Percentage__c=9.00
        );
        insert testWorkPlan;
        
        WorkPlan testWorkPlan2 = new WorkPlan(
            Name = 'Test Workplan 2',
            Labour_Charge__c = 100.0,
            Duration_Min__c = 130, 
            Duration_Hour__c = 2,
            Discount__c = 10,
            Work_Type__c = testWorkType.Id,
            WorkOrderId = testWorkOrder2.Id,
            IGST_Percentage__c=18.00,
            SGST_Percentage__c=9.00,
            CGST_Percentage__c=9.00
        );
        insert testWorkPlan2;
        
        Pre_Delivery_Inspection__c pdI = new Pre_Delivery_Inspection__c(Parameter__c = 'q234retgh' ,Attribute__c = 'Accessories', Description__c = 'sadfgn'  );
        insert pdI;
        
        Pre_Delivery_Inspection_Item__c pdiItem = new Pre_Delivery_Inspection_Item__c(
            Asset_Milestone__c = asm.Id, Pre_Delivery_Inspection__c = pdI.Id, 
            Check__c = false
        );
        insert pdiItem;
        
        Warranty_Prior__c createdWarranty = [SELECT Id, Job_Card__c, Status__c FROM Warranty_Prior__c WHERE Job_Card__c = :testWorkOrder.Id LIMIT 1];
 
        createdWarranty.Status__c = 'Approved';
        createdWarranty.Job_Card__c=testWorkOrder.Id;
        update createdWarranty; 
	
        
       Test.startTest();
        
        testWorkOrder.Cancellation_Reason__c='sagar';
        testWorkOrder.Status='Cancellation Requested';
        try{
             update testWorkOrder;
        }catch(Exception e){
            
        }
        
        testWorkOrder.Status='New';
        update testWorkOrder;
        
        testWorkOrder.Status='In Progress';
        update testWorkOrder;
        
        testWorkOrder.Status='Ready for Delivery';
        update testWorkOrder; 

        testWorkOrder = [SELECT Id, Status FROM WorkOrder WHERE Id = :testWorkOrder.Id];
        System.assertEquals('Ready for Delivery', testWorkOrder.Status);
        pdiItem.Check__c=true;
        update pdiItem;
        testWorkOrder.Status='Completed';
        update testWorkOrder;

        
        testWorkOrder2.Cancellation_Reason__c='sagar';
        testWorkOrder2.Status='Cancellation Requested';
        
         try{
            update testWorkOrder2;
        }catch(Exception e){
            
        }
        
       
        testWorkOrder2.Status='New';
        update testWorkOrder2;
        testWorkOrder2.Status='In Progress';
        update testWorkOrder2;
        
        testWorkOrder2.Status='Ready for Delivery';
        update testWorkOrder2; 
        testWorkOrder2.Status='Completed';
        //update testWorkOrder2;
       
        testWorkOrder.Status='New';
        update testWorkOrder;
        ///delete testWorkOrder;
        delete testWorkOrder2;
        
        
       //testWorkOrder = [SELECT Id, Status FROM WorkOrder WHERE Id = :testWorkOrder.Id];
       // testWorkOrder.Status = 'Completed';
       // testWorkOrder.Cancellation_Reason__c = 'asdfgb';
        //update testWorkOrder;
        
        Test.stopTest();
    }
    
}