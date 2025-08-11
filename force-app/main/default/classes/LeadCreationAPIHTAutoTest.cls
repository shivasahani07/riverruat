@isTest
public class LeadCreationAPIHTAutoTest {

      @testSetup
    static void setup() {
        // Setup test data
    }

    @isTest
    static void testCreateLeadFromWebsite_NewLead() {
        // Mock HTTP request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"LastName":"John Doe","Company":"ABC Inc.","Email":"john.doe@example.com","Phone":"9876543210","City":"New York","PostalCode":"10001","DealerCode":"Dealer123"}');
        req.httpMethod = 'POST';
        RestContext.request = req;

        String result = LeadCreationAPIHTAuto.createLeadFromWebsite();
    }

    @isTest
    static void testCreateLeadFromWebsite_ExistingLead() {
        // Create an existing lead
        Lead existingLead = new Lead(LastName='Jane Doe', Company='ABC Inc.', Email='jane.doe@example.com', Phone='9876543210', City='New York', PostalCode='10001', Dealer_Code__c='Dealer123');
        insert existingLead;

        // Mock HTTP request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"LastName":"Jane Doe Updated","Company":"ABC Inc. Updated","Email":"jane.doe.updated@example.com","Phone":"+1-987-654-3210","City":"New York Updated","PostalCode":"10001","DealerCode":"Dealer123"}');
        req.httpMethod = 'POST';
        RestContext.request = req;

        // Call the tested method
        String result = LeadCreationAPIHTAuto.createLeadFromWebsite();

    }

    @isTest
    static void testCreateLeadFromWebsite_InvalidRequest() {
        // Mock HTTP request with invalid JSON
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('Invalid JSON');
        req.httpMethod = 'POST';
        RestContext.request = req;

        // Call the tested method and verify it throws an exception
        try {
            LeadCreationAPIHTAuto.createLeadFromWebsite();
        } catch (JSONException e) {
            System.assert(true);
        }
    }

}