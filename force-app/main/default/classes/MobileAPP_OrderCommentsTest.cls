@isTest(seeAllData = true)
public class MobileAPP_OrderCommentsTest {
    @isTest
    static void testOrderComments(){
        User usr = UtilityTestClass.createSalesManagerUser();
        List<Order> ord = [Select Id From Order limit 1];
        MobileApp_Wrapper.MobileApp_Comments wrapperObj = new MobileApp_Wrapper.MobileApp_Comments();
        wrapperObj.userId = usr.Id;
        wrapperObj.OrderId = ord[0].Id;
        wrapperObj.Comments = 'Test Comments';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileAPP_OrderComments.OrderComments();
    }
    @isTest
    static void testUpdateFollowUp_EmptyBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_OrderComments.OrderComments();
        
    }
    @isTest
    static void testUpdateException() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('Invalid');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileAPP_OrderComments.OrderComments();
    }
}