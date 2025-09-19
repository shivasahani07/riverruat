global class ExpiredMilestoneBatch implements Database.Batchable<sObject>, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch milestones that are past due and not already expired
        return Database.getQueryLocator([
            SELECT Id, Name, MilestoneDate, Stage, VehicleId FROM AssetMilestone
            WHERE MilestoneDate < :System.today() 
            AND Stage != 'Expired' limit 1
        ]);
    }

    global void execute(Database.BatchableContext bc, List<AssetMilestone> scope) {
        List<AssetMilestone> milestonesToUpdate = new List<AssetMilestone>();
        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        set<Id> milesIds = new set<id>();  
        for (AssetMilestone milestone : scope) {
            // 1. Mark milestone as expired
            milestone.Stage = 'Expired';
            milestonesToUpdate.add(milestone);
            milesIds.add(milestone.id);
        }
           list<ServiceAppointment > ServiceAppointments = [select id ,Account.Name,Call_status__c,Account.Email__c,Asset_Milestone__c,Asset_Milestone__r.MilestoneDate from ServiceAppointment where Asset_Milestone__c IN : milesIds];
            if (!ServiceAppointments.isEmpty()) {
                for (ServiceAppointment sa :  ServiceAppointments) {
                    sa.Call_Status__c = 'NFA';
                    saToUpdate.add(sa);

                    // 3. Send email to customer if account email exists
                    if (sa.Account.Email__c != null) {
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new String[] { sa.Account.Email__c });
                        mail.setSubject('Your Service Appointment has Expired');

                        String body = 'Hey ' + sa.Account.Name + ',' +
                                      '\n\nYour service appointment dated ' + 
                                      sa.Asset_Milestone__r.MilestoneDate.format() + 
                                      ' has expired.' +
                                      '\n\nIf you still need assistance, please contact our Service Advisor or reschedule a new appointment.' +
                                      '\n\nThank you!';
                        mail.setPlainTextBody(body);

                        // Org-wide email address (optional)
                        OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'River Mobility' LIMIT 1 ];
                        mail.setOrgWideEmailAddressId(owea.Id);

                        emails.add(mail);
                    }
                }
            }
        

        if (!milestonesToUpdate.isEmpty()) {
            update milestonesToUpdate;
        }
        if (!saToUpdate.isEmpty()) {
            update saToUpdate;
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Expired milestone batch completed.');
    }

    // Schedulable method
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ExpiredMilestoneBatch(), 50);
    }
}