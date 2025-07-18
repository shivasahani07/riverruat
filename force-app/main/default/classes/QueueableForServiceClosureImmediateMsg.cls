/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 06-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QueueableForServiceClosureImmediateMsg implements Queueable, Database.AllowsCallouts{
    private List<Id> jobCardIds;
    private Map<Id,String> jobCardNumberMap;
    private Map<Id,String> scAdvisorNameMap;
    private Map<Id,String> scAdvisorPhoneMap;
    private Map<Id,String> wmNameMapForMap;
    private Map<Id,String> wmPhoneMapForMap;
    private Map<Id,String> asmNameMap;
    private Map<Id,String> asmEmailMap;
    private Map<Id,String> phoneMap;
    public QueueableForServiceClosureImmediateMsg(List<Id> jobCardIds,Map<Id,String> jobCardNumberMap,Map<Id,String> scAdvisorNameMap,
                                                   Map<Id,String> scAdvisorPhoneMap,Map<Id,String> wmNameMapForMap,Map<Id,String> wmPhoneMapForMap,Map<Id,String> asmNameMap,
                                                   Map<Id,String> asmEmailMap,Map<Id,String> phoneMap) {

       this.jobCardIds=jobCardIds;
       this.jobCardNumberMap=jobCardNumberMap;
       this.scAdvisorNameMap=scAdvisorNameMap;
       this.scAdvisorPhoneMap = scAdvisorPhoneMap;
       this.wmNameMapForMap = wmNameMapForMap;
       this.wmPhoneMapForMap = wmPhoneMapForMap;
       this.asmNameMap = asmNameMap;
       this.asmEmailMap = asmEmailMap;
       this.phoneMap = phoneMap;
    }

    public void execute(QueueableContext qc){
        if(!jobCardIds.isEmpty()){
            Id currentJobcardId = jobCardIds.remove(0);
            String workOrderNumber = jobCardNumberMap.get(currentJobcardId);
            String serviceAdvisorName = scAdvisorNameMap.get(currentJobcardId);
            String serviceAdvisorPhone =  scAdvisorPhoneMap.get(currentJobcardId);
            String workManagerName = wmNameMapForMap.get(currentJobcardId);
            String workManagerPhone = wmPhoneMapForMap.get(currentJobcardId);
            String asmName = asmNameMap.get(currentJobcardId);
            String asmEmail = asmEmailMap.get(currentJobcardId);
            String phone = phoneMap.get(currentJobcardId);
             

            if(workOrderNumber != null){
                sendWhatsAppMessage(workOrderNumber,serviceAdvisorName,serviceAdvisorPhone,workManagerName,workManagerPhone,asmName,asmEmail,phone);
            }
            
            if(!jobCardIds.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableForServiceClosureImmediateMsg(jobCardIds,jobCardNumberMap,scAdvisorNameMap,scAdvisorPhoneMap,wmNameMapForMap,wmPhoneMapForMap,asmNameMap,asmEmailMap,phoneMap));
            }
        }
    }
    public static void sendWhatsAppMessage(String workOrderNumber,String serviceAdvisorName,String serviceAdvisorPhone,String workManagerName,
                                            String workManagerPhone, String asmName, String asmEmail, String phone){
         
        try{
           WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
        String url = String.isNotBlank(w.API_Endpoint__c) ? w.API_Endpoint__c : '';
        String apikey = String.isNotBlank(w.API_Key__c) ? w.API_Key__c : '';
        String recipientPhoneNumber = '+91' + phone;

        Map<String,Object> payload = new Map<String,Object>();

        Map<String,Object> template = new Map<String,Object>();
        Map<String,Object> parameters = new Map<String,Object>();

        Map<String,Object> recipient = new Map<String,Object>();
        recipient.put('id',recipientPhoneNumber);

        parameters.put('7',asmEmail);
        parameters.put('6',asmName);
        parameters.put('5',workManagerPhone);
        parameters.put('4',workManagerName);
        parameters.put('3',serviceAdvisorPhone);
        parameters.put('2',serviceAdvisorName);
        parameters.put('1',workOrderNumber);

        template.put('parameters',parameters);
        template.put('language','en_US');
        template.put('name','job_card_closer');

        payload.put('template',template);
        payload.put('type','template');
        payload.put('kookoo_id','OZNTLWA:918197205802');
        payload.put('recipient',recipient);

        String requestBody = JSON.serialize(payload);
        System.debug('PayLoad == >'+JSON.serializePretty(payload));

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://in1-ccaaspro.ozonetel.com/whatsApp_API/v1/WhatsAppSendOzone/reply');
       // req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('apikey','KK47b958dee3505cf2e2c6391c27bbaba4');
        req.setHeader('Cookie','PHPSESSID=b1b5beb88ec80de98066dad0b5c9349d');
        req.setHeader('Content-Type','application/json');
        req.setBody(requestBody);

        HttpResponse res = http.send(req);
        if(res.getStatusCode() == 200){
            System.debug('WhatsApp Message is sent successfully');
        }


        } catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }                                       

     }
}