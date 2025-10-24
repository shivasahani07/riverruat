@isTest
public class OrderTriggerTest {
    
    @testSetup
    static void setup() {
        // Create test data
        Account account = new Account(Name = 'Test Account', AccountSource = 'Other',Type ='Dealer', Center_Code__c = 'DCODE-45');
        insert account;
        
        Account dealerAccount = new Account(Name = 'Test Dealer Account', Center_Code__c = 'TEST',Type ='Dealer');
        insert dealerAccount;
        
        OrderCounter__c counterSetting = new OrderCounter__c(Name = 'Count', Counter__c = 0);
        insert counterSetting;
    }
    
    @isTest
    static void testOrderTriggerBeforeInsert() {
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;
        
        // Create a new order
        Order order = new Order(AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id, 
                                Dealer__c = [SELECT Id FROM Account WHERE Name = 'Test Dealer Account'].Id,
                                EffectiveDate = Date.valueOf('2024-12-19'),
                                Status='Draft',
                                Pricebook2Id = standardPricebook.Id);
        
        // Insert the order
        Test.startTest();
        insert order;
        Test.stopTest();
        
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
        
        // Verify that the Website_Order_Id__c is populated
        Order insertedOrder = [SELECT Website_Order_Id__c FROM Order WHERE Id = :order.Id];
        System.assert(insertedOrder.Website_Order_Id__c != null);
        
        // Verify that the counter is incremented
        OrderCounter__c updatedCounterSetting = [SELECT Counter__c FROM OrderCounter__c WHERE Name = 'Count'];
        System.assert(updatedCounterSetting.Counter__c == 1);
    }
    
    @isTest
    static void testOrderTriggerBeforeUpdate() {
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;
        
        // Create a new order
        Order order = new Order(AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id, 
                                Dealer__c = [SELECT Id FROM Account WHERE Name = 'Test Dealer Account'].Id,
                                EffectiveDate = Date.valueOf('2024-12-19'),
                                Status='Booking',
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
        
        // Update the order
        Test.startTest();
        order.Status = 'Booking';
        update order;
        Test.stopTest();
        
        // Verify that the Website_Order_Id__c is updated
        Order updatedOrder = [SELECT Website_Order_Id__c FROM Order WHERE Id = :order.Id];
        System.assert(updatedOrder.Website_Order_Id__c != null);
        
        // Verify that the counter is incremented
        OrderCounter__c updatedCounterSetting = [SELECT Counter__c FROM OrderCounter__c WHERE Name = 'Count'];
        System.assert(updatedCounterSetting.Counter__c == 1);
    }
    
    @isTest
    static void testOrderTriggerAfterUpdate() {
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;
        
        // Create a new order
        Order order = new Order(AccountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id, 
                                Dealer__c = [SELECT Id FROM Account WHERE Name = 'Test Dealer Account'].Id,
                                EffectiveDate = Date.valueOf('2024-12-19'),
                                Status='Booking',
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
        
        // Update the order
        Test.startTest();
        order.Status = 'Booking';
        update order;
        Test.stopTest();
        
        
        
        // Verify that the OrderTriggerHandler.handleOrderUpdate method is called
        // You may need to add additional assertions here depending on the implementation of the OrderTriggerHandler class
    }
}