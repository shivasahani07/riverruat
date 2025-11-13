@isTest
public class BatchRecordControllerTest {
    
    @isTest
    static void testGetCurrentUserContact_NoContact() {
        City__c cty = new City__c(Name = 'Kochi', Zone__c = 'South', City_Pincode__c = '682001');
        insert cty;
        
        Account testAccount = new Account(Name='Test Account',Phone='9876543210',Type='Service Center', Center_Code__c='27482734', City__c = cty.Id);
        insert testAccount;
        
        Contact testContact = new Contact(FirstName='Test', LastName='Contact', Phone='1234567890', Email='test@example.com', AccountId=testAccount.Id);
        insert testContact;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'No',
            LastName = 'ContactUser',
            Email = 'nocontact@test.com',
            Username = 'nocontact' + System.currentTimeMillis() + '@test.com',
            Alias = 'nocu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;
        
        System.runAs(testUser) {
            try {
                Test.startTest();
                BatchRecordController.getCurrentUserContact();
                Test.stopTest();
            } catch (AuraHandledException e) {
            }
        }
    }
    @isTest
    static void testGetCurrentUserContact_WithContact() {
        // Setup data
        City__c cty = new City__c(Name = 'Kochi', Zone__c = 'South', City_Pincode__c = '682001');
        insert cty;
        
        Account testAccount = new Account(Name='Test Account',Phone='9876543210',Type='Service Center', Center_Code__c='27482734', City__c = cty.Id);
        insert testAccount;
        
        Contact testContact = new Contact(FirstName='Test', LastName='Contact', Phone='1234567890', Email='test@example.com', AccountId=testAccount.Id);
        insert testContact;
        
        // Create a Portal User with a Customer Community license
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];  // Customer Community User Profile
        User portalUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test.user@test.com',
            Username = 'test.user' + System.currentTimeMillis() + '@test.com',
            Alias = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            ContactId = testContact.Id  // Associate the User with the Contact
            //UserType = 'Customer'  // Required for portal users
        );
        insert portalUser;
        
        // Run test as the created portal user
        System.runAs(portalUser) {
            Test.startTest();
            Contact userContact = BatchRecordController.getCurrentUserContact(); // This should hit the query
            Test.stopTest();
            
            // Assert the retrieved Contact's fields
            System.assertNotEquals(null, userContact, 'User should have an associated contact.');
            System.assertEquals(testContact.Id, userContact.Id, 'The Contact ID should match.');
        }
    }
    
    
    @isTest
    static void testFetchClaims() {
        City__c cty = new City__c(Name = 'Kochi', Zone__c = 'South', City_Pincode__c = '682001');
        insert cty;
        
        Account testAccount = new Account(Name='Test Account',Phone='9876543210',Type='Service Center', Center_Code__c='27482734', City__c = cty.Id);
        insert testAccount;
        
        Test.startTest();
        List<Claim> fetchedClaims = BatchRecordController.fetchClaims(testAccount.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCreateBatchAndTagClaims() {
        City__c cty = new City__c(Name = 'Kochi', Zone__c = 'South', City_Pincode__c = '682001');
        insert cty;
        
        Account testAccount = new Account(Name='Test Account',Phone='9876543210',Type='Service Center', Center_Code__c='27482734', City__c = cty.Id);
        insert testAccount;
        
        Contact testContact = new Contact(FirstName='Test', LastName='Contact', Phone='1234567890', Email='test@example.com', AccountId=testAccount.Id);
        insert testContact;
        
        List<Claim> claims = new List<Claim>();
        for (Integer i = 0; i < 5; i++) {
            claims.add(new Claim(
                Name = 'Test Claim ' + i,
                Status = 'Submitted',
                AccountId = testAccount.Id
            ));
        }
        insert claims;
        
        Date dispatchDate = Date.today().addDays(1);
        String lrNumber = 'LR123';
        String lrAttachment = 'SampleAttachment';
        String TOD = 'T&C';
        String AOC = 'River Factory'; 
        String RN = 'Raman from JP Nagar'; 
        String VN = 'vn-123'; 
        String HPS = 'Nakul'; 
        String Phone = '9876543221';
        String POS = 'Demo'; 
        String TN = 'ARV Transporter'; 
        String TID = 'TR_0002'; 
        String Eway = 'EWAY-0002'; 
        String MOT = 'Road'; 
        String purpose = 'Demo Again';
        
        Test.startTest();
        Id batchId = BatchRecordController.createBatchAndTagClaims(
            new List<Id>{claims[0].Id, claims[1].Id},
            dispatchDate,
            lrNumber,
            lrAttachment, TOD, AOC, RN, VN, HPS, Phone, POS, TN, TID, Eway, MOT, purpose, 
            testContact.Id, testContact.Account.City__c, testContact.Account.Service_Center__c
        );
        Test.stopTest();
    }
    
    @isTest
    static void testCreateBatchAndTagClaims_Validation() {
        City__c cty = new City__c(Name = 'Kochi', Zone__c = 'South', City_Pincode__c = '682001');
        insert cty;
        
        Account testAccount = new Account(Name='Test Account',Phone='9876543210',Type='Service Center', Center_Code__c='27482734', City__c = cty.Id);
        insert testAccount;
        
        Contact testContact = new Contact(FirstName='Test', LastName='Contact', Phone='1234567890', Email='test@example.com', AccountId=testAccount.Id);
        insert testContact;
        
        List<Claim> claims = new List<Claim>();
        for (Integer i = 0; i < 5; i++) {
            claims.add(new Claim(
                Name = 'Test Claim ' + i,
                Status = 'Submitted',
                AccountId = testAccount.Id
            ));
        }
        insert claims;
        
        Test.startTest();  // Start test for all the validations
        
        try {
            BatchRecordController.createBatchAndTagClaims(new List<Id>(), Date.today(), 'LR123', 'SampleAttachment', 'T&C','River HQ', 'Raman from JP Nagar', 
                                                          'vn-123','Nakul','9876543221','Demo', 'ARV Transporter', 'TR_0002', 'EWAY-0002','Road','Demo Again', 
                                                          testContact.Id, testContact.Account.City__c, testContact.Account.Service_Center__c);
        } catch (Exception e) {}
        
        Test.stopTest();  // End the test for all validations
    }
}