@isTest
public with sharing class CreatePostServiceFeedbackBatch_Test {
    
    @isTest
    public static void testBatchClass(){
        
        // Create test data
        Account acc = new Account(Name = 'Test Account', Type = 'Customer');
        insert acc;
        
        Account accService = new Account(Name = 'Service Center', Type = 'Service Center', Center_Code__c='84888');
        insert accService;
        
        Schema.Location loc = new Schema.Location(Name='Test Location', LocationType='State');
        insert loc;
        
        // Create Contact
        Contact con = new Contact(
            FirstName = 'Joey', 
            LastName = 'Shaul',
            AccountId = acc.Id,
            Phone = '8967452312',
            Role_Type__c = 'Sales',
            Location__c = loc.Id
        );
        insert con;
	        
        // Create Contact
        Contact con2 = new Contact(
            FirstName = 'Joey', 
            LastName = 'Shaul',
            AccountId = accService.Id,
            Phone = '8962452312',
            Designation__c = 'CRE',
            Role_Type__c = 'Sales',
            Location__c = loc.Id
        );
        insert con2;
        
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
        
        WhatsappIntegration__c w = new WhatsappIntegration__c(Name='WhatsApp API',rnr_whatsapp_book_test_ride__c='anythig.jpg',Service_Endpoint__c='www.whatsapp.com',Service_Bearer_Token__c='8o7btii7');
        insert w;
        
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        ServiceResource sr = new ServiceResource(Name = 'Test Advisor', RelatedRecordId = testUser.Id);
        insert sr;
        
        
        // Create WorkOrders
        // WorkOrder that should be included (completed 4 days ago)
        WorkOrder wo1 = new WorkOrder(
            AccountId = acc.Id,
            ContactId = con.Id,
            Vehicle__c = v.Id,
            Status = 'New',
            //Completed_Date__c = System.now().addDays(-4),
            Subject = 'Old Completed WO',
            Service_Center__c = accService.Id,
            RR_Service_Advisor__c=sr.Id
        );
        
        // WorkOrder that should NOT be included (completed yesterday)
        WorkOrder wo2 = new WorkOrder(
            AccountId = acc.Id,
            ContactId = con.Id,
            Vehicle__c = v.Id,
            Status = 'New',
            //Completed_Date__c = System.now().addDays(-1),
            Subject = 'Recent Completed WO',
            RR_Service_Advisor__c=sr.Id
        );
        
        // WorkOrder with wrong status
        WorkOrder wo3 = new WorkOrder(
            AccountId = accService.Id,
            ContactId = con.Id,
            Vehicle__c = v.Id,
            Status = 'New',
            //Completed_Date__c = System.now().addDays(-3),
            Subject = 'In Progress WO',
            RR_Service_Advisor__c=sr.Id
        );
        
        insert new List<WorkOrder> { wo1, wo2, wo3 };
        wo1.Status = 'Completed';
        wo1.Completed_Date__c = System.now().addDays(-3);        
        update wo1;
        
        System.debug('Account_Type__c on WO1: ' + [SELECT Account_Type__c FROM WorkOrder WHERE Id = :wo1.Id].Account_Type__c);

        
        // ----------------------- TESTING EXECUTE METHOD ----------------------- // 
        
        // Create Feedback_Question__c records
        Feedback_Question__c q1 = new Feedback_Question__c(
            Name = 'How was the service?',
            Question_Type__c = 'Subjective',
            Form_Name__c = 'PSF Questionnaire'
        );
        
        Feedback_Question__c q2 = new Feedback_Question__c(
            Name = 'Any suggestions?',
            Question_Type__c = 'Subjective',
            Form_Name__c = 'PSF Questionnaire'
        );
        
        insert new List<Feedback_Question__c> { q1, q2 };
            
        
        
        
        Test.startTest();
       // String testLabel = 'True,' + wo1.Id;
       // CreatePostServiceFeedbackBatch batch = new CreatePostServiceFeedbackBatch();
       // Database.executeBatch(batch, 200);
        //batch.execute(null);
        //
        //
       CreatePostServiceFeedbackBatch batch = new CreatePostServiceFeedbackBatch(true, wo1.Id);
       Database.executeBatch(batch, 200);
        Test.stopTest();
        
    }
}