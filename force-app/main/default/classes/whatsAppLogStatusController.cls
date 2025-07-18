/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 03-31-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/whatsappLogStatus')
global with sharing class whatsAppLogStatusController {
    @HttpPost
    global static void populateStatusOnIntegrationLogs(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        try{
            String reqBody = request.requestBody != null ? request.requestBody.toString() : '';
            System.debug('Request Body ==> ' + reqBody);

            
            Map<String, Object> requestMap = (reqBody != '') ?  (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String,Object>();
            System.debug('Request Map ==>'+requestMap);
            
            Object recipientIdObj = requestMap.get('recipient_id');
            String phoneNumber = recipientIdObj != null ? String.valueOf(recipientIdObj) : '';

           // String phoneNumber = requestMap.containsKey('recipient_id') ? (String)requestMap.get('recipient_id') : '';
            String messageStatus = requestMap.containsKey('status') ? (String)requestMap.get('status') : '';

           
            Integration_Log__c log = new Integration_Log__c();
            log.Request_Payload__c = reqBody;
           // log.Response_Payload__c = resBody;
            log.Phone_Number__c = phoneNumber;
            log.WhatsApp_Message_Status__c = messageStatus;
            log.Status__c='Success';
            insert log;
           

            Map<String,Object> responseMap = new Map<String,Object>();
            Map<String,Object> data = new Map<String,Object>();
            data.put('status code',200);
            data.put('message','success');
            responseMap.put('data',data);

            String payloadToReturn = JSON.serializePretty(responseMap);

            response.responseBody = Blob.valueOf(payloadToReturn);
            
            String resBody = response.responseBody != null ? response.responseBody.toString() : '';
            

            System.debug('Inserted Log Record Is ==>'+log);

        }catch(Exception e){
            System.debug('Error occurred ==> ' + e.getMessage());
            System.debug('Error Line Number ==> ' + e.getLineNumber());

            Map<String,Object> responseMap = new Map<String,Object>();
            Map<String,Object> data = new Map<String,Object>();
            data.put('status code',400);
            data.put('message',e.getMessage());
            responseMap.put('data',data);

            String payloadToReturn = JSON.serializePretty(responseMap);

            response.responseBody = Blob.valueOf(payloadToReturn);
        }
    }
}