global class CaseStatusClosedEmailBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Integer hours = Integer.valueOf(Label.Case_Status_Check_Hours_For_Closed_Status);
        DateTime targetTime = System.now().addHours(-hours);

        return Database.getQueryLocator([
            SELECT Id, Subject, CaseNumber, Owner.Name, Owner.Email, SuppliedName, ContactPhone, ContactEmail, Status, CreatedDate 
            FROM Case 
            WHERE Status != 'Closed' 
            AND CreatedDate <= :targetTime
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope.isEmpty()) return;

        List<Case> cases = (List<Case>)scope;

        String htmlBody = '<p>Dear User,</p>';
        htmlBody += '<p>The following cases are still pending to "Closed" status:</p>';
        htmlBody += '<table border="1" cellpadding="5" cellspacing="0">';
        htmlBody += '<tr><th>Case Number</th><th>Supplied Name</th><th>Contact Phone</th><th>Contact Email</th><th>Status</th><th>Owner</th><th>Created Date</th></tr>';

        for (Case c : cases) {
            htmlBody += '<tr>';
            htmlBody += '<td>' + c.CaseNumber + '</td>';
            htmlBody += '<td>' + (c.SuppliedName != null ? c.SuppliedName : '') + '</td>';
            htmlBody += '<td>' + (c.ContactPhone != null ? c.ContactPhone : '') + '</td>';
            htmlBody += '<td>' + (c.ContactEmail != null ? c.ContactEmail : '') + '</td>';
            htmlBody += '<td>' + c.Status + '</td>';
            htmlBody += '<td>' + (c.Owner != null ? c.Owner.Name : '') + '</td>';
            htmlBody += '<td>' + String.valueOf(c.CreatedDate) + '</td>';
            htmlBody += '</tr>';
        }

        htmlBody += '</table>';
        htmlBody += '<p>Please take appropriate action.</p>';
        htmlBody += '<p>Regards,<br/>Salesforce System</p>';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { 'lokhandeshubham772@gmail.com' });
        mail.setSubject('Case Status Reminder: Action Needed');
        mail.setHtmlBody(htmlBody);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    global void finish(Database.BatchableContext bc) {
        // Optional finish logic
    }
}