/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global with sharing class IntegrationFailureBatch implements Database.Batchable<SObject>, Database.Stateful {
    List<String> htmlRowsList = new List<String>();
    Integer success=0;
    Integer fail =0;

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date todayDate = Date.today();
        Date yesterday = todayDate.addDays(-1);

        DateTime startDateTime = DateTime.newInstance(yesterday, Time.newInstance(0, 0, 0, 0));
        DateTime endDateTime = DateTime.newInstance(yesterday, Time.newInstance(23, 59, 59, 999));

        return Database.getQueryLocator([
            SELECT Id, Name, Integration_Type__c, Status__c, Response_Payload__c, CreatedDate, Request_Payload__c,Order__r.EffectiveDate,Order__r.OrderNumber,Order__r.Website_Order_Id__c
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
            AND CreatedDate <= :endDateTime AND Order__c != null
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        
        for (SObject s : scope) {
            Integration_Log__c i = (Integration_Log__c)s;
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

            if(i.Status__c == 'Success'){
                success++;
            }
            if(i.Status__c == 'Failed'){
                fail++;
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        // String htmlHeader = '<html><body><h2>Integration Report</h2>'
        //                     + '<table border="1" cellpadding="5" cellspacing="0">'
        //                     + '<tr style="background-color:#3498DB; color:white;">'
        //                     + '<th>Name</th><th>Integration Type</th><th>Status</th>'+'<th>Salesforce Order Number</th><th>Website Order Number</th><th>Order Date</th>'
        //                     + '<th>Request Body</th><th>Response Body</th>'
        //                     + '</tr>';

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

        Integration_Log_Emails__c i = Integration_Log_Emails__c.getInstance('Integration Log Emails');
        List<String> recipientEmails = i.Emails__c.split(',');

        //List<String> recipientsEmail = new List<String>{'aniket.k@utilitarianlabs.com'};

        OrgWideEmailAddress[] orgWideEmail = [
            SELECT Id FROM OrgWideEmailAddress WHERE Address = 'support@rideriver.com' LIMIT 1
        ];

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if (!orgWideEmail.isEmpty()) {
            email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
        }
        email.setPlainTextBody(
            'Integration Report Summary:\n' +
            'Total Success: ' + success + '\n' +
            'Total Failure: ' + fail + '\n\n' +
            'Please check your email in HTML format for detailed results.'
        );
        email.setHtmlBody(htmlBody);
        email.setToAddresses(recipientEmails);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        System.debug('Emails sent successfully!');
    }
}