/**
 * @description       : Lead Report Batch with Debug Logs
 * @author            : Aniket Karmakar
 * @last modified on  : 09-17-2025
**/
global class LeadReportBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Map dealerCode -> list of CSV/HTML rows
    Map<String, List<String>> dealerToCsvRows = new Map<String, List<String>>();
    Map<String, List<String>> dealerToHtmlRows = new Map<String, List<String>>();

    String reportMode;

    global LeadReportBatch(String mode) {
        this.reportMode = mode;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
         Date today = System.today();
        Datetime startDate;
        Datetime endDate = Datetime.newInstance(today, Time.newInstance(23,59,59,999));

        if (reportMode == 'MONTHLY') {
            Date firstDay = Date.newInstance(today.year(), today.month(), 1);
            startDate = Datetime.newInstance(firstDay, Time.newInstance(0,0,0,0));
        } else {
            startDate = Datetime.newInstance(today, Time.newInstance(0,0,0,0));
        }

        System.debug('### ReportMode=' + reportMode + ', StartDate=' + startDate + ', EndDate=' + endDate);

        return Database.getQueryLocator([
            SELECT Id, Name, Phone, Owner.Name, LeadSource, CreatedDate,
                   Dealer_Code__c, Lead_Dealer_Code__c,IsConverted
            FROM Lead
            WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
                  AND Lead_Dealer_Code__c != null
            ORDER BY CreatedDate DESC
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        System.debug('### EXECUTE METHOD: Scope size=' + scope.size());

        Set<Id> leadIds = new Set<Id>();
        for (SObject s : scope) {
            leadIds.add(((Lead)s).Id);
        }
        System.debug('### Lead Ids in scope=' + leadIds);

        // Build follow-up counts
        Map<Id, Integer> followUpCountMap = new Map<Id, Integer>();
        if (!leadIds.isEmpty()) {
            for (AggregateResult ar : [
                SELECT Lead__c leadId, COUNT(Id) followUpCount
                FROM Follow_Up__c
                WHERE Lead__c IN :leadIds
                GROUP BY Lead__c
            ]) {
                followUpCountMap.put((Id)ar.get('leadId'), (Integer)ar.get('followUpCount'));
            }
        }
        System.debug('### followUpCountMap=' + followUpCountMap);

        Map<Id, Test_Drive__c> leadToTestDriveMap = new Map<Id, Test_Drive__c>();
    if (!leadIds.isEmpty()) {
        for (Test_Drive__c td : [
            SELECT Id, Lead__c, Test_Drive_Status__c
            FROM Test_Drive__c
            WHERE Lead__c IN :leadIds
            ORDER BY CreatedDate ASC
        ]) {
            if (!leadToTestDriveMap.containsKey(td.Lead__c)) {
                leadToTestDriveMap.put(td.Lead__c, td); // only 0th record
            }
        }
    }
    System.debug('### leadToTestDriveMap=' + leadToTestDriveMap);


        // Build dealer grouped rows
        for (SObject s : scope) {
            Lead l = (Lead)s;
            Integer followUps = followUpCountMap.get(l.Id);
            if (followUps == null) followUps = 0;

            String dealerCode = String.isNotBlank(l.Lead_Dealer_Code__c) ? l.Lead_Dealer_Code__c : l.Dealer_Code__c;
            if (String.isBlank(dealerCode)) {
                dealerCode = 'UNKNOWN'; // fallback group
            }

            System.debug('### Processing Lead: Id=' + l.Id + ', DealerCode=' + dealerCode + ', FollowUps=' + followUps);

            String bookingStatus = l.IsConverted ? 'Yes' : 'No';


            String testDriveCompleted = 'No';
        if (leadToTestDriveMap.containsKey(l.Id)) {
            Test_Drive__c td = leadToTestDriveMap.get(l.Id);
            if (td.Test_Drive_Status__c == 'Completed') {
                testDriveCompleted = 'Yes';
            }
        }

        // CSV row
        String csvRow = '"' + String.valueOf(l.CreatedDate) + '","'
            + l.Name + '","'
            + l.Phone + '","'
            + l.Owner.Name + '","'
            + l.LeadSource + '","'
            + followUps + '","'
            // + l.Dealer_Code__c + '","'
            + l.Lead_Dealer_Code__c + '","'
            + bookingStatus + '","'
            + testDriveCompleted + '"';

        // HTML row
        String htmlRow = '<tr style="text-align:center;">'
                         + '<td>' + l.CreatedDate.format() + '</td>'
                         + '<td>' + l.Name + '</td>'
                         + '<td>' + l.Phone + '</td>'
                         + '<td>' + l.Owner.Name + '</td>'
                         + '<td>' + l.LeadSource + '</td>'
                         + '<td>' + followUps + '</td>'
                        //  + '<td>' + (l.Dealer_Code__c != null ? l.Dealer_Code__c : '') + '</td>'
                         + '<td>' + (l.Lead_Dealer_Code__c != null ? l.Lead_Dealer_Code__c : '') + '</td>'
                         + '<td>' + bookingStatus + '</td>'
                         + '<td>' + testDriveCompleted + '</td>'
                         + '</tr>';

            if (!dealerToCsvRows.containsKey(dealerCode)) {
                dealerToCsvRows.put(dealerCode, new List<String>());
                dealerToHtmlRows.put(dealerCode, new List<String>());
            }
            dealerToCsvRows.get(dealerCode).add(csvRow);
            dealerToHtmlRows.get(dealerCode).add(htmlRow);
        }

        System.debug('### dealerToCsvRows so far=' + dealerToCsvRows.keySet());
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('### FINISH METHOD STARTED');
        System.debug('### dealerToCsvRows keys=' + dealerToCsvRows.keySet());

        Lead_Report_Id__c setting = Lead_Report_Id__c.getInstance('Lead Report Id'); 
        System.debug('setting==>'+setting);
    Boolean sendToAll = (setting != null && setting.Send_To_All__c);
    System.debug('sendToAll==>'+sendToAll);
    Set<Id> allowedAccIds = new Set<Id>();

    
//        if (!sendToAll && setting != null && !String.isBlank(setting.Allowed_Accounts__c)) {
//     List<String> accIdStrings = setting.Allowed_Accounts__c.split(',');
//     for (String accIdStr : accIdStrings) {
//         if (!String.isBlank(accIdStr)) {
//             allowedAccIds.add((Id) accIdStr.trim());
//         }
//     }
// }

   if (!sendToAll) {
    for (Allowed_Accounts_For_Lead_Report__mdt mdtRec : [
        SELECT Account_Ids__c
        FROM Allowed_Accounts_For_Lead_Report__mdt
    ]) {
        if (!String.isBlank(mdtRec.Account_Ids__c)) {
            try {
                allowedAccIds.add((Id) mdtRec.Account_Ids__c.trim());
            } catch (Exception e) {
                System.debug('Invalid Account Id in metadata: ' + mdtRec.Account_Ids__c);
            }
        }
    }
}
System.debug('allowedAccIds==>' + allowedAccIds);

System.debug('allowedAccIds==>'+allowedAccIds);

List<String> addditionalEmails = setting.Allowed_Emails__c.split(',');
System.debug('Additional Emails==>'+addditionalEmails);

        // CSV Header
        String header = 'Enquiry Date,Customer Name,Mobile,PS Name,Lead Source,Follow Up Count,Lead Dealer Code,Booking Status,Test Drive Completed';

        // Fetch Accounts for Dealer Codes
        // List<Account> accounts = [
        //     SELECT Id, Center_Code__c, Email__c
        //     FROM Account
        //     WHERE Center_Code__c IN :dealerToCsvRows.keySet()
        // ];
        // System.debug('### Accounts fetched=' + accounts.size());

        // Map<String, Account> dealerCodeToAccount = new Map<String, Account>();
        // for (Account acc : accounts) {
        //     System.debug('### Account: Id=' + acc.Id + ', Center_Code=' + acc.Center_Code__c + ', Email=' + acc.Email__c);
        //     if (!String.isBlank(acc.Center_Code__c)) {
        //         dealerCodeToAccount.put(acc.Center_Code__c, acc);
        //     }
        // }
        List<Account> accounts = [
        SELECT Id, Center_Code__c, Email__c
        FROM Account
        WHERE Center_Code__c IN :dealerToCsvRows.keySet()
        ORDER BY CreatedDate ASC
    ];

    System.debug('Fetched Dealer Accounts=>'+accounts);

    Map<String, Account> dealerCodeToAccount = new Map<String, Account>();
    for (Account acc : accounts) {
        if (!String.isBlank(acc.Center_Code__c) && !dealerCodeToAccount.containsKey(acc.Center_Code__c)) {
            dealerCodeToAccount.put(acc.Center_Code__c, acc);
        }
    }
    System.debug('dealerCodeToAccount==>'+dealerCodeToAccount);
        OrgWideEmailAddress[] orgWideEmail = [
            SELECT Id FROM OrgWideEmailAddress WHERE Address = 'support@rideriver.com' LIMIT 1
        ];
        System.debug('### OrgWideEmailAddress found=' + orgWideEmail);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (String dealer : dealerToCsvRows.keySet()) {
            System.debug('### Processing dealer=' + dealer);

            if (!dealerCodeToAccount.containsKey(dealer)) {
                System.debug('### Skipping dealer (no account found)=' + dealer);
                continue;
            }

            Account acc = dealerCodeToAccount.get(dealer);
            System.debug('Current Account==>'+acc + 'Current Dealer Code ==>'+acc.Center_Code__c);
            if (String.isBlank(acc.Email__c)) {
                System.debug('### Skipping dealer (no email)=' + dealer);
                continue;
            }

            // Build CSV for this dealer
            String csvContent = header + '\n' + String.join(dealerToCsvRows.get(dealer), '\n');
            System.debug('### CSV Content Length=' + csvContent.length());

            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('EnquiryReport_' + dealer + '.csv');
            attachment.setBody(Blob.valueOf(csvContent));

            // Build HTML for this dealer
            String htmlHeader = '<html><body><h2>Enquiry Report - Dealer ' + dealer + '</h2>'
                               + '<table border="1" cellpadding="5" cellspacing="0">'
                               + '<tr style="background-color:#3498DB; color:white;">'
                               + '<th>Enquiry Date</th><th>Customer Name</th><th>Mobile</th>'
                               + '<th>PS Name</th><th>Lead Source</th><th>Follow Up Count</th>'
                               + '<th>Lead Dealer Code</th><th>Booking Status</th><th>Test Drive Completed</th></tr>';
            String htmlFooter = '</table></body></html>';
            String htmlBody = htmlHeader + String.join(dealerToHtmlRows.get(dealer), '') + htmlFooter;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            List<String> toAddresses = new List<String>();

           if (sendToAll) {
            // Old logic
            toAddresses.add(acc.Email__c);
            toAddresses.addAll(addditionalEmails);
            // email.setToAddresses(new String[] { acc.Email__c });
            // email.setToAddresses(addditionalEmails);
        } else {
            // Only send to Allowed Accounts’ Emails
            if (!allowedAccIds.contains(acc.Id)) {
                System.debug('Skipping dealer ' + dealer + ' (not in AllowedAccounts)');
                continue;
            }
            toAddresses.add(acc.Email__c);
            toAddresses.addAll(addditionalEmails);
            // email.setToAddresses(new String[] { acc.Email__c});
            // email.setToAddresses(addditionalEmails);
        }


           email.setToAddresses(toAddresses);

            //email.setToAddresses(new String[] { acc.Email__c, 'aniket.k@utilitarianlabs.com','jishena@gmail.com','sandeep.singh@utilitarianlabs.com' });
            email.setSubject('Daily Enquiry Report - Dealer ' + dealer);
            if (!orgWideEmail.isEmpty()) {
                email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
            }
            email.setPlainTextBody('Please find attached your daily leads report.');
            email.setHtmlBody(htmlBody);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

            System.debug('### Adding email for dealer=' + dealer + ', To=' + acc.Email__c);
            emails.add(email);
        }

        System.debug('### Total emails prepared=' + emails.size());
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
            System.debug('### Emails sent successfully!');
        } else {
            System.debug('### No emails to send.');
        }
    }
}