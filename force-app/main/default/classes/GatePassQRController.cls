/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-14-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class GatePassQRController {
    
    public static void checkAndGenerateQR(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        Id vehicleRecordType = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();//added by Aniket on 14/10/2025
        try {

            List<Order> vehicleOrders = new List<Order>();
            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordType) {
                    vehicleOrders.add(ord);
                }
            }

            if (vehicleOrders.isEmpty()) {
                System.debug('No Vehicle Orders found. Skipping GatePass QR generation.');
                return;
            }


            System.debug('Starting checkAndGenerateQR with ' + newOrders.size() + ' orders.');

            List<Id> eligibleOrderIds = new List<Id>();
            List<Order> ordersToUpdate = new List<Order>();
 
            User u;
            List<User> userList = [SELECT Id,Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            System.debug('userList==>'+userList);
            if(!userList.isEmpty()){
                u=userList[0];
            }
            // String currentUserName = [SELECT Id,Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Name;
            String currentUserName = u.Name;
            System.debug('currentUserName ==>'+currentUserName);

            for (Order ord : vehicleOrders) {
                try {
                    Order oldOrd = oldOrderMap.get(ord.Id);
                    System.debug('Checking order Id: ' + ord.Id + ' with new status: ' + ord.Status);
                    
                    if(ord.RecordTypeId == vehicleRecordType){
                        if (ord.Status == 'Ready for Delivery' && ord.Delivery_Date__c != null &&
                        oldOrd != null && oldOrd.Delivery_Date__c != ord.Delivery_Date__c) {
                        
                        System.debug('Order eligible for QR generation: ' + ord.Id);

                        if (ord.Gate_Pass_Issuer__c == null) {
                            ord.Gate_Pass_Issuer__c = currentUserName;
                            ord.Gate_Pass_Generated_Date_Time__c = System.now();
                        }

                        eligibleOrderIds.add(ord.Id);
                    }
                    }
                   
                } catch (Exception innerEx) {
                    System.debug('Exception in inner loop for order Id: ' + ord.Id + ' - ' + innerEx.getMessage());
                    ExceptionHelper.createExceptionLog(innerEx);
                }
            }

            System.debug('Total eligible orders for QR generation: ' + eligibleOrderIds.size());

            if (!eligibleOrderIds.isEmpty()) {
                updateOrdersWithIssuerInfo(eligibleOrderIds, currentUserName);
                
                startQRGenerationBatch(eligibleOrderIds);
            } else {
                System.debug('No eligible orders found for QR generation.');
            }

        } catch (Exception e) {
            System.debug('Exception caught in checkAndGenerateQR: ' + e.getMessage());
            ExceptionHelper.createExceptionLog(e);
        }
    }
    
    private static void updateOrdersWithIssuerInfo(List<Id> orderIds, String currentUserName) {
        try {
            List<Order> ordersToUpdate = new List<Order>();
            for (Id orderId : orderIds) {
                ordersToUpdate.add(new Order(
                    Id = orderId,
                    Gate_Pass_Issuer__c = currentUserName,
                    Gate_Pass_Generated_Date_Time__c = System.now()
                ));
            }
            update ordersToUpdate;
            System.debug('Updated ' + ordersToUpdate.size() + ' orders with issuer information');
        } catch (Exception e) {
            System.debug('Error updating orders with issuer info: ' + e.getMessage());
            ExceptionHelper.createExceptionLog(e);
        }
    }
    
    private static void startQRGenerationBatch(List<Id> orderIds) {
        try {
            System.debug('Starting QR Generation Batch for ' + orderIds.size() + ' orders');
            
            gatePassQRGeneratorHelper batch = new gatePassQRGeneratorHelper(orderIds);
            Database.executeBatch(batch, 1);
            
            System.debug('Batch job started successfully');
            
        } catch (Exception e) {
            System.debug('Error starting batch job: ' + e.getMessage());
            ExceptionHelper.createExceptionLog(e);
        }
    }
}