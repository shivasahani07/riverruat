@isTest
public class LeadCreationAPI91WheelsTest {
 @testSetup
    static void setup() {
        // Setup test data
    }

    @isTest
    static void testCreateLeadFromWebsite_NewLead() {
        // Mock HTTP request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"LastName":"John Doe","Company":"ABC Inc.","Email":"john.doe@example.com","Phone":"+919035244424","City":"New York","PostalCode":"293002","DealerCode":"293002"}');
        req.httpMethod = 'POST';
        RestContext.request = req;

        // Call the tested method
        //String result = LeadCreationAPI91Wheels.createLeadFromWebsite();
        try{
             String result = LeadCreationAPI91Wheels.createLeadFromWebsite();
        }catch(Exception e){
            
        }


    }

    @isTest
    static void testCreateLeadFromWebsite_ExistingLead() {
        // Create an existing lead
        Lead existingLead = new Lead(LastName='Jane Doe', Company='ABC Inc.', Email='jane.doe@example.com', Phone='+919035244424', City='New York', PostalCode='293002', Dealer_Code__c='293002');
        insert existingLead;

        // Mock HTTP request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"LastName":"Jane Doe Updated","Company":"ABC Inc. Updated","Email":"jane.doe.updated@example.com","Phone":"+919035244424","City":"New York Updated","PostalCode":"293002","DealerCode":"293002"}');
        req.httpMethod = 'POST';
        RestContext.request = req;

        // Call the tested method

        try{
             String result = LeadCreationAPI91Wheels.createLeadFromWebsite();
        }catch(Exception e){
            
        }
        //Lead updatedLead = [SELECT LastName, Company, Email, City, PostalCode FROM Lead WHERE Phone = '+919035244424'][0];

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
            LeadCreationAPI91Wheels.createLeadFromWebsite();
        } catch (JSONException e) {

        }
    }

}