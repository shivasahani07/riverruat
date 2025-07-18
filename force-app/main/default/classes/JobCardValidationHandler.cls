public class JobCardValidationHandler {

    public static void validateJobCardStatus(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
        try {
            for (WorkOrder newJob : newList) {
                WorkOrder oldJob = oldMap.get(newJob.Id);

                if (oldJob == null) {
                    System.debug('Skipping record due to null oldJob for ID: ' + newJob.Id);
                    continue;
                }

                System.debug('Checking Job Card: ' + newJob.Id);
                System.debug('Old Status: ' + oldJob.Status);
                System.debug('New Status: ' + newJob.Status);

                if (oldJob.Status == 'Completed') {
                    System.debug('Job Card ' + newJob.Id + ' is already completed. Preventing update.');
                    newJob.addError('You cannot update Completed Job card');
                }
            }
        } catch (Exception ex) {
            System.debug('Exception in validateJobCardStatus: ' + ex.getMessage() + 'Line Number : ' + ex.getLineNumber());
        }
    }
}