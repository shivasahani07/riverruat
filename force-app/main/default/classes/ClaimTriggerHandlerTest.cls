@isTest
public class ClaimTriggerHandlerTest {

    static testMethod void testCodeCoverage() {
        
        Account acc = new Account(Name = 'testing Account', Type = 'Customer', Phone = '9807654321');
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
            )
        };
        insert workOrders;

        Warranty_Prior__c wp = new Warranty_Prior__c(
            Status__c = 'pending',
            Job_Card__c = workOrders[0].Id
        );
        insert wp;

        Claim testClaim = new Claim(
            Name = 'Test Claim',
            Warranty_Prior__c = wp.Id,
            By_Pass__c = false,
            AccountId = acc.Id,
            Status = 'Draft'
        );
        insert testClaim;
		
        /* Additional Code */
        Claim oldClaim = testClaim.clone(true, false, false, false);
        System.debug('oldClaim : ' + oldClaim);
        
        testClaim.Status = 'Submitted';
        update testClaim;
        
        Claim newClaim = [SELECT Id, Name,ClaimType,Received_Quantity__c,Credit_Note_Number__c,Vehicle__c,Status,FinalizedDate,Create_Batch__c,Warranty_Prior__c,
                          Job_Card__c,Unit_Price__c,Shipped_Quantity__c,Total_Claimed_Amount__c,Total_Claim_Amount__c,Approved_Amount__c,Total_Approved_Amount__c	 
                          FROM Claim WHERE Id = :testClaim.Id];

        Map<Id, Claim> oldMap = new Map<Id, Claim>{ oldClaim.Id => oldClaim };
        Map<Id, Claim> newMap = new Map<Id, Claim>{ newClaim.Id => newClaim };
        
        DMLLogger.logChanges(oldMap, newMap, 'UPDATE', 'Claim');
        /* Till Here */
        
        ClaimTriggerHandler.addTest();
        ClaimTriggerHandler.addTest2();
        ClaimTriggerHandler.addTest3();
    }
}