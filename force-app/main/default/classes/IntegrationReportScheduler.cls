/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global without sharing class IntegrationReportScheduler implements Schedulable{
    global void execute(SchedulableContext SC){
        Database.executeBatch(new IntegrationFailureBatch(),200);
    }
}