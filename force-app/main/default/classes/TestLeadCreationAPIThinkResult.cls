@isTest
private class TestLeadCreationAPIThinkResult {

    // Common setup: create a test dealer account
    @testSetup
    static void setupData() {
        Account dealer = new Account(
            Name = 'Test Dealer',
            Type = 'Dealer',
            Center_Code__c = 'DLR001'
        );
        insert dealer;
    }

    // Utility method to create request body JSON
    private static String generateRequestBody(String phone, Boolean withDates, Boolean includePostalCode) {
        Map<String, Object> requestMap = new Map<String, Object>{
            'FullName' => 'Test User',
            'Company' => 'Test Company',
            'Email' => 'testuser@example.com',
            'Phone' => phone,
            'City' => 'Test City',
            'buyingSpan' => 'Within 7 Days',
            'HomeTestRide' => true,
            'InstoreTestdrive' => false,
            'DealerCode' => 'DLR001'
        };

        if (includePostalCode) {
            requestMap.put('PostalCode', '560001'); // any dummy pin code
        }

        if (withDates) {
            requestMap.put('startDateTimeStr', String.valueOf(System.now()));
            requestMap.put('endDateTimeStr', String.valueOf(System.now().addHours(2)));
        }

        return JSON.serialize(requestMap);
    }

    // Test case: Successful lead creation
    @isTest
    static void testCreateNewLead() {
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/LeadCreationAPIThinkResult';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generateRequestBody('9999999999', true, true));

        RestContext.request = req;
        RestContext.response = res;

        String response = LeadCreationAPIThinkResult.createLeadFromWebsite();
        System.debug('Response: ' + response);

        System.assert(response.contains('Lead processed successfully'), 'Actual Response: ' + response);
     //   System.assertEquals(200, RestContext.response.statusCode == 0 ? 200 : RestContext.response.statusCode);

        Test.stopTest();

        List<Lead> leads = [SELECT Id FROM Lead WHERE Phone = '9999999999'];
        System.assertEquals(1, leads.size(), 'Lead should be inserted');

        List<Integration_Log__c> logs = [SELECT Id, Status__c FROM Integration_Log__c WHERE Status__c = 'Success'];
        System.assert(!logs.isEmpty(), 'Success log should be inserted');
    }

    // Test case: Duplicate lead handling (Conflict 409)
    @isTest
    static void testDuplicateLeadHandling() {
        // Create an existing lead with same phone
        Lead existingLead = new Lead(
            LastName = 'Existing Lead',
            Company = 'Existing Co',
            Phone = '8888888888',
            Email = 'existing@example.com',
            City = 'City',
            PostalCode = '560001'
        );
        insert existingLead;

        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/LeadCreationAPIThinkResult';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generateRequestBody('8888888888', false, true));

        RestContext.request = req;
        RestContext.response = res;

        String response = LeadCreationAPIThinkResult.createLeadFromWebsite();
        System.debug('Duplicate Response: ' + response);

        System.assert(response.contains('Duplicate Lead Found'), 'Should detect duplicate lead');
        System.assertEquals(409, RestContext.response.statusCode, 'Expected status code 409');

        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Id, Response_Payload__c 
            FROM Integration_Log__c 
            WHERE Lead__c = :existingLead.Id
        ];
        System.assert(!logs.isEmpty(), 'Duplicate log should be inserted');
        System.assert(logs[0].Response_Payload__c.contains('Duplicate Lead Found'));
    }

    // Test case: Missing PostalCode – fallback to DealerCode
    @isTest
    static void testFallbackWithoutPostalCode() {
        Test.startTest();

        // Create request body with null postal code and valid dealer code
        String body = generateRequestBody('7777777777', false, false);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/LeadCreationAPIThinkResult';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        String response = LeadCreationAPIThinkResult.createLeadFromWebsite();
        System.debug('Fallback Response: ' + response);

        System.assert(response.contains('Lead processed successfully'), 'Actual Response: ' + response);
      //  System.assertEquals(200, RestContext.response.statusCode == 0 ? 200 : RestContext.response.statusCode);

        Test.stopTest();

        List<Lead> leads = [SELECT Id, Dealer_Code__c FROM Lead WHERE Phone = '7777777777'];
        System.assertEquals(1, leads.size(), 'Lead should be inserted without postal code');

        System.assertEquals('DLR001', leads[0].Dealer_Code__c, 'Dealer code should fallback correctly');

        List<Integration_Log__c> logs = [
            SELECT Id, Status__c FROM Integration_Log__c 
            WHERE Status__c = 'Success'
        ];
        System.assert(!logs.isEmpty(), 'Success log should be created');
    }
}