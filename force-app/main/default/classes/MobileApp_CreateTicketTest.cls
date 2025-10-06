@isTest
public class MobileApp_CreateTicketTest { 
    @isTest
    static void testCreateTicket() {
        User usr = UtilityTestClass.createSalesManagerUser();
        MobileApp_Wrapper.MobileApp_CreateTicket wrapperObj = new MobileApp_Wrapper.MobileApp_CreateTicket();
        wrapperObj.UserId = usr.Id;
        wrapperObj.description = 'Mr.';
        wrapperObj.SS1 = EncodingUtil.base64Encode(Blob.valueOf('sample image data'));
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileApp_CreateTicket.CreateTicket();
    }
    @isTest
    static void testCreateTicket1() {
        MobileApp_Wrapper.MobileApp_CreateTicket wrapperObj = new MobileApp_Wrapper.MobileApp_CreateTicket();
        wrapperObj.UserId ='';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileApp_CreateTicket.CreateTicket();
    }
    @isTest
    static void testUpdateException() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('Invalid');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileApp_CreateTicket.CreateTicket();
    }
    @isTest
    static void testUpdateFollowUp_EmptyBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileApp_CreateTicket.CreateTicket();
        
    }

}