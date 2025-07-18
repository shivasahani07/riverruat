@isTest
public with sharing class AppointmentSlotController_Test {
    
    @isTest
    public static void testAppointmentSlotController() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Type = 'Service Center',
            Center_Code__c = '292001',
            Email__c = 'test@gmail.com',
            Phone = '9089786756');
        insert acc;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'Soumya',
            LastName  = 'Mishra',
            AccountId = acc.Id,
            Phone  = '9089786756'
        );
        insert con;

        Service_Bay__c sb = new Service_Bay__c(
            Service_Center__c = acc.Id,
            Vehicle_Capacity__c = 5,
            Technician__c = con.Id
        );
        insert sb;

        Integer count = AppointmentSlotController.getServiceBayCount(acc.Id);
        System.assertEquals(0, count); // Optional assertion


        /*
        AppointmentSlotController.createSlot(
            acc.Id,
            System.today(),
            System.today(),
            '10:00 am',
            '11:00 am',
            2,
            30
        );
        */
    }
}