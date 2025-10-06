@isTest(seealldata = true)
public class MobileApp_EventTestDriveTest {
    @isTest
    static void testGetTestDrives_success() {
        Account testAccount = UtilityTestClass.createTestAccount('Test Account', 'C001', 'Test Store', '560076', 'Customer');
        User usr = UtilityTestClass.createSalesManagerUser(); 
        Opportunity opp = UtilityTestClass.createTestOpportunity( 'Test Opportunity', testAccount.Id, 'RNR', System.today().addDays(30), 10000 );
        opp.OwnerId = usr.Id; update opp;
        
        Test_Drive__c td = UtilityTestClass.createTest1Driver('Test Drive Existing', opp.Id, 'Scheduled');
        td.OwnerId = usr.Id; td.Start_Date__c = DateTime.now();  td.Start_Date__c = DateTime.now(); td.End_Date__c = DateTime.now().addHours(2); update td;
  
        MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
        wrapper.UserId = usr.Id;
        wrapper.FilterDate = '2025-03-15';
        wrapper.FilterEndRange = '2025-09-25';

        String requestBody = JSON.serialize(wrapper);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventTestDrive';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileApp_EventTestDrive.getTestDrives();
    }
    @isTest
    static void testGetTestDrivesException() {
       

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventTestDrive';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('Invalid');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileApp_EventTestDrive.getTestDrives();
    }
    
    
}