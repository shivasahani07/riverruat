public without sharing class GatePassController {
    
    @RemoteAction
    public static Order getOrderDetails(Id orderId) {
        try {
            Order ord = [
                SELECT Id, OrderNumber, Assigned_Vehicle__r.VehicleIdentificationNumber,Assigned_Vehicle__r.VehicleRegistrationNumber,Account.Name, Delivery_Date__c, Dealer__r.Name, Status, Gate_Pass_Approved__c,
                 Gate_Pass_Rejected__c, Gate_Pass_Issuer__c, Gate_Pass_Generated_Date_Time__c FROM Order WHERE Id = :orderId LIMIT 1];
            System.debug('OrderDtl ; ' + ord);
            return ord;
        } catch (Exception e) {
            System.debug('Error fetching order: ==>' + e.getMessage());
            System.debug('Error fetching order: ==>' + e.getLineNumber());
            return null;
        }
    }

    @RemoteAction
    public static String approveGatePass(Id orderId) {
        try {
            Order ord = [SELECT Id FROM Order WHERE Id = :orderId LIMIT 1];
            ord.Status = 'Vehicle Delivered';
            ord.Gate_Pass_Approved__c = true;
            ord.Gate_Pass_Rejected__c = false;
            update ord;
            System.debug('Gate Pass Updated. ==>'+ord);
            return 'Gate Pass Approved Successfully.';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    @RemoteAction
    public static String rejectGatePass(Id orderId) {
        try {
            Order ord = [SELECT Id FROM Order WHERE Id = :orderId LIMIT 1];
            ord.Gate_Pass_Rejected__c = true;
            ord.Gate_Pass_Approved__c = false;
            update ord;
            System.debug('Gate Pass Rejected. ==>'+ord);
            return 'Gate Pass Rejected.';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}