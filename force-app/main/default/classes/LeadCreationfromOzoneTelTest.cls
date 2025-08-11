@isTest
public class LeadCreationfromOzoneTelTest {
 @TestSetup
    static void setup() {
        // Setup test data
    }

    @IsTest
    static void testCreateLeadFromWebsite() {
        // Test creating a new lead
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"FullName": "John Doe", "Company": "ABC", "Email": "john.doe@example.com", "Phone": "1234567890", "City": "San Francisco", "PostalCode": "94105", "HomeTestRide": true, "InstoreTestdrive": false, "startDateTimeStr": "2023-10-25 10:00:00", "endDateTimeStr": "2023-10-25 13:00:00", "DealerCode": "XYZ"}');
        RestContext.request = req;
        String result = LeadCreationFromRiverWebsite.createLeadFromWebsite();
    }

    @IsTest
    static void testUpdateExistingLead() {
        // Test updating an existing lead
        Lead lead = new Lead(LastName = 'John Doe', Company = 'Jane Doe', Email = 'john.doe@example.com', Phone = '1234567890');
        insert lead;
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"FullName": "Jane Doe", "Company": "Jane Doe", "Email": "jane.doe@example.com", "Phone": "1234567890", "City": "San Francisco", "PostalCode": "94105", "HomeTestRide": true, "InstoreTestdrive": false, "startDateTimeStr": "2023-10-25 10:00:00", "endDateTimeStr": "2023-10-25 13:00:00", "DealerCode": "XYZ"}');
        RestContext.request = req;
        String result = LeadCreationfromOzoneTel.createLeadFromWebsite();
    }

    @IsTest
    static void testNullValues() {
        // Test handling null values
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"FullName": "John Doe", "Company": null, "Email": null, "Phone": "1234567890", "City": null, "PostalCode": null, "HomeTestRide": null, "InstoreTestdrive": null, "startDateTimeStr": null, "endDateTimeStr": null, "DealerCode": null}');
        RestContext.request = req;
        String result = LeadCreationfromOzoneTel.createLeadFromWebsite();
    }
}