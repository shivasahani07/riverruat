/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 08-29-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global without sharing class LeadReportScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        System.debug('LeadReportScheduler.execute() started');
        sendReportEmail();
        System.debug('LeadReportScheduler.execute() finished');
    }

    public void sendReportEmail() {
        try {
            System.debug('Starting sendReportEmail method');

            String reportId = '00OBh000000enMzMAI';//Hardcoded for Now For Testing , Later it would come dynamically From Custom Setting 
            System.debug('Report Id = ' + reportId);

            Map<String, List<List<String>>> dealerToRows = new Map<String, List<List<String>>>();
            Set<String> dealerCodes = new Set<String>();

            // Run report
            Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
            System.debug('📊 Report Results Retrieved? ' + (results != null));

            // Extract headers
            List<String> headers = new List<String>();
            Map<String, Reports.DetailColumn> detailCols = results.getReportExtendedMetadata().getDetailColumnInfo();
            System.debug('📊 Detail Columns Count = ' + detailCols.size());

            for (String colKey : results.getReportMetadata().getDetailColumns()) {
                if (detailCols.containsKey(colKey)) {
                    headers.add(detailCols.get(colKey).getLabel());
                } else {
                    headers.add(colKey);
                }
            }
            System.debug('📊 Report Headers = ' + headers);

            String csvContent = String.join(headers, ',') + '\n';

            // CHANGED: Instead of only checking "T!T", loop through all factMap keys
            Map<String, Reports.ReportFact> factMap = results.getFactMap();
            Integer totalRowCount = 0;

            for (String key : factMap.keySet()) {
                if (key.endsWith('!T')) {  // only detail rows
                    Reports.ReportFact fact = factMap.get(key);

                    if (fact instanceof Reports.ReportFactWithDetails) {
                        Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails) fact;
                        List<Reports.ReportDetailRow> detailRows = factDetails.getRows();

                        System.debug('📊 Found ' + detailRows.size() + ' rows under key ' + key);
                        totalRowCount += detailRows.size();

                        for (Reports.ReportDetailRow row : detailRows) {
                            List<String> rowValues = new List<String>();
                            String dealerCode = ''; // 🔄 keep dealerCode extraction working

                            Integer i = 0;
                            for (Reports.ReportDataCell cell : row.getDataCells()) {
                                String val = cell.getLabel();
                                if (String.isBlank(val)) {
                                    val = (cell.getValue() == null) ? '' : String.valueOf(cell.getValue());
                                }
                                rowValues.add(val);

                                // 🔄 Still extract dealer code dynamically
                                if (headers[i] == 'Dealer Code') {
                                    dealerCode = val;
                                }
                                i++;
                            }

                            if (!String.isBlank(dealerCode)) {
                                dealerCodes.add(dealerCode);
                                if (!dealerToRows.containsKey(dealerCode)) {
                                    dealerToRows.put(dealerCode, new List<List<String>>());
                                }
                                dealerToRows.get(dealerCode).add(rowValues);
                            }

                            // Also add to global CSV
                            csvContent += String.join(rowValues, ',') + '\n';
                        }
                    }
                }
            }
            System.debug(' Total Rows Extracted = ' + totalRowCount);

            // 🔄 Rest of your existing dealer email logic remains unchanged
            Map<String, Account> dealerCodeToAccount = new Map<String, Account>();
            for (Account acc : [
                SELECT Id, Center_Code__c, Email__c
                FROM Account
                WHERE Center_Code__c IN :dealerCodes
            ]) {
                if (!String.isBlank(acc.Center_Code__c)) {
                    dealerCodeToAccount.put(acc.Center_Code__c, acc);
                }
            }

            OrgWideEmailAddress[] orgWideEmail = [
                SELECT Id FROM OrgWideEmailAddress WHERE Address = 'support@rideriver.com' LIMIT 1
            ];
            System.debug('Org-Wide Email Found? ' + !orgWideEmail.isEmpty());

            for (String dealer : dealerToRows.keySet()) {
                if (!dealerCodeToAccount.containsKey(dealer)) continue;

                Account acc = dealerCodeToAccount.get(dealer);
                if (String.isBlank(acc.Email__c)) continue;

                String csvContentDealer = String.join(headers, ',') + '\n';
                for (List<String> rowVals : dealerToRows.get(dealer)) {
                    csvContentDealer += String.join(rowVals, ',') + '\n';
                }

                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('DailyReport_' + dealer + '.csv');
                attachment.setBody(Blob.valueOf(csvContentDealer));

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] { acc.Email__c });
                email.setSubject('Daily Report - Dealer ' + dealer);
                if (!orgWideEmail.isEmpty()) {
                    email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                }
                email.setPlainTextBody('Please find attached your daily leads report.');
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                System.debug('Email sent to ' + acc.Email__c + ' for Dealer ' + dealer);
            }

        } catch (Exception e) {
            System.debug('Error while sending report email: ' + e.getMessage());
            System.debug('Error Line Number: ' + e.getLineNumber());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
}