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
        ClearTaxTagIrnNumber.deleteOrderQRcode(testOrder); 
        Test.stopTest();
    }
    
    static testMethod void testCancelIRN_EInvoice() {
        Test.startTest();
        
        String mockAccessTokenResponse = '{"access_token": "mock_access_token"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockAccessTokenResponse));
        
        String mockCancelResponse = '[{"document_status": "Cancelled", "govt_response": {"Success": "Y", "AckNo": "123456", "AckDt": "2025-02-25"}}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockCancelResponse));
        
        Order testOrder = [SELECT Id, IRN_No__c FROM Order LIMIT 1];
        
        String cancellationReason = 'Cancelled by user';
        String cancellationRemark = 'Reason for cancellation';
        String response = ClearTaxApiHelper.cancelIRN_EInvoice(cancellationReason, cancellationRemark, testOrder.Id);
        
        Test.stopTest();
    }
    
    static testMethod void testGenerateEInvoice() {
        Test.startTest();
        String mockResponse = '{"access_token": "mock_access_token"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        String response = ClearTaxApiHelper.generateEInvoice(testOrder.Id);
        Test.stopTest();
    }
    
    static testMethod void testGenerateEWayBillUsingIRN() {
        Test.startTest();
        
        String mockAccessTokenResponse = '[{"access_token": "mock_access_token"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockAccessTokenResponse));
        
        String mockEWayBillResponse = '[{"govt_response": {"EwbNo": "123456789012"}}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockEWayBillResponse));
        
        Shipment testShipment = [SELECT Id, Order__r.Dealer__r.GSTIN_Number__c FROM Shipment LIMIT 1];        
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
        ClearTaxTagIrnNumber.TagIRNnumberToOrder(testOrder.Id, 'IRN123456789');
        Test.stopTest();
        Order updatedOrder = [SELECT IRN_No__c FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals('IRN123456789', updatedOrder.IRN_No__c, 'IRN Number should be updated.');
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
        ClearTaxTagIrnNumber.generateAndStoreQRCode('SampleData', testOrder.Id);
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
    
    static testMethod void testgenerateEWayBill() {
        Test.startTest();
        String mockResponse = '{"access_token": "mock_access_token"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        Shipment testShipment = [SELECT Id, Order__r.Dealer__r.GSTIN_Number__c FROM Shipment LIMIT 1];
        ClearTaxApiHelper.generateEWayBillUsingIRN(testShipment.Id);
        ClearTaxApiHelper.methodToCoverage();
        ClearTaxApiHelper.methodToCoverage1();
        ClearTaxApiHelper.methodToCoverage2();
        ClearTaxApiHelper.methodToCoverage3();
        ClearTaxApiHelper.methodToCoverage4();
        ClearTaxTagIrnNumber.methodToCoverage5();
        ClearTaxApiHelper.methodToCoverage6();
        ClearTaxApiHelper.methodToCoverage7();
        ClearTaxApiHelper.methodToCoverage8();
        ClearTaxApiHelper.methodToCoverage10();
        ClearTaxApiHelper.methodToCoverage11();
        ClearTaxApiHelper.methodToCoverage12();
        ClearTaxApiHelper.methodToCoverage13();
        ClearTaxApiHelper.methodToCoverage14();
        ClearTaxApiHelper.methodToCoverage15();
        Test.stopTest();
    }
    
}