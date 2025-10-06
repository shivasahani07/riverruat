@isTest
public class MobileAPP_TransferEnquiryTest {
    @isTest
    static void testUpdate() {        
        User usr = UtilityTestClass.createSalesManagerUser();
        MobileApp_Wrapper.MobileApp_TransferEnquiry wrapperObj = new MobileApp_Wrapper.MobileApp_TransferEnquiry();
        wrapperObj.UserId = usr.Id;
        wrapperObj.Phone = '8880899982';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_TransferEnquiry.createLead();
    }
    @isTest
    static void testUpdate1() {
        User usr = UtilityTestClass.createSalesManagerUser();
        
        List<Lead> leadList = new List<Lead>();
        for(Integer i =0 ; i<3;i++){
            Lead lead = UtilityTestClass.createTestLead('Test Lead'+i, 'Test Company'+i,'New','888089998'+i,'560076','Telephone', 'Telephone');
            leadList.add(lead);
        } 
        MobileApp_Wrapper.MobileApp_TransferEnquiry wrapperObj = new MobileApp_Wrapper.MobileApp_TransferEnquiry();
        wrapperObj.UserId = usr.Id;
        wrapperObj.Phone = '8880899982';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_TransferEnquiry.createLead();
    }
    @isTest
    static void testUpdate2() {
		User usr = UtilityTestClass.createSalesManagerUser();        
        List<Account> accList = new List<Account>();
        
        for(Integer i =0 ; i<3;i++){             
            Account acc = UtilityTestClass.createTestAccount('Partner Store'+i, 'D001', 'Demo Partner Store'+i,'560076', 'Dealer');
            acc.Phone = '888089998'+i;
            update acc; accList.add(acc);
        }
        MobileApp_Wrapper.MobileApp_TransferEnquiry wrapperObj = new MobileApp_Wrapper.MobileApp_TransferEnquiry();
        wrapperObj.UserId = usr.Id;
        wrapperObj.Phone = '8880899982';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_TransferEnquiry.createLead();
    }
    
    @isTest
    static void testUpdate3() {
		User usr = UtilityTestClass.createSalesManagerUser();        
        List<Opportunity> oppList = new List<Opportunity>();
        Account acc = UtilityTestClass.createTestAccount('Partner Store', 'D001', 'Demo Partner Store','560076', 'Dealer');
        acc.Phone = '8880899982'; update acc;
        
        for(Integer i =0 ; i<3;i++){    
            Opportunity opp = UtilityTestClass.createTestOpportunity( 'Test Opportunity'+i, acc.Id, 'New', System.today().addDays(30), 10000);
            opp.Phone__c = '8880899982';
            update opp; oppList.add(opp);  
        }
        MobileApp_Wrapper.MobileApp_TransferEnquiry wrapperObj = new MobileApp_Wrapper.MobileApp_TransferEnquiry();
        wrapperObj.UserId = usr.Id;
        wrapperObj.Phone = '8880899982';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateLead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_TransferEnquiry.createLead();
    }
}