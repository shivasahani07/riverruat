@isTest
public class MobileApp_EventOpenOppTest {
    @isTest
    public static void getTestDrives() {
        User testUser = UtilityTestClass.createSalesManagerUser();
        
        System.runAs(testUser) {
            Account acc = UtilityTestClass.createTestAccount('Test Account', 'C001', 'Test Store', '560076', 'Customer');
            Opportunity opp = UtilityTestClass.createTestOpportunity( 'Test Opportunity', acc.Id, 'RNR', System.today().addDays(30), 10000 );
            Order ord = new Order( Status = 'Activated', OpportunityId = opp.Id, AccountId = acc.Id, OwnerId = testUser.Id, EffectiveDate = Date.today());
            insert ord;
            
            Comment__c comment = new Comment__c(
                Description__c = 'Test Comment',
                Order__c = ord.Id
            );
            insert comment;
            
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrapper.UserId = testUser.Id;
            wrapper.FilterDate = 'THIS_MONTH';
            
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/EventClosedOppAndOrder';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            MobileApp_EventOpenOpp.getTestDrives();
        }
    }

    
    @isTest
    public static void getTestDrives1() {
        User testUser = UtilityTestClass.createSalesManagerUser();
        MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
        wrapper.UserId = testUser.Id;
        wrapper.FilterDate = '2025-03-15';
        wrapper.FilterEndRange = '2025-03-16';    
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventClosedOppAndOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileApp_EventOpenOpp.getTestDrives();
    }
    
}