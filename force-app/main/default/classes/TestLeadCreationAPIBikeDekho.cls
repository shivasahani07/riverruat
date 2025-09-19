@isTest
private class TestLeadCreationAPIBikeDekho {

    @testSetup
    static void setupTestData() {
        // Create a dealer account
        Account dealer = new Account(
            Name = 'Test Dealer',
            Type = 'Dealer',
            Center_Code__c = 'DLR001'
        );
        insert dealer;
    }

    // Utility method to generate request payload
    private static String generateRequestBody(String phone, Boolean withDates, Boolean includePostalCode) {
        Map<String, Object> requestData = new Map<String, Object>{
            'FullName' => 'Bike Dekho User',
            'Company' => 'BikeDekho Ltd',
            'Email' => 'bikedekho@example.com',
            'Phone' => phone,
            'City' => 'Test City',
            'buyingSpan' => 'Within 7 Days',  // Make sure this is a valid picklist value
            'HomeTestRide' => true,
            'InstoreTestdrive' => false,
            'DealerCode' => 'DLR001'
        };

        if (includePostalCode) {
            requestData.put('PostalCode', '560001');  // Dummy PIN
        }

        if (withDates) {
            requestData.put('startDateTimeStr', String.valueOf(System.now()));
            requestData.put('endDateTimeStr', String.valueOf(System.now().addHours(1)));
        }

        return JSON.serialize(requestData);
    }

    @isTest
    static void testCreateNewLead() {
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/createLeadBikeDekho';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generateRequestBody('9999999999', true, true));

        RestContext.request = req;
        RestContext.response = res;

        String response = LeadCreationAPIBikeDekho.createLeadFromWebsite();
        System.debug('Response: ' + response);

        System.assert(response.contains('Lead processed successfully'), 'Actual Response: ' + response);

        Test.stopTest();

        List<Lead> leads = [SELECT Id FROM Lead WHERE Phone = '9999999999'];
        System.assertEquals(1, leads.size(), 'Lead should be inserted');

        List<Integration_Log__c> logs = [SELECT Id FROM Integration_Log__c WHERE Status__c = 'Success'];
        System.assert(!logs.isEmpty(), 'Integration log should be created');
    }

    @isTest
    static void testDuplicateLeadHandling() {
        // Insert a lead with same phone to simulate duplicate
        Lead existingLead = new Lead(
            LastName = 'Existing',
            Company = 'Existing Co',
            Email = 'existing@example.com',
            Phone = '8888888888',
            City = 'Existing City',
            PostalCode = '560001'
        );
        insert existingLead;

        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/createLeadBikeDekho';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generateRequestBody('8888888888', false, true));

        RestContext.request = req;
        RestContext.response = res;

        String response = LeadCreationAPIBikeDekho.createLeadFromWebsite();
        System.debug('Duplicate Response: ' + response);

        System.assert(response.contains('Duplicate Lead Found'), 'Expected duplicate lead handling');
        System.assertEquals(409, RestContext.response.statusCode, 'Should return HTTP 409 for duplicates');

        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Id, Response_Payload__c 
            FROM Integration_Log__c 
            WHERE Lead__c = :existingLead.Id
        ];
        System.assert(!logs.isEmpty(), 'Duplicate log should be recorded');
        System.assert(logs[0].Response_Payload__c.contains('Duplicate Lead Found'), 'Response should mention duplicate');
    }

    @isTest
    static void testCreateLeadWithoutPostalCode() {
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/createLeadBikeDekho';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generateRequestBody('7777777777', false, false));

        RestContext.request = req;
        RestContext.response = res;

        String response = LeadCreationAPIBikeDekho.createLeadFromWebsite();
        System.debug('Fallback Dealer Response: ' + response);

        System.assert(response.contains('Lead processed successfully'), 'Expected success message without postal code');

        Test.stopTest();

        List<Lead> leads = [SELECT Id, Dealer_Code__c FROM Lead WHERE Phone = '7777777777'];
        System.assertEquals(1, leads.size(), 'Lead should be inserted');
        System.assertEquals('DLR001', leads[0].Dealer_Code__c, 'Dealer code should fallback to provided value');

        List<Integration_Log__c> logs = [SELECT Id FROM Integration_Log__c WHERE Status__c = 'Success'];
        System.assert(!logs.isEmpty(), 'Success log should be created');
    }
}