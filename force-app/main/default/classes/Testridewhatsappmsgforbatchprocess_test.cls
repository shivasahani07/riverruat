@istest
public class Testridewhatsappmsgforbatchprocess_test {
    @isTest
    static void testBatchWithCallouts() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Dealer_Code__c = '291002',
            LeadSource = '91Wheels',
            Status = 'New',
            Phone = '9876543210'
        );
        insert testLead;
        Test_Drive__c td=new Test_Drive__c();
        td.Lead__c=testLead.Id;
        td.Ride_Type__c='STR';
        td.Test_Ride_Date__c=Date.today();
        insert td;
        
         WhatsappIntegration__c mockIntegration = new WhatsappIntegration__c(
            Name = 'WhatsApp API',
            API_Endpoint__c = 'https://api.whatsapp.com/send',
            API_Key__c = 'mock-api-key',
            test_ride_booked_text_2_image__c = 'https://example.com/image.jpg'
        );
        insert mockIntegration;
        
        Test.setMock(HttpCalloutMock.class, new Testridewhatsappmsgforbatchprocessmock());
        
        Test.startTest();
        Testridewhatsappmsgforbatchprocess batchJob = new Testridewhatsappmsgforbatchprocess();
        Database.executeBatch(batchJob, 2);
        Test.stopTest();
        
        
        List<Lead> processedLeads = [SELECT Id, Status, Phone FROM Lead WHERE Status = 'New'];
        
    }
    
    @isTest
    static void testScheduler() {
        
        Lead testLead = new Lead(
            FirstName = 'Scheduled',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            Phone = '9876543210'
        );
        insert testLead;
        Test.setMock(HttpCalloutMock.class, new Testridewhatsappmsgforbatchprocessmock());

        String cronExp = '0 0 12 * * ?';
        Test.startTest();
        Testrideforwhatsappmsgschedule scheduler = new Testrideforwhatsappmsgschedule();
        String jobId = System.schedule('TestLeadBatchScheduler', cronExp, scheduler);
        Test.stopTest();
        
    }
}