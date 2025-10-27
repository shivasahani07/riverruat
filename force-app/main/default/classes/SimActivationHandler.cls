/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class SimActivationHandler {
    public static void activateSim(List<Order> orderList,Map<Id,Order> oldOrderMap){
        Id vehicleRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
        try{
            Set<Id> vehicleIds = new Set<Id>();
            for(Order o : orderList){
               if(o.RecordTypeId == vehicleRecordType && o.Status != oldOrderMap.get(o.Id).Status && o.Status == 'RTO Registration'){
                  if(o.Assigned_Vehicle__c != null){
                      vehicleIds.add(o.Assigned_Vehicle__c);
                  }
               }
            }
            System.debug('vehicleIds==>'+vehicleIds);
            List<Id> vehicleIdsForAPI = new List<Id>();
            Map<Id,String> simPhoneMap = new Map<Id,String>();
            Map<Id,String> cmpMap = new Map<Id,String>();
            Map<Id,String> currCmpMap = new Map<Id,String>();

            List<Vehicle> vehicleList = [SELECT Id,SIM_Activation_Phone__c,Sim_Activation_Status__c FROM Vehicle WHERE Id IN:vehicleIds];
            if(!vehicleList.isEmpty()){
                for(Vehicle v : vehicleList){
                   vehicleIdsForAPI.add(v.Id);
                   simPhoneMap.put(v.Id,v.SIM_Activation_Phone__c != null ? v.SIM_Activation_Phone__c : 'Blank');

                   if(v.Sim_Activation_Status__c == 'Pending' || v.Sim_Activation_Status__c == null){
                       cmpMap.put(v.Id,'A');
                       currCmpMap.put(v.Id,'RP');
                   }
                   if(v.Sim_Activation_Status__c == 'Activated'){
                       cmpMap.put(v.Id,'SC');
                       currCmpMap.put(v.Id,'A');
                   }
                   if(v.Sim_Activation_Status__c == 'Safe Custody'){
                       cmpMap.put(v.Id,'A');
                       currCmpMap.put(v.Id,'SC');
                   }
                }
                 
          
            }
            if(!vehicleIdsForAPI.isEmpty()){
                System.enqueueJob(new SIMActivationQueueable(vehicleIdsForAPI,simPhoneMap,cmpMap,currCmpMap));
            }
            

        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
}