@isTest
global class ServiceAppointmentSchedulerTest {
    
    @testSetup
    static void setupData() {
        // Create Account (Dealer)
        Account dealerAcc = new Account(Name = 'Dealer Test');
        insert dealerAcc;

        // Create Customer Account and Contact (Current Owner)
        Account customerAcc = new Account(Name = 'Customer Test', Type = 'Customer');
        insert customerAcc;

        // Create CRE Contact under Dealer
        Account acc = new Account(Name = 'Partner');
        insert acc;
        
        User owner;
        try {
            owner = [SELECT Id, UserRoleId FROM User WHERE Id = :acc.OwnerId LIMIT 1];
        } catch (Exception e) {
            System.debug('No owner found for account: ' + acc.Id);
            return;
        }
        
        if (owner != null && owner.UserRoleId == null) {
            UserRole ownerRole = new UserRole(Name = 'Account Owner Role');
            insert ownerRole;
            owner.UserRoleId = ownerRole.Id;
            update owner;
        }
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Phone = '9999999998',
            AccountId = acc.Id,
            Primary_Contact__c = true,
            Designation__c = 'CRE'  // ADDED THIS LINE - CRITICAL FIX
        );
        insert testContact;
        
        Test.startTest();

        UserRole role = new UserRole(Name = 'Partner User Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager (Partner)'];
        User partnerUser = new User(
            LastName = 'Partner',
            Email = 'partner@example.com',
            Username = 'partneruser@example.com' + System.currentTimeMillis(),
            ProfileId = p.Id,
            Alias = 'partn',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = testContact.Id,
            UserRoleId = role.Id,
            IsActive = true
        );
        insert partnerUser;

        // Create Vehicle record - CHANGED TO Vehicle__c
        Vehicle vehicle = new Vehicle(
            Name = 'Test Vehicle',
            Account__c = dealerAcc.Id,
            Dealer__c = dealerAcc.Id,
            CurrentOwnerId = customerAcc.Id
        );
        insert vehicle;

        // Create WorkOrder for Vehicle
        WorkOrder wo = new WorkOrder(
            Subject = 'Last Work Order',
            Vehicle__c = vehicle.Id,
            OwnerId = partnerUser.Id
        );
        insert wo;

        // Create AssetMilestone record - CHANGED MilestoneDate to be within range
        list<AssetMilestone> milestonlist = new List<AssetMilestone>();
        AssetMilestone milestone = new AssetMilestone(
            Name = 'Test Milestone',
            MilestoneDate = System.today().addDays(15), // CHANGED to be within 20-day range
            Stage = 'Tentative',
            VehicleId = vehicle.Id
            // REMOVED AssetId as it's not required in batch query
        );
        insert milestone;
        milestonlist.add(milestone);
        
        Test.stopTest();
    }
    
    static testMethod void testBatchExecution() {
        // Verify test data exists before batch execution
        List<AssetMilestone> milestones = [SELECT Id, Name, MilestoneDate, Stage, VehicleId, 
                                          Vehicle.Dealer__c, Vehicle.CurrentOwnerId 
                                          FROM AssetMilestone 
                                          WHERE Stage = 'Tentative'];
        System.debug('Found milestones: ' + milestones.size());
        
        Test.startTest();
        Database.executeBatch(new ServiceAppointmentScheduler(), 50);
        Test.stopTest();
        
        // Verify results
        List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment];
        System.assert(appointments.size() > 0, 'Service Appointments should be created');
    }
    
    static testMethod void testSchedulableExecution() {
        Test.startTest();
        System.schedule('Test Scheduler Job', '0 0 12 * * ?', new ServiceAppointmentScheduler());
        Test.stopTest();
    }
}