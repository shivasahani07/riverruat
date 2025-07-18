/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 06-13-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QueueableForPostServiceWhatsApp implements Queueable, Database.AllowsCallouts{
    private List<Id> jobCardIds;
    private Map<Id,String> serviceCentreNameMap;
    private Map<Id,String> phoneNumberMap;
    public QueueableForPostServiceWhatsApp(List<Id> jobCardIds,Map<Id,String> serviceCentreNameMap,Map<Id,String> phoneNumberMap) {
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
                System.enqueueJob(new QueueableForPostServiceWhatsApp(jobCardIds,serviceCentreNameMap,phoneNumberMap));
            }
        }
    }
    public static void sendWhatsAppMessage(Id jobcardId,String serviceCentreName,String phoneNumber){
        WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
        String endPoint = w.Service_Endpoint__c;
        String token = w.Service_Bearer_Token__c;
        String fullPhone = '+91'+phoneNumber;
        String templateName = 'service_message_right_after_service';
        try{
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('messaging_product', 'whatsapp');
        payload.put('recipient_type', 'individual');
        payload.put('to', fullPhone);
        payload.put('type', 'template');

        
        Map<String, Object> template = new Map<String, Object>();
        template.put('name', templateName);
        template.put('language', new Map<String, Object>{ 'code' => 'en_US' });

       
        List<Object> components = new List<Object>();

        
        Map<String, Object> bodyComponent = new Map<String, Object>();
        bodyComponent.put('type', 'body');
        bodyComponent.put('parameters', new List<Object>{
            new Map<String, Object>{
                'type' => 'text',
                'text' => serviceCentreName
            }
        });

        
        Map<String, Object> buttonComponent = new Map<String, Object>();
        buttonComponent.put('type', 'button');
        buttonComponent.put('sub_type', 'url');
        buttonComponent.put('index', '0');
        buttonComponent.put('parameters', new List<Object>{
            new Map<String, Object>{
                'type' => 'text',
                'text' => jobcardId
            }
        });

        
        components.add(bodyComponent);
        components.add(buttonComponent);

        
        template.put('components', components);

        
        payload.put('template', template);

        String serializedPayload = JSON.serialize(payload);
        System.debug('serializedPayload==>'+JSON.serializePretty(payload));

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization','Bearer '+token);
        req.setHeader('Cookie','ps_l=1; ps_n=1; ps_l=1; ps_n=1');
        req.setHeader('Content-Type','application/json');
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