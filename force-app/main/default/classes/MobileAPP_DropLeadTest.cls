@isTest
public class MobileAPP_DropLeadTest {
    @isTest
    static void testUpdate1() {
        User usr = UtilityTestClass.createSalesManagerUser();
        Lead lead = UtilityTestClass.createTestLead('Test Lead', 'Test Company','New','8880899982','560076','Telephone', 'Telephone');
        
        MobileApp_Wrapper.MobileApp_DropLead wrapperObj = new MobileApp_Wrapper.MobileApp_DropLead();
        wrapperObj.UserId = usr.Id;
        wrapperObj.LeadId = lead.Id;
        wrapperObj.DropOutReason = 'Considering Later / Unable to Proceed';
        wrapperObj.DropOutSubReason = 'Out of delivery area';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DropLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_DropLead.DropLead();
    }
    
    @isTest
    static void testUpdate2() {
        User usr = UtilityTestClass.createSalesManagerUser();
        Account acc = UtilityTestClass.createTestAccount('Demo Store', 'D002', 'Demo Store', '560076', 'Dealer');
        Opportunity opp = UtilityTestClass.createTestOpportunity('Opp One', acc.Id, 'Prospecting', Date.today().addDays(10), 10000);    
        MobileApp_Wrapper.MobileApp_DropLead wrapperObj = new MobileApp_Wrapper.MobileApp_DropLead();
        wrapperObj.UserId = usr.Id;
        wrapperObj.LeadId = opp.Id;
        wrapperObj.DropOutReason = 'Considering Later / Unable to Proceed';
        wrapperObj.DropOutSubReason = 'Out of delivery area';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DropLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileAPP_DropLead.DropLead();  
    }
    
    @isTest
    static void testUpdate3() {  
        User usr = UtilityTestClass.createSalesManagerUser();
        Account acc = UtilityTestClass.createTestAccount('Demo Store', 'D002', 'Demo Store', '560076', 'Dealer');
        Opportunity opp = UtilityTestClass.createTestOpportunity('Opp One', acc.Id, 'Prospecting', Date.today().addDays(10), 10000);    
        MobileApp_Wrapper.MobileApp_DropLead wrapperObj = new MobileApp_Wrapper.MobileApp_DropLead();
        wrapperObj.UserId = usr.Id;
        wrapperObj.LeadId = opp.Id;
        wrapperObj.DropOutReason = 'Considering Later / Unable to Proceed';
        wrapperObj.DropOutSubReason = 'Others – need reason';
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DropLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileAPP_DropLead.DropLead();
        
    }
    
    @isTest
    static void testUpdateFollowUp_EmptyBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DropLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_DropLead.DropLead();
        
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
        MobileAPP_DropLead.DropLead();
    }
}