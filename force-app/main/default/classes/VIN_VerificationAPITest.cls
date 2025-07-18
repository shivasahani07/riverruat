@isTest
public class VIN_VerificationAPITest {
    
    @TestSetup
    static void testSetup() {
        TestDataFactory.createVehicle();
    }
    
    @isTest
    static void testVerifyVINSuccess() {
        // Create test data
        
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('vin_number', '111S');
        requestBody.put('phone_number', '9011113246');
        
        // Set up mock request and response objects
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        // Call the verifyVIN method
        Test.startTest();
        VIN_VerificationAPI.verifyVIN();
        Test.stopTest();
        
        
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        
    }
   
    @isTest
    static void testVerifyVINVehicleNotFound() {
        // Prepare request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('vin_number', '1112S');
        requestBody.put('phone_number', '9011113246');
        
        // Set up mock request and response objects
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        // Call the verifyVIN method
        Test.startTest();
        VIN_VerificationAPI.verifyVIN();
        Test.stopTest();
        
        // Retrieve the response
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());

    }
   
    @isTest
    static void testVerifyVINPhoneNumberMismatch() {
        
        // Prepare request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('vin_number', '111S');
        requestBody.put('phone_number', '1234567890');
        
        // Set up mock request and response objects
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        // Call the verifyVIN method
        Test.startTest();
        VIN_VerificationAPI.verifyVIN();
        Test.stopTest();
        
        // Retrieve the response
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        
    }
    
    @isTest
    static void testVerifyVINPrimaryContactNotSet() {
        Contact con = [SELECT Id from Contact WHERE Primary_Contact__c = true];
        
        delete con;
        
        // Prepare request body
        Map<String, Object> requestBody = new Map<String, Object>();
        
        requestBody.put('vin_number', '111S');
        requestBody.put('phone_number', '9011113246');
        
        // Set up mock request and response objects
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        // Call the verifyVIN method
        Test.startTest();
        VIN_VerificationAPI.verifyVIN();
        Test.stopTest();
        
        // Retrieve the response
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
    }
}