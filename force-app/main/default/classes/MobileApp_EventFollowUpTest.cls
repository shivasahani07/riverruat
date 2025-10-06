@isTest
public class MobileApp_EventFollowUpTest {
    @isTest
    public static void testGetFollowUps(){
        User usr = UtilityTestClass.createSalesManagerUser();
        
        Account acc = UtilityTestClass.createTestAccount('Test Account', 'C001', 'Test Store', '560076', 'Customer');

        Opportunity opp = UtilityTestClass.createTestOpportunity( 'Test Opportunity', acc.Id, 'RNR', System.today().addDays(30), 10000 );
        
        String OwnerId = UserInfo.getUserId();
        Follow_Up__c followUp = new Follow_Up__c(); 
        followUp.Name = 'Test Follow Up';
        followUp.Opportunity__c = opp.Id;
        followUp.OwnerId = OwnerId;
        followUp.Feedback__c = 'Test Feedback';
        followUp.Follow_Up_Date__c = Date.today();
        followUp.Next_Follow_Up_Date__c = Date.today().addDays(2);
        followUp.Status__c = 'New';
        followUp.FollowUpType__c = 'booking call';
        insert followUp;

        MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
        wrapper.UserId = UserInfo.getUserId();
        wrapper.FilterDate = 'THIS_MONTH'; 
        wrapper.FilterEndRange = null;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventFollowUp';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        MobileApp_EventFollowUp.getFollowUps();
    }
    @isTest
    public static void testGetFollowUps1(){
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventFollowUp';
        req.httpMethod = 'POST';
        req.requestBody = null;
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        MobileApp_EventFollowUp.getFollowUps();
        Test.stopTest();
    }
    @isTest
    static void testGetFollowUps2() {
        MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
        wrapper.UserId = '';
        wrapper.FilterDate = 'TODAY';

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventFollowUp';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileApp_EventFollowUp.getFollowUps();

    }

}