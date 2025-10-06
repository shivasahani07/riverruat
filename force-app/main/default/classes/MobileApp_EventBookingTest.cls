@isTest
public class MobileApp_EventBookingTest {
    @isTest
    static void testValidRequestToday() {
        User testUser = UtilityTestClass.createSalesManagerUser();
        System.runAs(testUser) {
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrapper.UserId = testUser.Id;
            wrapper.FilterDate = 'TODAY';
            wrapper.FilterEndRange = null;

            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestUri = '/services/apexrest/EventBooking';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
            RestContext.request = req;
            RestContext.response = res;

            MobileApp_EventBooking.getRetails();
        }
    }
    @isTest
    static void testValidRequestToday1() {
        User testUser = UtilityTestClass.createSalesManagerUser();
        System.runAs(testUser) {
            
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrapper.UserId = testUser.Id;
            wrapper.FilterDate = 'THIS_MONTH';
            wrapper.FilterEndRange = null;

            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestUri = '/services/apexrest/EventBooking';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
            RestContext.request = req;
            RestContext.response = res;

            MobileApp_EventBooking.getRetails();
        }
    }
        @isTest
    static void testValidRequestToday2() {
        User testUser = UtilityTestClass.createSalesManagerUser();
        System.runAs(testUser) {
            
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrapper.UserId = testUser.Id;
            wrapper.FilterDate = 'THIS_WEEK';
            wrapper.FilterEndRange = null;

            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestUri = '/services/apexrest/EventBooking';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
            RestContext.request = req;
            RestContext.response = res;

            MobileApp_EventBooking.getRetails();
        }
    }
    @isTest
    static void testValidRequestToday3() {
        User testUser = UtilityTestClass.createSalesManagerUser();
        System.runAs(testUser) {
            
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrapper.UserId = testUser.Id;
            wrapper.FilterDate = '2025-03-15';
            wrapper.FilterEndRange = '2025-03-16';

            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestUri = '/services/apexrest/EventBooking';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
            RestContext.request = req;
            RestContext.response = res;

            MobileApp_EventBooking.getRetails();
        }
    }
    @isTest
    static void testValidRequestToday4() {
        MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
        wrapper.UserId = ''; 
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventTicket';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileApp_EventBooking.getRetails();
    }
    
    @isTest
    static void testValidRequestToday5() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventTicket';
        req.httpMethod = 'POST';
        req.requestBody = null;
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileApp_EventBooking.getRetails();
    }
    @isTest
    static void testValidRequestToday6() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/EventBooking';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"invalidJson": }');
        RestContext.request = req;
        RestContext.response = res;
        MobileApp_EventBooking.getRetails();
    }

}