@isTest(seeAllData=true)
public class LeadReportSchedulerTest {
    @isTest
    static void testSendReportEmailDirectly() {
       
        Account acc = new Account(Name = 'Test Dealer',Center_Code__c = 'DLR001',Email__c = 'dealer@test.com');
        
        insert acc;
        
        Report r = [SELECT Id,DeveloperName,Name FROM Report WHERE Name = 'Leads report' LIMIT 1];
  
        LeadReportScheduler scheduler = new LeadReportScheduler();

        Test.startTest();
        
        scheduler.executeWithHour(19);
        
        
        /*String cronExpression = '0 0 0 1 1 ?';
        
        System.schedule('Lead Scheduler Test Class', cronExpression, new LeadReportScheduler().executeWithHour(19));*/
        
        Test.stopTest();
    }
    @isTest
    static void testSendReportEmailAt7AM() {
        // covers morning path
        LeadReportScheduler scheduler = new LeadReportScheduler();

        Test.startTest();
        scheduler.executeWithHour(7);
        Test.stopTest();
    }
}