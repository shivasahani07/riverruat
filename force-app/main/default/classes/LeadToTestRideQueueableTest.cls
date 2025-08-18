@IsTest
public class LeadToTestRideQueueableTest {
    @IsTest
    static void testQueueable(){
        WhatsappIntegration__c mockIntegration = new WhatsappIntegration__c(
            Name = 'WhatsApp API',
            API_Endpoint_Updated__c = 'https://api.whatsapp.com/send',
            API_Key__c = 'mock-api-key'
        );
        insert mockIntegration;
        
        
        Lead testLead1 = new Lead(FirstName = 'Test 1', LastName = 'lastName 1', Company = 'Test Company 1', LeadSource = 'Google', Dealer_Code__c = '292001', Phone = '1234567890');
        Lead testLead2 = new Lead(FirstName = 'Test 2', LastName = 'lastName 2', Company = 'Test Company 2', LeadSource = 'Facebook', Dealer_Code__c = '292002', Phone = '0987654321');
        
        insert new List<Lead>{testLead1, testLead2};
            
        List<Id> leadIds = new List<Id>{testLead1.Id, testLead2.Id};    
            
            Map<Id,String> phoneMap = new Map<Id,String>{testLead1.Id=>'9876543210'};
            String templateName = 'lead_to_test_ride_flow';    
        
       Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());        
        Test.startTest();
        LeadToTestRideQueueable queueableJob = new LeadToTestRideQueueable(leadIds, templateName,phoneMap);
        System.enqueueJob(queueableJob);
        Test.stopTest(); 
        
    }
     public class HttpCalloutMockImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}'); // Simulate a successful API response
            return res;
        }
    }

}