@isTest
public with sharing class TaskHandler_Test {

    @isTest
    public static void testHandleAfterInsert() {

        // Create test data
        Account acc = new Account(Name = 'Test Account', Type='Customer');
        insert acc;

        // Create Contact
        Contact con = new Contact(
            AccountId = acc.Id,    
            FirstName = 'Joey', 
            LastName = 'Shaul',
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
            Status = 'Completed',
            Completed_Date__c = System.now().addDays(-4),
            Subject = 'Old Completed WO'
        );
        insert wo1;

        // --------------------------------- handleAfterInsert Test Check ---------------------------------
        Post_Service_Feedback__c psf = new Post_Service_Feedback__c();
        psf.Job_Card__c = wo1.Id;
        psf.Status__c = 'Pending';
        insert psf;

        Task psfTask = new Task();
        psfTask.Subject = 'followup-';
        psfTask.Status = 'Pending';
        psfTask.Priority = 'High';
        psfTask.ActivityDate = Date.today();
        psfTask.WhatId = psf.Id;
        insert psfTask;

        // --------------------------------- handleTicketCallCount Test Check ---------------------------------
        Ticket__c newTicket = new Ticket__c(
            Post_Service_Feedback__c = psf.Id,
            Job_Card__c = psf.Job_card__c
        );
        insert newTicket;

        Task ticketTask = new Task();
        ticketTask.Subject = 'ti -';
        ticketTask.Status = 'Pending';
        ticketTask.Priority = 'High';
        ticketTask.ActivityDate = Date.today();
        ticketTask.WhatId = newTicket.Id;
        insert ticketTask;

        // --------------------------------- handleAppointmentCallCount Test Check ---------------------------------


        ServiceAppointment appoint = new ServiceAppointment();
        appoint.Vehicle__c = v.Id;
        appoint.ParentRecordId = wo1.Id;
        insert appoint;

        Task appointTask = new Task();
        appointTask.Subject = '- call back request';
        appointTask.Status = 'Pending';
        appointTask.Priority = 'High';
        appointTask.ActivityDate = Date.today();
        appointTask.WhatId = appoint.Id;
        insert appointTask;
        
        TaskHandler.mytest();

    }

    
    
    
}