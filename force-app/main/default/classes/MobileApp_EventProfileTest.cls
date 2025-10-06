@isTest
public class MobileApp_EventProfileTest {
    @isTest
    static void testGetTestDrives_success() {
        User usr = UtilityTestClass.createSalesManagerUser1();
        System.runAs(usr) {
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/EventProfile';
            req.httpMethod = 'POST';
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            MobileApp_EventProfile.getTestDrives();
        }
    }
}