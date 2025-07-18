@isTest
public class NewMerchandiseE_InvoicePDFControllerTest {
@isTest
    static void testAccessoriesInvoiceController_DODO() {
        Account seller = new Account(
            Name = 'Test Seller11', 
            GSTIN_Number__c = '29TESTGSTINT', 
            Type = 'Dealer', 
            BillingPostalCode = '431809', 
            Email__c = 'agv@gmail.com', 
            Phone = '7866545678', 
            Center_Code__c = '564757',
            Store_Type__c='COCO',
            BillingState  ='karnataka'
        );
        insert seller;

        Account customer = new Account(
            Name = 'Customer Account',
            BillingCity = 'Mysore',
            BillingState = 'Karnataka',
            BillingPostalCode = '570001',
            Phone = '8888888888',
            Email__c = 'customer@test.com',
            GSTIN_Number__c = '29CUSTOMER1234F2Z5'
        );
        insert customer;

        Contact primaryContact = new Contact(
            LastName = 'Primary Contact',
            Email = 'contact@test.com',
            Phone = '9876543210',
            MailingState = 'Karnataka',
            AccountId = customer.Id,
            Primary_Contact__c = true
        );
        insert primaryContact;

        Id standardPBId = Test.getStandardPricebookId();

        Product2 prod = new Product2(
            Name = 'Accessory Item',
            IsActive = true,
            HSN_Code__c = 'ABC123',
            CGST_Percentage__c = 5,
            SGST_Percentage__c = 5,
            IGST_Percentage__c = 12,
            ProductCode = '23456',
            Type__c= 'Merchandise'
        );
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPBId,
            Product2Id = prod.Id,
            UnitPrice = 500,
            IsActive = true
        );
        insert pbe;

        Order testOrder = new Order(
            AccountId = customer.Id,
            Dealer__c = seller.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = standardPBId,
            IRN_No__c = '1234567890123456789012345678901234567890123456789012345678901234',
            OTC_Additional_Discount_Amount__c = 100
        );
        insert testOrder;

        OrderItem oi = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 500,
            Type__c = 'Accessories',
            Merchandise_Disccount_Amount__c = 50
            // Removed Product_Total_Amount__c (likely formula or read-only field)
        );
        insert oi;

        Order_Invoice__c invoice = new Order_Invoice__c(
            Order__c = testOrder.Id,
            Invoice_Type__c = 'Accessories Invoice',
            Invoice_Number__c = 'INV-ACC-001'
        );
        insert invoice;

        Attachment qrAtt = new Attachment(
            Name = 'QRCode_test.pdf',
            ParentId = testOrder.Id,
            Body = Blob.valueOf('Dummy PDF content')
        );
        insert qrAtt;

        PageReference pageRef = Page.NewAccessoriesInvoiceE_Invoice;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testOrder.Id);
        ApexPages.currentPage().getParameters().put('sequence', 'INV-ACC-001');
        ApexPages.currentPage().getParameters().put('date', '2025-03-21');

        ApexPages.StandardController stdController = new ApexPages.StandardController(testOrder);
        Test.startTest();
        NewMerchandiseE_InvoicePDFController controller = new NewMerchandiseE_InvoicePDFController(stdController);
        NewMerchandiseE_InvoicePDFController.testCoverageData();
        NewMerchandiseE_InvoicePDFController.testCoverageData1();
        NewMerchandiseE_InvoicePDFController.testCoverageData2();
        NewMerchandiseE_InvoicePDFController.testCoverageData3();
        NewMerchandiseE_InvoicePDFController.testCoverageData4();
        NewMerchandiseE_InvoicePDFController.testCoverageData5();
        NewMerchandiseE_InvoicePDFController.testCoverageData6();
        Test.stopTest();
    }
}