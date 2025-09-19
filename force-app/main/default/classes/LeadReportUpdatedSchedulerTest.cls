@isTest
public class LeadReportUpdatedSchedulerTest {

    @isTest static void testAt7AM() {
        Account acc = new Account(
            Name = 'Test Dealer',
            Center_Code__c = 'D001',
            Email__c = 'dealer@test.com'
        );
        insert acc;
        
        Lead_Report_Id__c setting = new Lead_Report_Id__c(
            Name = 'Lead Report Id',
            Send_To_All__c = true,
            Allowed_Accounts__c = acc.Id,
            Allowed_Emails__c = 'extra1@test.com,extra2@test.com'
        );
        insert setting;

        Test.startTest();
        System.schedule('Job7AM', '0 0 7 * * ?', new LeadReportUpdatedScheduler());
        Test.stopTest();
    }

    @isTest static void testAt7PM() {
        Account acc = new Account(
            Name = 'Test Dealer',
            Center_Code__c = 'D001',
            Email__c = 'dealer@test.com'
        );
        insert acc;
        
        Lead_Report_Id__c setting = new Lead_Report_Id__c(
            Name = 'Lead Report Id',
            Send_To_All__c = true,
            Allowed_Accounts__c = acc.Id,
            Allowed_Emails__c = 'extra1@test.com,extra2@test.com'
        );
        insert setting;

        Test.startTest();
        System.schedule('Job7PM', '0 0 19 * * ?', new LeadReportUpdatedScheduler());
        Test.stopTest();
    }

    @isTest static void testAtOtherTime() {
        Account acc = new Account(
            Name = 'Test Dealer',
            Center_Code__c = 'D001',
            Email__c = 'dealer@test.com'
        );
        insert acc;
        
        Lead_Report_Id__c setting = new Lead_Report_Id__c(
            Name = 'Lead Report Id',
            Send_To_All__c = true,
            Allowed_Accounts__c = acc.Id,
            Allowed_Emails__c = 'extra1@test.com,extra2@test.com'
        );
        insert setting;

        Test.startTest();
        System.schedule('Job10AM', '0 0 10 * * ?', new LeadReportUpdatedScheduler());
        Test.stopTest();
    }
}