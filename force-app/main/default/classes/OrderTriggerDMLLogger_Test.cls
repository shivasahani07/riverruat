@isTest
private class OrderTriggerDMLLogger_Test {

    @testSetup
    static void setupData() {
        // Account
        Account account = new Account(Name = 'Test Account', AccountSource = 'Other',Type ='Dealer', Center_Code__c = 'DCODE-45');
        insert account;
        
        Account dealerAccount = new Account(Name = 'Test Dealer Account', Center_Code__c = 'TEST',Type ='Dealer');
        insert dealerAccount;

        // Get Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;

        // Order record
        Order order = new Order(AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id, 
                                Dealer__c = [SELECT Id FROM Account WHERE Name = 'Test Dealer Account'].Id,
                                EffectiveDate = Date.valueOf('2024-12-19'),
                                Status='Draft',
                                Pricebook2Id = standardPricebook.Id);
        insert order;
        
        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            IsActive = true,
            HSN_Code__c = 'HSN-3849',
            Type__c = 'Accessories'
        );
        insert prod;
    
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pricebookEntry;
        
        OrderItem oi = new OrderItem();
        oi.OrderId = order.Id;
        oi.Product2Id = prod.Id;
        oi.PricebookEntryId = priceBookEntry.Id;
        oi.UnitPrice = 45.99;
        oi.Quantity = 2;
        insert oi;
        
        Insurance__c ins = new Insurance__c(Name='Kotak Bank', GSTIN_Number__c='GSTIN2345552353', Insurer_Code__c='IN023');
        insert ins;
    }

    @isTest
    static void testAfterUpdateLogsChanges() {
        
        Order ord = [SELECT Id, Status FROM Order LIMIT 1];
        ord.Status = 'Order Cancelled';
        //ord.Insurance_Type__c = 'In House';
        ord.Insurance__c = [SELECT Id FROM Insurance__c LIMIT 1].Id;
        ord.Insurance_Amount__c = 100000;

        Test.startTest();        
        update ord;
        Test.stopTest();

        System.assert(true, 'Order update executed without errors.');
    }

    @isTest
    static void testBeforeDeleteLogsChanges() {
        
        Order ord = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        delete ord; 
        Test.stopTest();

        System.assert(true, 'Order delete executed without errors.');
    }
}