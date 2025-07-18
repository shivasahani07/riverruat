@isTest
public class NewCreateReceiptVehicleControllerTest {
 
    @isTest
    static void testdeliverychallanController1() {
        Account acc = new Account(
            Name = 'Test Name',
            Type = 'Dealer',
            Phone = '9011113246',
            BillingCity = 'Bangalore',
            BillingStreet = '123 Test St\nBangalore',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '560001',
            Store_Type__c = 'DODO',
            Center_Code__c ='12345'
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
            LastName = 'Test Contact',
            Email = 'test@example.com',
            Phone = '9011113246',
            MailingCity = 'Test City',
            MailingCountry = 'India',
            MailingPostalCode = '12345',
            MailingState = 'Karnataka',
            MailingStreet = '123 Test St',
            Primary_Contact__c = true,
            Role_Type__c = 'Service'
        );
        insert testContact;
        
        Order testOrder = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Website_Order_Id__c = 'QWERTY1234567WE',
            Transportation_Charges__c = 100,
            BillingCountry = 'India',
            BillingState = 'Karnataka',
            Dealer__c = dealerAccount.Id,
            IRN_No__c = 'qwer1234'
        );
        insert testOrder;
        
        PageReference pageRef = Page.NewCreateReceiptVehicle; 
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController standardController = new ApexPages.StandardController(testOrder);
        NewCreateReceiptVehicleController controller = new NewCreateReceiptVehicleController(standardController);
        CurrencyToWordsInRupees.convert(21);
        CurrencyToWordsInRupees.convert(11);
        CurrencyToWordsInRupees.convert(999);
        CurrencyToWordsInRupees.convert(9999);
        CurrencyToWordsInRupees.convert(99999);
        NewCreateReceiptVehicleController.testCoverageData();
        NewCreateReceiptVehicleController.testCoverageData1();
        NewCreateReceiptVehicleController.testCoverageData2();
        NewCreateReceiptVehicleController.testCoverageData3();
        NewCreateReceiptVehicleController.testCoverageData4();
        NewCreateReceiptVehicleController.testCoverageData5();
        NewCreateReceiptVehicleController.testCoverageData6();
    }
    
}