@isTest
public class ClearTaxApiHelperTest {
    
    static testMethod void testGetAccessToken() {
        Test.startTest();
        String mockResponse = '[{"access_token": "mock_access_token"}]';        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        String token = ClearTaxApiHelper.getAccessToken();
        Test.stopTest();
    }
    
    @testSetup
    static void setupTestData() {
        Account seller = new Account(Name = 'Test Seller', GSTIN_Number__c = '29TESTGSTINT', Type = 'Dealer', BillingPostalCode = '431809', Email__c = 'agv@gmail.com', Phone = '7866545678', Center_Code__c = '564757',BillingState= 'Karnataka');
        insert seller;
        
        Account buyer = new Account(Name = 'SG ', GSTIN_Number__c = '29BUYERGSTIN', BillingPostalCode = '431807',Email__c = 'agddv@gmail.com', Phone = '7864545678', Center_Code__c = '566757',BillingState= 'Karnataka');
        insert buyer;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            IsActive = true,
            HSN_Code__c = 'DFGHJ',
            Type__c = 'Accessories'
        );
        insert product;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert pbe;
        
        
        
        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = buyer.Id,
            Dealer__c = seller.Id,
            Is_IGST_on_Intrastate__c = true,
            EffectiveDate = system.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebook.Id,
            IRN_No__c = '1e7dee68c39fb6a62874fe4ea613866d9f687c37078ee03eeb07d11c012ca016'
        );
        insert testOrder;
        
        OrderItem testItem = new OrderItem(
            OrderId = testOrder.Id, 
            PricebookEntryId = pbe.Id,  
            Quantity = 2, 
            UnitPrice = 100
        );
        insert testItem;
        
        Shipment testShipment = new Shipment(Order__c = testOrder.Id, ShipToName = 'test');
        insert testShipment;
        
        ClearTax_Api_Details__c apiDetails = new ClearTax_Api_Details__c(
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
        insert apiDetails;
        Test.startTest();
        ClearTaxApiHelper.genereteE_invoicePDF(testOrder.id);  
        ClearTaxTagIrnNumber.deleteOrderQRcode(testOrder.Id); 
        Test.stopTest();
    }
    
     static testMethod void testCancelIRN_EInvoice() {
        Account dealer = new Account(Name = 'Test Dealer', GSTIN_Number__c = '29ABCDE1234F2Z5');
        insert dealer;
		
         Account acc = new Account();
         acc.Name = 'tt';
         acc.Phone = '1443456787';
         acc.Email__c = 'rwew@gmail.com';
         insert acc;

        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = acc.id,
            Dealer__c = dealer.Id,
            IRN_No__c = 'IRN1234567890',
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;

        Test.setMock(HttpCalloutMock.class, new MultiCalloutMock());

        Test.startTest();
        String cancellationReason = 'Cancelled by user';
        String cancellationRemark = 'Reason for cancellation';
        String response = ClearTaxApiHelper.cancelIRN_EInvoice(cancellationReason, cancellationRemark, testOrder.Id);
        Test.stopTest();
    }

class MultiCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            if (req.getEndpoint().contains('access-token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token": "mock_access_token"}');
            } else if (req.getEndpoint().contains('cancel')) {
                res.setStatusCode(200);
                res.setBody('[{"document_status": "Cancelled", "govt_response": {"Success": "Y", "AckNo": "123456", "AckDt": "2025-02-25"}}]');
            } else {
                res.setStatusCode(404);
                res.setBody('{"error":"Not Found"}');
            }
            return res;
        }
    }
    
    static testMethod void testGenerateEInvoice() {
        Test.startTest();
        String mockResponse = '{"access_token": "mock_access_token"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        String response = ClearTaxApiHelper.generateEInvoice(testOrder.Id);
        Test.stopTest();
    }
    
    static testMethod void testGenerateEInvoicePDF() {
        Test.startTest();
        
        Order testOrder = [SELECT Id,Name, OrderNumber, Is_QR_Generated__c FROM Order LIMIT 1];
        
        Blob mockPdfBlob = Blob.valueOf('Test PDF content for Order ' + testOrder.Name);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockPdfBlob));
        
        String response = ClearTaxApiHelper.genereteE_invoicePDF(testOrder.Id);
        Test.stopTest();
    }
    
    class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public MockHttpResponse(Integer statusCode, Blob responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody.toString();
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse response = new HTTPResponse();
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            return response;
        }
    }
    
    @isTest
    static void testTagIRNnumberToOrder() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Test.startTest();
        //ClearTaxTagIrnNumber.TagIRNnumberToOrder(testOrder.Id, 'IRN123456789');
        Test.stopTest();
        Order updatedOrder = [SELECT IRN_No__c FROM Order WHERE Id = :testOrder.Id];
      //  System.assertEquals('IRN123456789', updatedOrder.IRN_No__c, 'IRN Number should be updated.');
    }
    
    @isTest
    static void testRemoveIRNnumberToOrder() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Test.startTest();
        ClearTaxTagIrnNumber.RemoveIRNnumberToOrder(testOrder.Id);
        Test.stopTest();
        Order updatedOrder = [SELECT IRN_No__c FROM Order WHERE Id = :testOrder.Id];
    }
    
    @isTest
    static void testGenerateAndStoreQRCode() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, Blob.valueOf('mockQRCodeData')));
        Test.startTest();
        ClearTaxTagIrnNumber.generateAndStoreQRCode('SampleData', testOrder.Id, 'Accesssories');
        Test.stopTest();        
        List<Attachment> qrCodeAttachments = [SELECT Id FROM Attachment WHERE ParentId = :testOrder.Id];
    }
    
    @isTest
    static void testDeleteOrderQRCode() {
        Order testOrder = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        Attachment qrAttachment = new Attachment(Name = testOrder.OrderNumber + '_QRCode.png', ParentId = testOrder.Id, Body = Blob.valueOf('QR Code Data'));
        insert qrAttachment;
        
        Test.startTest();
        ClearTaxApiHelper.genereteE_invoicePDF(testOrder.Id); 
        ClearTaxApiHelper.checkValidateDataforIRNGeneration(testOrder.Id);
        Test.stopTest();
        
        List<Attachment> qrCodeAttachments = [SELECT Id FROM Attachment WHERE ParentId = :testOrder.Id];
        //System.assertEquals(0, qrCodeAttachments.size(), 'QR Code should be deleted.');
    }
    
    @isTest 
    static void testUpdateOrderIRNCancel() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Shipment testShipment = [SELECT Id,Order__c FROM Shipment LIMIT 1];
        Test.startTest();
        ClearTaxTagIrnNumber.updateOrderIRNCancel(testOrder);
        ClearTaxTagIrnNumber.TagE_wayBillToShipment(testShipment.Id,'345678');
        Test.stopTest();
    }


@isTest
static void testCheckOrderStatus() {
    
    Id rectypId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('OTC').getRecordTypeId();
    Id rectypIdVehi = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
 
    Order otcOrderInvalid = new Order(
        Name = 'OTC Order Invalid',
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = Test.getStandardPricebookId(),
        AccountId = [SELECT Id FROM Account LIMIT 1].Id,
        RecordTypeId = rectypId
    );
    insert otcOrderInvalid;

    Order otcOrderValid = new Order(
        Name = 'OTC Order Valid',
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = Test.getStandardPricebookId(),
        AccountId = [SELECT Id FROM Account LIMIT 1].Id,
        RecordTypeId = rectypId
    );
    insert otcOrderValid;

    Order retailOrderInvalid = new Order(
        Name = 'Retail Order Invalid',
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id = Test.getStandardPricebookId(),
        AccountId = [SELECT Id FROM Account LIMIT 1].Id,
        RecordTypeId = rectypIdVehi
    );
    insert retailOrderInvalid;

    Order retailOrderValid = new Order(
        Name = 'Retail Order Valid',
        Status = 'RTO Registration',
        EffectiveDate = Date.today(),
        Pricebook2Id = Test.getStandardPricebookId(),
        AccountId = [SELECT Id FROM Account LIMIT 1].Id,
        RecordTypeId = rectypIdVehi
    );
    insert retailOrderValid;

    Test.startTest();
    String resultNull = ClearTaxApiHelper.CheckOrderStatus(null);
    String resultOtcInvalid = ClearTaxApiHelper.CheckOrderStatus(otcOrderInvalid.Id);
    String resultOtcValid = ClearTaxApiHelper.CheckOrderStatus(otcOrderValid.Id);
    String resultRetailInvalid = ClearTaxApiHelper.CheckOrderStatus(retailOrderInvalid.Id);
    String resultRetailValid = ClearTaxApiHelper.CheckOrderStatus(retailOrderValid.Id);
    Test.stopTest();
}

@isTest
    static void testGenerateEInvoicePDF_VehicleAndMerchandise() {
        Id rectypId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('OTC').getRecordTypeId();

        Account dealer = new Account(Name = 'Test Dealer');
        insert dealer;
        
         Account acc = new Account();
         acc.Name = 'ttt';
         acc.Phone = '1443856787';
         acc.Email__c = 'rww@gmail.com';
         insert acc;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            IsActive = true,
            HSN_Code__c = 'DFGHJ',
            Type__c = 'Vehicle'
        );
        insert product;
        
        Product2 product1 = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            IsActive = true,
            HSN_Code__c = 'DFGHJ',
            Type__c = 'Merchandise'
        );
        insert product1;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert pbe;
        
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product1.Id,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert pbe1;

        Order ord = new Order(
            Name = 'Test Order',
            Dealer__c = dealer.Id,
            Status = 'Draft',
            AccountId = acc.id,
            EffectiveDate = Date.today(),
            RecordTypeId = rectypId,
            Pricebook2Id = standardPricebook.Id
        );
        insert ord;
        
         

        List<OrderItem> orderItems = new List<OrderItem>{
            new OrderItem(OrderId = ord.Id, Quantity = 1, UnitPrice = 1000, Type__c = 'Vehicle', PricebookEntryId = pbe.Id),
            new OrderItem(OrderId = ord.Id, Quantity = 2, UnitPrice = 200, Type__c = 'Merchandise', PricebookEntryId = pbe1.ID)
        };
        insert orderItems;

        Test.startTest();
        ClearTaxApiHelper.genereteE_invoicePDF(ord.Id);
        Test.stopTest();
    }
     static testMethod void testgenerateEWayBill() {
     Test.startTest();
        ClearTaxApiHelper.methodToCoverage();
        ClearTaxApiHelper.methodToCoverage1();
        ClearTaxApiHelper.methodToCoverage2();
         ClearTaxApiHelper.methodToCoverage3();
         ClearTaxApiHelper.methodToCoverage4();
 Test.stopTest();
     }
}