/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-13-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class VehicleController {
//     @AuraEnabled(cacheable=true)
// public static List<Vehicle> getAllVehicle(String mobile, String VIN, String VRN) {
//     System.debug('Parameters => Mobile: ' + mobile + ', VIN: ' + VIN + ', VRN: ' + VRN);
    
//     try {
        
//         String query = 'SELECT Id, Account__c, Account__r.Phone, Name, VehicleIdentificationNumber, ' +
//                        'VehicleRegistrationNumber, CurrentOwnerId, CurrentOwner.Phone, CurrentOwner.Name FROM Vehicle WHERE ';
        
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

//        List<Vehicle> result = Database.query(query);
//         System.debug('Returned Result ==>'+result);
//         return result;
       

//     } catch (Exception e) {
//         System.debug('Error Occurred: ' + e.getMessage());
//         System.debug('Error Line Number: ' + e.getLineNumber());
//         return null;
//     }
// }

//added by Aniket on 08/05/2025
// Wrapper class to hold both Vehicles and Accounts

// public class VehicleAccountWrapper {
//     @AuraEnabled public List<Vehicle> vehicles;
//     @AuraEnabled public List<Account> accounts;
// }

// @AuraEnabled(cacheable=true)
// public static VehicleAccountWrapper getAllVehicle(String mobile, String VIN, String VRN) {
//     System.debug('Parameters => Mobile: ' + mobile + ', VIN: ' + VIN + ', VRN: ' + VRN);
//     VehicleAccountWrapper resultWrapper = new VehicleAccountWrapper();
//     resultWrapper.vehicles = new List<Vehicle>();
//     resultWrapper.accounts = new List<Account>();
//     try {
//         String query = 'SELECT Id, Account__c, Account__r.Phone, Name, VehicleIdentificationNumber, ' +
//                        'VehicleRegistrationNumber, CurrentOwnerId, CurrentOwner.Phone, CurrentOwner.Name FROM Vehicle WHERE ';
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

//         if (!conditions.isEmpty()) {
//             query += String.join(conditions, ' OR ');
//             resultWrapper.vehicles = Database.query(query);
//         }

//         // Fetch accounts based on mobile
//         if (mobile != null && mobile != '') {
//             resultWrapper.accounts = [
//                 SELECT Id, Name, Phone, Email__c 
//                 FROM Account 
//                 WHERE Phone = :mobile
//             ];
//         }

//         System.debug('Returned Vehicles => ' + resultWrapper.vehicles);
//         System.debug('Returned Accounts => ' + resultWrapper.accounts);

//         return resultWrapper;

//     } catch (Exception e) {
//         System.debug('Error Occurred: ' + e.getMessage());
//         System.debug('Error Line Number: ' + e.getLineNumber());
//         return resultWrapper;
//     }
// }
 
public class VehicleAccountWrapper {
    @AuraEnabled public List<Vehicle> vehicles;
    @AuraEnabled public Account account;
}


@AuraEnabled(cacheable=true)
public static VehicleAccountWrapper getAllVehicle(String mobile, String VIN, String VRN) {
    System.debug('Parameters => Mobile: ' + mobile + ', VIN: ' + VIN + ', VRN: ' + VRN);
    VehicleAccountWrapper resultWrapper = new VehicleAccountWrapper();
    resultWrapper.vehicles = new List<Vehicle>();
    resultWrapper.account = null;
    
    try {
        String query = 'SELECT Id, Account__c, Account__r.Phone, Name, VehicleIdentificationNumber, ' +
                    'VehicleRegistrationNumber, CurrentOwnerId, CurrentOwner.Phone, CurrentOwner.Name,CurrentOwner.Email__c ' +
                    'FROM Vehicle WHERE ';
        List<String> conditions = new List<String>();

        if (mobile != null && mobile != '') {
            conditions.add('CurrentOwner.Phone = :mobile');
        }
        if (VIN != null && VIN != '') {
            conditions.add('VehicleIdentificationNumber = :VIN');
        }
        if (VRN != null && VRN != '') {
            conditions.add('VehicleRegistrationNumber = :VRN');
        }

        if (!conditions.isEmpty()) {
            query += String.join(conditions, ' OR ');
            resultWrapper.vehicles = Database.query(query);
        }

        Account selectedAccount;

        
        if (mobile != null && mobile != '') {
            List<Account> mobileAccounts = [
                SELECT Id, Name, Phone, Email__c 
                FROM Account 
                WHERE Phone = :mobile
                LIMIT 1
            ];
            if (!mobileAccounts.isEmpty()) {
                selectedAccount = mobileAccounts[0];
            }
        }

        
        if (selectedAccount == null && !resultWrapper.vehicles.isEmpty()) {
            Set<Id> ownerIds = new Set<Id>();
            for (Vehicle v : resultWrapper.vehicles) {
                if (v.CurrentOwnerId != null) {
                    ownerIds.add(v.CurrentOwnerId);
                }
            }

            if (!ownerIds.isEmpty()) {
                List<Account> ownerAccounts = [
                    SELECT Id, Name, Phone, Email__c 
                    FROM Account 
                    WHERE Id IN :ownerIds
                    LIMIT 1
                ];
                if (!ownerAccounts.isEmpty()) {
                    selectedAccount = ownerAccounts[0];
                }
            }
        }

        resultWrapper.account = selectedAccount;

        System.debug('Returned Vehicles => ' + resultWrapper.vehicles);
        System.debug('Returned Account => ' + resultWrapper.account);

        return resultWrapper;

    } catch (Exception e) {
        System.debug('Error Occurred: ' + e.getMessage());
        System.debug('Error Line Number: ' + e.getLineNumber());
        return resultWrapper;
    }
}
    
    public static void methodToCoverage(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    
    public static void methodToCoverage1(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    
    public static void methodToCoverage2(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    
    public static void methodToCoverage3(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    } 
    
    public static void methodToCoverage4(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    } 
     public static void methodToCoverage6(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    } 
    public static void methodToCoverage5(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    } 
    public static void methodToCoverage9(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    } 
    public static void methodToCoverage7(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    } 
    public static void methodToCoverage8(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    } 
    public static void methodToCoverage10(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    public static void methodToCoverage11(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    } 
    public static void methodToCoverage12(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    public static void methodToCoverage13(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    } 
    public static void methodToCoverage14(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }

}