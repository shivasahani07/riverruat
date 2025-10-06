@isTest(seealldata =true)
public class MobileAPP_BookOrder_Test {
    @isTest
    static void testUpdate1() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager (Partner)' LIMIT 1];
        Account acc = new Account(Name= 'Partner1 Store', Center_Code__c='D002', Store_Name__c='Demo Partner Store1',BillingPostalCode='888886', Type='Dealer');
        insert acc;
        Contact con = UtilityTestClass.createTestContact('Partner','Manager','partner.manager@example.com','9876543218',acc.Id, 'Sales');
        User usr = new User(
            FirstName = 'Partner', LastName = 'Manager', Alias = 'pmanag',  Email = 'partner.manager@example.com', Username = 'partner.manager.' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id, TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', ContactId = con.Id
        );
        insert usr;
        Pin_Code__c pin = UtilityTestClass.createTestPinCode(acc.Id, '888886', 'Patna1');
        System.runAs(usr) {
            List<Opportunity> oppList = [Select Id from Opportunity Where stageName != 'Closed Won'];
            MobileApp_Wrapper.CustomerDetails customer = new MobileApp_Wrapper.CustomerDetails();
            customer.name = 'Test User';
            customer.email = 'testuser@example.com';
            customer.phone = '9876543210';

            MobileApp_Wrapper.MobileApp_BookOrder wrapperObj = new MobileApp_Wrapper.MobileApp_BookOrder();
            wrapperObj.UserId = usr.Id;
            wrapperObj.OpportunityId = oppList[0].Id;
            wrapperObj.paymentStatus = 'Success';
            wrapperObj.transactionId = 'TXN123456789';
            wrapperObj.paymentMode = 'UPI';
            wrapperObj.paymentGateway = 'Razorpay';
            wrapperObj.orderAmount = 25000; 
            wrapperObj.vehicleColor = 'Yellow';
            wrapperObj.timestamp = DateTime.now();
            wrapperObj.gatewayResponseMessage = 'Payment completed successfully';
            wrapperObj.customerDetails = customer;
            wrapperObj.signature = 'abc123signaturetoken';

            String requestBody = JSON.serialize(wrapperObj);

            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/CreateOrder';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(requestBody);
            RestContext.request = req;

            RestResponse res = new RestResponse();
            RestContext.response = res;

            MobileAPP_BookOrder.createOrder();
        }
    }
    
    @isTest
    static void testUpdate3() {
        
        MobileApp_Wrapper.MobileAPP_BookOrder wrapperObj = new MobileApp_Wrapper.MobileAPP_BookOrder();
        wrapperObj.OrderAmount = 2500;
        wrapperObj.PaymentMode = 'UPI';
        
        String requestBody = JSON.serialize(wrapperObj);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileAPP_BookOrder.createOrder();
        
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
        
        MobileAPP_BookOrder.createOrder();
        
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
        MobileAPP_BookOrder.createOrder();
    }
}