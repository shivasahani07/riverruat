@isTest(seeAllData=true)
public class MobileApp_DashboardTest {
    @isTest
    public Static void testLeadTotalLeads(){
        User usr = UtilityTestClass.createSalesManagerUser();
        System.runAs(usr) {
            Account testAccount = UtilityTestClass.createTestAccount('Test Account', 'C001', 'Test Store', '560076', 'Customer');
            Opportunity opp = UtilityTestClass.createTestOpportunity( 'Test Opportunity', testAccount.Id, 'RNR', System.today().addDays(30), 10000 );
            opp.OwnerId = usr.Id; update opp;
            
            Order ord = new Order(  Status = 'Activated',AccountId = testAccount.Id, OpportunityId = opp.Id, EffectiveDate = Date.today(), OwnerId = usr.Id );
            insert ord;
            
            Test_Drive__c td = UtilityTestClass.createTest1Driver('Test Drive Existing', opp.Id, 'Scheduled');
            td.OwnerId = usr.Id; td.Start_Date__c = DateTime.now(); update td;
            
            Follow_Up__c fu = new Follow_Up__c(Name = 'Test Follow Up', Follow_Up_Date__c = Date.today().addDays(-1), Lead__c = null , Opportunity__c = opp.Id);
            fu.Status__c = 'New';fu.OwnerId= UserInfo.getUserId(); insert fu;
            
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrp = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrp.UserId = usr.Id;
            wrp.FilterDate = '2026-08-15';
            wrp.FilterEndRange = '2026-09-16';
            String reqBody = JSON.serialize(wrp);
            
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(reqBody);
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/userDashboard';
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            MobileApp_Dashboard.LeadTotalLeads();

        }
    }
    @isTest
    public Static void testLeadTotalLeads1(){
        User usr = UtilityTestClass.createSalesManagerUser();
        System.runAs(usr) {
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrp = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrp.UserId = usr.Id;
            wrp.FilterDate = 'TODAY';
            String reqBody = JSON.serialize(wrp);
            
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(reqBody);
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/userDashboard';
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            MobileApp_Dashboard.LeadTotalLeads();

        }
    }
    @isTest
    public Static void testLeadTotalLeads2(){
        User usr = UtilityTestClass.createSalesManagerUser();
        System.runAs(usr) {
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrp = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrp.UserId = usr.Id;
            wrp.FilterDate = 'THIS_WEEK';
            String reqBody = JSON.serialize(wrp);
            
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(reqBody);
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/userDashboard';
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            MobileApp_Dashboard.LeadTotalLeads();

        }
    }
    @isTest
    public Static void testLeadTotalLeads3(){
        User usr = UtilityTestClass.createSalesManagerUser();
        System.runAs(usr) {
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrp = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrp.UserId = usr.Id;
            wrp.FilterDate = 'THIS_MONTH';
            String reqBody = JSON.serialize(wrp);
            
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(reqBody);
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/userDashboard';
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            MobileApp_Dashboard.LeadTotalLeads();

        }
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
        
        MobileApp_Dashboard.LeadTotalLeads();
        
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
        MobileApp_Dashboard.LeadTotalLeads();
    }
}