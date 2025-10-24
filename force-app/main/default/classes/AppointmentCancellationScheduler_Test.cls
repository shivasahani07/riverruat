@isTest
private class AppointmentCancellationScheduler_Test {

    @testSetup
    static void setupData() {
        // Create OrgWideEmailAddress (used in email sending)
       
        
     OrgWideEmailAddress owe   =  [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'River Mobility' LIMIT 1];

        // Create Account
        Account acc = new Account(
            Name = 'Test Customer',
            Email__c = 'customer@test.com'
        );
        insert acc;

        // Create Service Appointment
        ServiceAppointment sa = new ServiceAppointment(
            Subject = 'Test Service Appointment',
            Status = 'Scheduled',
             ParentRecordId = acc.id,
            SchedStartTime = System.now().addDays(-2),
            SchedEndTime = System.now().addDays(-2).addHours(1)
        );
        insert sa;

        // Create Appointment__c (custom object)
        Appointment__c appt = new Appointment__c(
            
            Status__c = 'Pending',
            Appointment_Date__c = Date.today().addDays(-1),  // past date → should be cancelled
            Service_Appointment__c = sa.Id
        );
        insert appt;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        AppointmentCancellationScheduler batch = new AppointmentCancellationScheduler();
        Database.executeBatch(batch, 50);
        Test.stopTest();
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String jobId = System.schedule(
            'Appointment Cancel Job',
            '0 0 12 * * ?', // every day at noon
            new AppointmentCancellationScheduler()
        );
        Test.stopTest();
    }

    @isTest
    static void testExecuteMethodDirectly() {
        List<Appointment__c> apptList = [SELECT Id, Status__c, Appointment_Date__c,
                                                Service_Appointment__c,
                                                Service_Appointment__r.Account.Email__c,
                                                Service_Appointment__r.Account.Name,
                                                Service_Appointment__r.SchedStartTime
                                         FROM Appointment__c LIMIT 1];
        AppointmentCancellationScheduler scheduler = new AppointmentCancellationScheduler();
        Test.startTest();
        scheduler.execute(null, apptList);
        Test.stopTest();
    }
}