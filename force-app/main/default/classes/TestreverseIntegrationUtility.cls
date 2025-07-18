@isTest
public class TestreverseIntegrationUtility {
     public class MockAccessTokenCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{\"code\":200,\"data\":{\"token\":\"xxxxxxxxxxxx\",\"token_type\":\"Bearer\"}}');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void testGenerateAccessToken() {
        
        Website_Creds__c rwd = new Website_Creds__c(
            Name = 'Website Creds',
            BaseURL__c = 'https://dummyurl.com',
            ClientId__c = 'TestClientId',
            ClientSecret__c = 'TestClientSecret'
        );
        insert rwd;

        
        Test.setMock(HttpCalloutMock.class, new MockAccessTokenCallout());

        Test.startTest();
        String accessToken = reverseIntegrationUtility.gererateAccessToken();
        Test.stopTest();
    }
}