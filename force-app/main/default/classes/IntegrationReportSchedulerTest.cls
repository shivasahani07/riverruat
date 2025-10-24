@IsTest
public class IntegrationReportSchedulerTest {
    @IsTest
    static void coverMethod(){
        
        Integration_Log_Emails__c emails = new Integration_Log_Emails__c(Name='Integration Log Emails',Emails__c='test@example.com');
        insert emails;
        
        Test.startTest();
        System.schedule('Job10AM', '0 0 10 * * ?', new IntegrationReportScheduler());
        Test.stopTest();
    }

}