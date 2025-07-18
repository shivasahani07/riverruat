@isTest
public with sharing class PostServiceFeedbackHandler_Test {
    
    @isTest
    public static void testHandleStatusCompleted() {

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

        // --------------------------------- handleStatusCompleted Test Check ---------------------------------
        Post_Service_Feedback__c psf = new Post_Service_Feedback__c();
        psf.Job_Card__c = wo1.Id;
        psf.Status__c = 'Pending';
        insert psf;

        Questionnaire__c que1 = new Questionnaire__c();
        //que1.Question__c = 'On a scale of 1 to 5, how satisfied are you with the service experience today?';
        que1.Question_Type__c = 'Subjective';
        que1.Post_Service_Feedback__c = psf.Id;
        que1.Rating_Number__c = 8;
        insert que1;

        // REFRESH FROM DATABASE
        psf = [SELECT Id, Status__c FROM Post_Service_Feedback__c WHERE Id = :psf.Id];
        psf.Status__c = 'Completed';
        update psf;



        

    }
}