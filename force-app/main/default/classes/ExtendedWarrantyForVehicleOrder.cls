/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 09-19-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ExtendedWarrantyForVehicleOrder {
    public static void punchOTCMethod(List<Order> newOrderList,Map<Id,Order> oldOrderMap){
        System.debug('EW Method Is Called By Aniket');
        Id vehicleRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
        try{
             Set<Id> orderIds = new Set<Id>();
            Set<Id> vehicleIds = new Set<Id>();
            Map<Id,wrapperForEWIntegration> mapWhenAssignedVehicle = new Map<Id,wrapperForEWIntegration>();
            List<Id> orderIdsToProcessWhenAssignedVehicle = new List<Id>();
            if(!newOrderList.isEmpty()){
                for(Order o : newOrderList){
                    if(o.RecordTypeId == vehicleRecordTypeId && o.Assigned_Vehicle__c != null && o.Status == 'RTO Registration' && o.Status != oldOrderMap.get(o.Id).Status){
                        orderIds.add(o.Id);
                        vehicleIds.add(o.Assigned_Vehicle__c);
                    }
                }
            }   
            Map<Id, Vehicle> vehicleMap = new Map<Id, Vehicle>();
            if (!vehicleIds.isEmpty()) {
                for (Vehicle v : [SELECT Id, Purchased_Date__c, ChassisNumber, Name,VehicleIdentificationNumber, RR_Battery_Number__c, EngineNumber, Charger_PC_Number__c, Account__c, Account__r.Center_Code__c,CurrentOwnerId,CurrentOwner.Center_Code__c, CreatedDate,Dealer__r.Center_Code__c
                                  FROM Vehicle WHERE Id IN :vehicleIds]) {
                                      vehicleMap.put(v.Id, v);
                                  }
            }
            System.debug('vehicleMap==>'+vehicleMap);
            Set<Id> orderIdsForEW = new Set<Id>();
            List<OrderItem> ordeProductList = [Select Id,Type__c,Product2Id,Product2.Name,OrderId,Product2.ProductCode from OrderItem WHERE OrderId IN:orderIds];
            System.debug('Order Product List==>'+ordeProductList);
            
            if(!ordeProductList.isEmpty()){
                for(OrderItem oi : ordeProductList){
                    if(oi.Type__c == 'Accessories'){
                        if(oi.Product2.ProductCode.startsWith('RV-EW')){
                            orderIdsForEW.add(oi.OrderId);
                        }
                    }
                }
            }
            List<Order> finalOrderListForEW = [select id,Assigned_Vehicle__c,Assigned_Vehicle__r.VehicleIdentificationNumber,Dealer__r.Type,Dealer__r.Service_Center__r.Type
                                                   ,Dealer__r.Center_Code__c,Dealer__r.Store_Type__c,Dealer__r.Service_Center__r.Store_Type__c,Dealer__r.Service_Center__r.Center_Code__c,Assigned_Vehicle__r.VehicleRegistrationNumber,Account.Name, Account.Phone,Assigned_Vehicle__r.PDI_Status_Pass__c from Order where Id IN:orderIdsForEW];
            
                          if(!finalOrderListForEW.isEmpty()){
                    for (Order order : finalOrderListForEW) {
                        if (order.Assigned_Vehicle__c != null && vehicleMap.containsKey(order.Assigned_Vehicle__c) && order.Assigned_Vehicle__r.PDI_Status_Pass__c == true) {
                            Vehicle v = vehicleMap.get(order.Assigned_Vehicle__c);
                            wrapperForEWIntegration w = new wrapperForEWIntegration();
                            w.vehicleId = v.Id;
                            // w.dealerCode = v.Dealer__r.Center_Code__c !=null ? v.Dealer__r.Center_Code__c : '';
                            //w.dealerCode = order.Dealer__r.Center_Code__c !=null ? order.Dealer__r.Center_Code__c : '';
                            w.dealerCode = order.Dealer__r.Type=='Dealer' && order.Dealer__r.Store_Type__c == 'DODO' && order.Dealer__r.Service_Center__r.Type=='Service Center' && order.Dealer__r.Service_Center__r.Store_Type__c =='DODO' ? order.Dealer__r.Service_center__r.Center_Code__c : order.Dealer__r.Type=='Dealer' && order.Dealer__r.Store_Type__c == 'COCO' && order.Dealer__r.Service_Center__r.Type=='Service Center' && order.Dealer__r.Service_Center__r.Store_Type__c =='COCO' ? order.Dealer__r.Center_Code__c : order.Dealer__r.Type=='Dealer' && order.Dealer__r.Store_Type__c =='DODO' && order.Dealer__r.Service_Center__r.Type=='Service Center' && order.Dealer__r.Service_Center__r.Store_Type__c=='COCO' ? order.Dealer__r.Center_Code__c : order.Dealer__r.Center_Code__c;
                            w.purchaseDate = v.Purchased_Date__c != null ? v.Purchased_Date__c : System.Today();
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
                    System.enqueueJob(new QueueableForVehicleEWIntegration(orderIdsToProcessWhenAssignedVehicle,mapWhenAssignedVehicle));
                }
            
            
        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
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