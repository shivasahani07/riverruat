@isTest
public class PSFQuestionnaireWrapperApex_Test {
	
    @isTest
    public static void test_getPsfIdFromTask(){
        
        // Create test data
        Account acc = new Account(Name = 'Test Account', Type = 'Customer');
        insert acc;
        
        Account accService = new Account(Name = 'Test Account', Type = 'Service Center', Center_Code__c='84888');
        insert accService;
        
        // Create Contact
        Contact con = new Contact(
            FirstName = 'Joey', 
            LastName = 'Shaul',
            AccountId = acc.Id,
            Phone = '8967452312'
        );
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
        v.CurrentOwnerId = acc.Id;
        insert v;
        
        // Create WorkOrders
        WorkOrder wo1 = new WorkOrder(
            AccountId = acc.Id,
            ContactId = con.Id,
            Vehicle__c = v.Id,
            Status = 'Completed',
            Completed_Date__c = System.now().addDays(-4),
            Subject = 'Old Completed WO',
            Service_Center__c = accService.Id
        );
        
        // Create PSF
        Post_Service_Feedback__c psf = new Post_Service_Feedback__c(
        	Job_Card__c = wo1.Id,
            Status__c = 'Pending'
        );
        insert psf;
        
        Task tsk = new Task(
        	Subject = 'FollowUp-',
            WhatId = psf.Id
        );
        insert tsk;
        
        PSFQuestionnaireWrapperApex.getPsfIdFromTask(tsk.Id);
    }
}