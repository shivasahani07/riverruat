global class CreatePostServiceFeedbackBatch implements Database.Batchable<SObject> {
    
    /*
    global void execute(SchedulableContext sc) {
        CreatePostServiceFeedbackBatch batch = new CreatePostServiceFeedbackBatch();
        Database.executeBatch(batch, 200);
    }
    */
    
    private Boolean isTest = false;
    private Id testWorkOrderId;

    public CreatePostServiceFeedbackBatch() {} 

    public CreatePostServiceFeedbackBatch(Boolean isTest, Id testWorkOrderId) {
        this.isTest = isTest;
        this.testWorkOrderId = testWorkOrderId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime threeDaysAgo = System.now().addDays(-3);
		
		List<String> jobCardList = system.label.IsPSFTesting.split(',');
        String jobFlag = jobCardList[0];
        String TestRecordId = jobCardList[1];
        if(jobFlag == 'True' && isTest && testWorkOrderId != null){
            return Database.getQueryLocator([ SELECT Id, Status, Completed_Date__c, AccountId, Account_Type__c, Service_Center__c, RR_Service_Advisor__c
                                             FROM WorkOrder 
                                             WHERE Id =: TestRecordId  
                                             AND Status = 'Completed'
                                            ]);
        }
        else{
            System.debug('WorkOrders found for batch: ' + [SELECT Id, Status, Completed_Date__c, AccountId, Account_Type__c, Service_Center__c, RR_Service_Advisor__c,
                            (SELECT Id FROM Post_Service_Feedbacks__r LIMIT 1)
                        FROM WorkOrder
                        WHERE Status = 'Completed'
                        AND Completed_Date__c <= :threeDaysAgo 
                        AND Account_Type__c = 'Customer'].size());

            return Database.getQueryLocator([ 
                        SELECT Id, Status, Completed_Date__c, AccountId, Account_Type__c, Service_Center__c, RR_Service_Advisor__c,
                            (SELECT Id FROM Post_Service_Feedbacks__r LIMIT 1)
                        FROM WorkOrder
                        WHERE Status = 'Completed'
                        AND Completed_Date__c <= :threeDaysAgo 
                        AND Account_Type__c = 'Customer'
            ]);
        }
        
        /*
        return Database.getQueryLocator([
            SELECT Id, Status, Completed_Date__c, AccountId, Account_Type__c, Service_Center__c, RR_Service_Advisor__c,
            	(SELECT Id FROM Post_Service_Feedbacks__r LIMIT 1)
            FROM WorkOrder
            WHERE Status = 'Completed'
            AND Completed_Date__c <= :threeDaysAgo 
			AND Account_Type__c = 'Customer'
            //AND RR_Service_Advisor__c != Null
            //AND Service_Center__c != Null
            
        ]);
		*/
    }
    
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Post_Service_Feedback__c> feedbacksToCreate = new List<Post_Service_Feedback__c>();
        Map<Id, Id> workOrderToFeedbackMap = new Map<Id, Id>();
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();

        // ------------------------- Changes --------------------------- //
        Set<Id> accountIds = new Set<Id>();     // Fetch Accounts
        Map<Id, List<Contact>> accountContactsMap = new Map<Id, List<Contact>>();
        Set<Id> contactIds = new Set<Id>();

        for(SObject w : scope){
            WorkOrder wo = (WorkOrder) w;
            if(wo.Service_Center__c != null){
                accountIds.add(wo.Service_Center__c);
            }
        }

        if(! accountIds.isEmpty()){
            for (Account acc : [SELECT Id, 
                        (SELECT Id, Designation__c FROM Contacts WHERE Designation__c = 'CRE') 
                    FROM Account WHERE Id IN :accountIds]) {
                    accountContactsMap.put(acc.Id, acc.Contacts);

                    for (Contact con : acc.Contacts) {
                        contactIds.add(con.Id);
                    }
            }
        }

        // Map of ContactId to UserId where Contact is linked to User
        Map<Id, Id> contactToUserMap = new Map<Id, Id>();
        if (!contactIds.isEmpty()) {
            for (User usr : [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIds AND IsActive = true]) {
                contactToUserMap.put(usr.ContactId, usr.Id);
            }
        }

        
        for (SObject w1 : scope) {
            WorkOrder wo = (WorkOrder) w1;
            // Skip the records for which the PSF records are already created
            if (wo.Post_Service_Feedbacks__r != null && !wo.Post_Service_Feedbacks__r.isEmpty()) {
                System.debug('Skip the Job Card. PSF is already created for this Job Card.');
                continue;
            }
            
            Post_Service_Feedback__c feedback = new Post_Service_Feedback__c();
            feedback.Status__c = 'Pending';
            feedback.Job_Card__c = wo.Id;

            List<Contact> contacts = accountContactsMap.get(wo.Service_Center__c);

            if (contacts != null && !contacts.isEmpty()) {
                Boolean ownerAssigned = false;

                // Try to assign OwnerId to first Contact who is also a User
                for (Contact con : contacts) {
                    if (contactToUserMap.containsKey(con.Id)) {
                        feedback.OwnerId = contactToUserMap.get(con.Id);
                        ownerAssigned = true;
                        break;
                    }
                }

                // Optional: If no User found for any Contact, assign default Owner or skip
                if (!ownerAssigned) {
                    System.debug(' ****************************** INSIDE OWNER NOT ASSIGNED ***************************** ');
                    feedback.OwnerId = UserInfo.getUserId(); // Optional: Default OwnerId
                }
            }

            feedbacksToCreate.add(feedback);
            workOrderMap.put(wo.Id, wo);
        }
        
        if (!feedbacksToCreate.isEmpty()) {
            insert feedbacksToCreate;
            System.debug('feedbacksToCreate==>'+feedbacksToCreate);
            
            /*
            // -------------- UPDATING THE JOB CARD FOR WHOM THE PSF ARE GENERATED --------------- //
            Set<Id> jobCardIdSet = new Set<Id>();
            for(Post_Service_Feedback__c psf : feedbacksToCreate){
                jobCardIdSet.add(psf.Job_Card__c);
            }
            
            List<WorkOrder> workOrderList = new List<WorkOrder>();
            for(Id jobId : jobCardIdSet){
                WorkOrder wo = new WorkOrder(Id = jobId, PSF_Generated__c = TRUE);
                workOrderList.add(wo);
            }
            
            if(! workOrderList.isEmpty()){
                update workOrderList;
            }
            */
            
            for (Post_Service_Feedback__c psf : feedbacksToCreate) {
                if (psf.Job_Card__c != null) {
                    workOrderToFeedbackMap.put(psf.Job_Card__c, psf.Id);
                }
            }
            
            List<Feedback_Question__c> questions = [
                SELECT Name, Question_Type__c, Form_Name__c, Is_Rating_Question__c, Question__c, Is_Main_Rating__c
                FROM Feedback_Question__c
                WHERE  Question_Type__c = 'Subjective' AND Form_Name__c = 'PSF Questionnaire'
            ];
            
            List<Questionnaire__c> questionnairesToInsert = new List<Questionnaire__c>();
            
            for (SObject w : scope) {
                WorkOrder wo = (WorkOrder) w;
                Id psfId = workOrderToFeedbackMap.get(wo.Id);
                if (psfId != null) {
                    for (Feedback_Question__c q : questions) {
                        Questionnaire__c question = new Questionnaire__c();
                        question.Post_Service_Feedback__c = psfId;
                        question.Question__c = q.Question__c;
                        question.Question_Type__c = q.Question_Type__c;
                        question.Status__c = 'Pending';
                        question.Is_Rating_Question__c = q.Is_Rating_Question__c;
                        question.Is_Main_Rating__c = q.Is_Main_Rating__c;
                        questionnairesToInsert.add(question);
                    }
                }
            }
            
            if (!questionnairesToInsert.isEmpty()) {
                insert questionnairesToInsert;
            }
        }

        // ==================================== CODE ADDED TO CREATE RELATED TASK ==================================== //

        Set<Id> insertedPSFIds = new Set<Id>();
        Map<Id, ContactAndVehicleDetailsWrapper> psfToDetailsMap = new Map<Id, ContactAndVehicleDetailsWrapper>();

        for(Post_Service_Feedback__c psf : feedbacksToCreate){
            insertedPSFIds.add(psf.Id);
        }

        List<Post_Service_Feedback__c> feedbacks = [
            SELECT Id, Name, OwnerId, Owner.Name, Call_Count__c, Job_Card__c, Job_Card__r.Vehicle__c, Job_Card__r.Vehicle__r.CurrentOwnerId, 
            Job_Card__r.Vehicle__r.CurrentOwner.Name, Job_Card__r.Vehicle__r.CurrentOwner.Phone,  
            Job_Card__r.Vehicle__r.CurrentOwner.Email__c, Job_Card__r.Vehicle__r.CurrentOwner.Secondary_Phone_Number__c 
            FROM Post_Service_Feedback__c 
            WHERE Id IN : insertedPSFIds
        ];

        for(Post_Service_Feedback__c feed : feedbacks){
            psfToDetailsMap.put(feed.Id, 
                new ContactAndVehicleDetailsWrapper(feed.Job_Card__r.Vehicle__c, 
                    feed.Job_Card__r.Vehicle__r.CurrentOwner.Phone, 
                    feed.Job_Card__r.Vehicle__r.CurrentOwner.Email__c,
                    feed.Job_Card__r.Vehicle__r.CurrentOwnerId,
                    feed.Job_Card__r.Vehicle__r.CurrentOwner.Name)
            );
        }
        System.debug('psfToDetailsMap : ' + psfToDetailsMap);

        Id PSF_RecordType_Id = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PSF RecordType').getRecordTypeId();
        System.debug('PSF_RecordType_Id : ' + PSF_RecordType_Id);

        List<Task> taskListToInsert = new List<Task>();

        for(Post_Service_Feedback__c psf : feedbacks){

            if(psf.Call_Count__c == null){
                psf.Call_Count__c = 1;
            }
            
            Task newTask = new Task();
            newTask.Subject = 'FollowUp-' + psf.Call_Count__c + '-' + psf.Name;
            newTask.Status = 'Pending';
            newTask.Priority = 'High';
            newTask.ActivityDate = Date.today();
            newTask.WhatId = psf.Id;
            newTask.Vehicle__c = psfToDetailsMap.get(psf.Id).vehicleId != null ? psfToDetailsMap.get(psf.Id).vehicleId : null; 
            newTask.Phone_Number__c = psfToDetailsMap.get(psf.Id).phone != null ? psfToDetailsMap.get(psf.Id).phone : null;
            newTask.Customer__c = psfToDetailsMap.get(psf.Id).customer != null ? psfToDetailsMap.get(psf.Id).customer : null;
            newTask.Call_To_c__c = psfToDetailsMap.get(psf.Id).customerName != null ? psfToDetailsMap.get(psf.Id).customerName : null;
            newTask.Description = 'Call the customer to discuss service feedback';
            newTask.RecordTypeId = PSF_RecordType_Id;
            newTask.OwnerId = psf.OwnerId;
            //newTask.OwnerId = Label.CRE_User_Id; 
            //newTask.OwnerId = UserInfo.getUserId();
    
            taskListToInsert.add(newTask);
        }

        if(! taskListToInsert.isEmpty()){
            insert taskListToInsert;
            System.debug('PSF TASK INSERTED SUCCESSFULLY');
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
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