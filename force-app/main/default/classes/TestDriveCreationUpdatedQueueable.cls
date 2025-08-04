/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 08-04-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class TestDriveCreationUpdatedQueueable implements Queueable,Database.allowsCallouts{

    private List<Id> testDriveIds;
    private Map<Id,String> idToPhoneMap;
    private Map<Id,String> idToTimeMap;
    private Map<Id,String> idToRideTypeMap;
    private Map<Id,String> idToTimeOnly;

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
        try{
            String fullPhone = '+91'+ phoneNumber;
            Map<String,Object> payLoad = new Map<String,Object>();
            
            List<Map<String,Object>> components = new List<Map<String,Object>>();
            Map<String,Object> component1 = new Map<String,Object>();
            Map<String,Object> component2 = new Map<String,Object>();
            Map<String,Object> component3 = new Map<String,Object>();
            Map<String,Object> component4 = new Map<String,Object>();

            //dataset for component 1
            List<Map<String,Object>> paramForData = new List<Map<String,Object>>();
            Map<String,Object> paramForDataMapForTime = new Map<String,Object>();
            Map<String,Object> paramForDataMapForRideType = new Map<String,Object>();
            paramForDataMapForRideType.put('text',rideType);
            paramForDataMapForRideType.put('type','text');
            paramForDataMapForTime.put('text',timeFormat + ' at ' + timeOnly);
            paramForDataMapForTime.put('type','text');
            paramForData.add(paramForDataMapForRideType);
            paramForData.add(paramForDataMapForTime);
            component1.put('parameters',paramForData);
            component1.put('type','body');
           //upto here 

           //dataset for component 2
           List<Map<String,Object>> paramForComp2 = new List<Map<String,Object>>();
           Map<String,Object> param2 = new Map<String,Object>();
           param2.put('payload','CONFIRM_TEST_RIDE');
           param2.put('type','payload');
           paramForComp2.add(param2);
           component2.put('parameters',paramForComp2);
           component2.put('index','0');
           component2.put('sub_type','quick_reply');
           component2.put('type','button');
           //upto here

           //dataset for component 3
           List<Map<String,Object>> paramForComp3 = new List<Map<String,Object>>();
           Map<String,Object> param3 = new Map<String,Object>();
           param3.put('payload','RESCHEDULE');
           param3.put('type','payload');
           paramForComp3.add(param3);
           component3.put('parameters',paramForComp3);
           component3.put('index','1');
           component3.put('sub_type','quick_reply');
           component3.put('type','button');
           //upto here

           //dataset for component 3
           List<Map<String,Object>> paramForComp4 = new List<Map<String,Object>>();
           Map<String,Object> param4 = new Map<String,Object>();
           param4.put('payload','CANCEL_TEST_RIDE');
           param4.put('type','payload');
           paramForComp4.add(param4);
           component4.put('parameters',paramForComp4);
           component4.put('index','2');
           component4.put('sub_type','quick_reply');
           component4.put('type','button');
           //upto here
           
           components.add(component1);
           components.add(component2);
           components.add(component3);
           components.add(component4);

        
          Map<String,Object> template = new Map<String,Object>();
          Map<String,Object> language = new Map<String,Object>();
          language.put('code','en_US');
          template.put('components',components);
          template.put('language',language);
          template.put('name','test_ride_reminder_confirmation');

          payLoad.put('template',template);
          payLoad.put('type','template');
          payLoad.put('to',fullPhone);
          payLoad.put('messaging_product','whatsapp');

          String serializedBody = JSON.serializePretty(payLoad);
          System.debug('Payload==>'+serializedBody);

          Http http = new Http();
          HttpRequest req = new HttpRequest();
          req.setHeader('apikey','KK47b958dee3505cf2e2c6391c27bbaba4');
          req.setHeader('Content-Type','application/json');
          req.setHeader('Cookie','PHPSESSID=b1b5beb88ec80de98066dad0b5c9349d');
          req.setHeader('Authorization','Bearer EAAXxARj4rG4BAGn1hROuTWTC8OdZAoHslZBZBSoHMKoW6efGAZAfdpklXYFSJLeSjfnQBvWjjGH2GFulHP0FkGY440TZBn2ox405jamyBhLIdSBJvUw0c1Ii71ZBYAtJUJ3AaavdgDcy1DyFZA93gWtKdRDPc458caPQHzhjfVHXgqsZCf1FJMXU');
          req.setBody(serializedBody);
          req.setEndpoint('https://graph.facebook.com/v18.0/449353421601049/messages');
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