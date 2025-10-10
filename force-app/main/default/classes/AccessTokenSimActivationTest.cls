@IsTest
public class AccessTokenSimActivationTest {
    public class MockAccessToken implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"testAccess","refresh_token":"testRefresh","scope":"default","token_type":"Bearer","expires_in":720}');
            res.setStatusCode(200);
            return res;
        }
        
    }
    @IsTest
    static void coverMethod(){
        SIM_Activation_API_Details__c s = new SIM_Activation_API_Details__c();
        s.UserName__c='test';
        s.Password__c='123';
        s.Basu_URL__c='https://www.example.com';
        s.Name='SIM Activation API Details';
        insert s;
        
        Test.setMock(HttpCalloutMock.class,new MockAccessToken());
        Test.startTest();
        String accessToken = AccessTokenSimActivation.getAccessToken();
        Test.stopTest();
        
    }

}