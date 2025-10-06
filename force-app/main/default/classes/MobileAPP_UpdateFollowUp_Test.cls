@isTest
public class MobileAPP_UpdateFollowUp_Test {
     @isTest
    static void testUpdateFollowUp_Success() {
        User usr = UtilityTestClass.createSalesManagerUser();
        Follow_Up__c followUp = new Follow_Up__c(Name = 'Test FollowUp',Follow_Up_Date__c = system.today());
        insert followUp;

        MobileApp_Wrapper.MobileApp_UpdateFollowUp wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateFollowUp();
        wrapperObj.UserId = usr.Id;
        wrapperObj.followUprating = null;
        wrapperObj.FollowUpId = followUp.Id;
        wrapperObj.FollowUpStatusCompleted = true;

        String requestBody = JSON.serialize(wrapperObj);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateFollowUp';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        MobileAPP_UpdateFollowUp.UpdateFollowUp();
    }
    
    @isTest
    static void testUpdateFollowUp_Success1() {
        Follow_Up__c followUp = new Follow_Up__c(Name = 'Test FollowUp',Follow_Up_Date__c = system.today());
        insert followUp;

        MobileApp_Wrapper.MobileApp_UpdateFollowUp wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateFollowUp();
        wrapperObj.FollowUpId = followUp.Id;
        wrapperObj.FollowUpStatusCompleted = true;

        String requestBody = JSON.serialize(wrapperObj);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateFollowUp';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        MobileAPP_UpdateFollowUp.UpdateFollowUp();
    }

    @isTest
    static void testUpdateFollowUp_MissingId() {
        MobileApp_Wrapper.MobileApp_UpdateFollowUp wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateFollowUp();
        wrapperObj.FollowUpId = null;
        wrapperObj.FollowUpStatusCompleted = true;

        String requestBody = JSON.serialize(wrapperObj);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateFollowUp';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        MobileAPP_UpdateFollowUp.UpdateFollowUp();
    }

    @isTest
    static void testUpdateFollowUp_EmptyBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateFollowUp';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        MobileAPP_UpdateFollowUp.UpdateFollowUp();
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
        MobileAPP_UpdateFollowUp.UpdateFollowUp();
    }

}