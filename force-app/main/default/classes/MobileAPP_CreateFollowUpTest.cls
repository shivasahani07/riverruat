@isTest
public class MobileAPP_CreateFollowUpTest {
    @isTest
    static void testCreateFollowup(){
        User usr = UtilityTestClass.createSalesManagerUser();
        Account testAccount = UtilityTestClass.createTestAccount('Test Account', 'C001', 'Test Store', '560076', 'Customer');
        Opportunity opp = UtilityTestClass.createTestOpportunity( 'Test Opportunity', testAccount.Id, 'New', System.today().addDays(30), 10000);
        
        MobileApp_Wrapper.MobileApp_CreateFollowUp wrapperObj = new MobileApp_Wrapper.MobileApp_CreateFollowUp();
        wrapperObj.UserId = usr.Id;
        wrapperObj.LeadId = opp.Id;
        wrapperObj.FollowUpDate = '2025-08-01';
        wrapperObj.FollowUpTime = '12:20:34';
        wrapperObj.FollowUpFeedback = 'dejkhjsk' ;
        wrapperObj.followUpType = 'Schedule TR Call';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileAPP_CreateFollowUp.createFollowup();
        
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
        MobileAPP_CreateFollowUp.createFollowup();
    }
    
    
    @isTest
    static void testCreateFollowup1() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_CreateFollowUp.createFollowup();
        
    }
    
}