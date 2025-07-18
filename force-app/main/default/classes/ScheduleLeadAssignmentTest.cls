/**
* @File Name : ScheduleLeadAssignmentTest.cls
* @Description :
* @Author : Anwar Chikle
* @Last Modified By :
* @Last Modified On : April 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 3, 2025 |   | Initial Version
**/

@isTest
public class ScheduleLeadAssignmentTest {

    @isTest
    static void testScheduleLeadAssignmentExecute() {
        Test.startTest();
        ScheduleLeadAssignment.scheduleJob();
        Test.stopTest();
    }

    @isTest
    static void testExecuteMethod() {
        ScheduleLeadAssignment sla = new ScheduleLeadAssignment();
        Test.startTest();
        sla.execute(null);
        Test.stopTest();
    }

    @isTest
    static void testManualCronSchedule() {
        String cron = '0 0 12 * * ?';
        Test.startTest();
        System.schedule('Manual_LeadAssignment', cron, new ScheduleLeadAssignment());
        Test.stopTest();
    }
}