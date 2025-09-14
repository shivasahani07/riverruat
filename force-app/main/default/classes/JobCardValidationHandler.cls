/**
 * @description       : Preventing Update if job card is already completed
 * @author            : Ram Kumar
 * @group             : 
 * @last modified on  : 08-11-2025
 * @last modified by  : Ram Kumar
**/
public class JobCardValidationHandler {

    public static void validateJobCardStatus(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
        try {
           
            String currentProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
            if (currentProfileName == 'System Administrator') {
                return;
            }
            
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