@isTest
public class MobileAPP_UpdateTestDriveTest {
    @isTest
    static void testcreateTestDrive() {
        User usr = UtilityTestClass.createSalesManagerUser();
        Account acc = UtilityTestClass.createTestAccount('Demo Store', 'D002', 'Demo Store', '560076', 'Dealer');
        Opportunity testOpp = UtilityTestClass.createTestOpportunity( 'Test Opportunity', acc.Id, 'New', System.today().addDays(30), 10000);
        Test_Drive__c testDrive = UtilityTestClass.createTest1Driver('Test Drive test',testOpp.Id , 'Reschedule');
        MobileApp_Wrapper.MobileApp_UpdateTestDrive wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateTestDrive();
        wrapperObj.UserId = usr.Id;
        wrapperObj.TestDriveId = testDrive.Id;
        wrapperObj.TestDriveStatus = testDrive.Test_Drive_Status__c;
        wrapperObj.TestDriveDate = '2025-08-05';
        wrapperObj.TestDriveTime = '02:23:45';
        wrapperObj.StartTestDrive = false;
        wrapperObj.CompleteTestDrive = false;
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateTestDrive.createTestDrive();
    }
    @isTest
    static void testcreateTestDrive1() {
        User usr = UtilityTestClass.createSalesManagerUser();
        MobileApp_Wrapper.MobileApp_UpdateTestDrive wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateTestDrive();
        wrapperObj.UserId = usr.Id;
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateTestDrive.createTestDrive();
    }
    @isTest
    static void testcreateTestDrive2() {
        MobileApp_Wrapper.MobileApp_UpdateTestDrive wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateTestDrive();
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateTestDrive.createTestDrive();
    }
    @isTest
    static void testcreateTestDrive3() {
        User usr = UtilityTestClass.createSalesManagerUser();
        Account acc = UtilityTestClass.createTestAccount('Demo Store', 'D002', 'Demo Store', '560076', 'Dealer');
        Opportunity testOpp = UtilityTestClass.createTestOpportunity( 'Test Opportunity', acc.Id, 'New', System.today().addDays(30), 10000);
        Test_Drive__c testDrive = UtilityTestClass.createTest1Driver('Test Drive test',testOpp.Id , 'Reschedule');
        MobileApp_Wrapper.MobileApp_UpdateTestDrive wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateTestDrive();
        wrapperObj.UserId = usr.Id;
        wrapperObj.TestDriveId = testDrive.Id;
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateTestDrive.createTestDrive();
    }
    @isTest
    static void testcreateTestDrive4() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateTestDrive.createTestDrive();
    }
    @isTest
    static void testUpdateException() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateLead';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf('Invalid');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileAPP_UpdateTestDrive.createTestDrive();
    }
    @isTest
    static void testCreateTestDrive5() {
        User usr = UtilityTestClass.createSalesManagerUser();
        Account acc = UtilityTestClass.createTestAccount('Demo Store', 'D002', 'Demo Store', '560076', 'Dealer');
        Opportunity opp = UtilityTestClass.createTestOpportunity('Test Opportunity', acc.Id, 'New', System.today().addDays(10), 5000);
        Test_Drive__c testDrive = UtilityTestClass.createTest1Driver('Test Drive', opp.Id, 'Scheduled');
        
        MobileApp_Wrapper.MobileApp_UpdateTestDrive wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateTestDrive();
        wrapperObj.UserId = usr.Id;
        wrapperObj.TestDriveId = testDrive.Id;
        wrapperObj.TestDriveStatus = 'Reschedule';
        
        
        String jsonBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateTestDrive';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateTestDrive.createTestDrive();
        
    }
    @isTest
    static void testCreateTestDrive6() {
        User usr = UtilityTestClass.createSalesManagerUser();
        Account acc = UtilityTestClass.createTestAccount('Demo Store', 'D002', 'Demo Store', '560076', 'Dealer');
        Opportunity opp = UtilityTestClass.createTestOpportunity('Test Opportunity', acc.Id, 'New', System.today().addDays(10), 5000);
        Test_Drive__c testDrive = UtilityTestClass.createTest1Driver('Test Drive', opp.Id, 'Reschedule');
        
        MobileApp_Wrapper.MobileApp_UpdateTestDrive wrapperObj = new MobileApp_Wrapper.MobileApp_UpdateTestDrive();
        wrapperObj.UserId = usr.Id;
        wrapperObj.TestDriveId = testDrive.Id;
        wrapperObj.TestDriveStatus = testDrive.Test_Drive_Status__c;
        wrapperObj.TestDriveDate = '2025-08-05';
        wrapperObj.TestDriveTime = '02:23:45';
        wrapperObj.StartTestDrive = true;
        
        
        String jsonBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateTestDrive';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        MobileAPP_UpdateTestDrive.createTestDrive();
        
    }


}