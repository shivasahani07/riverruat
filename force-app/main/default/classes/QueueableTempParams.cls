/**
 * @description       : 
 * @author            : Anwar
 * @group             : 
 * @last modified on  : 10-10-2025
 * @last modified by  : Anwar
**/
public class QueueableTempParams implements Queueable, Database.allowsCallouts{
    private List<Id> orderIdsToProcess;
    private String templateName;
    private Map<Id,String> orderByPhoneMap;
    private String color;
   
    public QueueableTempParams(List<Id> orderIdsToProcess, String templateName, Map<Id,String> orderByPhoneMap,String color) {
        system.debug('orderByPhoneMap ===> ' + orderByPhoneMap);
        this.orderIdsToProcess = orderIdsToProcess;
        this.templateName = templateName;
        this.orderByPhoneMap = orderByPhoneMap;
        this.color = color;
    }
    public void execute(QueueableContext qc){
        
        if(!orderIdsToProcess.isEmpty()){
            Id currentOrderId = orderIdsToProcess.remove(0);
            String phoneNumber = orderByPhoneMap.get(currentOrderId);
            system.debug('currentOrderId ===> ' + currentOrderId);
            system.debug('phoneNumber ===> ' + phoneNumber);
             if(phoneNumber != null && currentOrderId != null){
                withOutParamMsg(templateName,phoneNumber,color);
            }
            
                if(!orderIdsToProcess.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableTempParams(orderIdsToProcess,templateName,orderByPhoneMap,color));
            }        
        }    
    }
    
    public static void withOutParamMsg(String templateName,String phoneNumber,String color){
        system.debug('templateName ===> ' + templateName);
        system.debug('phoneNumber ===> ' + phoneNumber);
        List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
        
        WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
        String url = w.API_Endpoint__c!=null ? w.API_Endpoint__c : '';
        String apikey = w.API_Key__c!=null ? w.API_Key__c : '';
        String recipientId = '91' + phoneNumber;
        
        Map<String,Object> parameters = new Map<String,Object>();
        parameters.put('1',color);

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
        template.put('parameters', parameters);

        requestBody.put('template', template);

        
        String jsonBody = JSON.serialize(requestBody);
        system.debug('jsonBody ===> ' + jsonBody);
        System.debug('Payload ==>'+JSON.serializePretty(requestBody));

        Http http = new Http();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('apikey', apikey); // Replace with actual API key
        req.setHeader('Content-Type', 'application/json');
       // req.setHeader('Cookie', 'PHPSESSID=baefcd0d990d72449dfb7692422f8a65'); // Replace with the actual session ID if required
        req.setBody(jsonBody);
		system.debug('req ===> ' + req);
       
        
        try {
            HttpResponse res = http.send(req);
            String status;
            if(res.getStatusCode() == 200){
               status='Success';
            }else{
                status='Failed';
            }
            // IntegrationLogHelper.IntegrationLogWrapper wrapper = new IntegrationLogHelper.IntegrationLogWrapper();
            //         wrapper.requestBody = jsonBody;
            //         wrapper.responseBody = res.getBody();
            //         wrapper.status = status;
            //         wrapper.templateName = templateName;
            //         wrapper.statusCode = String.valueof(res.getStatusCode());

            //         IntegrationLogHelper.createIntegrationLogs(wrapper);
            System.debug('Response Status: ' + res.getStatus());
            System.debug('Response Body: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
        
    }