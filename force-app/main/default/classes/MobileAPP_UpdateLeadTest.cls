@isTest
public class MobileAPP_UpdateLeadTest {
    @isTest
    static void testUpdate1() {
       	User usr = UtilityTestClass.createSalesManagerUser();
        Lead lead = UtilityTestClass.createTestLead('Test Lead', 'Test Company','New','8880899982','560076','Telephone', 'Telephone');
        
        MobileApp_Wrapper.MobileApp_UpdateLead wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateLead();
        wrapperObj.UserId = usr.Id;
        wrapperObj.LeadId = lead.Id;
        wrapperObj.LeadStatus = lead.Status;
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateLead.updateLead();
    }
    
    @isTest
    static void testUpdate2() {
       	User usr = UtilityTestClass.createSalesManagerUser();
        Lead lead = UtilityTestClass.createTestLead('Test Lead', 'Test Company','New','8880899982','560076','Telephone', 'Telephone');
        
        MobileApp_Wrapper.MobileApp_UpdateLead wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateLead();
        wrapperObj.UserId = usr.Id;
        wrapperObj.LeadId = lead.Id;
        wrapperObj.LeadStatus = null;
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateLead.updateLead();
    }
    
    @isTest
    static void testUpdate3() {  		
        MobileApp_Wrapper.MobileApp_UpdateLead wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateLead();
        wrapperObj.LeadId = null;

        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileAPP_UpdateLead.updateLead();
        
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
        MobileAPP_UpdateLead.updateLead();
    }

    
    @isTest
    static void testUpdate4() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateLead.updateLead();
        
    }
}