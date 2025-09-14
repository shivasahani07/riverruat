/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 02-14-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AddJobCardInVehiclePageController{

    @AuraEnabled(cacheable = true)
    public static wrapperForJobCards getVehicleDetails(String recordId) {
        try {
            System.debug('Record ID: ' + recordId);

            List<Vehicle> vehicles = [SELECT Id, Account__c,CurrentOwnerId, Dealer__c, VehicleIdentificationNumber FROM Vehicle WHERE Id = :recordId LIMIT 1];
            System.debug('Fetched Vehicle: ' + vehicles);

            Vehicle v = vehicles.isEmpty() ? null : vehicles[0];
            if (v == null) {
                throw new AuraHandledException('Vehicle not found.');
            }

            List<Account> accounts = [SELECT Id FROM Account WHERE Id = :v.Dealer__c LIMIT 1];
            System.debug('Fetched Account: ' + accounts);

            Account a = accounts.isEmpty() ? null : accounts[0];
            if (a == null) {
                throw new AuraHandledException('Dealer not found.');
            }

            List<Contact> contacts = [SELECT Id, AccountId, Primary_Contact__c FROM Contact WHERE AccountId = :a.Id LIMIT 1];
            System.debug('Fetched Contact: ' + contacts);

            Contact c = contacts.isEmpty() ? null : contacts[0];
            if (c == null) {
                throw new AuraHandledException('Contact not found.');
            }

            List<AssetMilestone> milestones = [
                SELECT Id, MilestoneType, VehicleId 
                FROM AssetMilestone 
                WHERE VehicleId = :recordId 
                AND MilestoneType = 'Sold' 
                LIMIT 1
            ];
            System.debug('Fetched AssetMilestone: ' + milestones);

            Boolean isSold = false;
            String milestoneMessage = '';

            if (!milestones.isEmpty()) {
                isSold = true;
            } else {
               System.debug('there is no sold milstone');
            }

            wrapperForJobCards w = new wrapperForJobCards();
            w.VehicleId = v.Id;
            w.AccountIds = a.Id;
            w.ContactIds = c.Id;
            w.VIN = v.VehicleIdentificationNumber;
            w.mileStoneType = isSold ? 'Sold' : 'Not Sold';
            w.isSold = isSold;
            w.milestoneMessage = milestoneMessage;

            System.debug('Wrapper Details: ' + w);

            return w;

        } catch (AuraHandledException e) {
            System.debug('Handled Error: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug('Unexpected Error: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    } 

/*    @AuraEnabled(cacheable = true)
public static wrapperForJobCards getVehicleDetails(String recordId) {
    try {
        // Get the current logged-in user's Account and Contact
        String currentUserId = UserInfo.getUserId();
        List<User> currentUserList = [SELECT AccountId, ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
        User currentUser = currentUserList.isEmpty() ? null : currentUserList[0];

        if (currentUser == null || currentUser.AccountId == null || currentUser.ContactId == null) {
            throw new AuraHandledException('Logged-in user does not have an associated Account or Contact.');
        }

        // Fetch the Account and Contact for the logged-in user
        List<Account> userAccountList = [SELECT Id FROM Account WHERE Id = :currentUser.AccountId LIMIT 1];
        Account userAccount = userAccountList.isEmpty() ? null : userAccountList[0];

        List<Contact> userContactList = [SELECT Id FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
        Contact userContact = userContactList.isEmpty() ? null : userContactList[0];

        if (userAccount == null) {
            throw new AuraHandledException('Logged-in user does not have an associated Account.');
        }

        if (userContact == null) {
            throw new AuraHandledException('Logged-in user does not have an associated Contact.');
        }

        // Debug: Print fetched details
        System.debug('Logged-in User Account: ' + userAccount);
        System.debug('Logged-in User Contact: ' + userContact);

        // Fetch the Vehicle using the provided recordId
        List<Vehicle> vehicles = [SELECT Id, Account__c, VehicleIdentificationNumber FROM Vehicle WHERE Id = :recordId LIMIT 1];
        Vehicle v = vehicles.isEmpty() ? null : vehicles[0];

        if (v == null) {
            throw new AuraHandledException('Vehicle not found.');
        }

        // Check if the vehicle's associated Account is the same as the logged-in user's Account
       if (v.Account__c != userAccount.Id) {
            throw new AuraHandledException('Vehicle is not associated with the logged-in user\'s Account.');
        }

        // Check if the logged-in user's Contact is associated with the Account
        if (userContact.AccountId != userAccount.Id) {
            throw new AuraHandledException('Logged-in user\'s Contact is not associated with the logged-in user\'s Account.');
        } 

        // Fetch AssetMilestone to check if the vehicle is "Sold"
        List<AssetMilestone> milestones = [
            SELECT Id, MilestoneType, VehicleId 
            FROM AssetMilestone 2
            WHERE VehicleId = :recordId 
            AND MilestoneType = 'Sold' 
            LIMIT 1
        ];
        Boolean isSold = !milestones.isEmpty();

        // Prepare the wrapper object
        wrapperForJobCards w = new wrapperForJobCards();
        w.VehicleId = v.Id;
        w.AccountIds = userAccount.Id;
        w.ContactIds = userContact.Id;
        w.VIN = v.VehicleIdentificationNumber;
        w.mileStoneType = isSold ? 'Sold' : 'Not Sold';
        w.isSold = isSold;
        w.milestoneMessage = '';

        System.debug('Wrapper Details: ' + w);

        return w;

    } catch (AuraHandledException e) {
        System.debug('Handled Error: ' + e.getMessage());
        throw e;
    } catch (Exception e) {
        System.debug('Unexpected Error: ' + e.getMessage());
        throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
    }
} */


    public class wrapperForJobCards{
        @AuraEnabled
        public Id VehicleId { get; set; }
        @AuraEnabled
        public Id AccountIds { get; set; }
        @AuraEnabled
        public Id ContactIds { get; set; }
        @AuraEnabled
        public String VIN { get; set; }
        @AuraEnabled
        public String mileStoneType { get; set; }
        @AuraEnabled
        public Boolean isSold { get; set; }
        @AuraEnabled
        public String milestoneMessage { get; set; }
    }

    @AuraEnabled
    public static List<String> createJobCard(String jobCardData) {
        System.debug('jobCardData =====>'+jobCardData);
        List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
        List<String> insertedWorkOrderIds = new List<String>();

        try {
            if (String.isEmpty(jobCardData)) {
                throw new AuraHandledException('No job card data provided.');
            }

            Map<String, Object> jobCardMap = (Map<String, Object>) JSON.deserializeUntyped(jobCardData);

            if (jobCardMap.get('accId') == null || jobCardMap.get('conId') == null || jobCardMap.get('vehId') == null) {
                throw new AuraHandledException('Missing required fields: Dealer Id, Contact Id, Vehicle Id.');
            }

            List<RecordType> vehiclePDIRecordTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'Vehicle_PDI'];

            if (vehiclePDIRecordTypes.isEmpty()) {
                throw new AuraHandledException('No RecordType found for Vehicle_PDI.');
            }

            Id vehiclePDIRecordTypeId = vehiclePDIRecordTypes[0].Id;
            
            
            Id userId = UserInfo.getUserId();
            List<user> userServiceAccount = [SELECT   id,Contact.AccountId From User where Id =: userId AND Contact.Account.Type = 'Service Center' limit 1];
            WorkOrder w = new WorkOrder();
            w.AccountId = (Id) jobCardMap.get('accId');
            w.ContactId = (Id) jobCardMap.get('conId');
            w.vehicle__c = (Id) jobCardMap.get('vehId');
            w.Odometer_Reading__c = (Integer) jobCardMap.get('oRed');
            w.RR_Job_Type__c = (String) jobCardMap.get('jobType');
            w.RecordTypeId = vehiclePDIRecordTypeId;
           if (!userServiceAccount.isEmpty() && userServiceAccount[0].Contact.AccountId != null) {
            w.Service_Center__c = userServiceAccount[0].Contact.AccountId;
            } else {
            // handle fallback - for example, assign accId or leave it null
            w.Service_Center__c = null;
            }           
            workOrdersToInsert.add(w);
            System.debug('workOrdersToInsert ======>'+workOrdersToInsert);

            if (!workOrdersToInsert.isEmpty()) {
                insert workOrdersToInsert;
            }

            for (WorkOrder wo : workOrdersToInsert) {
                insertedWorkOrderIds.add(wo.Id);
            }

            return insertedWorkOrderIds;

        } catch (DmlException e) {
            System.debug('DML Exception: ' + e.getMessage());
            System.debug('DML Exception=======> ' + e.getLinenumber());
            System.debug('DML Error Details: ' + e.getStackTraceString());
            throw new AuraHandledException('DML Error: ' + e.getMessage() + '. StackTrace: ' + e.getStackTraceString());
        } catch (QueryException e) {
            System.debug('Query Exception: ' + e.getMessage());
            System.debug('Query Error Details: ' + e.getStackTraceString());
            throw new AuraHandledException('Query Error: ' + e.getMessage() + '. StackTrace: ' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('Unexpected Error: ' + e.getMessage());
            System.debug('Full Exception Details: ' + e.getStackTraceString());
            throw new AuraHandledException('Unexpected Error: ' + e.getMessage() + '. Full Exception: ' + e.getStackTraceString());
        }
    }
}