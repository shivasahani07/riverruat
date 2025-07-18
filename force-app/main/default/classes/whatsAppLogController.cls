/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @last modified on  : 03-31-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
@RestResource(urlMapping='/buttonClicks')
global with sharing class whatsAppLogController {
    @HttpPost
    global static void createIntegrationLog(){

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        try {
            
            String reqBody = request.requestBody != null ? request.requestBody.toString() : '';
            System.debug('Request Body ==> ' + reqBody);

            
            Map<String, Object> requestMap = (reqBody != '') ?  (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String,Object>();
            System.debug('Request Map ==>'+requestMap);

            
            String phoneNumber = requestMap.containsKey('phoneNumber') ? (String) requestMap.get('phoneNumber') : '';
            String buttonName = requestMap.containsKey('buttonname') ? (String) requestMap.get('buttonname') : '';

            Integration_Log__c log = new Integration_Log__c();
            log.Request_Payload__c = reqBody;
           // log.Response_Payload__c = resBody;
            log.Phone_Number__c = phoneNumber;
            log.Button_Name__c = buttonName;
            insert log;

            Map<String,Object> responseMapToReturn = new Map<String,Object>();
            Map<String,Object> data = new Map<String,Object>();

            data.put('status code',200);
            data.put('message','success');
            
            responseMapToReturn.put('data',data);
            
            String payloadToReturn = JSON.serializePretty(responseMapToReturn);

            response.responseBody = Blob.valueOf(payloadToReturn);

            String resBody = response.responseBody != null ? response.responseBody.toString() : '';
            System.debug('Inserted Log Record Is ==>'+log);

           
        } 
        catch (Exception e) {
            System.debug('Error occurred ==> ' + e.getMessage());
            System.debug('Error Line Number ==> ' + e.getLineNumber());
            
            Map<String,Object> responseMapToReturn = new Map<String,Object>();
            Map<String,Object> data = new Map<String,Object>();

            data.put('status code','400');
            data.put('message',e.getMessage());
            
            responseMapToReturn.put('data',data);

            String payloadToReturn = JSON.serializePretty(responseMapToReturn);
            response.responseBody = Blob.valueOf(payloadToReturn);
           
        }
    }
}