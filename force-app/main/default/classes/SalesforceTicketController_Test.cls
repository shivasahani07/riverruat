@isTest
private class SalesforceTicketController_Test {
    
    @TestSetup
    static void makeData(){
        
        Contact testContact = new Contact(
            LastName = 'Smith',
            FirstName = 'John',
            Designation__c = 'Technical Support',
            Phone = '8978675467'
        );
        insert testContact;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'janedoe@example.com',
            Username = 'janedoe' + DateTime.now().getTime() + '@example.com',
            Alias = 'jdoe',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;

        Salesforce_Support__c ticket = new Salesforce_Support__c(
            Status__c = 'Open',
            Subject__c = 'Test Subject'
        );
        insert ticket;
    }

    @isTest
    private static void test_getSalesforceSupportRecords(){

        List<Salesforce_Support__c> testRecords = new List<Salesforce_Support__c>();

        testRecords.add(new Salesforce_Support__c(
            Status__c = 'Open',
            Subject__c = 'Subject 1',
            Description__c = 'Test Description 2'
        ));

        testRecords.add(new Salesforce_Support__c(
            Status__c = 'Closed',
            Subject__c = 'Subject 2',
            Description__c = 'Test Description 2'
        ));

        insert testRecords;

        SalesforceTicketController.getSalesforceSupportRecords(); 
    }

    @isTest
    private static void test_GetContactAndUserOptions() {

        List<SalesforceTicketController.ContactUserWrapper> results = SalesforceTicketController.getContactAndUserOptions();        
    }

    @isTest
    private static void test_CreateTicketAssignment() {

        Salesforce_Support__c tckt = [SELECT Id FROM Salesforce_Support__c WHERE Status__c = 'Open' AND Subject__c = 'Test Subject' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE FirstName = 'Jane' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Smith' LIMIT 1];

        System.debug(tckt.Id + ' ----- ' + usr.Id + ' ----- ' + con.Id);

        String msg = SalesforceTicketController.createTicketAssignment(tckt.Id, usr.Id, con.Id, 'Test Remarks', 'High');
    }
}