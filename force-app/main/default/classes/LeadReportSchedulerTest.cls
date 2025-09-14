@isTest(seeAllData=true)
public class LeadReportSchedulerTest {
    @isTest
    static void testSendReportEmailDirectly() {
       
        Account acc = new Account(Name = 'Test Dealer',Center_Code__c = 'DLR001',Email__c = 'dealer@test.com');
        
        insert acc;
        
        Report r = [SELECT Id,DeveloperName,Name FROM Report WHERE Name = 'Daily lead updates' LIMIT 1];
  
        LeadReportScheduler scheduler = new LeadReportScheduler();

        Test.startTest();
        
        String cronExpression = '0 0 0 1 1 ?';
        
        System.schedule('Lead Scheduler Test Class', cronExpression, new LeadReportScheduler());
        
        Test.stopTest();
    }
}