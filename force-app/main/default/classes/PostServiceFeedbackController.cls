public without sharing class PostServiceFeedbackController {
	
    public class QuestionnaireWrapper {
        @AuraEnabled public List<Questionnaire__c> questionnaires = new List<Questionnaire__c>();
        @AuraEnabled public Decimal averageRating = -1; // Default to -1
    }

    public class PicklistWrapper{

        @AuraEnabled public List<String> ratingPicklist;
        @AuraEnabled public List<String> yes_no_ratingPicklist;
        @AuraEnabled public List<String> complaintRegardingValues;

        public PicklistWrapper(List<String> ratingPicklist, List<String> yes_no_ratingPicklist, List<String> complaintRegardingValues){
            this.ratingPicklist = ratingPicklist;
            this.yes_no_ratingPicklist = yes_no_ratingPicklist;
            this.complaintRegardingValues = complaintRegardingValues;
        }
    }

    @AuraEnabled(cacheable=false)
    public static QuestionnaireWrapper getQuestionnaires(Id psfId) {
        QuestionnaireWrapper wrapper = new QuestionnaireWrapper();

        wrapper.questionnaires = [
            SELECT Id, Question__c, Rating__c, Rating_Yes_No__c, Is_Rating_Question__c, Complaint_Regarding__c, Complaint_Description__c, Additional_Comments__c
            FROM Questionnaire__c
            WHERE Post_Service_Feedback__c = :psfId
            ORDER BY Is_Rating_Question__c ASC
        ];

        Post_Service_Feedback__c psf = [
            SELECT Average_Rating__c
            FROM Post_Service_Feedback__c
            WHERE Id = :psfId
            LIMIT 1
        ];

        wrapper.averageRating = psf.Average_Rating__c != null ? psf.Average_Rating__c : -1;
        return wrapper;
    }


/*
    @AuraEnabled(cacheable=true)
    public static List<String> getRatingPicklistValues() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = Questionnaire__c.Rating__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            values.add(entry.getValue());
        }
        
        return values; 
    }
*/

    @AuraEnabled(cacheable=true)
    public static PicklistWrapper getRatingPicklistValues(){

        List<String> ratingValues = new List<String>();
        List<String> yes_no_ratingValues = new List<String>();
        List<String> complaintRegardingValues = new List<String>();

        // Get Rating Picklist Values    
        Schema.DescribeFieldResult ratingField = Questionnaire__c.Rating__c.getDescribe();
        List<Schema.PicklistEntry> ratingPicklistEnteries = ratingField.getPicklistValues();

        for(Schema.PicklistEntry entry : ratingPicklistEnteries){
            ratingValues.add(entry.getValue());
        }

        // Get Rating Picklist Values    
        Schema.DescribeFieldResult yes_no_ratingField = Questionnaire__c.Rating_Yes_No__c.getDescribe();
        List<Schema.PicklistEntry> yes_no_ratingPicklistEnteries = yes_no_ratingField.getPicklistValues();

        for(Schema.PicklistEntry entry : yes_no_ratingPicklistEnteries){
            yes_no_ratingValues.add(entry.getValue());
        }

        // Get Complaint_Regarding__c Picklist Values    
        Schema.DescribeFieldResult crPicklist = Questionnaire__c.Complaint_Regarding__c.getDescribe();
        List<Schema.PicklistEntry> complaintRegardingPicklist = crPicklist.getPicklistValues();

        for(Schema.PicklistEntry entry : complaintRegardingPicklist){
            complaintRegardingValues.add(entry.getValue());
        }

        return new PicklistWrapper(ratingValues, yes_no_ratingValues, complaintRegardingValues);
    }


    @AuraEnabled
    public static String saveRatings(List<Questionnaire__c> updatedQuestions, Id psfId, Id taskId, String complaintText) {
	
        String WMEmailId = '';
        
        System.debug('updatedQuestions' + updatedQuestions);
        System.debug('psfId : ' + psfId);
        System.debug('taskId : ' + taskId);

        // Set Status__c = 'Completed' for all updated Questionnaire__c records
        for (Questionnaire__c q : updatedQuestions) {
            q.Status__c = 'Completed';
        }

        update updatedQuestions;

        // Calculate average
        /*
        List<Questionnaire__c> allQs = [
            SELECT Rating__c FROM Questionnaire__c
            WHERE Post_Service_Feedback__c = :psfId AND Rating__c != null
        ];
        */
        List<Questionnaire__c> allQs = [
            SELECT Rating__c FROM Questionnaire__c
            WHERE Post_Service_Feedback__c = :psfId
            AND Rating__c != null
            AND Is_Main_Rating__c = true
        ];

        Decimal sum = 0;
        Integer count = 0;
        for (Questionnaire__c q : allQs) {
            if (q.Rating__c != null) {
                sum += Decimal.valueOf(q.Rating__c);
                count++;
            }
        }

        Decimal avg = (count > 0) ? (sum / count).setScale(2) : 0;

        Post_Service_Feedback__c psfToUpdate = new Post_Service_Feedback__c(
            Id = psfId,
            Average_Rating__c = avg
        );

        List<SObject> recordsToInsert = new List<SObject>();
        Boolean ticketCreated = false;
        Ticket__c insertedTicket;

        if (avg < 7) {
            Post_Service_Feedback__c psfrec = [
                SELECT Id, Name, Job_card__c,
                        OwnerId,
                        Job_Card__r.AccountId,
                        Job_Card__r.Vehicle__c,
                        Job_Card__r.ContactId,
                        Job_Card__r.Vehicle__r.VehicleIdentificationNumber,
                        Job_Card__r.Vehicle__r.LastOdometerReading,Job_Card__r.Service_Center__c
                FROM Post_Service_Feedback__c
                WHERE Id = :psfId
                LIMIT 1
            ];

            /*
            // Fetch Account 
            Id accountId = psfrec.Job_Card__r.Service_Center__c;
            System.debug('AccountId : ' + accountId);

            // Fetch Contacts where Designation is "WM"
            List<Contact> wmContacts = new List<Contact>();
            if(accountId != null){
                wmContacts = [
                    SELECT Id, Name, Designation__c, Owner.Name, OwnerId 
                    FROM Contact
                    WHERE AccountId = :accountId
                    AND Designation__c = 'WM'
                ];
                System.debug('wmContacts : ' + wmContacts);
            }            

            String wmUserId = '';
            if (!wmContacts.isEmpty()) {
                Contact wm = wmContacts[0];

                // Now find the user related to this contact
                List<User> users = [
                    SELECT Id, Name, ContactId, Contact.Name, Email, isActive
                    FROM User
                    WHERE ContactId = :wm.Id
                    AND isActive = true
                    LIMIT 1
                ];
                System.debug('users found : ' + users);

                if(! users.isEmpty()){
                    wmUserId = users[0].Id;
                    WMEmailId = users[0].Email;
                    System.debug('wmUserId Exists : ' + wmUserId);
                }
            }
            else{
                System.debug('No User was found related to that Contact');
                System.debug('Assign Current Logged In User Id to Ticket Owner : ' + UserInfo.getUserId());
                
                User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId()];
                WMEmailId = currentUser.Email;
                System.debug('Current User Email: ' + WMEmailId);
            }
            */

            Id ticketRecordTypeId = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Ticket__c' 
                AND DeveloperName = 'PSF_Ticket' 
                LIMIT 1
            ].Id;

            System.debug('ticketRecordTypeId : ' + ticketRecordTypeId);

            Ticket__c newTicket = new Ticket__c(
                Post_Service_Feedback__c = psfrec.Id,
                Job_Card__c = psfrec.Job_card__c,
                RecordTypeId = ticketRecordTypeId,
                Status__c = 'Open',
                Vehicle__c = psfrec.Job_Card__r.Vehicle__c,
                VIN__c = psfrec.Job_Card__r.Vehicle__r.VehicleIdentificationNumber,
                Odo_Meter_Reading__c = psfrec.Job_Card__r.Vehicle__r.LastOdometerReading,
                Service_Center__c = psfrec.Job_Card__r.Service_Center__c,  // <-- added this line
                OwnerId = psfrec.OwnerId,
                //OwnerId = String.isNotBlank(wmUserId) ? (Id) wmUserId : UserInfo.getUserId(), // <-- added this line
                //OwnerId = Label.CRE_User_Id,
                Customer_Complaint__c = complaintText
            );
            recordsToInsert.add(newTicket);
            System.debug('Ticket Added to the List');

            psfToUpdate.Status__c = 'Ticket Raised';
            psfToUpdate.Sub_Status__c = '';
            psfToUpdate.Next_Follow_Up_Date__c = null;
            ticketCreated = true;

            System.debug('newTicket : ' + newTicket);
            System.debug('------- psfToUpdate ------- : ' + psfToUpdate);
        } 
        else {
            System.debug('INSIDE ELSE');
            psfToUpdate.Status__c = 'Completed';

            Task t = [SELECT Id, Status FROM Task WHERE Id = :taskId LIMIT 1];
            t.Status = 'Completed';
            update t;

            System.debug('TASK ID : ' + taskId);
            System.debug('Inside Else');
        }

        update psfToUpdate;

        if (!recordsToInsert.isEmpty()) {
            System.debug('recordsToInsert : ' + recordsToInsert);
            insert recordsToInsert;
            insertedTicket = (Ticket__c) recordsToInsert[0];

            System.debug('================== TICKET INSERTED ========== ' + recordsToInsert.size());
        }

        // ==================================== CODE ADDED TO CREATE TICKET RELATED TASK ==================================== //

        Set<Id> insertedTicketIds = new Set<Id>();
        Map<Id, ContactAndVehicleDetailsWrapper> ticketToDetailsMap = new Map<Id, ContactAndVehicleDetailsWrapper>();

        for(SObject tick : recordsToInsert){
            insertedTicketIds.add(tick.Id);
        }

        List<Ticket__c> allInsertedTickets = [
            SELECT Id, Name, OwnerId, Owner.Name, Job_Card__c, Job_Card__r.Vehicle__c, Job_Card__r.Vehicle__r.CurrentOwnerId, Post_Service_Feedback__c, Post_Service_Feedback__r.Name,
            Job_Card__r.Vehicle__r.CurrentOwner.Name, Job_Card__r.Vehicle__r.CurrentOwner.Phone,  
            Job_Card__r.Vehicle__r.CurrentOwner.Email__c, Job_Card__r.Vehicle__r.CurrentOwner.Secondary_Phone_Number__c 
            FROM Ticket__c
            WHERE Id IN : insertedTicketIds
        ];

        for(Ticket__c t : allInsertedTickets){
            ticketToDetailsMap.put(t.Id, 
                new ContactAndVehicleDetailsWrapper(t.Job_Card__r.Vehicle__c, 
                    t.Job_Card__r.Vehicle__r.CurrentOwner.Phone, 
                    t.Job_Card__r.Vehicle__r.CurrentOwner.Email__c,
                    t.Job_Card__r.Vehicle__r.CurrentOwnerId,
                    t.Job_Card__r.Vehicle__r.CurrentOwner.Name)
            );
        }

        Id ticketTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('TICKET RecordType').getRecordTypeId();
        System.debug('ticketTaskRecordTypeId : ' + ticketTaskRecordTypeId);

        /*
        Id taskRecordTypeId = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Task' 
                AND DeveloperName = 'TICKET_RecordType' 
                LIMIT 1
        ].Id;
            System.debug('taskRecordTypeId : ' + taskRecordTypeId);
        */

        List<Task> taskListToInsert = new List<Task>();

        for(Ticket__c ti : allInsertedTickets){
            Task newTask = new Task();
            newTask.Subject = ti.Name + '-' + 'FollowUp Call-' + 1;
            newTask.Status = 'Pending';
            newTask.Priority = 'High';
            newTask.ActivityDate = Date.today();
            newTask.OwnerId = UserInfo.getUserId(); 
            newTask.WhatId = ti.Id;
            newTask.Vehicle__c = ticketToDetailsMap.get(ti.Id).vehicleId != null ? ticketToDetailsMap.get(ti.Id).vehicleId : null; 
            newTask.Phone_Number__c = ticketToDetailsMap.get(ti.Id).phone != null ? ticketToDetailsMap.get(ti.Id).phone : null;
            newTask.Customer__c = ticketToDetailsMap.get(ti.Id).customer != null ? ticketToDetailsMap.get(ti.Id).customer : null;
            newTask.Call_To_c__c = ticketToDetailsMap.get(ti.Id).customerName != null ? ticketToDetailsMap.get(ti.Id).customerName : null;
            newTask.Description = 'Call the customer to discuss service feedback';
            //newTask.OwnerId = Label.CRE_User_Id;
            newTask.OwnerId = ti.OwnerId;  
            newTask.PSF_Name__c = ti.Post_Service_Feedback__r.Name;

            newTask.RecordTypeId = ticketTaskRecordTypeId;
            taskListToInsert.add(newTask);
        }

        if(! taskListToInsert.isEmpty()){
            insert taskListToInsert;
            System.debug('TICKET TASK INSERTED SUCCESSFULLY');
        }

        /*
        if (ticketCreated && insertedTicket != null) {
            User adminUser = [
                SELECT Id, Email
                FROM User
                WHERE Profile.Name = 'System Administrator' AND IsActive = true AND Email != null
                LIMIT 1
            ];

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { WMEmailId });
            email.setSubject('Ticket Raised for Low Feedback Rating');
            email.setPlainTextBody(
                'A new Ticket has been raised due to low feedback (Average Rating: ' + avg + ').\n\n' +
                'Ticket ID: ' + insertedTicket.Id + '\n' +
                'Associated Feedback ID: ' + psfId
            );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
        */
        
        return (ticketCreated && insertedTicket != null) ? insertedTicket.Id : null;
    }

    // WRAPPER CLASS
    public class ContactAndVehicleDetailsWrapper {
        public Id vehicleId;
        public String phone;
        public String email;
        public Id customer;
        public String customerName;

        public ContactAndVehicleDetailsWrapper(Id vehicleId, String phone, String email, Id customer, String customerName) {
            this.vehicleId = vehicleId;
            this.phone = phone;
            this.email = email;
            this.customer = customer;
            this.customerName = customerName;
        }
    }
}