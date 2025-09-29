/**
* @description       : 
* @author            : Aniket Karmakar
* @group             : 
* @last modified on  : 09-16-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class OrderInvoiceGenerationOTCController {
    public static void eWAndRSACallout(List<Order> newOrderList,Map<Id,Order> oldOrderMap) {
        System.debug('RSA Method Is Called By Aniket');
        Id otcRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('OTC').getRecordTypeId();
        System.debug('eWAndRSAAfterOTC List==>'+newOrderList);
        try{
            Set<Id> orderIds = new Set<Id>();
            Set<Id> vehicleIds = new Set<Id>();
            Map<Id,wrapperForEWIntegration> mapWhenAssignedVehicle = new Map<Id,wrapperForEWIntegration>();
            List<Id> orderIdsToProcessWhenAssignedVehicle = new List<Id>();
            if(!newOrderList.isEmpty()){
                for(Order o : newOrderList){
                    if(o.RecordTypeId == otcRecordTypeId && o.Assigned_Vehicle__c != null && o.Status == 'Invoice Generation' && o.Status != oldOrderMap.get(o.Id).Status){
                        orderIds.add(o.Id);
                        vehicleIds.add(o.Assigned_Vehicle__c);
                    }
                }
            }
            System.debug('orderIds==>'+orderIds);
            System.debug('vehicleIds==>'+vehicleIds);
            Map<Id, Vehicle> vehicleMap = new Map<Id, Vehicle>();
            if (!vehicleIds.isEmpty()) {
                for (Vehicle v : [SELECT Id, Purchased_Date__c, ChassisNumber, Name,VehicleIdentificationNumber, RR_Battery_Number__c, EngineNumber, Charger_PC_Number__c, Account__c, Account__r.Center_Code__c,CurrentOwnerId,CurrentOwner.Center_Code__c, CreatedDate,Dealer__r.Center_Code__c
                                  FROM Vehicle WHERE Id IN :vehicleIds]) {
                                      vehicleMap.put(v.Id, v);
                                  }
            }
            System.debug('vehicleMap==>'+vehicleMap);
            Set<Id> orderIdsToGetOrderList = new Set<Id>();
            List<Order> orderListForRSA = new List<Order>();
            Set<Id> orderIdsForEW = new Set<Id>();
            List<OrderItem> ordeProductList = [Select Id,Type__c,Product2Id,Product2.Name,OrderId,Product2.ProductCode from OrderItem WHERE OrderId IN:orderIds];
            System.debug('Order Product List==>'+ordeProductList);
            if(!ordeProductList.isEmpty()){
                for(OrderItem oi : ordeProductList){
                    if(oi.Type__c == 'Accessories' && oi.Product2.Name.contains('Road Side Assistance')){
                        orderIdsToGetOrderList.add(oi.OrderId);
                    }
                    if(oi.Type__c == 'Accessories'){
                        if(oi.Product2.ProductCode.startsWith('RV-EW')){
                            orderIdsForEW.add(oi.OrderId);
                        }
                    }
                }
                List<Order> finalOrderList = [select id,Assigned_Vehicle__c,Assigned_Vehicle__r.VehicleIdentificationNumber,Assigned_Vehicle__r.VehicleRegistrationNumber,Account.Name, Account.Phone from Order where Id IN:orderIdsToGetOrderList];
                List<Order> finalOrderListForEW = [select id,Assigned_Vehicle__c,Assigned_Vehicle__r.VehicleIdentificationNumber,Dealer__r.Type,Dealer__r.Service_Center__r.Type
                                                   ,Dealer__r.Center_Code__c,Dealer__r.Store_Type__c,Dealer__r.Service_Center__r.Store_Type__c,Dealer__r.Service_Center__r.Center_Code__c,Assigned_Vehicle__r.VehicleRegistrationNumber,Account.Name, Account.Phone,Assigned_Vehicle__r.PDI_Status_Pass__c from Order where Id IN:orderIdsForEW];
                System.debug('finalOrderList==>'+finalOrderList);
                System.debug('finalOrderListForEW==>'+finalOrderListForEW);
                if(!finalOrderListForEW.isEmpty()){
                    for (Order order : finalOrderListForEW) {
                        if (order.Assigned_Vehicle__c != null && vehicleMap.containsKey(order.Assigned_Vehicle__c) && order.Assigned_Vehicle__r.PDI_Status_Pass__c == true) {
                            Vehicle v = vehicleMap.get(order.Assigned_Vehicle__c);
                            wrapperForEWIntegration w = new wrapperForEWIntegration();
                            w.vehicleId = v.Id;
                            // w.dealerCode = v.Dealer__r.Center_Code__c !=null ? v.Dealer__r.Center_Code__c : '';
                            //w.dealerCode = order.Dealer__r.Center_Code__c !=null ? order.Dealer__r.Center_Code__c : '';
                            w.dealerCode = order.Dealer__r.Type=='Dealer' && order.Dealer__r.Store_Type__c == 'DODO' && order.Dealer__r.Service_Center__r.Type=='Service Center' && order.Dealer__r.Service_Center__r.Store_Type__c =='DODO' ? order.Dealer__r.Service_center__r.Center_Code__c : order.Dealer__r.Type=='Dealer' && order.Dealer__r.Store_Type__c == 'COCO' && order.Dealer__r.Service_Center__r.Type=='Service Center' && order.Dealer__r.Service_Center__r.Store_Type__c =='COCO' ? order.Dealer__r.Center_Code__c : order.Dealer__r.Type=='Dealer' && order.Dealer__r.Store_Type__c =='DODO' && order.Dealer__r.Service_Center__r.Type=='Service Center' && order.Dealer__r.Service_Center__r.Store_Type__c=='COCO' ? order.Dealer__r.Center_Code__c : order.Dealer__r.Center_Code__c;
                            w.purchaseDate = v.Purchased_Date__c != null ? v.Purchased_Date__c : null;
                            w.chassisNumber = v.VehicleIdentificationNumber != null ? v.VehicleIdentificationNumber :'';
                            w.model = v.Name != null ? v.Name :'';
                            w.battery = v.RR_Battery_Number__c != null ? v.RR_Battery_Number__c : '';
                            w.engineNumber = v.EngineNumber != null ? v.EngineNumber : '';
                            w.charger = v.Charger_PC_Number__c != null ? v.Charger_PC_Number__c : '';
                            orderIdsToProcessWhenAssignedVehicle.add(order.Id);
                            mapWhenAssignedVehicle.put(order.Id, w);
                        }
                    }
                    System.debug('orderIdsToProcessWhenAssignedVehicle==>'+orderIdsToProcessWhenAssignedVehicle);
                }
                if(!orderIdsToProcessWhenAssignedVehicle.isEmpty()){
                    System.enqueueJob(new QueueableForOTCEWIntegration(orderIdsToProcessWhenAssignedVehicle,mapWhenAssignedVehicle));
                }
                if(!finalOrderList.isEmpty()){
                    System.debug('RSA Method Is Called By Aniket 2');
                    for(Order oo : finalOrderList){
                        string  chassisNO=oo.Assigned_Vehicle__r.VehicleIdentificationNumber;
                        string vehicleRegistrationNo=oo.Assigned_Vehicle__r.VehicleRegistrationNumber;
                        Id VehicleId=oo.Assigned_Vehicle__r.Id;
                        Id OrderIdnumber=oo.Id;
                        string AccountName=oo.Account.Name;
                        string AccountPhoneNo=oo.Account.Phone;
                        system.debug('chassisNO == >'+chassisNO+' && OrderIdnumber == >'+OrderIdnumber+' && AccountName == >'+AccountName+' && AccountPhoneNo == >'+AccountPhoneNo+' && VehicleId == >'+VehicleId);
                        if(chassisNO != null || chassisNO != ''){
                            //RSAcalloutHelper.RsaCreationFuthuremethod(chassisNO,OrderIdnumber,AccountName,AccountPhoneNo,VehicleId);
                        }else{
                            system.debug('Method Not Called  RsaCreationFuthuremethod ** /  chassisNO is not Found == >');
                        }
                    }
                } 
                
                
            }
        }
        catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
    public class wrapperForEWIntegration{
        public Id vehicleId{get;set;}
        public String dealerCode{get;set;}
        public Date purchaseDate{get;set;}
        public String chassisNumber{get;set;}
        public String model{get;set;}
        public String battery{get;set;}
        public String engineNumber{get;set;}
        public String charger{get;set;}
        //public String soldFrom{get;set;}
        
    }
}