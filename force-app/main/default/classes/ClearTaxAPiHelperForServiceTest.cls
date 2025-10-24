@isTest
public class ClearTaxAPiHelperForServiceTest {
    
    @isTest
    static void testGetAccessToken() {
        ClearTax_Api_Details__c setting = new ClearTax_Api_Details__c(
            Name = 'ClearTax Api',
            BaseURL_AccessToken__c = 'https://api.cleartax.in/access-token',
            Client_Secret__c = 'test_secret',
            E_Invoice_Base_URL__c = 'https://api-sandbox.clear.in/einv/v2/eInvoice/generate',
            Cancel_IRN_Base_URL__c = 'https://api-sandbox.clear.in/einv/v2/eInvoice/cancel',
            E_Way_Bill_BaseURL__c = 'https://api-sandbox.clear.in/einv/v2/eInvoice/ewaybill',
            GST_Rate__c = 12.0,
            POS_Code__c = '12',
            Buyer_State_Code__c = '33'
        );
        insert setting;
        
        Test.setMock(HttpCalloutMock.class, new CombinedMockCallout());
        
        Test.startTest();
        String token = ClearTaxAPiHelperForService.getAccessToken();
        Test.stopTest();
    } 
    
    @isTest
    static void testGeneratePayloadAndEInvoice() {
        // Setup test data (Accounts, Product, Pricebook, WorkOrder, etc.) - same as your current code
        Account serviceCenter = new Account(
            Name = 'Service Center A',
            GSTIN_Number__c = '22AAAAA0000A1Z5',
            BillingStreet = '123 Center St',
            BillingCity = 'Bengaluru',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '123456',
            Center_Code__c = '22',
            Type = 'Service Center'
        );
        insert serviceCenter;
        
        Account customer = new Account(
            Name = 'Customer A',
            GSTIN_Number__c = '22BBBBB1111B2Z5',
            BillingStreet = '456 Cust St',
            BillingCity = 'bengaluru',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '654321'
        );
        insert customer;
        
        Product2 prod = new Product2(Name = 'TestProd', HSN_Code__c = '1234', ProductCode= '124', Type__c ='Accessories', IsActive = true);
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pricebookEntry;
        
        WorkOrder wo = new WorkOrder(
            AccountId = customer.Id,
            Service_Center__c = serviceCenter.Id,
            StartDate = System.Today(),
            Status = 'New',
            Subject = 'WO 1',
            Pricebook2Id = standardPricebook.Id
            // Add other fields as needed
        );
        insert wo;
        
        wo.EndDate = System.Today().addDays(1);
        update wo;
        
        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Quantity = 2,
            List_Price_New__c = 100,
            Discount = 0,
            RR_Product__c = prod.Id,
            RR_Parts_Category__c = 'Paid',
            CGST__c = 9,
            SGST__c = 9,
            IGST__c = 18
        );
        insert woli;
        
        CodeSet labourCode = new CodeSet(
            Name = 'LabourCode1',
            HSN_Code__c = '9987',
            Code= 'Code - 001',
            RR_Labour_Charge__c = 200
        );
        insert labourCode;
        
        WorkPlan wp = new WorkPlan(
            WorkOrderId = wo.Id,
            Name ='test labour',
            RR_Labour_Category__c = 'Paid',
            Labour_Charge__c = 200,
            Discount__c = 0,
            RR_Labour_Code__c = labourCode.Id,
            CGST__c = 9,
            SGST__c = 9,
            IGST__c = 18
        );
        insert wp;
        
        ClearTax_Api_Details__c setting = new ClearTax_Api_Details__c(
            Name = 'ClearTax Api',
            BaseURL_AccessToken__c = 'https://mocked.clear.tax/access-token',
            E_Invoice_Base_URL__c = 'https://mocked.clear.tax/invoice',
            Client_Secret__c = 'mockedSecret'
        );
        insert setting;
        
        Test.setMock(HttpCalloutMock.class, new CombinedMockCallout());
        
        Test.startTest();
        String payload = ClearTaxAPiHelperForService.generatePayloadForIRN(wo.Id);
        String result = ClearTaxAPiHelperForService.generateEInvoice(wo.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCheckWorkOrderStatus() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        
        Schema.Location loc = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'State',
            State__c = 'Karnataka',
            IsInventoryLocation = true
        );
        insert loc;
        
        Contact con = new Contact(
            LastName = 'testing Contact',
            AccountId = acc.Id,
            Phone = '9123456789',
            Email = 'test@test.com',
            Role_Type__c= 'Service',
            Location__c = loc.Id
        );
        insert con;
        
        WorkOrder woInvalid = new WorkOrder(
            AccountId = acc.Id,
            StartDate = Date.today(),
            Subject = 'WO Invalid',
            Status = 'New'
        );
        insert woInvalid;
        
        WorkOrder woValid = new WorkOrder(
            AccountId = acc.Id,
            RR_Technician__c = con.Id,
            StartDate = Date.today(),
            Subject = 'WO Valid',
            Status = 'Ready for Delivery'
        );
        insert woValid;
        
        Test.startTest();
        String msg1 = ClearTaxAPiHelperForService.CheckWorkOrderStatus(woInvalid.Id);
        String msg2 = ClearTaxAPiHelperForService.CheckWorkOrderStatus(woValid.Id);
        String msg3 = ClearTaxAPiHelperForService.CheckWorkOrderStatus(null);
        Test.stopTest();
    }
    
    @isTest
    static void testCancelIRN_EInvoice() {
        Account serviceCenter = new Account(
            Name = 'Test Center',
            GSTIN_Number__c = '29ABCDE1234F1Z5',
            BillingStreet = 'Street 1',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '560001',
            Type = 'Service Center',
            Center_Code__c = '3324'
        );
        insert serviceCenter;
        
        Account customer = new Account(Name = 'Test Customer');
        insert customer;
        
        WorkOrder wo = new WorkOrder(
            AccountId = customer.Id,
            Service_Center__c = serviceCenter.Id,
            StartDate = Date.today(),
            Subject = 'Cancel IRN Test',
            Status = 'Completed',
            IRN_No__c = 'TESTIRN123456'
        );
        insert wo;
        
        ClearTax_Api_Details__c setting = new ClearTax_Api_Details__c(
            Name = 'ClearTax Api',
            BaseURL_AccessToken__c = 'https://mocked.clear.tax/access-token',
            E_Invoice_Base_URL__c = 'https://mocked.clear.tax/invoice',
            Cancel_IRN_Base_URL__c = 'https://mocked.clear.tax/invoice/cancel',
            Client_Secret__c = 'mockedSecret'
        );
        insert setting;
        
        Test.setMock(HttpCalloutMock.class, new CombinedMockCallout());
        
        
        Test.startTest();
        String result = ClearTaxAPiHelperForService.cancelIRN_EInvoice('1', 'Testing Cancel', wo.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGenerateEInvoicePDF() {
        Account serviceCenter = new Account(
            Name = 'Service Center A',
            GSTIN_Number__c = '22AAAAA0000A1Z5',
            BillingStreet = '123 Center St',
            BillingCity = 'Bengaluru',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '123456',
            Center_Code__c = '22',
            Type = 'Service Center'
        );
        insert serviceCenter;
        
        Account customer = new Account(
            Name = 'Customer A',
            GSTIN_Number__c = '22BBBBB1111B2Z5',
            BillingStreet = '456 Cust St',
            BillingCity = 'Bengaluru',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '654321'
        );
        insert customer;
        
        Schema.Location loc = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'State',
            State__c = 'Karnataka',
            IsInventoryLocation = true
        );
        insert loc;
        
        Contact con = new Contact(
            LastName = 'testing Contact',
            AccountId = customer.Id,
            Phone = '9123456789',
            Email = 'test@test.com',
            Role_Type__c= 'Service',
            Location__c = loc.Id
        );
        insert con;
        
        WorkOrder wo = new WorkOrder(
            AccountId = customer.Id,
            RR_Technician__c = con.Id,
            Service_Center__c = serviceCenter.Id,
            StartDate = System.today(),
            Status = 'Ready for Delivery',
            Is_QR_Generated__c = true
        );
        insert wo;
        
        Test.startTest();
        String result = ClearTaxAPiHelperForService.genereteE_invoicePDF(wo.Id);
        Test.stopTest();
        
        Attachment att = [SELECT Id, Name, ParentId, ContentType FROM Attachment WHERE ParentId = :wo.Id LIMIT 1];
        wo = [SELECT Is_E_invoice_Generated__c FROM WorkOrder WHERE Id = :wo.Id];
    }
    
    
    @isTest
    static void testCheckValidateDataforIRNGeneration() {
        Account serviceCenter = new Account(
            Name = 'Service Center A',
            GSTIN_Number__c = '22AAAAA0000A1Z5',
            BillingStreet = '123 Center St',
            BillingCity = 'Bengaluru',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '123456',
            Center_Code__c = '22',
            Store_Type__c = 'COCO',
            Type = 'Service Center'
        );
        insert serviceCenter;
        
        Account customer = new Account(
            Name = 'Customer A',
            GSTIN_Number__c = '22BBBBB1111B2Z5',
            BillingStreet = '456 Cust St',
            BillingCity = 'Bengaluru',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '654321'
        );
        insert customer;
        
        Schema.Location loc = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'State',
            State__c = 'Karnataka',
            IsInventoryLocation = true
        );
        insert loc;
        
        Contact con = new Contact(
            LastName = 'testing Contact',
            AccountId = customer.Id,
            Phone = '9123456789',
            Email = 'test@test.com',
            Role_Type__c= 'Service',
            Location__c = loc.Id
        );
        insert con;
        
        WorkOrder wo = new WorkOrder(
            AccountId = customer.Id,
            RR_Technician__c = con.Id,
            Service_Center__c = serviceCenter.Id,
            StartDate = System.today(),
            Status = 'Ready for Delivery'
        );
        insert wo;
        
        Test.startTest();
        String result = ClearTaxAPiHelperForService.checkValidateDataforIRNGeneration(wo.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGenerateAndStoreQRCode() {
        Account acc = new Account(
            Name = 'Test Account',
            GSTIN_Number__c = '22AAAAA0000A1Z5',
            BillingStreet = '123 Test St',
            BillingCity = 'Bengaluru',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '123456'
        );
        insert acc;
        
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;
        
        Test.setMock(HttpCalloutMock.class, new QRCodeMock());
        
        Test.startTest();
        ClearTaxTagIrnNumberForService.generateAndStoreQRCode('Sample QR Data', wo.Id);
        Test.stopTest();
    }
    
    
    private class QRCodeMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'image/png');
            res.setBodyAsBlob(Blob.valueOf('Mock QR Code Image Data'));
            return res;
        }
    }
    
    
    
    class CombinedMockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('access-token')) {
                response.setBody('{"access_token": "mocked_access_token"}');
                response.setStatusCode(200);
            } else if (req.getEndpoint().contains('invoice/cancel')) {
                response.setBody('[{"document_status":"IRN_CANCELLED","govt_response":{"Success":"Y","AckNo":1234567890,"AckDt":"2023-12-01T10:00:00"}}]');
                response.setStatusCode(200);
            } else if (req.getEndpoint().contains('invoice')) {
                response.setBody('[{"document_status":"IRN_CREATED","govt_response":{"Success":"Y","Irn":"IRN12345","SignedQRCode":"QRCodeData"}}]');
                response.setStatusCode(200);
            } else {
                response.setBody('{}');
                response.setStatusCode(404);
            }
            
            return response;
        }
    }
    
}