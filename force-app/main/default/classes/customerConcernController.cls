/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 04-02-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class customerConcernController {
    // @AuraEnabled
    // public static List<Vehicle> getAllVehicle(String mobile){
    //     System.debug('Mobile ==>'+mobile);
    //     try{
    //         List<Vehicle> vehicleList = [Select id,Account__c,Account__r.Phone,Name,VehicleIdentificationNumber,VehicleRegistrationNumber,CurrentOwnerId,CurrentOwner.Phone from Vehicle Where CurrentOwner.Phone =:mobile];
    //         return vehicleList;

    //     }
    //     catch(Exception e){
    //         System.debug('Error Occured==>'+e.getMessage());
    //         System.debug('Error Line Number Is ==>'+e.getLineNumber());
    //         return null;
    //     }
    // }
//     @AuraEnabled
// public static List<Vehicle> getAllVehicle(String mobile, String VIN, String VRN) {
//     System.debug('Parameters => Mobile: ' + mobile + ', VIN: ' + VIN + ', VRN: ' + VRN);
    
//     try {
        
//         String query = 'SELECT Id, Account__c, Account__r.Phone, Name, VehicleIdentificationNumber, ' +
//                        'VehicleRegistrationNumber, CurrentOwnerId, CurrentOwner.Phone FROM Vehicle WHERE ';
        
//         List<String> conditions = new List<String>();
        
        
//         if (mobile != null && mobile != '') {
//             conditions.add('CurrentOwner.Phone = :mobile');
//         }
//         if (VIN != null && VIN != '') {
//             conditions.add('VehicleIdentificationNumber = :VIN');
//         }
//         if (VRN != null && VRN != '') {
//             conditions.add('VehicleRegistrationNumber = :VRN');
//         }
        
        
//         if (conditions.isEmpty()) {
//             return new List<Vehicle>();
//         }
        
        
//         query += String.join(conditions, ' OR '); 
        
//         System.debug('Final Query: ' + query);

        
//         return Database.query(query);
//     } catch (Exception e) {
//         System.debug('Error Occurred: ' + e.getMessage());
//         System.debug('Error Line Number: ' + e.getLineNumber());
//         return null;
//     }
// }
@AuraEnabled
public static List<Vehicle> getAllVehicle(String mobile, String VIN, String VRN) {
    System.debug('Parameters => Mobile: ' + mobile + ', VIN: ' + VIN + ', VRN: ' + VRN);
    
    try {
        
        String query = 'SELECT Id,ModelName, Account__c, Account__r.Phone,Account__r.Email__c, Name, VehicleIdentificationNumber, ' +
                       'VehicleRegistrationNumber, CurrentOwnerId, CurrentOwner.Name,CurrentOwner.Phone, CurrentOwner.Email__c FROM Vehicle WHERE ';

        List<String> conditions = new List<String>();
        Map<String, Object> queryParams = new Map<String, Object>();

        
        if (String.isNotBlank(mobile)) {
            conditions.add('CurrentOwner.Phone = :mobile');
            queryParams.put('mobile', mobile);
        }
        if (String.isNotBlank(VIN)) {
            conditions.add('VehicleIdentificationNumber = :VIN');
            queryParams.put('VIN', VIN);
        }
        if (String.isNotBlank(VRN)) {
            conditions.add('VehicleRegistrationNumber = :VRN');
            queryParams.put('VRN', VRN);
        }

        
        if (conditions.isEmpty()) {
            return new List<Vehicle>();
        }

        
        query += String.join(conditions, ' AND ');

        System.debug('Final Query: ' + query);

        
        return Database.query(query);
    } catch (Exception e) {
        System.debug('Error Occurred: ' + e.getMessage());
        System.debug('Error Line Number: ' + e.getLineNumber());
        return null;
    }
}


    @AuraEnabled(cacheable=true)
public static List<Case> getRecentCases(String vehicleId) {
    return [SELECT Id, CaseNumber, Status, Subject, CreatedDate FROM Case WHERE Vehicle__c = :vehicleId ORDER BY CreatedDate DESC LIMIT 3];
}
@AuraEnabled(cacheable = true)
public static List<WorkOrder> getJobCardList(String vehicleId){
    return [Select id,WorkOrderNumber,RR_Job_Type__c, Service_Center__c,Service_Center__r.Name,Vehicle__c,createdDate from WorkOrder Where Vehicle__c =: vehicleId ORDER BY CreatedDate DESC LIMIT 3];
}
@AuraEnabled(cacheable = true)
public static List<Account> getAccountList(String typeOfAccount) {
    String query = 'SELECT Id, Name, Type FROM Account';
    
    if (typeOfAccount != null) {
        query += ' WHERE Type = :typeOfAccount';
    }
    
    return Database.query(query);
}

}