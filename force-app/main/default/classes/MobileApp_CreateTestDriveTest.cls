@isTest
public class MobileApp_CreateTestDriveTest {
    @isTest
    static void testCreateTestDrive() {
        User usr = UtilityTestClass.createSalesManagerUser();
        Account testAccount = UtilityTestClass.createTestAccount('Test Account', 'C001', 'Test Store', '560076', 'Customer');
        Opportunity testOpp = UtilityTestClass.createTestOpportunity( 'Test Opportunity', testAccount.Id, 'New', System.today().addDays(30), 10000);
        
        MobileApp_Wrapper.MobileApp_CreateTestDrive wrapperObj = new MobileApp_Wrapper.MobileApp_CreateTestDrive();
        wrapperObj.UserId = usr.Id;
        wrapperObj.LeadId = testOpp.Id;
        wrapperObj.TestDriveDate = '2025-08-05';
        wrapperObj.TestDriveTime = '10:30:45';
        wrapperObj.homeTestDrive = true;
        wrapperObj.HomeTestDriveAddress = '123 Main St';
        wrapperObj.storeTestDrive = false;
        wrapperObj.pincode = '560001';
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateTestDrive';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(wrapperObj));
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        MobileApp_CreateTestDrive.createTestDrive();
    }
    @isTest
    static void testCreateTestDrive1() {        
        MobileApp_Wrapper.MobileApp_CreateTestDrive wrapperObj = new MobileApp_Wrapper.MobileApp_CreateTestDrive();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateTestDrive';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(wrapperObj));
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        MobileApp_CreateTestDrive.createTestDrive();
    }
    @isTest
    static void testCreateTestDrive2() {
        User usr = UtilityTestClass.createSalesManagerUser();
        MobileApp_Wrapper.MobileApp_CreateTestDrive wrapperObj = new MobileApp_Wrapper.MobileApp_CreateTestDrive();
        wrapperObj.UserId = usr.Id;
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateTestDrive';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(wrapperObj));
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        MobileApp_CreateTestDrive.createTestDrive();
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
        
        MobileApp_CreateTestDrive.createTestDrive();        
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
        MobileApp_CreateTestDrive.createTestDrive(); 
    }
}