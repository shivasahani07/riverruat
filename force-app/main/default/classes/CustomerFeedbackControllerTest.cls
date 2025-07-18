@isTest
private class CustomerFeedbackControllerTest {

    static testMethod void testControllerInitialization() {
        Account acc = new Account(Name = 'Test Account', Email__c = 'test@gmail.com', type='Customer' );
        insert acc;
        
        Account accDealer = new Account(Name = 'Test Delaer', Email__c = 'testdelaer@gmail.com', Phone = '8767868687', type='Dealer',Center_Code__c = 'asdj12w');
        insert accDealer;

        Contact con = new Contact(Lastname = 'Test Contact', AccountId = acc.id, Phone = '1234567890');
        insert con;

        Asset asset = new Asset(Name = 'Test Asset', AccountId = acc.id, ContactId = con.id);
        insert asset;

        Product2 product = new Product2(Name = 'Test Product', Type__c = 'Parts', HSN_Code__c = 'TESTHSN', ProductCode = '12312');
        insert product;

        VehicleDefinition vehiDefi = new VehicleDefinition(Name = 'Test Definition', ProductId = product.id);
        insert vehiDefi;

        Software_Version__c softwareVersion = new Software_Version__c(Name = 'Test Version 1');
        insert softwareVersion;

        Vehicle vehicle = new Vehicle(
            Name = 'Test Vehicle',
            assetId = asset.id,
            VehicleIdentificationNumber = 'TEST123',
            VehicleRegistrationNumber = 'RIVER-GUJ-8A2-C',
            VehicleDefinitionId = vehiDefi.id,
            Software_Version__c = softwareVersion.id,
            CurrentOwnerId = acc.id,
            PDI_Status_Pass__c = true,
            Charger_PC_Number__c = 'ABC123'
        );
        insert vehicle;
        
        Case testCase = new Case(
            contactId = con.id,
            accountId = acc.id,
            Vehicle_Registration_Number__c = 'RIVER-GUJ-8A2-C',
            
         vehicle__c = vehicle.id,
            case_type__c = 'Urgent Complaint',
            status = 'New',
            Case_Category__c = 'Parts',
            Assign_to_Dealer__c = accDealer.id,
            origin = 'Phone',
            Category__c = 'Minor',
            Escalations_Team_Contact__c ='9999999990',
            Subject__c = 'Parts concern',
            Description = 'Test'
        );
        insert testCase;
        
       
        
        
        Order testOrder = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Website_Order_Id__c = 'QWERTY1234567WE',
            Dealer__c = accDealer.Id,
            Internal_Purchase__c = false,
            
            Transportation_Charges__c = 100,
            BillingCountry = 'India',
            BillingState = 'Karnataka',
             IRN_No__c = 'qwer1234',
            Assigned_Vehicle__c = vehicle.id
        );
        insert testOrder;

        Customer_Feedback__c testFeedback = new Customer_Feedback__c(
            Case__c = testCase.Id,
            name = 'Test Customer Feedback',
            issue_type__c = 'Parts',
           	Resolution_provided__C = 'Test Solution'
        );
        insert testFeedback;

        AssetMilestone testMilestone = new AssetMilestone(
            Name = 'Test Milestone ',
            MilestoneDate = Date.today().addDays(10),
            VehicleId = vehicle.id,
            MilestoneType = 'PDI',
            Stage = 'Tentative',
            UsageType = 'Automotive',
            AssetId = asset.id
        );
        insert testMilestone;
        
        AssetMilestone testMilestone22 = new AssetMilestone(
            Name = 'Test Milestone ',
            MilestoneDate = Date.today().addDays(10),
            VehicleId = vehicle.id,
            MilestoneType = 'SOld',
            Stage = 'Tentative',
            UsageType = 'Automotive',
            AssetId = asset.id
        );
        insert testMilestone22;
        
        AssetMilestone testMilestone1 = new AssetMilestone(
            Name = 'Test Milestone ',
            MilestoneDate = Date.today().addDays(10),
            VehicleId = vehicle.id,
            MilestoneType = 'Customer Delivery',
            Stage = 'Tentative',
            UsageType = 'Automotive',
            AssetId = asset.id
        );
        insert testMilestone1;
        
        // Start test
        Test.startTest();

        // Set page parameters
        PageReference pageRef = Page.CustomerFeedbackForm; // Replace YourPageName with the actual page name
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', testCase.Id);

        // Create a StandardController instance with the Case record
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        
        // Instantiate the controller
        CustomerFeedbackController controller = new CustomerFeedbackController(sc);

        // Verify controller properties
        //System.assertEquals(testCase.Id, controller.currentCase.Id);
        //System.assertEquals(vehicle.Id, controller.caseVehicle.Id);
        //System.assertEquals(1, controller.customerFeedbacks.size());
       

        Test.stopTest();
    }
    
   
}