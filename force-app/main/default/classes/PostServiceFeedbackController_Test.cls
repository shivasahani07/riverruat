@isTest
public with sharing class PostServiceFeedbackController_Test {

    @isTest
    public static void testQuestionnaierCompController(){

        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'Joey', 
            LastName = 'Shaul',
            AccountId = acc.Id,
            Phone = '8967452312');
        insert con;

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product', 
            IsActive = true, 
            ProductCode = 'PROd-39784',
            HSN_Code__c = 'HSN-384',
            Type__c = 'Parts');
        insert prod;

        // Create Asset
        Asset ass = new Asset(Name = 'River NX-299', AccountId = acc.Id, Product2Id = prod.Id);
        insert ass;

        // Create Vehicle Defination
        VehicleDefinition vd = new VehicleDefinition();
        vd.Name = 'VD Name 1';
        vd.ProductId = prod.Id; 
        insert vd;

        // Create Software_Version__c
        Software_Version__c sv = new Software_Version__c(Name = 'V1.29');
        insert sv;

        // Create Vehicle
        Vehicle v = new Vehicle();
        v.Name = 'River NX-299';
        v.AssetId = ass.Id;
        v.VehicleDefinitionId = vd.Id;
        v.VehicleIdentificationNumber = '83493HHHGBBB';
        v.Software_Version__c = sv.Id;
        v.Charger_PC_Number__c = 'CHR001';
        insert v;

        // Create WorkOrders
        WorkOrder wo1 = new WorkOrder(
            AccountId = acc.Id,
            ContactId = con.Id,
            Vehicle__c = v.Id,
            //Status = 'Completed',
            //Completed_Date__c = System.now().addDays(-4),
            Subject = 'Old Completed WO'
        );
        insert wo1;

        Post_Service_Feedback__c psf = new Post_Service_Feedback__c();
        psf.Job_Card__c = wo1.Id;
        psf.Status__c = 'Pending';
        insert psf;

        // If Questionnaire Rating > 7
        Questionnaire__c qc1 = new Questionnaire__c();
        //qc1.Question__c = 'On a scale of 1 to 5, how satisfied are you with the service experience today?';
        qc1.Question_Type__c = 'Subjective';
        qc1.Rating__c = '9';
        qc1.Post_Service_Feedback__c = psf.Id;

        Questionnaire__c qc2 = new Questionnaire__c();
        //qc2.Question__c = 'How would you rate the timeliness of the service?';
        qc2.Question_Type__c = 'Subjective';
        qc2.Rating__c = '9';
        qc2.Post_Service_Feedback__c = psf.Id;

        List<Questionnaire__c> lstQuestionnaire1 = new List<Questionnaire__c>{qc1, qc2};
        insert lstQuestionnaire1;

        Task newTask = new Task();
        newTask.Subject = 'Test Task';
        newTask.Status = 'Pending';
        newTask.Priority = 'High';
        newTask.ActivityDate = Date.today();
        newTask.WhatId = psf.Id;
        insert newTask;
        
        

        PostServiceFeedbackController.getQuestionnaires(psf.Id);
        PostServiceFeedbackController.getRatingPicklistValues();

        PostServiceFeedbackController.saveRatings(lstQuestionnaire1, psf.Id, newTask.Id, 'No Ticket Will be Created');

    }
	
    @isTest
    public static void testQuestionnaierCompController2(){

        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'Joey', 
            LastName = 'Shaul',
            AccountId = acc.Id,
            Phone = '8967452312');
        insert con;

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product', 
            IsActive = true, 
            ProductCode = 'PROd-39784',
            HSN_Code__c = 'HSN-384',
            Type__c = 'Parts');
        insert prod;

        // Create Asset
        Asset ass = new Asset(Name = 'River NX-299', AccountId = acc.Id, Product2Id = prod.Id);
        insert ass;

        // Create Vehicle Defination
        VehicleDefinition vd = new VehicleDefinition();
        vd.Name = 'VD Name 1';
        vd.ProductId = prod.Id; 
        insert vd;

        // Create Software_Version__c
        Software_Version__c sv = new Software_Version__c(Name = 'V1.29');
        insert sv;

        // Create Vehicle
        Vehicle v = new Vehicle();
        v.Name = 'River NX-299';
        v.AssetId = ass.Id;
        v.VehicleDefinitionId = vd.Id;
        v.VehicleIdentificationNumber = '83493HHHGBBB';
        v.Software_Version__c = sv.Id;
        v.Charger_PC_Number__c = 'CHR001';
        insert v;

        // Create WorkOrders
        WorkOrder wo1 = new WorkOrder(
            AccountId = acc.Id,
            ContactId = con.Id,
            Vehicle__c = v.Id,
            //Status = 'Completed',
            //Completed_Date__c = System.now().addDays(-4),
            Subject = 'Old Completed WO'
        );
        insert wo1;

        Post_Service_Feedback__c psf = new Post_Service_Feedback__c();
        psf.Job_Card__c = wo1.Id;
        psf.Status__c = 'Pending';
        insert psf;

        // If Questionnaire Rating < 7
        Questionnaire__c qc3 = new Questionnaire__c();
        //qc3.Question__c = 'On a scale of 1 to 5, how satisfied are you with the service experience today?';
        qc3.Question_Type__c = 'Subjective';
        qc3.Rating__c = '5';
        qc3.Post_Service_Feedback__c = psf.Id;

        Questionnaire__c qc4 = new Questionnaire__c();
        //qc4.Question__c = 'How would you rate the timeliness of the service?';
        qc4.Question_Type__c = 'Subjective';
        qc4.Rating__c = '2';
        qc4.Post_Service_Feedback__c = psf.Id;

        List<Questionnaire__c> lstQuestionnaire2 = new List<Questionnaire__c>{qc3, qc4};
        insert lstQuestionnaire2;

        Task newTask = new Task();
        newTask.Subject = 'Test Task';
        newTask.Status = 'Pending';
        newTask.Priority = 'High';
        newTask.ActivityDate = Date.today();
        newTask.WhatId = psf.Id;
        insert newTask;
        
        PostServiceFeedbackController.saveRatings(lstQuestionnaire2, psf.Id, newTask.Id, 'Again Same Issue is Coming - Ticket will be created.');
    } 

}