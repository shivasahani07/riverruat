/**
 * @description       : Sends daily Integration Log report (HTML + CSV)
 * @author            : Aniket Karmakar
 * @last modified on  : 10-24-2025
**/
global with sharing class IntegrationFailureBatch implements Database.Batchable<SObject>, Database.Stateful {
    List<String> htmlRowsList = new List<String>();
    List<String> csvRowsList = new List<String>();
    Integer success = 0;
    Integer fail = 0;

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date todayDate = Date.today();
        Date yesterday = todayDate.addDays(-1);

        DateTime startDateTime = DateTime.newInstance(yesterday, Time.newInstance(0, 0, 0, 0));
        DateTime endDateTime = DateTime.newInstance(yesterday, Time.newInstance(23, 59, 59, 999));

        return Database.getQueryLocator([
            SELECT Id, Name, Integration_Type__c, Status__c, Response_Payload__c, CreatedDate, 
                   Request_Payload__c, Order__r.EffectiveDate, Order__r.OrderNumber, Order__r.Website_Order_Id__c
            FROM Integration_Log__c
            WHERE Integration_Type__c IN (
                'Reverse Integration Create Order',
                'Reverse Integration Update Order',
                'Reverse Integration Create Order Product',
                'Reverse Integration Delete Order Product',
                'Reverse Integration Create Payment',
                'Reverse Integration Delete Order Payment'
            )
            AND CreatedDate >= :startDateTime
            AND CreatedDate <= :endDateTime
            AND Order__c != null
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        for (SObject s : scope) {
            Integration_Log__c i = (Integration_Log__c)s;

            // Build HTML Row
            String htmlRow = '<tr style="text-align:center;">'
                + '<td>' + i.Name + '</td>'
                + '<td>' + i.Integration_Type__c + '</td>'
                + '<td>' + i.Status__c + '</td>'
                + '<td>' + i.Order__r.OrderNumber + '</td>'
                + '<td>' + i.Order__r.Website_Order_Id__c + '</td>'
                + '<td>' + i.Order__r.EffectiveDate + '</td>'
                + '<td>' + i.Request_Payload__c + '</td>'
                + '<td>' + i.Response_Payload__c + '</td>'
                + '</tr>';
            htmlRowsList.add(htmlRow);
            
            String cleanRequest = i.Request_Payload__c;
            String cleanResponse = i.Response_Payload__c;

            // Replace newlines and commas that break CSV format
            if (cleanRequest != null) {
                cleanRequest = cleanRequest.replace('\n', ' ').replace('\r', ' ');
                cleanRequest = cleanRequest.replace('"', '""');
                if (cleanRequest.length() > 30000) cleanRequest = cleanRequest.substring(0, 30000) + '...'; // optional trim
            } else {
                cleanRequest = '';
            }

            if (cleanResponse != null) {
                cleanResponse = cleanResponse.replace('\n', ' ').replace('\r', ' ');
                cleanResponse = cleanResponse.replace('"', '""');
                if (cleanResponse.length() > 30000) cleanResponse = cleanResponse.substring(0, 30000) + '...'; // optional trim
            } else {
                cleanResponse = '';
            }



            // Build CSV Row (escape commas & quotes safely)
            String csvRow = '"' + String.join(new List<String>{
                i.Name,
                i.Integration_Type__c,
                i.Status__c,
                i.Order__r.OrderNumber,
                i.Order__r.Website_Order_Id__c,
                String.valueOf(i.Order__r.EffectiveDate),
                (i.Request_Payload__c != null ? i.Request_Payload__c.replace('"', '""') : ''),
                (i.Response_Payload__c != null ? i.Response_Payload__c.replace('"', '""') : '')
            }, '","') + '"';
            csvRowsList.add(csvRow);

            // Count status
            if (i.Status__c == 'Success') success++;
            if (i.Status__c == 'Failed') fail++;
        }
    }

    global void finish(Database.BatchableContext BC) {
        // HTML Header
        String htmlHeader = '<html><body>'
            + '<h2>Integration Report Summary</h2>'
            + '<p><b>Total Success:</b> ' + success + '<br/>'
            + '<b>Total Failure:</b> ' + fail + '</p>'
            + '<hr/>'
            + '<h2>Detailed Report</h2>'
            + '<table border="1" cellpadding="5" cellspacing="0">'
            + '<tr style="background-color:#3498DB; color:white;">'
            + '<th>Name</th><th>Integration Type</th><th>Status</th>'
            + '<th>Salesforce Order Number</th><th>Website Order Number</th><th>Order Date</th>'
            + '<th>Request Body</th><th>Response Body</th>'
            + '</tr>';

        String htmlFooter = '</table></body></html>';
        String htmlBody = htmlHeader + String.join(htmlRowsList, '') + htmlFooter;

        // CSV Header + Rows
        String csvHeader = 'Name,Integration Type,Status,Salesforce Order Number,Website Order Number,Order Date,Request Body,Response Body';
        String csvBody = csvHeader + '\n' + String.join(csvRowsList, '\n');
        Blob csvBlob = Blob.valueOf(csvBody);

        // Fetch email recipients
        Integration_Log_Emails__c emailConfig = Integration_Log_Emails__c.getInstance('Integration Log Emails');
        List<String> recipientEmails = emailConfig.Emails__c.split(',');

        // Org-wide email address
        OrgWideEmailAddress[] orgWideEmail = [
            SELECT Id FROM OrgWideEmailAddress WHERE Address = 'support@rideriver.com' LIMIT 1
        ];

        // Create email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Yesterday\'s Integration Log Report');
        email.setToAddresses(recipientEmails);
        if (!orgWideEmail.isEmpty()) {
            email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
        }

        // Add HTML + plain text
        email.setPlainTextBody(
            'Integration Report Summary:\n' +
            'Total Success: ' + success + '\n' +
            'Total Failure: ' + fail + '\n\n' +
            'A detailed CSV file is attached.'
        );
        email.setHtmlBody(htmlBody);

        // Add CSV attachment
        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        csvAttachment.setFileName('Integration_Report_' + Date.today().addDays(-1).format() + '.csv');
        csvAttachment.setBody(csvBlob);
        csvAttachment.setContentType('text/csv');
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { csvAttachment });

        // Send email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        System.debug('Integration Log Report Email sent successfully!');
    }
}