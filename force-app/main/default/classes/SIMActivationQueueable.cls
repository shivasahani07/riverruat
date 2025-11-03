/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-31-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class SIMActivationQueueable implements Queueable, Database.allowsCallouts{
    private List<Id> vehicleIds;
    private Map<Id,String> chipPhoneMap;
    private Map<Id,String> cmpState;
    private Map<Id,String> currentCmpState;
    
    public SIMActivationQueueable(List<Id> vehicleIds,Map<Id,String> chipPhoneMap,Map<Id,String> cmpState,Map<Id,String> currentCmpState) {

        this.vehicleIds = vehicleIds;
        this.chipPhoneMap = chipPhoneMap;
        this.cmpState = cmpState;
        this.currentCmpState = currentCmpState;

    }
    public void execute(QueueableContext QC){
         Id currentVehicleId = vehicleIds.remove(0);
         String currentChipPhone = chipPhoneMap.get(currentVehicleId);
         String currCmpState = cmpState.get(currentVehicleId);
         String presentcurrentCmpState = currentCmpState.get(currentVehicleId);

        System.debug('currentVehicleId==>'+currentVehicleId);
        System.debug('currentChipPhone==>'+currentChipPhone);
        System.debug('currCmpState==>'+currCmpState);
        System.debug('presentcurrentCmpState==>'+presentcurrentCmpState);


         if(currentVehicleId!=null){
            callSimActivationAPI(currentVehicleId,currentChipPhone,currCmpState,presentcurrentCmpState);
         }
         if(!vehicleIds.isEmpty() && !Test.isRunningTest()){
            System.enqueueJob(new SIMActivationQueueable(vehicleIds,chipPhoneMap,cmpState,currentCmpState));
         }
    }
    public static void callSimActivationAPI(Id currentVehicleId,String currentChipPhone,String cmpState,String currentCmpState){
        try{
            Boolean needToUpdateAccessToken = false;
            SIM_Activation_Api_Info__c s;
            String access_token;
            String deal_Id;
            List<SIM_Activation_Api_Info__c> simApi = [SELECT Id,Access_Token__c,Access_Token_Time__c FROM SIM_Activation_Api_Info__c WHERE Name = 'SIM API' LIMIT 1];
            if(!simApi.isEmpty()){
                s = simApi[0];
            }
            if(String.isBlank(s.Access_Token__c)){
                access_token = AccessTokenSimActivation.getAccessToken();
                
                needToUpdateAccessToken = true;

                System.debug('Access Token API Was Called');
            }
            if(!String.isBlank(s.Access_Token__c)){
                Long milliseconds = System.now().getTime() - s.Access_Token_Time__c.getTime();
                Integer diff = Integer.valueOf(milliseconds / (1000 * 60));

                System.debug('Difference ==>'+diff);
                if(diff >= 720){
                    access_token = AccessTokenSimActivation.getAccessToken();
                    
                    needToUpdateAccessToken = true;

                    System.debug('Access Token API Was Called');
                }
                else{
                    access_token = s.Access_Token__c;
                    System.debug('Access Token I am using the existing one');
                }
            }

            List<SIM_Activation_API_Details__c> simDetailList = SIM_Activation_API_Details__c.getAll().values();
            SIM_Activation_API_Details__c sim = SIM_Activation_API_Details__c.getInstance('SIM Activation API Details');

            if(cmpState == 'A' && (currentCmpState == 'SC' || currentCmpState == 'RP')){
                deal_Id = sim.Deal_Id_RP_to_A__c;
            }else if(cmpState == 'SC' && currentCmpState == 'A'){
                deal_Id = sim.Deal_Id_A_to_SC__c;
            }
            String userName = sim.UserName__c != null ? sim.UserName__c : 'could not find User Name';
            String password = sim.Password__c != null ? sim.Password__c : 'could not find Password';
            String BASE_URL = sim.Basu_URL__c != null ? sim.Basu_URL__c : 'could not find Base Url';

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setHeader('channel','Enterprise');
            req.setHeader('X-Trace-Id','1234321233');
            req.setHeader('username',userName);
            req.setHeader('entityId','100');
            req.setHeader('Content-Type','application/json');
            req.setHeader('Accept','application/json');
            req.setHeader('X-Authorization','Bearar '+access_token);
            req.setEndpoint(BASE_URL+'/updateendpointstatus');
            req.setMethod('POST');

            Map<String,Object> payLoad = new Map<String,Object>();
            Map<String,Object> serviceManagement = new Map<String,Object>();
            serviceManagement.put('remarks','state change of the Active  to Safecustody');
            serviceManagement.put('expiryDate','');
            serviceManagement.put('currentCmpState',currentCmpState);
            serviceManagement.put('circleId','1130539');
            serviceManagement.put('reasonCode',0);
            serviceManagement.put('dealId',String.valueof(deal_Id));
            serviceManagement.put('isDealChange',1);
            serviceManagement.put('isPlanChange',0);
            serviceManagement.put('billingState',1);
            serviceManagement.put('cmpState',String.valueof(cmpState));
            serviceManagement.put('serviceId',String.valueof(currentChipPhone));

            payLoad.put('externalId','');
            payLoad.put('comment','Creates a Service State Change Order');
            payLoad.put('serviceManagement',serviceManagement);
            payLoad.put('orderType','UpdateServiceState');

            String serializedBody = JSON.serialize(payLoad);
            System.debug('Payload ==>'+JSON.serializePretty(payLoad));

            req.setBody(serializedBody);

            HttpResponse res = http.send(req);
            if(res.getStatusCode() == 200 || res.getStatusCode() == 201){
                Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('responseMap===>'+responseMap);

                Vehicle v = [SELECT Id,Sim_Activation_OrderId__c,Sim_Activation_Status__c,Sim_Expiry_Date__c,Service_Provider__c FROM Vehicle WHERE Id=:currentVehicleId LIMIT 1];
                v.Sim_Activation_OrderId__c = responseMap.containsKey('orderId') ? (String)responseMap.get('orderId') : 'Not Found';
                v.Sim_Expiry_Date__c = Date.Today().addDays(365);
                v.Sim_Activation_Status__c = cmpState == 'A' ? 'Activated' : cmpState == 'SC' ? 'Safe Custody' : '';
                v.Service_Provider__c='Vodafone';

                update v;
                System.debug('Updated Vehicle ===>'+v);
                createLog(serializedBody,String.valueOf(responseMap),'Sim Activation','','Success');
            }else{
                Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('responseMap===>'+responseMap);
                System.debug('Some Error Occured in SIM Activation');
                createLog(serializedBody,String.valueOf(responseMap),'Sim Activation','','Failed');
            }


            if(needToUpdateAccessToken == true){
                SIM_Activation_Api_Info__c ss;
                List<SIM_Activation_Api_Info__c> simApiToUpdate = [SELECT Id,Access_Token__c,Access_Token_Time__c FROM SIM_Activation_Api_Info__c WHERE Name = 'SIM API' LIMIT 1];
                if(!simApi.isEmpty()){
                    ss = simApiToUpdate[0];
                }
                ss.Access_Token__c = access_token;
                ss.Access_Token_Time__c = DateTime.Now();
                update ss;
                System.debug('Updated Access Token ==>'+ss);
            }else{
                System.debug('No Need to Update Access Token');
            }
            




        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            createLog('','','Sim Activation',e.getMessage()+e.getLineNumber(),'Failed');
        }

    }
    public static void createLog(String reqBody,String resBody,String type,String errorMessage,String status){
        try{
            Integration_Log__c i = new Integration_Log__c();
            i.Request_Payload__c = String.isNotBlank(reqBody) ? reqBody : '';
            i.Response_Payload__c = String.isNotBlank(resBody) ? resBody : '';
            i.Integration_Type__c = String.isNotBlank(type) ? type : '';
            i.Error_Messages__c = String.isNotBlank(errorMessage) ? errorMessage : '';
            i.Status__c = status;

            insert i;

        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage() + 'at Line Number ==>'+e.getLineNumber());
        }
    }
}