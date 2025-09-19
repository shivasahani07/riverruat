global class AppointmentCancellationScheduler implements Database.Batchable<SObject>, Schedulable {
    
    // Schedulable entry point
    global void execute(SchedulableContext sc) {
        // Run this batch with batch size 50
        Database.executeBatch(new AppointmentCancellationScheduler(), 50);
    }

    // Batch start method → fetch records
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Status__c, Appointment_Date__c,Service_Appointment__c,
                   Service_Appointment__r.Account.Name,
                   Service_Appointment__r.Account.Email__c,
                   Service_Appointment__r.SchedStartTime
            FROM Appointment__c
            WHERE Status__c = 'Pending'
            AND Appointment_Date__c < :Date.today()   // expired or past due
        ]);
    }

    // Batch execute method → process scope
    global void execute(Database.BatchableContext bc, List<Appointment__c> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        set<Id> saIds = new Set<Id>();
        for (Appointment__c appt : scope) {
            // Mark as cancelled
            appt.Status__c = 'Cancel';
            saIds.add(appt.Service_Appointment__c);
            // Prepare email
            if (appt.Service_Appointment__r.Account.Email__c != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { appt.Service_Appointment__r.Account.Email__c });
                mail.setSubject('Your Service Appointment is Cancelled');
                
                String body = 'Hey ' + appt.Service_Appointment__r.Account.Name +
                    ',\n\nYour service appointment scheduled for ' + 
                    String.valueOf(appt.Service_Appointment__r.SchedStartTime) + 
                    ' has expired and is now cancelled.' +
                    '\n\nFor more info, please contact our Service Advisor.' +
                    '\n\nThank you.';
                
                mail.setPlainTextBody(body);
                mail.setOrgWideEmailAddressId([SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'River Mobility' LIMIT 1].Id);
                
                emails.add(mail);
            }
            List<ServiceAppointment> serviceApplist = [Select id From ServiceAppointment where Id IN:saIds ];
            List<ServiceAppointment> updateSAlist = new List<ServiceAppointment>();
            For(ServiceAppointment Sarec : serviceApplist){
                Sarec.Call_Status__c = 'NFA';
                updateSAlist.add(Sarec);
            }
            
            if(!updateSAlist.isEmpty()){
                update updateSAlist;
            }

        }

        if (!scope.isEmpty()) {
            update scope;
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    // Batch finish method → log completion
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch completed for cancelling expired appointments.');
    }
}