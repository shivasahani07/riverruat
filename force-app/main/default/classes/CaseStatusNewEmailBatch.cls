global class CaseStatusNewEmailBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Integer hours = Integer.valueOf(Label.Case_Status_Check_Hours_For_New_Status);
        DateTime targetTime = System.now().addHours(-hours);

        return Database.getQueryLocator([
            SELECT Id, Subject,CaseNumber,Owner.Name,Account.Name,Account.Phone, Account.Email__c, Owner.Email, Status, CreatedDate 
            FROM Case 
            WHERE Status = 'New' 
            AND CreatedDate <= :targetTime
        ]);
    }

   global void execute(Database.BatchableContext bc, List<SObject> scope) {
    Map<String, List<Case>> ownerEmailToCases = new Map<String, List<Case>>();
    system.debug('scope==='+scope);
    for (Case c : (List<Case>)scope) {
        if (c.Owner != null && c.Owner.Email != null) {
            String email = c.Owner.Email;

            if (!ownerEmailToCases.containsKey(email)) {
                ownerEmailToCases.put(email, new List<Case>());
            }
            ownerEmailToCases.get(email).add(c);
        }
    }

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (String ownerEmail : ownerEmailToCases.keySet()) {
        List<Case> cases = ownerEmailToCases.get(ownerEmail);

        String htmlBody = '<p>Dear User,</p>';
        htmlBody += '<p>The following cases are still in "New" status:</p>';
        htmlBody += '<table border="1" cellpadding="5" cellspacing="0">';
        htmlBody += '<tr><th>Case Number</th><th>Name</th><th>Phone</th><th>Email</th><th>Status</th><th>Owner</th><th>Created Date</th></tr>';

        for (Case c : cases) {
            htmlBody += '<tr>';
            htmlBody += '<td>' + c.CaseNumber + '</td>';
            htmlBody += '<td>' + c.Account.Name + '</td>';
              htmlBody += '<td>' + c.Account.Phone + '</td>';
              htmlBody += '<td>' + c.Account.Email__c + '</td>';
            htmlBody += '<td>' + 'New' + '</td>';
            htmlBody += '<td>' + c.Owner.Name + '</td>';
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

        emails.add(mail);
    }

    if (!emails.isEmpty()) {
        Messaging.sendEmail(emails);
    }
}


    global void finish(Database.BatchableContext bc) {
        // Optional finish logic
    }
}