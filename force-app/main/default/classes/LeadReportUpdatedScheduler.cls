/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global without sharing class LeadReportUpdatedScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        Integer currentHour = Datetime.now().hour();
        String mode;

        if (currentHour == 7) {
            mode = 'MONTHLY'; // 7 AM → this month's leads
        } else if (currentHour == 19) {
            mode = 'DAILY';   // 7 PM → today's leads
        } else {
            mode = 'DAILY';
            // System.debug('### Not a scheduled hour for report. Exiting...');
            // return;
        }

        System.debug('### Running LeadReportBatch in mode=' + mode);
        Database.executeBatch(new LeadReportBatch(mode), 200);
    }
}