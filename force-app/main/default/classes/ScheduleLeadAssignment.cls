public class ScheduleLeadAssignment implements Schedulable{
     public void execute(SchedulableContext sc) {
 
        SobjectLoadAssignment.ExecuteLoadAssignment(2);
        ScheduleLeadAssignment.scheduleNextRun();
    }

     public static void scheduleNextRun() {
        Datetime nextRunTime = System.now().addMinutes(30);
        String cronExp = nextRunTime.format('s m H d M \'?\' yyyy');
        System.schedule('QABatches_' + nextRunTime.getTime(), cronExp, new ScheduleLeadAssignment());
    }
    public static void scheduleJob() {
        scheduleNextRun();
    }
 
}