@isTest
public class NewCreateReceiptOChargesControllerTest {
    
    @isTest
    static void testController() {

        Account testAccount = new Account(
            Name = 'Test Customer ' + System.currentTimeMillis(),
            Type = 'Customer',
            Phone = '9011113246',
            Email__c = 'customer' + System.currentTimeMillis() + '@gmail.com',
            BillingCountry = 'India',
            BillingState = 'Karnataka'
        );
        insert testAccount;

        Account dodoDealer = new Account(
            Name = 'Test Dealer DODO ' + System.currentTimeMillis(),
            Type = 'Dealer',
            Phone = '9011113286',
            Email__c = 'dodo.dealer' + System.currentTimeMillis() + '@test.com',
            BillingCountry = 'India',
            BillingState = 'Karnataka',
            Account_Number__c = String.valueOf(System.currentTimeMillis()),
            Bank_Name__c = 'Canara',
            Center_Code__c = 'BR',
            Invoice_Sequence__c = 0,
            Store_Type__c ='DODO'
        );
        insert dodoDealer;

        Account cocoDealer = new Account(
            Name = 'Test Dealer COCO ' + System.currentTimeMillis(),
            Type = 'Dealer',
            Phone = '9011113290',
            Email__c = 'coco.dealer' + System.currentTimeMillis() + '@test.com',
            BillingCountry = 'India',
            BillingState = 'Karnataka',
            Account_Number__c = String.valueOf(System.currentTimeMillis()),
            Bank_Name__c = 'HDFC',
            Center_Code__c = 'CR',
            Invoice_Sequence__c = 1,
            Store_Type__c ='COCO'
        );
        insert cocoDealer;

        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe' + System.currentTimeMillis() + '@test.com',
            Phone = '9011113246',
            MailingCity = 'Karnataka',
            MailingCountry = 'India',
            MailingPostalCode = '12345',
            MailingState = 'Karnataka',
            MailingStreet = '123 Test Street',
            AccountId = testAccount.Id,
            Primary_Contact__c = true
        );
        insert testContact;

        Order dodoOrder = new Order(
            AccountId = testAccount.Id,
            BillingCity = 'Billing City',
            BillingCountry = 'India',
            BillingPostalCode = '54321',
            BillingState = 'Karnataka',
            BillingStreet = '456 Billing Street',
            ShippingCity = 'Shipping City',
            ShippingCountry = 'India',
            ShippingPostalCode = '67890',
            ShippingState = 'Karnataka',
            ShippingStreet = '789 Shipping Street',
            Insurance_Amount__c = 100.00,
            RTO_Charges__c = 20.00,
            Transportation_Charges__c = 100,
            Handling_Charges__c = 10.00,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Extended_Warranty__c = true,
            Dealer__c = dodoDealer.Id
        );
        insert dodoOrder;

        Order cocoOrder = new Order(
            AccountId = testAccount.Id,
            BillingCity = 'Billing City',
            BillingCountry = 'India',
            BillingPostalCode = '54321',
            BillingState = 'Karnataka',
            BillingStreet = '456 Billing Street',
            ShippingCity = 'Shipping City',
            ShippingCountry = 'India',
            ShippingPostalCode = '67890',
            ShippingState = 'Karnataka',
            ShippingStreet = '789 Shipping Street',
            Insurance_Amount__c = 100.00,
            RTO_Charges__c = 20.00,
            Transportation_Charges__c = 100,
            Handling_Charges__c = 10.00,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Extended_Warranty__c = true,
            Dealer__c = cocoDealer.Id
        );
        insert cocoOrder;

        Test.startTest();
        ApexPages.StandardController dodoController = new ApexPages.StandardController(dodoOrder);
        NewCreateReceiptOChargesController dodoReceiptController = new NewCreateReceiptOChargesController(dodoController);

        ApexPages.StandardController cocoController = new ApexPages.StandardController(cocoOrder);
        NewCreateReceiptOChargesController cocoReceiptController = new NewCreateReceiptOChargesController(cocoController);
        Test.stopTest();
    }
}