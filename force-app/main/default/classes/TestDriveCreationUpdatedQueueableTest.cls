@IsTest
public class TestDriveCreationUpdatedQueueableTest {
    public class HttpCalloutMockImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}'); 
            return res;
        }
    }
    @IsTest
    static void testWhatsAppMessage(){
        Lead testLead1 = new Lead(FirstName = 'Test', LastName = 'Ride', Company = 'Test Company 1', LeadSource = 'Google', Dealer_Code__c = '292001', Phone = '1234567890');
        insert testLead1; 
        
        Test_Drive__c testDrive = new Test_Drive__c(Name='Drive 1', Lead__c = testLead1.Id,Test_Drive_Date__c=System.Now());
        insert testDrive;
        
        Test_Drive__c testDrive2 = new Test_Drive__c(Name='Drive 1', Lead__c = testLead1.Id,Test_Drive_Date__c=System.Now());
        insert testDrive2;
        
        WhatsappIntegration__c w = new WhatsappIntegration__c(Name='WhatsApp API',API_Endpoint_Updated__c='https://www.example.com',Service_Bearer_Token__c='98vgku',
                                                             API_Key__c='87guth7');
        insert w;
        
       
        List<Id> testDriveIds = new List<Id>{testDrive.Id,testDrive2.Id};
        Map<Id, String> idToPhoneMap = new Map<Id, String>{testDrive.Id => '1234567890'};
        Map<Id,String> idToTimeMap = new Map<Id,String>{testDrive.Id => '04-02-2025'};  
        Map<Id,String> idToRideTypeMap = new Map<Id,String>{testDrive.Id => 'Home Ride'};    
        Map<Id,String> idToTimeOnly = new Map<Id,String>{testDrive.Id => '10:00 am'};
        
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        
        Test.startTest();
        
        
        TestDriveCreationUpdatedQueueable queueableJob = new TestDriveCreationUpdatedQueueable(testDriveIds, idToPhoneMap, idToTimeMap, idToRideTypeMap,idToTimeOnly);
        System.enqueueJob(queueableJob);
        
        Test.stopTest();    
    }

}