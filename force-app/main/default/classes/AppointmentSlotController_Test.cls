@isTest
private class AppointmentSlotController_Test {

    @testSetup
    static void setupTestData() {
        // Create Service Center Account
        Account serviceCenter = new Account(Name = 'Test Service Center');
        insert serviceCenter;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = serviceCenter.Id,
            Phone = '7897897890',
            Primary_Contact__c = true
        );
        insert con;

        // Create few Service Bays
        List<Service_Bay__c> bays = new List<Service_Bay__c>();
        for (Integer i = 0; i < 3; i++) {
            bays.add(new Service_Bay__c(
                Service_Center__c = serviceCenter.Id,
                Is_Active__c = true,
                Vehicle_Capacity__c = 2
            ));
        }
        insert bays;

        // Create Appointment Slot
        Appointment_Slot__c appSlot = new Appointment_Slot__c(
            Service_Center__c = serviceCenter.Id,
            Appointment_Slot_Date__c = System.today(),
            Start_Slot_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Slot_Time__c = Time.newInstance(17, 0, 0, 0),
            Slot_Duration_Minute__c = 60,
            Status__c = 'Published'
        );
        insert appSlot;

        // Related Slot Items
        List<Appointment_Slot_Item__c> items = new List<Appointment_Slot_Item__c>();
        for (Service_Bay__c bay : bays) {
            items.add(new Appointment_Slot_Item__c(
                Appointment_Slot__c = appSlot.Id,
                Service_Bay__c = bay.Id,
                Start_Time__c = Time.newInstance(9, 0, 0, 0),
                End_Time__c = Time.newInstance(10, 0, 0, 0),
                Booking_Status__c = 'Available'
            ));
        }
        insert items;
    }

    // Helper method to create test user safely
    private static User createTestUser(Id contactId) {
        
         UserRole role = new UserRole(Name = 'Partner User Role');
    insert role;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager (Partner)' LIMIT 1];
        return new User(
            FirstName = 'Slot',
            LastName = 'User',
            Alias = 'slotu',
            Email = 'slotuser@example.com',
            Username = 'slotuser' + System.currentTimeMillis() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
             UserRoleId = role.Id,
            ContactId = contactId
        );
    }

    @isTest
    static void testGetServiceBayCount() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Service Center' LIMIT 1];
        Test.startTest();
        Integer bayCount = AppointmentSlotController.getServiceBayCount(acc.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetAppointmentSlotMethod() {
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
        Primary_Contact__c = true
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

        System.runAs(partnerUser) {
            Test.startTest();
            List<Appointment_Slot_Item__c> list1 = AppointmentSlotController.getAppointmentSLot('Available');
            List<Appointment_Slot_Item__c> list2 = AppointmentSlotController.getAppointmentSLot('Booked');
            Test.stopTest();
        }
    }

    @isTest
    static void testGetCurrentContactServiceCenter() {
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
        Primary_Contact__c = true
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


        System.runAs(partnerUser) {
            Test.startTest();
            AppointmentSlotController.serviceCenterAppointmentWrapper wrap = AppointmentSlotController.getCurrentContactServiceCenter();
            Test.stopTest();
        }
    }

    @isTest
    static void testGetRemainingBayCountForRange() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Service Center' LIMIT 1];
        Date startD = System.today();
        Date endD = System.today().addDays(1);
        Test.startTest();
        Integer remain = AppointmentSlotController.getRemainingBayCountForRange(acc.Id, startD, endD);
        Test.stopTest();
    }

    @isTest
    static void testCreateSlotMethod() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Service Center' LIMIT 1];
        Date startD = System.today().addDays(1);
        Date endD = System.today().addDays(2);

        Test.startTest();
        Id newSlotId = AppointmentSlotController.createSlot(
            acc.Id,
            startD,
            endD,
            '09:00',
            '11:00',
            2,
            30
        );
        Test.stopTest();
    }

    @isTest
    static void testCreateSlotWithException() {
        Test.startTest();
        Id result = AppointmentSlotController.createSlot(
            null,
            System.today(),
            System.today(),
            '09:00',
            '10:00',
            2,
            30
        );
        Test.stopTest();
    }

    @isTest
    static void testGetRemainingBayCount_Exception() {
        Test.startTest();
        Integer res = AppointmentSlotController.getRemainingBayCountForRange(null, System.today(), System.today());
        Test.stopTest();
    }
}