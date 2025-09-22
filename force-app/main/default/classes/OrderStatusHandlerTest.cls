@isTest(seeAllData=true)
public class OrderStatusHandlerTest {
    public class HttpCalloutMockImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            
            String body = req.getBody();
            Map<String, Object> requestBody = (Map<String, Object>)JSON.deserializeUntyped(body);
           
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
         
    }
    static testMethod void testCodeCoverage() {
        OrderStatusHandler.addTest();
        OrderStatusHandler.addTest2();
        OrderStatusHandler.addTest3();
        OrderStatusHandler.addTest4();
        OrderStatusHandler.addTest5();
        OrderStatusHandler.addTest6();
        OrderStatusHandler.addTest7();
        OrderStatusHandler.addTest8();
        
       
    }
    
}