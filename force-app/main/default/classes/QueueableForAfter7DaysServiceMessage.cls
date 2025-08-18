/**
 * @description       : 
 * @author            : Aniket Karmkaar
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QueueableForAfter7DaysServiceMessage implements Queueable, Database.AllowsCallouts{
   private List<Id> jobCardIds;
    private Map<Id,String> serviceCentreNameMap;
    private Map<Id,String> phoneNumberMap;
    public QueueableForAfter7DaysServiceMessage(List<Id> jobCardIds,Map<Id,String> serviceCentreNameMap,Map<Id,String> phoneNumberMap) {
        this.jobCardIds=jobCardIds;
        this.serviceCentreNameMap=serviceCentreNameMap;
        this.phoneNumberMap=phoneNumberMap;

    }
    public void execute(QueueableContext qc){
        if(!jobCardIds.isEmpty()){
            Id currentJobcardId = jobCardIds.remove(0);
            String serviceCentreName = serviceCentreNameMap.get(currentJobcardId);
            String phoneNumber = phoneNumberMap.get(currentJobcardId);

            if(currentJobcardId!=null && String.isNotBlank(serviceCentreName) && String.isNotBlank(phoneNumber)){
                sendWhatsAppMessage(currentJobcardId,serviceCentreName,phoneNumber);
            }
            if(!jobCardIds.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableForAfter7DaysServiceMessage(jobCardIds,serviceCentreNameMap,phoneNumberMap));
            }
        }
    }
    public static void sendWhatsAppMessage(Id jobcardId,String serviceCentreName,String phoneNumber){
        System.debug('My Queueable Is called');
        WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
        String endPoint = w.API_Endpoint_Updated__c;
        //String token = w.Service_Bearer_Token__c;
        String fullPhone = phoneNumber;//Updated By Aniket on 12/08/2025
        String templateName = 'service_message_post_7_days';
        String apiKey = w.API_Key__c;
        try{
        Map<String, Object> payload = new Map<String, Object>();
        // payload.put('messaging_product', 'whatsapp');
        // payload.put('recipient_type', 'individual');
        // payload.put('to', fullPhone);
        // payload.put('type', 'template');

        
        // Map<String, Object> template = new Map<String, Object>();
        // template.put('name', templateName);
        // template.put('language', new Map<String, Object>{ 'code' => 'en_US' });

       
        // List<Object> components = new List<Object>();

        
        // Map<String, Object> bodyComponent = new Map<String, Object>();
        // bodyComponent.put('type', 'body');
        // bodyComponent.put('parameters', new List<Object>());

        
        // Map<String, Object> buttonComponent = new Map<String, Object>();
        // buttonComponent.put('type', 'button');
        // buttonComponent.put('sub_type', 'url');
        // buttonComponent.put('index', '0');
        // buttonComponent.put('parameters', new List<Object>{
        //     new Map<String, Object>{
        //         'type' => 'text',
        //         'text' => jobcardId
        //     }
        // });

        
        // components.add(bodyComponent);
        // components.add(buttonComponent);

        
        // template.put('components', components);

        List<Map<String,Object>> buttonParameters = new List<Map<String,Object>>();
        List<Map<String, Object>> parameters = new List<Map<String, Object>>();

        Map<String, Object> paramMap = new Map<String, Object>();
        paramMap.put('text', jobcardId);
        paramMap.put('type', 'text');
        parameters.add(paramMap);

        Map<String,Object> buttonParams = new Map<String,Object>();
        buttonParams.put('parameters',parameters);
        buttonParams.put('sub_type','url');
        buttonParams.put('index','0');
        buttonParams.put('type','button');
        buttonParameters.add(buttonParams);

        Map<String,Object> template = new Map<String,Object>();
        template.put('buttonParameters',buttonParameters);
        template.put('parameters',new Map<String,Object>());
        template.put('language','en_US');
        template.put('name',templateName);

        Map<String,Object> recipient = new Map<String,Object>();
        recipient.put('id',fullPhone);

        payload.put('template',template);
        payload.put('type','template');
        payload.put('kookoo_id','OZNTLWA:918197205802');
        payload.put('recipient',recipient);

        String serializedPayload = JSON.serialize(payload);
        System.debug('serializedPayload==>'+JSON.serializePretty(payload));

        Http http = new Http();
        HttpRequest req = new HttpRequest();
       // req.setHeader('Authorization','Bearer '+token);
       // req.setHeader('Cookie','ps_l=1; ps_n=1; ps_l=1; ps_n=1');
        req.setHeader('Content-Type','application/json');
        req.setHeader('apikey',apiKey);
        req.setHeader('Cookie','PHPSESSID=88d4ca379a75625f74c220bbd20947a7');
        req.setMethod('POST');
        req.setBody(serializedPayload);
        req.setEndpoint(endPoint);

        HttpResponse res = http.send(req);
        System.debug('Response Body ==>'+res.getBody());
        if(res.getStatusCode() == 200){
            System.debug('WhatsApp Message is Successfully Sent');
        }


        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
}