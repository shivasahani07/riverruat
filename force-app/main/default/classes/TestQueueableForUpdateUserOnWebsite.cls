@isTest
public class TestQueueableForUpdateUserOnWebsite {
    public class MockRiverCreateOrderCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"code":200,"success":true,"data":{"order_items":[{"id":"a39d43ac-124f-40c8-ad85-1ae27f9bd3c4","sku":"RINDIE-MB-9","product_type":"Accessories"}]}}');
            res.setStatusCode(200);
            return res;
        }
     
    }
     @isTest
    static void testQueueableWithCallout() {
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Email__c='ttt@test.com');
        insert testAccount;
        
        Website_Creds__c rwd = new Website_Creds__c(Name='Website Creds', BaseURL__c='https://dummywebsite.com');
        insert rwd;

        
        Test.setMock(HttpCalloutMock.class, new MockRiverCreateOrderCallout());
        
        Test.startTest();
        QueueableForUpdateUserOnWebsite q = new QueueableForUpdateUserOnWebsite(new List<Id>{testAccount.Id});
        System.enqueuejob(q);
        Test.stopTest();
    }

}