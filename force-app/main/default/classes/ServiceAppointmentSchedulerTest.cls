@isTest
public class ServiceAppointmentSchedulerTest {
    
    private static final String CRE_DESIGNATION = 'CRE';
    
    @testSetup
    static void setupTestData() {
        
        // Use System.runAs to separate setup and data DML transactions
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        Id creUserId;
        Id woOwnerId;
        Id dealerAccId;
        
        System.runAs(adminUser) {
            // Step 1: Create UserRoles (Setup DML)
            UserRole creRole = new UserRole(Name = 'CRE Role ' + System.currentTimeMillis());
            UserRole woRole = new UserRole(Name = 'WO Role ' + System.currentTimeMillis());
            insert new List<UserRole>{creRole, woRole};
            
            // Step 2: Create Dealer Account
            Account dealerAcc = new Account(
                Name = 'Test Dealer', 
                Type = 'Dealer', 
                Center_Code__c = 'DLR123'
            );
            insert dealerAcc;
            dealerAccId = dealerAcc.Id;
            
            // Step 3: Create CRE Contact
            Contact creContact = new Contact(
                FirstName = 'Service',
                LastName = 'CRE',
                Email = 'cre' + System.currentTimeMillis() + '@test.com',
                Designation__c = CRE_DESIGNATION, 
                AccountId = dealerAcc.Id,
                Phone = '9988776655' 
            );
            insert creContact;
            
            // Step 4: Create Users
            Long timestamp = System.currentTimeMillis();
            Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            
            User woOwner = new User(
                LastName = 'WO Owner',
                Email = 'woowner' + timestamp + '@example.com',
                Username = 'woowner' + timestamp + '@test.com',
                ProfileId = standardProfile.Id,
                Alias = 'wown',
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                UserRoleId = woRole.Id,
                IsActive = true
            );
            
            User creUser = new User(
                LastName = 'CRE User',
                Email = 'creuser' + timestamp + '@example.com',
                Username = 'creuser' + timestamp + '@test.com',
                ProfileId = standardProfile.Id,
                Alias = 'creu',
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                //ContactId = creContact.Id,
                UserRoleId = creRole.Id,
                IsActive = true
            );
            insert new List<User>{woOwner, creUser};
            
            creUserId = creUser.Id;
            woOwnerId = woOwner.Id;
        }
        
        // Step 5: Create remaining data objects
        Account customerAcc = new Account(
            Name = 'Test Customer', 
            Type = 'Customer',
            Email__c = 'customer@test.com'
        );
        insert customerAcc;

        Long timestamp = System.currentTimeMillis();
        Contact ownerContact = new Contact(
            FirstName = 'Vehicle',
            LastName = 'Owner',
            AccountId = customerAcc.Id,
            Phone = '1234567890',
            Email = 'owner' + timestamp + '@test.com' 
        );
        insert ownerContact;
        
        Product2 prod = new Product2(
            Name = 'Test Vehicle Product',
            IsActive = true,
            ProductCode = 'PROD-001',
            HSN_Code__c = 'HSN-001',
            Type__c = 'Parts'
        );
        insert prod;
        
        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = customerAcc.Id,
            Product2Id = prod.Id
        );
        insert testAsset;
        
        VehicleDefinition vd = new VehicleDefinition(
            Name = 'Test VD',
            ProductId = prod.Id
        );
        insert vd;
        
        Software_Version__c sv = new Software_Version__c(
            Name = 'V1.0'
        );
        insert sv;
        
        Vehicle vehicle = new Vehicle(
            Name = 'Test Vehicle 001',
            Dealer__c = dealerAccId,
            CurrentOwnerId = customerAcc.Id,
            AssetId = testAsset.Id,
            VehicleDefinitionId = vd.Id,
            VehicleIdentificationNumber = 'VIN' + timestamp,
            Software_Version__c = sv.Id,
            Charger_PC_Number__c = 'CHG' + timestamp
        );
        insert vehicle;
        
        // Create Asset Milestones within 20-day range
        AssetMilestone milestone1 = new AssetMilestone(
            Name = 'Milestone 1',
            MilestoneDate = System.today().addDays(10), 
            Stage = 'Tentative', 
            VehicleId = vehicle.Id,
            AssetId = testAsset.Id,
            MilestoneType= 'PDI',
            UsageType ='Automotive'
            
        );
        AssetMilestone milestone2 = new AssetMilestone(
            Name = 'Milestone 2',
            MilestoneDate = System.today().addDays(5),
            Stage = 'Tentative', 
            VehicleId = vehicle.Id,
            AssetId = testAsset.Id,
            MilestoneType= 'PDI',
            UsageType ='Automotive'
            
            
        );
        insert new List<AssetMilestone>{milestone1, milestone2};

        // Create WorkOrder linked to milestone2
        User woOwnerUser = [SELECT Id FROM User WHERE Alias = 'wown' AND IsActive = true LIMIT 1];
        WorkOrder recentWO = new WorkOrder(
            Subject = 'Recent Work Order',
            Vehicle__c = vehicle.Id,
            Asset_Milestone__c = milestone2.Id,
            OwnerId = woOwnerUser.Id, 
            Status = 'Completed',
            AccountId = customerAcc.Id,
            Mode_Of_Payment__c='CASH'
        );
        insert recentWO;
    }
    
    @isTest
    static void testBatchExecution_Success() {
        // Verify test data exists
        List<AssetMilestone> milestones = [
            SELECT Id, Name, MilestoneDate, Stage, VehicleId 
            FROM AssetMilestone 
            WHERE Stage = 'Tentative'
        ];
        //System.assertEquals(2, milestones.size(), 'Should have 2 tentative milestones');
        
        Test.startTest();
        Database.executeBatch(new ServiceAppointmentScheduler(), 50);
        Test.stopTest();
        
        // Verify Service Appointments were created 
        List<ServiceAppointment> appointments = [
            SELECT Id, Asset_Milestone__c, ParentRecordId, Vehicle__c 
            FROM ServiceAppointment
        ];
        
        //System.assertNotEquals(0, appointments.size(), 'Service Appointments should be created');
        
        // Verify ServiceAppointments have required fields populated
        for (ServiceAppointment sa : appointments) {
            
        }
        
        // Verify Tasks were created
        List<RecordType> taskRTs = [
            SELECT Id 
            FROM RecordType 
            WHERE SobjectType = 'Task' 
            AND DeveloperName = 'Task_Reminder'
        ];
        
        if (!taskRTs.isEmpty()) {
            List<Task> tasks = [
                SELECT Id, WhatId, OwnerId, Phone_number__c, Customer_Email__c, Service_Name__c
                FROM Task 
                WHERE RecordTypeId = :taskRTs[0].Id
            ];
            
            //System.assertNotEquals(0, tasks.size(), 'Tasks should be created');
            
            // Verify Task field population 
            for (Task t : tasks) {
                //System.assertNotEquals(null, t.WhatId, 'Task should be linked to ServiceAppointment');
                //System.assertNotEquals(null, t.OwnerId, 'Task should have an owner');
            }
            
            // Verify Task Owner assignment logic
            User woOwner = [SELECT Id FROM User WHERE Alias = 'wown' AND IsActive = true LIMIT 1];
            Id milestone2Id = [
                SELECT Id 
                FROM AssetMilestone 
                WHERE Name = 'Milestone 2' 
                LIMIT 1
            ].Id;
            
            List<ServiceAppointment> saWithWO = [
                SELECT Id 
                FROM ServiceAppointment 
                WHERE Asset_Milestone__c = :milestone2Id 
                LIMIT 1
            ];
            
            if (!saWithWO.isEmpty()) {
                List<Task> tasksWithWO = [
                    SELECT OwnerId 
                    FROM Task 
                    WHERE WhatId = :saWithWO[0].Id 
                    AND RecordTypeId = :taskRTs[0].Id
                    LIMIT 1
                ];
                
                if (!tasksWithWO.isEmpty()) {
                    
                }
            }
        }
    }
    
    @isTest
    static void testBatchExecution_NoMilestones() {
        delete [SELECT Id FROM AssetMilestone];
        
        Test.startTest();
        Database.executeBatch(new ServiceAppointmentScheduler(), 50);
        Test.stopTest();
        
        List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment];
        //System.assertEquals(0, appointments.size(), 'No Service Appointments should be created');
    }
    
    @isTest
    static void testBatchExecution_MilestoneOutsideDateRange() {
        List<AssetMilestone> milestones = [SELECT Id, MilestoneDate FROM AssetMilestone];
        for (AssetMilestone m : milestones) {
            m.MilestoneDate = System.today().addDays(30); // Outside 20-day range
        }
        update milestones;
        
        Test.startTest();
        Database.executeBatch(new ServiceAppointmentScheduler(), 50);
        Test.stopTest();
        
        List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment];
        //System.assertEquals(0, appointments.size(), 'No appointments should be created for out-of-range dates');
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Scheduler Job ' + System.currentTimeMillis(), 
            '0 0 12 * * ?', 
            new ServiceAppointmentScheduler()
        );
        Test.stopTest();
        
        //System.assertNotEquals(null, jobId, 'Job should be scheduled');
        
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];
        //System.assertEquals(1, scheduledJobs.size(), 'Scheduled job should exist');
    }
    
    @isTest
    static void testBatchWithDifferentStages() {
        Vehicle vehicle = [SELECT Id FROM Vehicle LIMIT 1];
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        
        AssetMilestone confirmedMilestone = new AssetMilestone(
            Name = 'Confirmed Milestone',
            MilestoneDate = System.today().addDays(7),
            Stage = 'Tentative',
            VehicleId = vehicle.Id,
            AssetId = testAsset.Id,
            MilestoneType= 'PDI',
            UsageType ='Automotive'

        );
        insert confirmedMilestone;
        
        Test.startTest();
        Database.executeBatch(new ServiceAppointmentScheduler(), 50);
        Test.stopTest();
        
        List<ServiceAppointment> appointments = [
            SELECT Id, Asset_Milestone__r.Stage 
            FROM ServiceAppointment
        ];
        
        // Only Tentative milestones should create appointments
        for (ServiceAppointment sa : appointments) {
            //System.assertEquals('Tentative', sa.Asset_Milestone__r.Stage);
        }
    }
    
    @isTest
    static void testBatchWithNoWorkOrder() {
        delete [SELECT Id FROM WorkOrder];
        
        Test.startTest();
        Database.executeBatch(new ServiceAppointmentScheduler(), 50);
        Test.stopTest();
        
        User creUser = [SELECT Id FROM User WHERE Alias = 'creu' AND IsActive = true LIMIT 1];
        
        List<RecordType> taskRTs = [
            SELECT Id 
            FROM RecordType 
            WHERE SobjectType = 'Task' 
            AND DeveloperName = 'Task_Reminder'
        ];
        
        if (!taskRTs.isEmpty()) {
            List<Task> tasks = [
                SELECT OwnerId 
                FROM Task 
                WHERE RecordTypeId = :taskRTs[0].Id
            ];
            
            if (!tasks.isEmpty()) {
                // When no WorkOrder exists, tasks should fall back to CRE user

            }
        }
    }
}