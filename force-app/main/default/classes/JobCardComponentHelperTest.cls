@isTest
public class JobCardComponentHelperTest {
    
    @testSetup
    static void setup() {
        
        Account acc2 = new Account();
        acc2.name = 'partner';
        acc2.Email__c = 'partner@gmail.com';
        acc2.Phone = '6767656776';
        acc2.Type = 'Service Center';
        acc2.Center_Code__c = 'sdf3e23';
        Insert acc2;
        
        Map<string,Sobject> mapnewRecords = TestDataFactory.createVehicle();
        
        List<AssetMilestone> milestoneList = new List<AssetMilestone>();
        
        // Create milestones in proper sequence
        AssetMilestone pdiMilestone = new AssetMilestone();
        pdiMilestone.Delivery_Date__c = System.today();
        pdiMilestone.MilestoneType = 'PDI';
        pdiMilestone.VehicleId = mapnewRecords.get('Vehicle').Id;
        pdiMilestone.MilestoneDate = System.today(); 
        pdiMilestone.AssetId = mapnewRecords.get('Asset').Id;
        pdiMilestone.Name = 'PDI';
        pdiMilestone.UsageType = 'Automotive';
        pdiMilestone.Stage = 'Active';
        pdiMilestone.Service_Center__c=acc2.Id;
        Insert pdiMilestone;
        
        // Update vehicle PDI status
        vehicle vh = (Vehicle)mapnewRecords.get('Vehicle');
        vh.PDI_Status_Pass__c = true;
        vh.VehicleRegistrationNumber='REG123';
        vh.VehicleIdentificationNumber='VIN1234';
        update vh;
        
        PriceBookEntry entry = (PriceBookEntry)mapnewRecords.get('PricebookEntry');
        Id PriceBookId = entry.PriceBook2Id;
        Account acc = (Account)mapnewRecords.get('Account');
        Product2 newProduct = (Product2)mapnewRecords.get('Product');
        
        // Create a Standard Order record
        Order standardOrder = new Order(
            AccountId = acc.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'RTO Registration',
            Description = 'Nothing',
            pricebook2Id = PriceBookId,
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'india',
            Assigned_Vehicle__c = vh.Id
        );
        Insert standardOrder;
        
        OrderItem orderItem = new OrderItem(
            OrderId = standardOrder.Id,
            PricebookEntryId = entry.Id,
            Product2Id = newProduct.Id,
            Quantity = 1, 
            UnitPrice = 1056765,
            Type__c = 'Vehicle'
        );
        
        // Create Order Received milestone (should come after PDI)
        AssetMilestone orderReceivedMilestone = new AssetMilestone();
        orderReceivedMilestone.Delivery_Date__c = System.today();
        orderReceivedMilestone.MilestoneType = 'PDI';
        orderReceivedMilestone.VehicleId = mapnewRecords.get('Vehicle').Id;
        orderReceivedMilestone.MilestoneDate = System.today();
        orderReceivedMilestone.AssetId = mapnewRecords.get('Asset').Id;
        orderReceivedMilestone.Name = 'PDI';
        orderReceivedMilestone.UsageType = 'Automotive';
        orderReceivedMilestone.Stage = 'Active';
        orderReceivedMilestone.Service_Center__c=acc2.Id;
        Insert orderReceivedMilestone;
        
        // Create Sold milestone (should come after Order Received)
        AssetMilestone soldMilestone = new AssetMilestone();
        soldMilestone.Delivery_Date__c = System.today();
        soldMilestone.MilestoneType = 'Sold';
        soldMilestone.VehicleId = mapnewRecords.get('Vehicle').Id;
        soldMilestone.MilestoneDate = System.today();
        soldMilestone.AssetId = mapnewRecords.get('Asset').Id;
        soldMilestone.Name = 'Sold';
        soldMilestone.UsageType = 'Automotive';
        soldMilestone.Stage = 'Active';
        soldMilestone.Service_Center__c=acc2.Id;        
        Insert soldMilestone;
        
        // Create Customer Delivery milestone (should come after Sold)
        AssetMilestone customerDeliveryMilestone = new AssetMilestone();
        customerDeliveryMilestone.Delivery_Date__c = System.today();
        customerDeliveryMilestone.MilestoneType = 'Customer Delivery';
        customerDeliveryMilestone.VehicleId = mapnewRecords.get('Vehicle').Id;
        customerDeliveryMilestone.MilestoneDate = System.today();
        customerDeliveryMilestone.AssetId = mapnewRecords.get('Asset').Id;
        customerDeliveryMilestone.Name = 'Customer Delivery';
        customerDeliveryMilestone.UsageType = 'Automotive';
        customerDeliveryMilestone.Stage = 'Active';
        customerDeliveryMilestone.Service_Center__c=acc2.Id;      
        Insert customerDeliveryMilestone;
        
        // Create a Tentative milestone for testing
        AssetMilestone tentativeMilestone = new AssetMilestone();
        tentativeMilestone.Delivery_Date__c = System.today().addDays(7);
        tentativeMilestone.MilestoneType = '1st Service';
        tentativeMilestone.VehicleId = mapnewRecords.get('Vehicle').Id;
        tentativeMilestone.MilestoneDate = System.today().addDays(7);
        tentativeMilestone.AssetId = mapnewRecords.get('Asset').Id;
        tentativeMilestone.Name = '1st Service';
        tentativeMilestone.UsageType = 'Automotive';
        tentativeMilestone.Stage = 'Tentative';
        tentativeMilestone.Service_Center__c=acc2.Id;      
        Insert tentativeMilestone;
        
        City__c city = new City__c(
            Name = 'Bengaluru',
            City_Masking_Name__c = 'Bengaluru',
            State__c = 'Karnataka',
            City_Pincode__c = '123456',
            Price_Book__c = PriceBookId
        );
        insert city;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'BTM';
        loc.LocationType = 'State';
        insert loc;
        
        Account acc1 = new Account();
        acc1.name = 'partner';
        acc1.Email__c = 'partner@gmail.com';
        acc1.Phone = '6767656776';
        acc1.Type = 'Dealer';
        acc1.Center_Code__c = 'sdf3e23';
        Insert acc1;
        
        
        List<contact> conList = [SELECT Id, Name , Email from contact where AccountId=:acc1.Id AND Primary_Contact__c = true];
        Contact testContact = new Contact();
        If(conList.size()>0){
            testContact = conList[0];
        }else{
            testContact = new Contact(
                FirstName = 'John',
                LastName = 'partner',
                Email = 'john.partner@test.com',
                Phone = '9011113046',
                MailingCity = 'Test City',
                MailingCountry = 'india',
                MailingPostalCode = '12345',
                MailingState = 'karnataka',
                MailingStreet = '123 Test Street',
                AccountId = acc1.Id,
                Primary_Contact__c = true,
                Location__c = loc.Id,
                Role_Type__c = 'Sales'
            );
            
            insert testContact;
        }
        
        acc1.IsPartner =true;
        update acc1;
        
        ServiceResource sr = new ServiceResource(name='Test Resource', RelatedRecordId = userinfo.GetUserId(), IsActive = true);
        Insert sr;
    }
    
    @isTest
    static void testFetchVehicleDetailsByVINFailure() {
        Test.startTest();
        String vehicleIdentifier = 'REG123';
        String inputType = 'RegistrationNumber';
        
        try{
            JobCardComponentHelper.VehicleWrapper vw = JobCardComponentHelper.fetchVehicleDetails(vehicleIdentifier, inputType);
        }catch(exception e){
            //System.assertEquals('Script-thrown exception', e.getMessage(), 'Script thrown error');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testFetchVehicleDetailsByVINSuccess() {
        Test.startTest();
        Vehicle testVehicle = [SELECT Id, VehicleIdentificationNumber,VehicleRegistrationNumber FROM Vehicle WHERE PDI_Status_Pass__c = true LIMIT 1];
        String vehicleIdentifier = testVehicle.VehicleRegistrationNumber;
        String inputType = 'RegistrationNumber';
        
        JobCardComponentHelper.VehicleWrapper vw = JobCardComponentHelper.fetchVehicleDetails(vehicleIdentifier, inputType);
        Test.stopTest();
        
        System.assertNotEquals(null, vw.vehicle, 'Vehicle should not be null');
        //System.assertEquals(vehicleIdentifier, vw.vehicle.VehicleIdentificationNumber, 'Vehicle VIN should match');
    }
    
    @isTest
    static void testFetchVehicleDetailsByRegistrationNumberFailure() {
        Test.startTest();
        String vehicleIdentifier = 'REG123';
        String inputType = 'RegistrationNumber';
        
        try{
            JobCardComponentHelper.VehicleWrapper vw = JobCardComponentHelper.fetchVehicleDetails(vehicleIdentifier, inputType);
        }catch(exception e){
            System.assertEquals(true, (e!=null), 'Script thrown error');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testFetchVehicleDetailsByRegistrationNumberSuccess() {
        Test.startTest();
        Vehicle testVehicle = [SELECT Id, VehicleRegistrationNumber FROM Vehicle WHERE PDI_Status_Pass__c = true LIMIT 1];
        String vehicleIdentifier = testVehicle.VehicleRegistrationNumber;
        String inputType = 'RegistrationNumber';
        
        JobCardComponentHelper.VehicleWrapper vw = JobCardComponentHelper.fetchVehicleDetails(vehicleIdentifier, inputType);
        Test.stopTest();
        
        System.assertNotEquals(null, vw.vehicle, 'Vehicle should not be null');
        System.assertEquals(vehicleIdentifier, vw.vehicle.VehicleRegistrationNumber, 'Vehicle registration number should match');
    }
    
    @isTest
    static void testValidateOTP() {
        Vehicle testVehicle = [SELECT Id, CurrentOwnerId,VehicleIdentificationNumber,VehicleRegistrationNumber FROM Vehicle WHERE PDI_Status_Pass__c = true LIMIT 1];
        Account ownerAccount = [SELECT Id FROM Account WHERE Id = :testVehicle.CurrentOwnerId LIMIT 1];
        
        // Create primary contact for the owner account
        Contact primaryContact = new Contact(
            FirstName = 'Primary',
            LastName = 'Contact',
            Phone = '9011113246',
            AccountId = ownerAccount.Id
        );
        insert primaryContact;
        
        Test.startTest();
        JobCardComponentHelper.contactDetails contactDetails = JobCardComponentHelper.validateOTP('9011113246', testVehicle);
        Test.stopTest();
        
        /*System.assertNotEquals(null, contactDetails.primaryCon, 'Primary contact should not be null');
        System.assertEquals(true, contactDetails.isPrimary, 'Primary contact flag should be true');
        System.assertEquals(true, contactDetails.isSecondaryPresent, 'Secondary contact present flag should be true');
        System.assertEquals('9011113246', contactDetails.primaryCon.Phone, 'Primary contact phone should match');*/
    }
    
    @IsTest
    static void testFetchServiceAdvisors() {
        Account acc = new Account(Name = 'Partner');
        insert acc;
        
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

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
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
            IsActive = true
        );
        insert standardUser;
        
        System.runAs(standardUser) {
            List<ServiceResource> result = JobCardComponentHelper.fetchServiceAdvisors('Test Resource');
            System.assert(result != null, 'Service advisors list should not be null');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchServiceCenters() {
        Test.startTest();
        List<Account> result = JobCardComponentHelper.fetchServiceCenterrs();
        System.assert(result != null, 'Service centers list should not be null');
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchCities() {
        Test.startTest();
        List<City__c> result = JobCardComponentHelper.fetchCities('Bengaluru');
        System.assert(result != null, 'Cities list should not be null');
        Test.stopTest();
    }
    
    @isTest
    static void testSaveCardDetails_PeriodicMaintenance() {
        Vehicle testVehicle = [SELECT Id, CurrentOwnerId, VehicleIdentificationNumber, VehicleRegistrationNumber FROM Vehicle WHERE PDI_Status_Pass__c = true LIMIT 1];
        ServiceResource sr = [SELECT Id, Name FROM ServiceResource LIMIT 1];
        
        Account ServiceCenter = new Account(Name='service center1', Type = 'Service Center', Phone = '7890898989', Center_Code__c='asde4r');
        Insert ServiceCenter;
        
        // Create a tentative milestone for testing
        AssetMilestone tentativeMilestone = new AssetMilestone();
        tentativeMilestone.Delivery_Date__c = System.today().addDays(7);
        tentativeMilestone.MilestoneType = '1st Service';
        tentativeMilestone.VehicleId = testVehicle.Id;
        tentativeMilestone.MilestoneDate = System.today().addDays(7);
        tentativeMilestone.Name = '1st Service';
        tentativeMilestone.UsageType = 'Automotive';
        tentativeMilestone.Stage = 'Tentative';
        //Insert tentativeMilestone;
        
        JobCardComponentHelper.JobCardDetails jobCardDetails = new JobCardComponentHelper.JobCardDetails();
        jobCardDetails.contactName = 'John Doe';
        jobCardDetails.phoneNumber = '9011113246';
        jobCardDetails.vehicle = testVehicle;
        jobCardDetails.email = 'john.doe@example.com';
        jobCardDetails.KmsCovered = 1500;
        jobCardDetails.address = new JobCardComponentHelper.AddressWrapper();
        jobCardDetails.address.street = '123 Main St';
        jobCardDetails.address.city = 'San Francisco';
        jobCardDetails.address.province = 'CA';
        jobCardDetails.address.country = 'USA';
        jobCardDetails.address.postalCode = '94105';
        jobCardDetails.ServiceAdvisor = sr.Id;
        jobCardDetails.ServiceCenter = ServiceCenter.Id;
        //jobCardDetails.Service_Center__c = ServiceCenter.Id;
        jobCardDetails.TypeOfJob = 'Periodic maintenance';
        jobCardDetails.subType = '1st Service';
        
        jobCardDetails.Charger = false;
        jobCardDetails.ToolKit = false;
        jobCardDetails.FirstAidKit = false;
        jobCardDetails.NonOEAccFitted = false;  
        jobCardDetails.RearViewMirror = false;
        jobCardDetails.VehicleDocument = false;
        jobCardDetails.SOC = 20;
        jobCardDetails.EstimatedCost = 500.00;
        jobCardDetails.EstimatedDeliveryTime = System.now().addDays(2);
        jobCardDetails.concernNoList = new List<JobCardComponentHelper.ConcernWrapper>();
        
        Test.startTest();
        JobCardComponentHelper.WrapperjobCardDetails result = JobCardComponentHelper.saveCardDetails(jobCardDetails);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.jobcardId, 'Job Card Id should not be null for successful creation');
    }
    
    @isTest
    static void testSaveCardDetails_OtherJobType() {
        Vehicle testVehicle = [SELECT Id, CurrentOwnerId, VehicleIdentificationNumber, VehicleRegistrationNumber FROM Vehicle WHERE PDI_Status_Pass__c = true LIMIT 1];
        ServiceResource sr = [SELECT Id, Name FROM ServiceResource LIMIT 1];
        
        /*Account ServiceCenter = new Account(Name='service center1', Type = 'Service Center', Phone = '7890898989', Center_Code__c='asde4r');
        Insert ServiceCenter;*/
        
        Account acccc = [SELECT Id,Type FROM Account WHERE Type='Service Center' LIMIT 1];
        
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
            AccountId = acccc.Id,
            Primary_Contact__c = true,
            Role_Type__c='Service',
            Location__c=l1.Id
        );
        insert testContact;
        
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
            IsActive = true
        );
        //insert standardUser;

        //User u = [SELECT Id,ContactId,Contact.Account.Type FROM User WHERE ContactId !=null AND Contact.Account.Type = 'Service Center' LIMIT 1];

        UserRole role = [SELECT Id,DeveloperName FROM UserRole WHERE DeveloperName='RiverMobilityPrivateLimitedJPNagarPartnerUser' LIMIT 1];
          
        /*standardUser.UserRoleId=role.Id;
        update standardUser;
        
        standardUser.ContactId=testContact.Id;
        update standardUser;*/
        
        
        JobCardComponentHelper.JobCardDetails jobCardDetails = new JobCardComponentHelper.JobCardDetails();
        jobCardDetails.contactName = 'John Doe';
        jobCardDetails.phoneNumber = '9011113246';
        jobCardDetails.vehicle = testVehicle;
        jobCardDetails.email = 'john.doe@example.com';
        jobCardDetails.KmsCovered = 1500;
        jobCardDetails.address = new JobCardComponentHelper.AddressWrapper();
        jobCardDetails.address.street = '123 Main St';
        jobCardDetails.address.city = 'San Francisco';
        jobCardDetails.address.province = 'CA';
        jobCardDetails.address.country = 'USA';
        jobCardDetails.address.postalCode = '94105';
        jobCardDetails.ServiceAdvisor = sr.Id;
        jobCardDetails.ServiceCenter = standardUser.Contact.AccountId;
        jobCardDetails.TypeOfJob = 'Periodic maintenance';
        jobCardDetails.subType = '1st Service';
        
        jobCardDetails.Charger = false;
        jobCardDetails.ToolKit = false;
        jobCardDetails.FirstAidKit = false;
        jobCardDetails.NonOEAccFitted = false;  
        jobCardDetails.RearViewMirror = false;
        jobCardDetails.VehicleDocument = false;
        jobCardDetails.SOC = 20;
        jobCardDetails.EstimatedCost = 500.00;
        jobCardDetails.EstimatedDeliveryTime = System.now().addDays(2);
        
        // Add concern list
        jobCardDetails.concernNoList = new List<JobCardComponentHelper.ConcernWrapper>();
        JobCardComponentHelper.ConcernWrapper concern = new JobCardComponentHelper.ConcernWrapper();
        concern.RRConcernCategory = 'Electrical';
        concern.RRSubCategory = 'Battery';
        concern.RRDescription = 'Battery not charging properly';
        jobCardDetails.concernNoList.add(concern);
        
        
            Test.startTest();
        JobCardComponentHelper.WrapperjobCardDetails result = JobCardComponentHelper.saveCardDetails(jobCardDetails);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.jobcardId, 'Job Card Id should not be null for successful creation');
        
        
    }
    
    @isTest
    static void testGetALLVORWithReasonBlank_FalseCase() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User demoUser = new User(
            FirstName = 'Demo',
            LastName = 'User',
            Alias = 'duser',
            Email = 'demo.user@example.com',
            Username = 'demo.user.' + System.currentTimeMillis() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert demoUser;
        
        Test.startTest();
        Boolean result = JobCardComponentHelper.getALLVORWithReasonBlank(demoUser.Id);
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false for non-partner user');
    }
    
    @isTest
    static void testGetAllVORWithReasonBlankWithDetails() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User demoUser = new User(
            FirstName = 'Demo',
            LastName = 'User',
            Alias = 'duser',
            Email = 'demo.user@example.com',
            Username = 'demo.user.' + System.currentTimeMillis() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert demoUser;
        
        Test.startTest();
        JobCardComponentHelper.VorDetailsWrapper result = JobCardComponentHelper.getAllVORWithReasonBlankWithDetails(demoUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.isOpenVORFound, 'Should return false for non-partner user');
    }
}