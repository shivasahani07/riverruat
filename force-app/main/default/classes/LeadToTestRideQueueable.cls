/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class LeadToTestRideQueueable implements Queueable, Database.allowsCallouts{
    private List<Id> orderIdsToProcess;
    private String templateName;
    private Map<Id,String> orderByPhoneMap;
   
    public LeadToTestRideQueueable(List<Id> orderIdsToProcess, String templateName, Map<Id,String> orderByPhoneMap) {
        system.debug('orderByPhoneMap ===> ' + orderByPhoneMap);
        this.orderIdsToProcess = orderIdsToProcess;
        this.templateName = templateName;
        this.orderByPhoneMap = orderByPhoneMap;
    }
    public void execute(QueueableContext qc){
        
        if(!orderIdsToProcess.isEmpty()){
            Id currentOrderId = orderIdsToProcess.remove(0);
            String phoneNumber = orderByPhoneMap.get(currentOrderId);
            system.debug('currentOrderId ===> ' + currentOrderId);
            system.debug('phoneNumber ===> ' + phoneNumber);
             if(phoneNumber != null && currentOrderId != null){
                withOutParamMsg(templateName,phoneNumber);
            }
            
                if(!orderIdsToProcess.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new LeadToTestRideQueueable(orderIdsToProcess,templateName,orderByPhoneMap));
            }        
        }    
    }
    
    public static void withOutParamMsg(String templateName,String phoneNumber){
        system.debug('templateName ===> ' + templateName);
        system.debug('phoneNumber ===> ' + phoneNumber);
        List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
        
        WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
        String url = w.API_Endpoint_Updated__c!=null ? w.API_Endpoint_Updated__c : '';
        String apikey = w.API_Key__c!=null ? w.API_Key__c : '';
        String recipientId = '91' + phoneNumber;

        // API endpoint
        //String endpoint = 'https://in-ccaas.ozonetel.com/api/v1/WhatsAppSendOzone/reply';

        // Prepare request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('recipient', new Map<String, String>{ 'id' => recipientId });
        requestBody.put('kookoo_id', 'OZNTLWA:918197205802');
        requestBody.put('type', 'template');

        // Prepare template
        Map<String, Object> template = new Map<String, Object>();
        template.put('name', templateName);
        template.put('language', 'en_US');
        template.put('parameters', new Map<String, Object>()); 

        requestBody.put('template', template);

        
        String jsonBody = JSON.serialize(requestBody);
        system.debug('jsonBody ===> ' + JSON.serializePretty(requestBody));

        Http http = new Http();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('apikey', apikey);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
		system.debug('req ===> ' + req);
       
        
        try {
            HttpResponse res = http.send(req);
            System.debug('Response Status: ' + res.getStatus());
            System.debug('Response Body: ' + res.getBody());
            if(res.getStatusCode() == 200){
                System.debug('Lead To Test Ride Flow WhatsApp Message Is Sent Successfully');
            }
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}