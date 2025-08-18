/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 08-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class TestDriveCreationUpdatedQueueable implements Queueable,Database.allowsCallouts{

    private List<Id> testDriveIds{get;set;}
    private Map<Id,String> idToPhoneMap{get;set;}
    private Map<Id,String> idToTimeMap{get;set;} 
    private Map<Id,String> idToRideTypeMap{get;set;}
    private Map<Id,String> idToTimeOnly{get;set;}

    public TestDriveCreationUpdatedQueueable(List<Id> testDriveIds,Map<Id,String> idToPhoneMap,Map<Id,String> idToTimeMap,Map<Id,String> idToRideTypeMap,Map<Id,String> idToTimeOnly) {
        this.testDriveIds = testDriveIds;
        this.idToPhoneMap = idToPhoneMap;
        this.idToTimeMap = idToTimeMap;
        this.idToRideTypeMap = idToRideTypeMap;
        this.idToTimeOnly=idToTimeOnly;
    }
    public void execute(QueueableContext qc){
        if(!testDriveIds.isEmpty()){
            Id currentTestDriveId = testDriveIds.remove(0);
            String phoneNumber = idToPhoneMap.get(currentTestDriveId);
            String timeFormatDate = idToTimeMap.get(currentTestDriveId);
            String rideType = idToRideTypeMap.get(currentTestDriveId);
            String timeOnly = idToTimeOnly.get(currentTestDriveId);

            System.debug('phoneNumber===>'+phoneNumber);
            System.debug('timeFormat===>'+timeFormatDate);
            System.debug('rideType===>'+rideType);

            if(phoneNumber!=null && timeFormatDate!=null && rideType!=null && timeOnly!=null){
                sendWhatsAppMessage(phoneNumber,timeFormatDate,rideType,timeOnly);
            }
            if(!testDriveIds.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new TestDriveCreationUpdatedQueueable(testDriveIds,idToPhoneMap,idToTimeMap,idToRideTypeMap,idToTimeOnly));
            }
        }

    }
    public static void sendWhatsAppMessage(String phoneNumber,String timeFormat,String rideType,String timeOnly){
        List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
        WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
        String endPoint = w.API_Endpoint_Updated__c != null ? w.API_Endpoint_Updated__c : 'Not Found';
        System.debug('endPoint==>'+endPoint);
        // String token = w.Service_Bearer_Token__c != null ? w.Service_Bearer_Token__c : 'Not Found';
        // System.debug('token==>'+token);
        String apiKey = w.API_Key__c != null ? w.API_Key__c : 'Not Found';
        System.debug('apiKey==>'+apiKey);
        // String cookie = w.Cookie__c != null ? w.Cookie__c : 'Not Found';
        // System.debug('cookie==>'+cookie);
        try{
            String fullPhone = '+91'+ phoneNumber;
            Map<String,Object> payLoad = new Map<String,Object>();
            
        //     List<Map<String,Object>> components = new List<Map<String,Object>>();
        //     Map<String,Object> component1 = new Map<String,Object>();
        //     Map<String,Object> component2 = new Map<String,Object>();
        //     Map<String,Object> component3 = new Map<String,Object>();
        //     Map<String,Object> component4 = new Map<String,Object>();

        //     //dataset for component 1
        //     List<Map<String,Object>> paramForData = new List<Map<String,Object>>();
        //     Map<String,Object> paramForDataMapForTime = new Map<String,Object>();
        //     Map<String,Object> paramForDataMapForRideType = new Map<String,Object>();
        //     paramForDataMapForRideType.put('text',rideType);
        //     paramForDataMapForRideType.put('type','text');
        //     paramForDataMapForTime.put('text',timeFormat + ' at ' + timeOnly);
        //     paramForDataMapForTime.put('type','text');
        //     paramForData.add(paramForDataMapForRideType);
        //     paramForData.add(paramForDataMapForTime);
        //     component1.put('parameters',paramForData);
        //     component1.put('type','body');
        //    //upto here 

        //    //dataset for component 2
        //    List<Map<String,Object>> paramForComp2 = new List<Map<String,Object>>();
        //    Map<String,Object> param2 = new Map<String,Object>();
        //    param2.put('payload','CONFIRM_TEST_RIDE');
        //    param2.put('type','payload');
        //    paramForComp2.add(param2);
        //    component2.put('parameters',paramForComp2);
        //    component2.put('index','0');
        //    component2.put('sub_type','quick_reply');
        //    component2.put('type','button');
        //    //upto here

        //    //dataset for component 3
        //    List<Map<String,Object>> paramForComp3 = new List<Map<String,Object>>();
        //    Map<String,Object> param3 = new Map<String,Object>();
        //    param3.put('payload','RESCHEDULE');
        //    param3.put('type','payload');
        //    paramForComp3.add(param3);
        //    component3.put('parameters',paramForComp3);
        //    component3.put('index','1');
        //    component3.put('sub_type','quick_reply');
        //    component3.put('type','button');
        //    //upto here

        //    //dataset for component 3
        //    List<Map<String,Object>> paramForComp4 = new List<Map<String,Object>>();
        //    Map<String,Object> param4 = new Map<String,Object>();
        //    param4.put('payload','CANCEL_TEST_RIDE');
        //    param4.put('type','payload');
        //    paramForComp4.add(param4);
        //    component4.put('parameters',paramForComp4);
        //    component4.put('index','2');
        //    component4.put('sub_type','quick_reply');
        //    component4.put('type','button');
        //    //upto here
           
        //    components.add(component1);
        //    components.add(component2);
        //    components.add(component3);
        //    components.add(component4);

        
        //   Map<String,Object> template = new Map<String,Object>();
        //   Map<String,Object> language = new Map<String,Object>();
        //   language.put('code','en_US');
        //   template.put('components',components);
        //   template.put('language',language);
        //   template.put('name','test_ride_reminder_confirmation');

        //   payLoad.put('template',template);
        //   payLoad.put('type','template');
        //   payLoad.put('to',fullPhone);
        //   payLoad.put('messaging_product','whatsapp');

          Map<String,Object> template = new Map<String,Object>();
         
          List<Map<String,Object>> parameters = new List<Map<String,Object>>();
          Map<String,Object> params = new Map<String,Object>();
          params.put('text',rideType);
          params.put('type','text');
          parameters.add(params);

          List<Map<String,Object>> buttonParameters = new List<Map<String,Object>>();
          Map<String,Object> buttonParams = new Map<String,Object>();
          buttonParams.put('parameters',parameters); 
          buttonParams.put('sub_type','quick_reply'); 
          buttonParams.put('index','0'); 
          buttonParams.put('type','button'); 
          buttonParameters.add(buttonParams);

          Map<String,Object> paramsForTemplate = new Map<String,Object>();
          paramsForTemplate.put('2',timeOnly);
          paramsForTemplate.put('1',timeFormat);

          template.put('buttonParameters',buttonParameters);
          template.put('parameters',paramsForTemplate);
          template.put('language','en_US');
          template.put('name','test_ride_reminder_confirmation');
         
          Map<String,Object> recipient = new Map<String,Object>();
          recipient.put('id',fullPhone);

         payLoad.put('template',template);
         payLoad.put('type','template');
         payLoad.put('kookoo_id','OZNTLWA:918197205802');
         payLoad.put('recipient',recipient);






          String serializedBody = JSON.serializePretty(payLoad);
          System.debug('Payload==>'+serializedBody);

          Http http = new Http();
          HttpRequest req = new HttpRequest();
          req.setHeader('apikey',apiKey);
          req.setHeader('Content-Type','application/json');
          req.setHeader('Cookie','PHPSESSID=33b3d2e99ec53c68aeaa20730d6ae9dd');
          //req.setHeader('Authorization','Bearer '+token);
          req.setBody(serializedBody);
          req.setEndpoint(endPoint);
          req.setMethod('POST');

          HttpResponse res = http.send(req);
          if(res.getStatusCode() == 200){
            System.debug('WhatsApp Message Got Successfully Sent');
          }else{
            System.debug('Error Sending WhatsApp Messsage');
            System.debug('Error Body==>'+res.getBody());
          }

        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
}