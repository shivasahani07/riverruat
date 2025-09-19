@isTest
private class TestLeadCreationsAPIBikewale {

    @testSetup
    static void setupTestData() {
        // Insert a dealer Account for dealer code lookup
        Account dealer = new Account(
            Name = 'Test Dealer BikeWale',
            Type = 'Dealer',
            Center_Code__c = 'DLRBW001'
        );
        insert dealer;
    }

    // Helper method to generate request JSON payload
    private static String generateRequestBody(String phone, Boolean withDates, Boolean includePostalCode) {
        Map<String, Object> data = new Map<String, Object>{
            'FullName' => 'Test User BikeWale',
            'Company' => 'Test Company BikeWale',
            'Email' => 'testbikewale@example.com',
            'Phone' => phone,
            'City' => 'Test City',
            'buyingSpan' => 'Within 7 Days',
            'HomeTestRide' => true,
            'InstoreTestdrive' => false,
            'DealerCode' => 'DLRBW001'
        };
        if (includePostalCode) {
            data.put('PostalCode', '560001');
        }
        if (withDates) {
            data.put('startDateTimeStr', String.valueOf(System.now()));
            data.put('endDateTimeStr', String.valueOf(System.now().addHours(2)));
        }
        return JSON.serialize(data);
    }

    @isTest
    static void testCreateNewLead() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/createLeadBikeWale';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generateRequestBody('9999999999', true, true));

        RestContext.request = req;
        RestContext.response = res;

        String response = LeadCreationsAPIBikewale.createLeadFromWebsite();
        System.debug('Response: ' + response);

        System.assert(response.contains('Lead processed successfully'), 'Expected success message');

        Test.stopTest();

        List<Lead> leads = [SELECT Id FROM Lead WHERE Phone = '9999999999'];
        System.assertEquals(1, leads.size(), 'Lead should be created');

        List<Integration_Log__c> logs = [SELECT Id, Status__c FROM Integration_Log__c WHERE Status__c = 'Success' AND Integration_Type__c = 'Lead Creation - BikeWale'];
        System.assert(!logs.isEmpty(), 'Success log should be inserted');
    }

    @isTest
    static void testDuplicateLeadHandling() {
        Lead existingLead = new Lead(
            LastName = 'Existing Lead',
            Company = 'Existing Company',
            Phone = '8888888888',
            Email = 'existingbikewale@example.com',
            City = 'Existing City',
            PostalCode = '560001'
        );
        insert existingLead;

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/createLeadBikeWale';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generateRequestBody('8888888888', false, true));

        RestContext.request = req;
        RestContext.response = res;

        String response = LeadCreationsAPIBikewale.createLeadFromWebsite();
        System.debug('Duplicate Response: ' + response);

        System.assert(response.contains('Duplicate Lead Found'), 'Expected duplicate lead message');
        System.assertEquals(409, RestContext.response.statusCode, 'Expected HTTP 409 for duplicates');

        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Id, Response_Payload__c 
            FROM Integration_Log__c 
            WHERE Lead__c = :existingLead.Id AND Integration_Type__c = 'Lead Creation - BikeWale'
        ];
        System.assert(!logs.isEmpty(), 'Duplicate log should be inserted');
        System.assert(logs[0].Response_Payload__c.contains('Duplicate Lead Found'), 'Log response should mention duplicate');
    }

    @isTest
    static void testCreateLeadWithoutPostalCode() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/createLeadBikeWale';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generateRequestBody('7777777777', false, false)); // No postal code

        RestContext.request = req;
        RestContext.response = res;

        String response = LeadCreationsAPIBikewale.createLeadFromWebsite();
        System.debug('Response without PostalCode: ' + response);

        System.assert(response.contains('Lead processed successfully'), 'Expected success message without postal code');

        Test.stopTest();

        List<Lead> leads = [SELECT Id, Dealer_Code__c FROM Lead WHERE Phone = '7777777777'];
        System.assertEquals(1, leads.size(), 'Lead should be created');
        System.assertEquals('DLRBW001', leads[0].Dealer_Code__c, 'Dealer code should fallback correctly');

        List<Integration_Log__c> logs = [SELECT Id, Status__c FROM Integration_Log__c WHERE Status__c = 'Success' AND Integration_Type__c = 'Lead Creation - BikeWale'];
        System.assert(!logs.isEmpty(), 'Success log should be created');
    }
}