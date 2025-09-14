@isTest
private class JobCardValidationHandlerTest {
    
    @isTest static void testPreventUpdateIfCompleted() {
        
        // Step 1: Get System Admin profile
    Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];

    // Step 2: Create a user with System Administrator profile
    User sysAdminUser = new User(
        FirstName = 'Sys',
        LastName = 'Admin',
        Email = 'sysadminuser@test.com',
        Username = 'sysadminuser@test.com' + System.currentTimeMillis(),
        Alias = 'sysad',
        ProfileId = sysAdminProfile.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
    );
    insert sysAdminUser;
        
        Account acc = new Account(Name = 'testing Account');
        insert acc;
        Account acc1 = new Account(Name = 'testing Account', Type = 'Dealer', Store_Type__c = 'DODO', Center_Code__c = '322002');
        insert acc1;

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
                Pricebook2Id = standardPricebook.Id,
                Service_Center__c = acc1.Id
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
                Pricebook2Id = standardPricebook.Id,
                Service_Center__c = acc1.Id
            )
        };
        insert workOrders;

        workOrders[0].Status = 'In Progress';
    update workOrders[0];

    workOrders[0].Status = 'Ready for Delivery';
    update workOrders[0];

    workOrders[0].Status = 'Completed';
    update workOrders[0];

        workOrders[0].Subject = 'Update Attempt';
        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>([SELECT Id, Status FROM WorkOrder WHERE Id = :workOrders[0].Id]);
	System.runAs(sysAdminUser) {
        Test.startTest();
        try {
            JobCardValidationHandler.validateJobCardStatus(new List<WorkOrder>{workOrders[0]}, oldMap);
            update workOrders[0];
        } catch (DmlException e) {
        }
    }
        workOrders[1].Subject = 'Update Allowed';
        oldMap = new Map<Id, WorkOrder>([SELECT Id, Status FROM WorkOrder WHERE Id = :workOrders[1].Id]);
        JobCardValidationHandler.validateJobCardStatus(new List<WorkOrder>{workOrders[1]}, oldMap);
        update workOrders[1];
        Test.stopTest();
    }
}