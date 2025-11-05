@isTest
public with sharing class AppointmentFormController_Test {
    
    @isTest
    public static void testGetServiceCenters() {

        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Type = 'Service Center',
            Center_Code__c = '292001',
            Email__c = 'test@gmail.com',
            Phone = '9089786756');
        insert acc;

        // --------------------------- TESTING getServiceCenters() --------------------------- //
        AppointmentFormController.getServiceCenters();
        
          Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka');
        insert testLocation;         
        // Create Contact
        Contact con = new Contact(
            AccountId = acc.Id,    
            FirstName = 'Joey', 
            LastName = 'Shaul',
           
            Location__c=testLocation.Id,Role_Type__c='Sales',
            Phone = '8967452312');
        insert con;

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product', 
            IsActive = true, 
            ProductCode = 'PROd-39784',
            HSN_Code__c = 'HSN-384',
            Type__c = 'Parts');
        insert prod;

        // Create Asset
        Asset ass = new Asset(Name = 'River NX-299', AccountId = acc.Id, Product2Id = prod.Id);
        insert ass;

        // Create Vehicle Defination
        VehicleDefinition vd = new VehicleDefinition();
        vd.Name = 'VD Name 1';
        vd.ProductId = prod.Id;
        insert vd;

        // Create Software_Version__c
        Software_Version__c sv = new Software_Version__c(Name = 'V1.29');
        insert sv;

        // Create Vehicle
        Vehicle v = new Vehicle();
        v.Name = 'River NX-299';
        v.AssetId = ass.Id;
        v.VehicleDefinitionId = vd.Id;
        v.VehicleIdentificationNumber = '83493HHHGBBB';
        v.Software_Version__c = sv.Id;
        v.Charger_PC_Number__c = 'CHR001';
        v.CurrentOwnerId = acc.Id;
        insert v;

        // Create WorkOrders
        WorkOrder wo1 = new WorkOrder(
            AccountId = acc.Id,
            ContactId = con.Id,
            Vehicle__c = v.Id,
            Status = 'Completed',
            Mode_Of_Payment__c = 'Cash',
            Completed_Date__c = System.now().addDays(-4),
            Subject = 'Old Completed WO'
        );
        insert wo1;

        Post_Service_Feedback__c psf = new Post_Service_Feedback__c();
        psf.Job_Card__c = wo1.Id;
        psf.Status__c = 'Pending';
        insert psf;

        Ticket__c newTicket = new Ticket__c(
            Post_Service_Feedback__c = psf.Id,
            Job_Card__c = psf.Job_card__c
        );
        insert newTicket;

        // --------------------------- TESTING getVehicleOwnerContacts() --------------------------- //
        String contactPhone1 = AppointmentFormController.getVehicleOwnerContacts(newTicket.Id);
    
        // Testing If Vehicle is Null
        // Create WorkOrders
        WorkOrder wo2 = new WorkOrder(
            AccountId = acc.Id,
            ContactId = con.Id,
            Status = 'Completed',
              Mode_Of_Payment__c = 'Cash',
            Completed_Date__c = System.now().addDays(-4),
            Subject = 'Old Completed WO'
        );
        insert wo2;

        Post_Service_Feedback__c psf2 = new Post_Service_Feedback__c();
        psf2.Job_Card__c = wo2.Id;
        psf2.Status__c = 'Pending';
        insert psf2;

        Ticket__c newTicket2 = new Ticket__c(
            Post_Service_Feedback__c = psf2.Id,
            Job_Card__c = psf2.Job_card__c
        );
        insert newTicket2;
        
        // Testing getVehicleOwnerContacts()
        String noContactNoFoundMsg = AppointmentFormController.getVehicleOwnerContacts(newTicket2.Id);
        System.assertEquals('No Contact Number Found', noContactNoFoundMsg);


        // --------------------------- TESTING getvehicleRecord() --------------------------- //
        
        // Create Account
        Account acc1 = new Account(
            Name = 'Test Account',
            Type = 'Customer',
            Center_Code__c = '292001',
            Email__c = 'test@gmail.com',
            Phone = '9089786756');
        insert acc1;

        // Create Contact
        Contact con1 = new Contact(
            AccountId = acc1.Id,    
            FirstName = 'Joel', 
            LastName = 'Shaul',
            Phone = '8967452312');
        insert con1;

        // Create Product
        Product2 prod1 = new Product2(
            Name = 'Tyres Product', 
            IsActive = true, 
            ProductCode = 'PROd-39784',
            HSN_Code__c = 'HSN-384',
            Type__c = 'Parts');
        insert prod1;

        // Create Asset
        Asset ass1 = new Asset(Name = 'River NX-400', AccountId = acc1.Id, Product2Id = prod1.Id);
        insert ass1;

        // Create Vehicle Defination
        VehicleDefinition vd1 = new VehicleDefinition();
        vd1.Name = 'VD Name 1.1';
        vd1.ProductId = prod1.Id;
        insert vd1;

        // Create Software_Version__c
        Software_Version__c sv1 = new Software_Version__c(Name = 'V1.29');
        insert sv1;

        // Create Vehicle
        Vehicle v1 = new Vehicle();
        v1.Name = 'River NX-299';
        v1.AssetId = ass1.Id;
        v1.VehicleDefinitionId = vd1.Id;
        v1.VehicleIdentificationNumber = '342ADD';
        v1.Software_Version__c = sv1.Id;
        v1.Charger_PC_Number__c = 'CHR001';
        v1.CurrentOwnerId = acc1.Id;
        v1.VehicleRegistrationNumber = '342ADD';
        insert v1;

        // Create WorkOrders
        WorkOrder wo3 = new WorkOrder(
            AccountId = acc1.Id,
            ContactId = con1.Id,
            Vehicle__c = v1.Id,
            Status = 'Completed',
             Mode_Of_Payment__c = 'Cash',
            Completed_Date__c = System.now().addDays(-4),
            Subject = 'Old Completed WO'
        );
        insert wo3;

        Post_Service_Feedback__c psf3 = new Post_Service_Feedback__c();
        psf3.Job_Card__c = wo3.Id;
        psf3.Status__c = 'Pending';
        insert psf3;

        Ticket__c newTicket3 = new Ticket__c(
            Post_Service_Feedback__c = psf3.Id,
            Job_Card__c = psf3.Job_card__c,
            Vehicle__c = v1.Id
        );
        insert newTicket3;
        
        Task ticketTask = new Task();
        ticketTask.Subject = 'ti -';
        ticketTask.Status = 'Pending';
        ticketTask.Priority = 'High';
        ticketTask.ActivityDate = Date.today();
        ticketTask.WhatId = newTicket3.Id;
        insert ticketTask;

        // Tested by passing Ticket Task Id
        AppointmentFormController.getvehicleRecord(ticketTask.Id);  
        
        // Tested by passing Service Appointment Id
        Account acc2 = new Account(
            Name = 'Test Account',
            Type = 'Customer',
            Center_Code__c = '292001',
            Email__c = 'test@gmail.com',
            Phone = '9083786756');
        insert acc2;

        Contact con2 = new Contact(
            AccountId = acc2.Id,    
            FirstName = 'Joey', 
            LastName = 'Shaul',
            Phone = '9967452312');
        insert con2;

        ServiceAppointment sa = new ServiceAppointment(
            ContactId = con2.Id,
            Vehicle__c = v1.Id,
            ParentRecordId = acc2.Id
        );
        insert sa;

        AppointmentFormController.getvehicleRecord(sa.Id);  

        // Tested by passing Unsupported Object
        AppointmentFormController.getvehicleRecord(acc.Id);  

        // --------------------------- TESTING createAppointment() --------------------------- //
    
        AppointmentFormController.createAppointment(newTicket3.Id, acc.Id, 'VRN900', System.today(), '9089786756');
    
        // --------------------------- TESTING createAppointmentforServiceAppointment() --------------------------- //
        
        Appointment_Slot__c appSlot = new Appointment_Slot__c(
            Appointment_Slot_Date__c = System.today().addDays(1),
            Slot_Duration_Minute__c = 30,
            Status__c = 'Published',
            Service_Center__c = acc.Id
        );
        insert appSlot;

        Appointment_Slot_Item__c appSlotItem = new Appointment_Slot_Item__c(
            Appointment_Slot__c = appSlot.Id
        );
        insert appSlotItem;

        Appointment__c appoint = new Appointment__c(
            VRN__c = 'KLORT879',
            Appointment_Date__c = System.today()
        );
        insert appoint;

        // --------------------------- TESTING getAvailableSlots() --------------------------- //
        AppointmentFormController.getAvailableSlots(appoint.Id);

        // --------------------------- TESTING AllotBookingSlot() --------------------------- //
        Task tsk = new Task(
        	Subject = 'Appointment Reminder',
            ActivityDate = System.today(),
            WhatId = appoint.Id,
            Status = 'Not Started'
        );
        insert tsk;
        
        AppointmentFormController.AllotBookingSlot(
            appoint.Id,
            appSlot.Id,
            appSlotItem.Id
        );

        // --------------------------- TESTING getSlotItems() --------------------------- //
        Appointment_Slot__c appSlot1 = new Appointment_Slot__c(
            Appointment_Slot_Date__c = System.today().addDays(1),
            Slot_Duration_Minute__c = 30,
            Status__c = 'Published',
            Service_Center__c = acc.Id
        );
       // insert appSlot1;

       
    }

    
    @isTest
    private static void testCreateAppointmentForServiceAppointment() {
        
        Account acc = new Account(
            Name = 'Test Account',
            Type = 'Service Center',
            Center_Code__c = '292001',
            Email__c = 'test@gmail.com',
            Phone = '9089786756');
        insert acc;

        Account acc1 = new Account(
            Name = 'Test Account',
            Type = 'Customer',
            Center_Code__c = '292001',
            Email__c = 'test@gmail.com',
            Phone = '9089786756');
        insert acc1;

        Contact con = new Contact(
            AccountId = acc1.Id, 
            FirstName = 'Joey', 
            LastName = 'Shaul',
            Phone = '9967452312');
        insert con;
        
        // Create Product
        Product2 prod1 = new Product2(
            Name = 'Tyres Product', 
            IsActive = true, 
            ProductCode = 'PROd-39784',
            HSN_Code__c = 'HSN-384',
            Type__c = 'Parts');
        insert prod1;

        // Create Asset
        Asset ass1 = new Asset(Name = 'River NX-400', AccountId = acc.Id, Product2Id = prod1.Id);
        insert ass1;
        
        
        
        // Create Vehicle Defination
        VehicleDefinition vd1 = new VehicleDefinition();
        vd1.Name = 'VD Name 1.1';
        vd1.ProductId = prod1.Id;
        insert vd1;

        // Create Software_Version__c
        Software_Version__c sv1 = new Software_Version__c(Name = 'V1.29');
        insert sv1;

        // Create Vehicle
        Vehicle v1 = new Vehicle();
        v1.Name = 'River NX-299';
        v1.AssetId = ass1.Id;
        v1.VehicleDefinitionId = vd1.Id;
        v1.VehicleIdentificationNumber = '342ADD';
        v1.Software_Version__c = sv1.Id;
        v1.Charger_PC_Number__c = 'CHR001';
        v1.CurrentOwnerId = acc1.Id;
        v1.VehicleRegistrationNumber = '342ADD';
        insert v1;
        
        
        
         AssetMilestone completedMilestone = new AssetMilestone();
        completedMilestone.Name = 'Completed Milestone';
        completedMilestone.AssetId = ass1.Id;
        completedMilestone.UsageType = 'Automotive';
        completedMilestone.MilestoneDate = System.today().addDays(1);
        completedMilestone.MilestoneType = 'PDI';
        completedMilestone.Stage = 'Active';
        completedMilestone.VehicleId =v1.Id;
        insert completedMilestone;
        
        
        completedMilestone.MilestoneDate = System.today().addDays(2);
        update completedMilestone;
        

        ServiceAppointment sa = new ServiceAppointment(
            ContactId = con.Id,
            Vehicle__c = v1.Id,
            ParentRecordId = acc.Id,
            Asset_Milestone__c = completedMilestone.id
        );
        insert sa;

        Appointment__c appoint = new Appointment__c(
            VRN__c = 'KLORT879',
            Appointment_Date__c = System.today()
        );
        insert appoint;

        Appointment_Slot__c slot = new Appointment_Slot__c(
            Appointment_Slot_Date__c = System.today().addDays(1),
            Slot_Duration_Minute__c = 30,
            Status__c = 'Published',
            Service_Center__c = acc.Id
        );
        insert slot;

        Appointment_Slot_Item__c slotItem = new Appointment_Slot_Item__c(
            Appointment_Slot__c = slot.Id
        );
        insert slotItem;
        

        // 6. Create a related Task to ServiceAppointment
        Task task = new Task(
            WhatId = sa.Id,
            Subject = 'Initial Contact',
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert task;

        
        // 7. Call the method
        Test.startTest();
        String newAppId = AppointmentFormController.createAppointmentforServiceAppointment(
            sa.Id,
            acc.Id,
            v1.VehicleRegistrationNumber,
            Date.today().addDays(3),
            '9876543210',
            'PMS',
            slot.Id,
            slotItem.Id,
            'Same issue is coming again - appointment description'
        );
        
        String newAppId1 = AppointmentFormController.createAppointmentforServiceAppointment(
            task.Id,
            acc.Id,
            v1.VehicleRegistrationNumber,
            Date.today().addDays(3),
            '9876543210',
            'PMS',
            slot.Id,
            slotItem.Id,
            'Same issue is coming again - appointment description'
        );
        Test.stopTest();        
    }
    @isTest
    static void testGetPicklistValues_Success() {
        // Call the method with a standard object and picklist field
        // Here, we use 'Case' and 'Status' because 'Status' is a standard picklist field
        List<String> values = AppointmentFormController.getPicklistValues('Case', 'Status');
    }

    @isTest
    static void testGetPicklistValues_InvalidField() {
        // Case where field doesn't exist
        List<String> values = AppointmentFormController.getPicklistValues('Case', 'InvalidField__c');
    }

    @isTest
    static void testGetPicklistValues_InvalidObject() {
        // Case where object doesn't exist
        List<String> values = AppointmentFormController.getPicklistValues('InvalidObject__c', 'Status');
    }

    @isTest
    static void testGetPicklistValues_NonPicklistField() {
        // Case where field exists but is not a picklist (e.g., Subject)
        List<String> values = AppointmentFormController.getPicklistValues('Case', 'Subject');
    }

    @isTest
    static void testGetPicklistValues_Exception() {
        // Force an exception by passing null values
        List<String> values = AppointmentFormController.getPicklistValues(null, null);
    }
    
    @isTest
    private static void testGetCurrentServiceCenter(){

      //  Vehicle testVehicle = [SELECT Id, CurrentOwnerId, VehicleIdentificationNumber, VehicleRegistrationNumber FROM Vehicle WHERE PDI_Status_Pass__c = true LIMIT 1];
      // ServiceResource sr = [SELECT Id, Name FROM ServiceResource LIMIT 1];
        
        Account ServiceCenter = new Account(Name='service center1', Type = 'Service Center', Phone = '7890898989', Center_Code__c='asde4r');
        Insert ServiceCenter;
        
         Account acc = new Account(
            Name = 'Test Account',
            Type = 'Service Center',
            Center_Code__c = '292001',
            Email__c = 'test@gmail.com',
            Phone = '9089786756');
        insert acc;
        
        Schema.Location l1 = new Schema.Location(); 
        l1.Name = 'Warehouse 1';
        l1.LocationType = 'Secondary';
        l1.IsInventoryLocation = true;
        // l1.Account__c=testAccount.Id;
        l1.Price_Book__c= Test.getStandardPricebookId();
        insert l1;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Phone = '9999999998',
            AccountId = acc.Id,
            Primary_Contact__c = true,
            Role_Type__c='Service',
            Location__c=l1.Id
        );
        insert testContact;
         UserRole role = [SELECT Id FROM UserRole LIMIT 1];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager (Partner)' LIMIT 1];
        User standardUser = new User(
            LastName = 'Standard',
            Email = 'standard@example.com',
            Username = 'standarduser@example.com' + System.currentTimeMillis(),
            ProfileId = p.Id,
            Alias = 'stand',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = testContact.Id,
            IsActive = true,
            UserRoleId = role.Id
        );
        //insert standardUser;

        //User u = [SELECT Id,ContactId,Contact.Account.Type FROM User WHERE ContactId !=null AND Contact.Account.Type = 'Service Center' LIMIT 1];

//UserRole role = [SELECT Id,DeveloperName FROM UserRole WHERE DeveloperName='RiverMobilityPrivateLimitedJPNagarPartnerUser' LIMIT 1];
          
        System.runAs(standardUser) {
            Test.startTest();

            // Call the method
			AppointmentFormController.getCurrentServiceCenter();

            Test.stopTest();
        }
    }       
	
}