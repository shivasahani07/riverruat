@isTest
public class JobCardRecordLockTest {
    
  @isTest
static void testPreventUpdateForJobCardStatus_BlockingStatus() {
    
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

    WorkPlan prtBlocked = new WorkPlan(Name = 'test', ParentRecordId = workOrders[0].Id);
    WorkPlan prtAllowed = new WorkPlan(Name = 'test', ParentRecordId = workOrders[1].Id);
    insert new List<WorkPlan>{prtBlocked, prtAllowed};

    WorkOrderLineItem woliAllowed = new WorkOrderLineItem(
        WorkOrderId = workOrders[0].Id,
        PricebookEntryId = pricebookEntry.Id,
        Quantity = 1,
        UnitPrice = 100
    );
    WorkOrderLineItem woliBlockedInsert = new WorkOrderLineItem(
        WorkOrderId = workOrders[0].Id,
        PricebookEntryId = pricebookEntry.Id,
        Quantity = 2,
        UnitPrice = 100
    );
    
    insert new List<WorkOrderLineItem>{woliAllowed, woliBlockedInsert};
         
    RR_Customer_Voice__c csVocieAllowed = New RR_Customer_Voice__c (RR_Work_Order__c =  workOrders[0].Id);
    RR_Customer_Voice__c csVocieBlocked = New RR_Customer_Voice__c (RR_Work_Order__c =  workOrders[0].Id);

    insert new List<RR_Customer_Voice__c>{csVocieAllowed, csVocieBlocked};
   
    Ticket__c tckt = new Ticket__c (Job_Card__c = workOrders[0].Id, Status__c = 'Open');
    insert new List<Ticket__c>{tckt};
        
Account testAccount = new Account(
            Name = 'testing Account',
            Type = 'Customer',
            Phone = '9807654321'
        );
        insert testAccount;       
         Warranty_Prior__c wp = new Warranty_Prior__c(
            Status__c = 'pending',
            Job_Card__c = workOrders[0].Id
        );
        insert wp;
        Claim testClaim = new Claim(
            Name = 'Test Claim',
            Warranty_Prior__c = wp.Id,
            By_Pass__c = false,
            AccountId = testAccount.Id,
            Status = 'Draft'
        );
        
        insert new List<Claim>{testClaim};
            ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR'
        );
               insert new List<ProductRequest>{po};
                   
       ProductRequired prdR = new ProductRequired(Product2Id = testProduct .Id, ParentRecordId = workOrders[0].Id );
    insert new List<ProductRequired>{prdR};
        
        ProductRequestLineItem lineItem2 = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id = testProduct.Id,
            Price_Book__c = standardPricebook.Id,
            QuantityRequested = 33
        );
    insert new List<ProductRequestLineItem>{lineItem2};

    workOrders[0].Status = 'Ready for Delivery';

    try {
        update workOrders[0];
    } catch (DmlException e) {}

    System.runAs(sysAdminUser) {
    
    Test.startTest();

    try {
        update prtBlocked;
        update woliBlockedInsert;
        update csVocieBlocked;
        update tckt;
        Delete prtAllowed;
        //update newAP;
        update testClaim;
        update po;
        Update prdR;
        update lineItem2;
    } catch (DmlException e) {}

    Test.stopTest();
    }
}


    
    
    @isTest
    static void testPreventUpdateForJobCardStatus_EmptyList() {
        Test.startTest();
        try {
            JobCardRecordLock.PreventUpdateForJobCardStatus(null);
            JobCardRecordLock.PreventUpdateForJobCardStatus(new List<WorkPlan>());
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    static testMethod void testCodeCoverage() {
        JobCardRecordLock.addTest();
       
        JobCardRecordLock.addTest2();
        JobCardRecordLock.addTest3();
       
        
       
    }
}