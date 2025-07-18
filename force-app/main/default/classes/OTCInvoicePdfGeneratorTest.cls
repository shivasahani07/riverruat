@isTest
public class OTCInvoicePdfGeneratorTest {

    @isTest
    static void testHandleOrderUpdate_WithOTCAccessory() {
        
        Account dealer = new Account(
            Name = 'Test Dealer',
            Type = 'Dealer',
            Phone = '9011113246',
            Email__c = 'dealer@test.com',
            BillingCity = 'Bangalore',
            BillingStreet = '123 Main St',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '560001',
            Center_Code__c = 'C123',
            Store_Type__c = 'COCO'
        );
        insert dealer;

        RecordType otcRecordType = [
            SELECT Id FROM RecordType
            WHERE DeveloperName = 'OTC' AND SObjectType = 'Order'
            LIMIT 1
        ];

        // ✅ Create Bangalore Price Book
        Pricebook2 bangalorePB = new Pricebook2(
            Name = 'Bangalore Price Book',
            IsActive = true
        );
        insert bangalorePB;

        // ✅ Insert Product
        Product2 prod = new Product2(
            Name = 'Test Accessory',
            ProductCode = '12345',
            HSN_Code__c = '12345',
            Type__c = 'Accessories',
            IsActive = true
        );
        insert prod;

        // ✅ Get Standard Pricebook ID and create Standard PricebookEntry
        Id stdPBId = Test.getStandardPricebookId();
        PricebookEntry stdPbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPBId,
            UnitPrice = 100,
            IsActive = true
        );
        insert stdPbe;

        // ✅ Now insert custom PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = bangalorePB.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // ✅ Use Bangalore Price Book in Order
        Order order = new Order(
            AccountId = dealer.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Website_Order_Id__c = 'ORDER001',
            Dealer__c = dealer.Id,
            Internal_Purchase__c = false,
            Transportation_Charges__c = 100,
            BillingCountry = 'India',
            BillingState = 'Karnataka',
            IRN_No__c = 'IRN123456789',
            RecordTypeId = otcRecordType.Id,
            Pricebook2Id = bangalorePB.Id
        );
        insert order;

        OrderItem oi = new OrderItem(
            OrderId = order.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id,
            Type__c = 'Accessories'
        );
        insert oi;

        Order_Invoice__c invoice = new Order_Invoice__c(
            Order__c = order.Id,
            Invoice_Type__c = 'Accessories Invoice',
            Invoice_Number__c = 'INV-ACC-001'
        );
        insert invoice;

        Order oldOrder = order.clone(false);
        order.Status = 'Invoice Generation';
        update order;

        Map<Id, Order> oldMap = new Map<Id, Order>{ oldOrder.Id => oldOrder };
        List<Order> newList = [SELECT Id, Status, RecordTypeId FROM Order WHERE Id = :order.Id];

        Test.startTest();
        OTCInvoicePdfGenerator.handleOrderUpdate(newList, oldMap);
        Test.stopTest();
    }
}