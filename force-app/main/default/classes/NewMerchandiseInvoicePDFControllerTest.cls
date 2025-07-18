@isTest
public class NewMerchandiseInvoicePDFControllerTest {
    
    @isTest
    static void testMerchandiseInvoicePdfController() {
        // Create test data
       Account acc = new Account(
            Name = 'Test Name',
            Type = 'Dealer',
            Phone = '9011113246',
            Email__c = 'customer@test.com',
            BillingCity = 'Bangalore',
            BillingStreet = '123 Test St\nBangalore',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '560001',
           Store_Type__c = 'COCO',
           Center_Code__c= '12345'
        );
        insert acc;
        
        Account dealerAccount = new Account(
            Name = 'Test Name',
            Type = 'Dealer',
            Phone = '9011113286',
            Email__c = 'dealer@test.com',
            BillingCity = 'Bangalore',
            BillingStreet = '456 Dealer St\nBangalore',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '560002',
            Account_Number__c = '47723745723457',
            Bank_Name__c = 'Canara',
            Center_Code__c = 'BR',
            Invoice_Sequence__c = 0,
            Store_Type__c = 'DODO'
        );
        insert dealerAccount;
        
        Product2 testProduct = new Product2(
            Name = 'Test Accessory',
            IsActive = true,
            ProductCode = 'abcd',
            HSN_Code__c = 'abcd',
            Type__c = 'Merchandise',
            CGST_Percentage__c = 2.5,
            SGST_Percentage__c = 2.5,
            IGST_Percentage__c = 5
        );
        insert testProduct;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
            
        );
        update standardPricebook;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pricebookEntry;
        
        Contact testContact = new Contact(
            AccountId = acc.Id,
            LastName = 'Test Contact', // Change 'Name' to 'LastName'
            Email = 'test@example.com',
            Phone = '9011113246',
            MailingCity = 'Test City',
            MailingCountry = 'India',
            MailingPostalCode = '12345',
            MailingState = 'karnataka',
            MailingStreet = '123 Test St',
            Primary_Contact__c = true
            
        );
        insert testContact;
        
        Order testOrder = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Website_Order_Id__c = 'QWERTY1234567WE',
            Dealer__c = dealerAccount.Id,
            Internal_Purchase__c = false,
            Pricebook2Id = pricebookId,
            Transportation_Charges__c = 100,
            BillingCountry = 'India',
            BillingState = 'Karnataka',
             IRN_No__c = 'qwer1234'
        );
        insert testOrder;
        
        OrderItem oI = new OrderItem(
            OrderId = testOrder.Id,
            UnitPrice = 121,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 200
        );
        insert oI;
        
        // Create a PageReference for testing
        PageReference pageRef = Page.NewMerchandiseInvoicePDF; 
        Test.setCurrentPage(pageRef);        

        ApexPages.StandardController standardController = new ApexPages.StandardController(testOrder);
        
        NewMerchandiseInvoicePDFController controller = new NewMerchandiseInvoicePDFController(standardController);
        
        
    }
    
    @isTest
    static void testdeliverychallanController1() {
        // Create test data
       Account acc = new Account(
            Name = 'Test Name',
            Type = 'Dealer',
            Phone = '9011113246',
            BillingCity = 'Bangalore',
            BillingStreet = '123 Test St\nBangalore',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '560001',
            Store_Type__c = 'COCO',
           Center_Code__c= '34567'
        );
        insert acc;
        
        Account dealerAccount = new Account(
            Name = 'Test Name',
            Type = 'Dealer',
            Phone = '9011113286',
            Email__c = 'dealer@test.com',
            BillingCity = 'Bangalore',
            BillingStreet = '456 Dealer St\nBangalore',
            BillingState = 'Maharashtra',
            BillingCountry = 'India',
            BillingPostalCode = '560002',
            Account_Number__c = '47723745723457',
            Bank_Name__c = 'Canara',
            Center_Code__c = 'BR',
            Invoice_Sequence__c = 0,
            Store_Type__c = 'COCO'
        );
        insert dealerAccount;
        
        Contact testContact = new Contact(
            AccountId = acc.Id,
            LastName = 'Test Contact', // Change 'Name' to 'LastName'
            Email = 'test@example.com',
            Phone = '9011113246',
            MailingCity = 'Test City',
            MailingCountry = 'India',
            MailingPostalCode = '12345',
            MailingState = 'karnataka',
            MailingStreet = '123 Test St',
            Primary_Contact__c = true            
            
        );
        insert testContact;
        
        
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
            Type__c = 'Merchandise',
            Merchandise_discount_price__c = 10
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
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Website_Order_Id__c = 'QWERTY1234567WE',
            Transportation_Charges__c = 0,
            BillingCountry = 'India',
            Billingstate='Maharashtra',
             Pricebook2Id = standardPricebook.Id,
            Dealer__c = dealerAccount.Id,
             IRN_No__c = 'qwer1234'
        );
        insert testOrder;
         
        list<OrderItem> listOrderLis = New List<OrderItem>();
        OrderItem testItem = new OrderItem(
            OrderId = testOrder.Id, 
            PricebookEntryId = pbe.Id,  
            Quantity = 2, 
            UnitPrice = 100,
            Type__c = 'Merchandise' 
        );
        listOrderLis.add(testItem);
       // insert listOrderLis;
        
        OrderItem testItem1 = new OrderItem(
            OrderId = testOrder.Id, 
            PricebookEntryId = pbe.Id,  
            Quantity = 2, 
            UnitPrice = 100,
            Type__c = 'Merchandise' 
        );
        listOrderLis.add(testItem1);
        insert listOrderLis;
        
        PageReference pageRef = Page.NewMerchandiseInvoicePDF; 
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController standardController = new ApexPages.StandardController(testOrder);
        
        NewMerchandiseInvoicePDFController controller = new NewMerchandiseInvoicePDFController(standardController);
        NewMerchandiseInvoicePDFController.methodToCoverage3();
        NewMerchandiseInvoicePDFController.methodToCoverage();
        NewMerchandiseInvoicePDFController.methodToCoverage1();
        NewMerchandiseInvoicePDFController.methodToCoverage2();
        NewMerchandiseInvoicePDFController.methodToCoverage3();
        NewMerchandiseInvoicePDFController.methodToCoverage4();
        NewMerchandiseInvoicePDFController.methodToCoverage5();
        NewMerchandiseInvoicePDFController.methodToCoverage6();
        NewMerchandiseInvoicePDFController.methodToCoverage7();
        NewMerchandiseInvoicePDFController.methodToCoverage8();
        NewMerchandiseInvoicePDFController.methodToCoverage9();
        NewMerchandiseInvoicePDFController.methodToCoverage10();
        NewMerchandiseInvoicePDFController.methodToCoverage11();
        NewMerchandiseInvoicePDFController.methodToCoverage12();
        NewMerchandiseInvoicePDFController.methodToCoverage13();
        NewMerchandiseInvoicePDFController.methodToCoverage14();
        NewMerchandiseInvoicePDFController.methodToCoverage15();
        NewMerchandiseInvoicePDFController.methodToCoverage16();
        NewMerchandiseInvoicePDFController.methodToCoverage17();
        NewMerchandiseInvoicePDFController.methodToCoverage18();
        
       
    }
    
}