@isTest(seealldata = true)
public class MobileApp_EventTicketTest {
    @isTest
    static void testGgetTickets() {
        //User usr = UtilityTestClass.createSalesManagerUser();
        //
        //Contact con = UtilityTestClass.createTestContact('Test','Contact','test@example.com','9876543218',acc.Id, 'Sales');
        User usr = [SELECT Id FROM User WHERE Profile.Name='Sales Manager (Partner)' AND isActive = true LIMIT 1];
        System.runAs(usr) {
            Salesforce_Support__c ticket = new Salesforce_Support__c(
                Status__c = 'Open',
                Subject__c = 'Test Subject',
                Type__c = 'Complaint',
                Description__c = 'Some issue reported',
                Internal_Team_Remarks__c = 'Initial remark'
            );
            insert ticket;
            system.debug('ticket ======>'+ticket);
            
            List<Salesforce_Support__c> salesforceTicket = [Select Id,OwnerId from Salesforce_Support__c Where Id =: ticket.Id];
            system.debug('salesforceTicket ======>'+salesforceTicket);
            
            MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
            wrapper.UserId = UserInfo.getUserId();
            
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/EventTicket';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
            RestContext.request = req;
            
            RestResponse res = new RestResponse();
            RestContext.response = res;
            
            MobileApp_EventTicket.getTickets();
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
        }
        
    }

    @isTest
    static void testGgetTickets1() {
        MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper wrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
        wrapper.UserId = ''; 
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventTicket';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileApp_EventTicket.getTickets();
    }
    
    @isTest
    static void testGgetTickets2() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EventTicket';
        req.httpMethod = 'POST';
        req.requestBody = null;
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        MobileApp_EventTicket.getTickets();
    }
    
}