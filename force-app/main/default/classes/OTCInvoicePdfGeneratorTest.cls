/**
 * @description       : 
 * @author            : Ram Kumar
 * @group             : 
 * @last modified on  : 07-16-2025
 * @last modified by  : Ram Kumar
**/
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

        Pricebook2 bangalorePB = new Pricebook2(
            Name = 'Bangalore Price Book',
            IsActive = true
        );
        insert bangalorePB;

        Product2 prodAccessory = new Product2(
            Name = 'Test Accessory',
            ProductCode = '12345',
            HSN_Code__c = '12345',
            Type__c = 'Accessories',
            IsActive = true
        );
        insert prodAccessory;

        Product2 prodMerchandise = new Product2(
            Name = 'Test Merchandise',
            ProductCode = '54321',
            HSN_Code__c = '54321',
            Type__c = 'Merchandise',
            IsActive = true
        );
        insert prodMerchandise;

        Id stdPBId = Test.getStandardPricebookId();

        PricebookEntry pbeAccessoryStd = new PricebookEntry(
            Product2Id = prodAccessory.Id,
            Pricebook2Id = stdPBId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbeAccessoryStd;

        PricebookEntry pbeAccessoryCustom = new PricebookEntry(
            Product2Id = prodAccessory.Id,
            Pricebook2Id = bangalorePB.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbeAccessoryCustom;

        PricebookEntry pbeMerchandiseStd = new PricebookEntry(
            Product2Id = prodMerchandise.Id,
            Pricebook2Id = stdPBId,
            UnitPrice = 200,
            IsActive = true
        );
        insert pbeMerchandiseStd;

        PricebookEntry pbeMerchandiseCustom = new PricebookEntry(
            Product2Id = prodMerchandise.Id,
            Pricebook2Id = bangalorePB.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert pbeMerchandiseCustom;

        // Test Accessories Order
        Order orderAccessory = new Order(
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
        insert orderAccessory;

        OrderItem oiAccessory = new OrderItem(
            OrderId = orderAccessory.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbeAccessoryCustom.Id,
            Type__c = 'Accessories'
        );
        insert oiAccessory;

        Order_Invoice__c invoiceAccessory = new Order_Invoice__c(
            Order__c = orderAccessory.Id,
            Invoice_Type__c = 'Accessories Invoice',
            Invoice_Number__c = 'INV-ACC-001'
        );
        insert invoiceAccessory;

        // Test Merchandise Order
        Order orderMerch = new Order(
            AccountId = dealer.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Website_Order_Id__c = 'ORDER002',
            Dealer__c = dealer.Id,
            Internal_Purchase__c = false,
            Transportation_Charges__c = 150,
            BillingCountry = 'India',
            BillingState = 'Karnataka',
            IRN_No__c = 'IRN987654321',
            RecordTypeId = otcRecordType.Id,
            Pricebook2Id = bangalorePB.Id
        );
        insert orderMerch;

        OrderItem oiMerch = new OrderItem(
            OrderId = orderMerch.Id,
            Quantity = 2,
            UnitPrice = 200,
            PricebookEntryId = pbeMerchandiseCustom.Id,
            Type__c = 'Merchandise'
        );
        insert oiMerch;

        Order_Invoice__c invoiceMerch = new Order_Invoice__c(
            Order__c = orderMerch.Id,
            Invoice_Type__c = 'Merchandise Invoice',
            Invoice_Number__c = 'INV-MERCH-001'
        );
        insert invoiceMerch;

        // Update Orders to 'Invoice Generation' status and call handler for Accessories
        Order oldOrderAccessory = orderAccessory.clone(false);
        orderAccessory.Status = 'Invoice Generation';
        update orderAccessory;

        // Update Orders to 'Invoice Generation' status and call handler for Merchandise
        Order oldOrderMerch = orderMerch.clone(false);
        orderMerch.Status = 'Invoice Generation';
        update orderMerch;

        Map<Id, Order> oldMap = new Map<Id, Order>{
            oldOrderAccessory.Id => oldOrderAccessory,
            oldOrderMerch.Id => oldOrderMerch
        };
        
        List<Order> newList = [
            SELECT Id, Status, RecordTypeId, Dealer__c FROM Order
            WHERE Id IN :new Set<Id>{orderAccessory.Id, orderMerch.Id}
        ];

        Test.startTest();
        OTCInvoicePdfGenerator.handleOrderUpdate(newList, oldMap);
        Test.stopTest();
    }
}