@isTest
public class ClaimTriggerHandlerTest {
    @testSetup
    static void setupTestData() {
        // Create common test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact con = new Contact(
            LastName = 'testing Contact',
            AccountId = testAccount.Id,
            Phone = '9123456789',
            Email = 'test@test.com',
            Primary_Contact__c = true
        );
        insert con;
        
        Product2 prod = new Product2(
            Name = 'test product',
            HSN_Code__c = '123',
            Type__c = 'Accessories',
            ProductCode = 'R112031462'
        );
        insert prod;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        PricebookEntry testEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testEntry;
        
        Asset asst = new Asset(
            Name = 'test Asset',
            AccountId = testAccount.Id,
            ContactId = con.Id
        );
        insert asst;
        
        Software_Version__c sv = new Software_Version__c(
            Name = 'test version',
            Latest_Software_Version__c = true
        );
        insert sv;
        
        VehicleDefinition vd = new VehicleDefinition(
            Name = 'test VehicleDefinition',
            ProductId = prod.Id
        );
        insert vd;
        
        Vehicle vac = new Vehicle(
            Name = 'test vehicle',
            CurrentOwnerId = testAccount.Id,
            Charger_PC_Number__c = '123CC',
            VehicleRegistrationNumber = '123',
            VehicleIdentificationNumber = 'NeoCity2022ZXi',
            VehicleDefinitionId = vd.Id,
            Software_Version__c = sv.Id,
            AssetId = asst.Id
        );
        insert vac;
        
        AssetMilestone completedMilestone = new AssetMilestone(
            Name = 'Completed Milestone',
            AssetId = asst.Id,
            UsageType = 'Automotive',
            MilestoneDate = System.today().addDays(1),
            MilestoneType = 'PDI',
            Stage = 'Active',
            VehicleId = vac.Id
        );
        insert completedMilestone;
        
        WorkOrder testWorkOrder = new WorkOrder(
            Vehicle__c = vac.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert testWorkOrder;
        
        
        
        Warranty_Prior__c testWarranty = new Warranty_Prior__c(
            Job_Card__c = testWorkOrder.Id
        );
        insert testWarranty;
        
                
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
            IGST_Percentage__c = 18.00,
            SGST_Percentage__c = 9.00,
            CGST_Percentage__c = 9.00
        );
        insert testWorkPlan;
        
        // Create email templates as current user to avoid mixed DML
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            EmailTemplate approvedTemplate = new EmailTemplate(
                DeveloperName = 'Claim_Approved1',
                FolderId = UserInfo.getUserId(),
                TemplateType = 'custom',
                Name = 'Approved Template',
                Subject = 'Claim Approved',
                Body = 'Test Body',
                IsActive = true
            );
            insert approvedTemplate;
            
            EmailTemplate rejectedTemplate = new EmailTemplate(
                DeveloperName = 'Claim_Rejection',
                FolderId = UserInfo.getUserId(),
                TemplateType = 'custom',
                Name = 'Rejected Template',
                Subject = 'Claim Rejected',
                Body = 'Test Body',
                IsActive = true
            );
            insert rejectedTemplate;
        }
    }
    
    @isTest
    static void testHandleAfterInsertPositive() {
        Warranty_Prior__c warranty = [SELECT Id FROM Warranty_Prior__c LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Claim testClaim = new Claim(
            Name = 'Test Claim',
            Warranty_Prior__c = warranty.Id,
            By_Pass__c = false,
            AccountId = testAccount.Id,
            Status = 'Draft'
        );
        insert testClaim;
        Test.stopTest();
        
        // Verify ClaimItems created
        List<ClaimItem> claimItems = [SELECT Id FROM ClaimItem WHERE ClaimId = :testClaim.Id];
        System.assert(!claimItems.isEmpty(), 'Should create ClaimItems');
    }
    
    @isTest
    static void testHandleAfterInsertNoWarranty() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Claim testClaim = new Claim(
            Name = 'Invalid Claim',
            Warranty_Prior__c = null,
            AccountId = testAccount.Id,
            By_Pass__c = false
        );
        insert testClaim;
        Test.stopTest();
        
        List<ClaimItem> claimItems = [SELECT Id FROM ClaimItem WHERE ClaimId = :testClaim.Id];
        System.assertEquals(0, claimItems.size(), 'No ClaimItems should be created');
    }
    
    @isTest
    static void testHandleAfterInsertBypass() {
        Warranty_Prior__c warranty = [SELECT Id FROM Warranty_Prior__c LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Claim testClaim = new Claim(
            Name = 'Bypassed Claim',
            Warranty_Prior__c = warranty.Id,
            AccountId = testAccount.Id,
            By_Pass__c = true
        );
        insert testClaim;
        Test.stopTest();
        
        List<ClaimItem> claimItems = [SELECT Id FROM ClaimItem WHERE ClaimId = :testClaim.Id];
        System.assertEquals(0, claimItems.size(), 'No ClaimItems should be created for bypassed Claim');
    }
    
    @isTest
    static void testHandleAfterUpdateApproved() {
        
        Id emailId = [SELECT Id From EmailTemplate WHERE DeveloperName = 'Claim_Approved1' LIMIT 1].Id;

        
        Warranty_Prior__c warranty = [SELECT Id FROM Warranty_Prior__c LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create claim first
        Claim testClaim = new Claim(
            Name = 'Update Test Claim',
            Warranty_Prior__c = warranty.Id,
            AccountId = testAccount.Id,
            By_Pass__c = false,
            Status = 'Draft'
        );
        insert testClaim;
        
        Test.startTest();
        // Update status to Approved
        testClaim.Status = 'Approved';
        update testClaim;
        
        Test.stopTest();
        
        //System.assertEquals(1, Limits.getEmailInvocations(), 'Approval email should be sent');
    } 
    
    @isTest
    static void testHandleAfterUpdateRejected() {
        Warranty_Prior__c warranty = [SELECT Id FROM Warranty_Prior__c LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Claim testClaim = new Claim(
            Name = 'Rejected Test Claim',
            Warranty_Prior__c = warranty.Id,
            AccountId = testAccount.Id,
            By_Pass__c = false,
            Status = 'Draft'
        );
        insert testClaim;
        
        Test.startTest();
        testClaim.Status = 'Rejected';
        update testClaim;
        Test.stopTest();
        
        //System.assertEquals(1, Limits.getEmailInvocations(), 'Rejection email should be sent');
    }
    
    @isTest
    static void testHandleAfterUpdateNoChange() {
        Warranty_Prior__c warranty = [SELECT Id FROM Warranty_Prior__c LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Claim testClaim = new Claim(
            Name = 'No Change Test',
            Warranty_Prior__c = warranty.Id,
            AccountId = testAccount.Id,
            By_Pass__c = false,
            Status = 'Draft'
        );
        insert testClaim;
        
        Test.startTest();
        // Update without changing status
        testClaim.Status = 'New';
        update testClaim;
        Test.stopTest();
        
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
    }
}