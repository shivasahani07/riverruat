@IsTest
public class POCreationInSAPQueueableTest {
     public class MockRiverCreateOrderCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"Success","message":"Successfully Posted the Data to SAP!!","timestamp":"26/June/2025 13:19:08","sapDocumentDetails":"210"}');
            res.setStatusCode(200);
            return res;
        }
    }
    public class MockRiverCreateOrderCalloutForFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"Failure","message":"Material is not Listed","timestamp":"26/June/2025 13:19:08","sapDocumentDetails":""}');
            res.setStatusCode(400);
            return res;
        }
    }
    @IsTest
    static void testAPIMethod(){
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka');
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
        Id stdPrBk = Test.getStandardPricebookId();
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New'
        );
        insert po;
        
        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        SAP_API_Creds__c r = new SAP_API_Creds__c(Name='SAP API Creds',User_Name__c='yuhj',Password__c='yiuyhjv',Endpoint__c='https://www.exapmle.com');
        insert r;
        
        
        Test.setMock(HttpCalloutMock.class, new MockRiverCreateOrderCallout());
        Test.startTest();
        POCreationInSAPQueueable queueable = new POCreationInSAPQueueable(new List<Id>{po.Id});
        System.enqueueJob(queueable);
        Test.stopTest();
    }
     @IsTest
    static void testAPIMethodForFailure(){
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka');
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id,Location__c =testLocation.id,Role_Type__c='Sales');
        insert con;
        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Parts');
        insert testProduct;
        
        Product2 testProduct2 = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcde',HSN_Code__c='abcde',Type__c='Parts');
        insert testProduct2;
        
        Id stdPrBk = Test.getStandardPricebookId();
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        ProductRequest po = new ProductRequest(
            Account__c = testAccount.Id,
            ShipmentType = 'VOR',
            Contact__c=con.Id,
            Product_Type__c='Service',
            Status='New'
        );
        insert po;
        
        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id =testProduct.Id ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );
        insert poLineItem;
        
        SAP_API_Creds__c r = new SAP_API_Creds__c(Name='SAP API Creds',User_Name__c='yuhj',Password__c='yiuyhjv',Endpoint__c='https://www.exapmle.com');
        insert r;
        
        
        Test.setMock(HttpCalloutMock.class, new MockRiverCreateOrderCalloutForFailure());
        Test.startTest();
        POCreationInSAPQueueable queueable = new POCreationInSAPQueueable(new List<Id>{po.Id});
        System.enqueueJob(queueable);
        Test.stopTest();
    }

}