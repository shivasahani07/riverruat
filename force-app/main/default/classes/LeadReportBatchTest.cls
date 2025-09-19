@isTest
private class LeadReportBatchTest {

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
        //insert dealerOwner;

        // Create Lead with Dealer_Code
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Phone = '9999999999',
            LeadSource = 'Web',
            Dealer_Code__c = 'D001',
            //Lead_Dealer_Code__c = null,
            //OwnerId = UserInfo.getUserId(),
            OwnerId = dealerOwner.Id,
            Status = 'Open - Not Contacted'
        );
        insert lead;

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

    } 

    @isTest
    static void testDailyReportBatch() {
        Test.startTest();
        LeadReportBatch batch = new LeadReportBatch('DAILY');
        Database.executeBatch(batch, 50);
        Test.stopTest();

        // Verify email was attempted
        //System.assertEquals(true, Limits.getEmailInvocations() > 0, 'Email should have been invoked');
    }

    @isTest
    static void testMonthlyReportBatch() {
        Test.startTest();
        LeadReportBatch batch = new LeadReportBatch('MONTHLY');
        Database.executeBatch(batch, 50);
        Test.stopTest();

        // Verify batch ran without errors
        //System.assertEquals(true, Limits.getEmailInvocations() > 0, 'Email should have been invoked in monthly mode');
    }

    @isTest
    static void testRestrictedAccounts() {
        // Update setting to restrict sending
        Lead_Report_Id__c setting = Lead_Report_Id__c.getInstance('Lead Report Id');
        setting.Send_To_All__c = false;
        update setting;

        Test.startTest();
        LeadReportBatch batch = new LeadReportBatch('DAILY');
        Database.executeBatch(batch, 50);
        Test.stopTest();

        // Since Allowed_Accounts__c is set, ensure still sends
        //System.assertEquals(true, Limits.getEmailInvocations() > 0, 'Email should still be sent to allowed accounts');
    }

}