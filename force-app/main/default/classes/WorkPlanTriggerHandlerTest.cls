@isTest
public class WorkPlanTriggerHandlerTest {
  
    @testSetup
    static void setupTestData() {
        // Create Warranty Prior records
        List<Warranty_Prior__c> warrantyList = new List<Warranty_Prior__c>();
        for (Integer i = 0; i < 2; i++) {
            warrantyList.add(new Warranty_Prior__c( ));
        }
        insert warrantyList;
        
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '9876543210',
            Type = 'Customer'
        );
        insert testAccount;

        // Create a test WorkOrder
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = testAccount.Id
        );
        insert testWorkOrder;
        
        List<WorkPlan> workPlans = new List<WorkPlan>();
        for (Warranty_Prior__c wp : warrantyList) {
            workPlans.add(new WorkPlan(Name = 'Test WorkPlan', Warranty_Prior__c = wp.Id,ParentRecordId = testWorkOrder.id));
        }
        insert workPlans;
        
        // Create WorkOrderLineItem records linked to one Warranty Prior
        //insert new WorkOrderLineItem(Warranty_Prior__c = warrantyList[0].Id);
    }

    @isTest
    static void testHandleAfterDelete() {
        // Fetch WorkPlan records for deletion
        List<WorkPlan> workPlansToDelete = [SELECT Id, Warranty_Prior__c FROM WorkPlan];
        
        // Delete WorkPlan records
        delete workPlansToDelete;
        
        // Call the method explicitly (if needed in a different context)
        WorkPlanTriggerHandler.handleAfterDelete(workPlansToDelete);
    }

	@isTest
    static void testPreventUpdateForJobCardStatus_BlockingStatus() {
        Account acc = new Account(Name = 'testing Account');
        insert acc;

        Contact con = new Contact(
            LastName = 'testing Contact',
            AccountId = acc.Id,
            Phone = '9123456789',
            Email = 'test@test.com'
        );
        insert con;

        Product2 testProduct = new Product2(
            Name = 'Test Accessory',
            IsActive = true,
            ProductCode = 'abcd',
            HSN_Code__c = 'abcd',
            Type__c = 'Accessories'
        );
        insert testProduct;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pricebookEntry;

        List<WorkOrder> workOrders = new List<WorkOrder>{
            new WorkOrder(
                Status = 'New',
                Subject = 'WO 1',
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
                RR_Customer_Rating__c = 5,
                RR_Customer_Suggestions__c = '12ss',
                RR_Check_all_requested_work_completed__c = 'Done',
                RR_Pending_Field_Fix__c = 'Done',
                RR_Ensure_latest_Firmware_is_flashed__c = 'Done',
                RR_Status_of_Side_Stand_switch_in_parked__c = 'done',
                RR_Electrical_Component_Functioning__c = 'Done',
                RR_Check_for_outstanding_Fault_Codes__c = 'Done',
                RR_Washing_Polishing__c = 'Done',
                Latest_Software_Version__c = 'Done',
                Current_Software_Versions__c = '1234',
                Pricebook2Id = standardPricebook.Id
            ),
            new WorkOrder(
                Status = 'New',
                Subject = 'WO 2',
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
                RR_Customer_Rating__c = 5,
                RR_Customer_Suggestions__c = '12ss',
                RR_Check_all_requested_work_completed__c = 'Done',
                RR_Pending_Field_Fix__c = 'Done',
                RR_Ensure_latest_Firmware_is_flashed__c = 'Done',
                RR_Status_of_Side_Stand_switch_in_parked__c = 'done',
                RR_Electrical_Component_Functioning__c = 'Done',
                RR_Check_for_outstanding_Fault_Codes__c = 'Done',
                RR_Washing_Polishing__c = 'Done',
                Latest_Software_Version__c = 'Done',
                Current_Software_Versions__c = '1234',
                Pricebook2Id = standardPricebook.Id
            )
        };
        insert workOrders;

        WorkPlan prtBlocked = new WorkPlan( Name= 'test',
            ParentRecordId = workOrders[0].Id
        );
        WorkPlan prtAllowed = new WorkPlan( Name= 'test',
            ParentRecordId = workOrders[1].Id
        );
        insert new List<WorkPlan>{prtBlocked, prtAllowed};

        workOrders[0].Status = 'Ready for Delivery';
        update workOrders[0];

        prtBlocked = [SELECT Id, ParentRecordId FROM WorkPlan WHERE Id = :prtBlocked.Id];
        Test.startTest();
        try {
            update prtBlocked;
        } catch (DmlException e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testPreventUpdateForJobCardStatus_EmptyList() {
        Test.startTest();
        try {
            WorkPlanTriggerHandler.PreventUpdateForJobCardStatus(null);
            WorkPlanTriggerHandler.PreventUpdateForJobCardStatus(new List<WorkPlan>());
        } catch (Exception e) {
        }
        Test.stopTest();
    }
}