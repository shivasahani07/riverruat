@isTest
public class LeadReportOneTimeBatchTest {
   @testSetup
    static void setupData() {
        // Create Account (dealer)
        Account acc = new Account(
            Name = 'Test Dealer',
            Center_Code__c = '291002',
            Email__c = 'dealer@test.com'
        );
        insert acc;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User dealerOwner = [SELECT Id,Name,Dealer_Code__c FROM User WHERE Dealer_Code__c!=null AND Dealer_Code__c = '291002' LIMIT 1];
        System.debug('dealerOwner==>'+dealerOwner);
        //insert dealerOwner;

        // Create Lead with Dealer_Code
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Phone = '9999999999',
            LeadSource = 'Google',
            Dealer_Code__c = '291002',
          
            //OwnerId = UserInfo.getUserId(),
            OwnerId = dealerOwner.Id,
            Status = 'Open - Not Contacted',
            PostalCode='291002',
            Verified__c=true
        );
        insert lead;
        
        System.debug('Lead In Test==?>'+lead.Lead_Dealer_Code__c);
            
        Lead lead2 = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Phone = '9999999990',
            LeadSource = 'Google',
            Dealer_Code__c = '291002',
            //Lead_Dealer_Code__c = null,
            //OwnerId = UserInfo.getUserId(),
            OwnerId = dealerOwner.Id,
            Status = 'Open - Not Contacted',
            PostalCode='291002',
            Verified__c=true
        );
        insert lead2;    
        
        
       lead = [SELECT Id, Lead_Dealer_Code__c FROM Lead WHERE Id = :lead.Id];
       lead2 = [SELECT Id, Lead_Dealer_Code__c FROM Lead WHERE Id = :lead2.Id];

    System.debug('Lead1 Formula==>' + lead.Lead_Dealer_Code__c); // Should be 291002
    System.debug('Lead2 Formula==>' + lead2.Lead_Dealer_Code__c); // Should be 291002

        // Add Follow Up for Lead
        Follow_Up__c fu = new Follow_Up__c(
            Lead__c = lead.Id,
            Name = 'Follow Up 1',
            Follow_Up_Date__c=System.Today()
        );
        insert fu;

        // Add Test Drive
        Test_Drive__c td = new Test_Drive__c(
            Lead__c = lead.Id,
            Test_Drive_Status__c = 'Completed'
        );
        insert td;

        // Insert Custom Setting
        Lead_Report_Id__c setting = new Lead_Report_Id__c(
            Name = 'Lead Report Id',
            Send_To_All__c = true,
            Allowed_Accounts__c = acc.Id,
            Allowed_Emails__c = 'extra1@test.com,extra2@test.com'
        );
        insert setting;
        
        WhatsappIntegration__c w = new WhatsappIntegration__c();
        w.Name='WhatsApp API';
        w.API_Endpoint__c = 'https://api.whatsapp.com/send';
        w.API_Key__c = 'mock-api-key';
        w.new_lead_book_a_test_ride_03__c='www.example.jpeg';
        insert w;

    } 

    @isTest
    static void testDailyReportBatch() {
         WhatsappIntegration__c mockIntegration = new WhatsappIntegration__c(
            Name = 'WhatsApp API',
            API_Endpoint__c = 'https://api.whatsapp.com/send',
            API_Key__c = 'mock-api-key',
            new_lead_book_a_test_ride_03__c='www.example.jpeg'
        );
        insert mockIntegration;
        
        Store_Details__mdt dealerCodes1 = new Store_Details__mdt(Name__c='test',Dealer_Code__c='291008',IsActive__c=true);
        Store_Details__mdt dealerCodes2 = new Store_Details__mdt(Name__c='test2',Dealer_Code__c='291008',IsActive__c=true);  
        
        List<Store_Details__mdt> storeDetails = [SELECT Name__c, Dealer_Code__c, IsActive__c FROM Store_Details__mdt WHERE IsActive__c = true];
        
       List<Lead> leads = [SELECT Id, LastName, Lead_Dealer_Code__c FROM Lead WHERE LastName LIKE 'Test Lead%'];
        
        DateTime TestCreatedDate = DateTime.now().addMinutes(-15);
        
        
        //Test.setCreatedDate(l.Id, TestCreatedDate);
        
        Test.startTest();
        LeadReportOneTimeBatch batch = new LeadReportOneTimeBatch('DAILY');
        Database.executeBatch(batch, 50);
        Test.stopTest();

        // Verify email was attempted
        //System.assertEquals(true, Limits.getEmailInvocations() > 0, 'Email should have been invoked');
    }

    @isTest
    static void testMonthlyReportBatch() {
         WhatsappIntegration__c mockIntegration = new WhatsappIntegration__c(
            Name = 'WhatsApp API',
            API_Endpoint__c = 'https://api.whatsapp.com/send',
            API_Key__c = 'mock-api-key',
            new_lead_book_a_test_ride_03__c='www.example.jpeg'
        );
        insert mockIntegration;
        
        Store_Details__mdt dealerCodes1 = new Store_Details__mdt(Name__c='test',Dealer_Code__c='291008',IsActive__c=true);
        Store_Details__mdt dealerCodes2 = new Store_Details__mdt(Name__c='test2',Dealer_Code__c='291008',IsActive__c=true);  
        
        List<Store_Details__mdt> storeDetails = [SELECT Name__c, Dealer_Code__c, IsActive__c FROM Store_Details__mdt WHERE IsActive__c = true];
        
        List<Lead> leads = [SELECT Id, LastName, Lead_Dealer_Code__c FROM Lead WHERE LastName LIKE 'Test Lead%'];
        
        Test.startTest();
        LeadReportOneTimeBatch batch = new LeadReportOneTimeBatch('MONTHLY');
        Database.executeBatch(batch, 50);
        Test.stopTest();

        // Verify batch ran without errors
        //System.assertEquals(true, Limits.getEmailInvocations() > 0, 'Email should have been invoked in monthly mode');
    }

    @isTest
    static void testRestrictedAccounts() {
        // Update setting to restrict sending
        
        
        WhatsappIntegration__c mockIntegration = new WhatsappIntegration__c(
            Name = 'WhatsApp API',
            API_Endpoint__c = 'https://api.whatsapp.com/send',
            API_Key__c = 'mock-api-key',
            new_lead_book_a_test_ride_03__c='www.example.jpeg'
        );
        insert mockIntegration;
        
        Store_Details__mdt dealerCodes1 = new Store_Details__mdt(Name__c='test',Dealer_Code__c='291008',IsActive__c=true);
        Store_Details__mdt dealerCodes2 = new Store_Details__mdt(Name__c='test2',Dealer_Code__c='291008',IsActive__c=true);  
        
        List<Store_Details__mdt> storeDetails = [SELECT Name__c, Dealer_Code__c, IsActive__c FROM Store_Details__mdt WHERE IsActive__c = true];
        
        Lead_Report_Id__c setting = Lead_Report_Id__c.getInstance('Lead Report Id');
        setting.Send_To_All__c = false;
        update setting;
        
        List<Lead> leads = [SELECT Id, LastName, Lead_Dealer_Code__c FROM Lead WHERE LastName LIKE 'Test Lead%'];

        Test.startTest();
        LeadReportOneTimeBatch batch = new LeadReportOneTimeBatch('DAILY');
        Database.executeBatch(batch, 50);
        Test.stopTest();

        // Since Allowed_Accounts__c is set, ensure still sends
        //System.assertEquals(true, Limits.getEmailInvocations() > 0, 'Email should still be sent to allowed accounts');
    }

    
}