public without sharing class IRNUpdateQueueableForService implements Queueable, Database.AllowsCallouts {

    private String workOrderId;
    private String irnNumber;
    private Integer attempt;

    public IRNUpdateQueueableForService(String workOrderId, String irnNumber, Integer attempt) {
        this.workOrderId = workOrderId;
        this.irnNumber   = irnNumber;
        this.attempt     = (attempt != null) ? attempt : 1;
    }

    public void execute(QueueableContext context) {
        System.debug('--- Entered IRNUpdateQueueableForService.execute ---');
        System.debug('WorkOrderId: ' + workOrderId);
        System.debug('IRN Number: ' + irnNumber);
        System.debug('Attempt #: ' + attempt);

        try {
            if (String.isBlank(irnNumber)) {
                System.debug('No IRN to update; exiting.');
                return;
            }

            WorkOrder updateWorkOrd = new WorkOrder(Id = workOrderId);
            updateWorkOrd.IRN_Generated_DateTime__c = System.now();
            updateWorkOrd.IRN_No__c = irnNumber;
            updateWorkOrd.Can_Cancel_IRN__c = true;
           
            try{
                 update updateWorkOrd;
            System.debug('WorkOrder update successful ==> ' + updateWorkOrd);
            }catch(exception e){
                System.debug('WorkOrder update successful ==> ' + e.getMessage()+ ' '+ e.getLineNumber());
                 ExceptionHelper.createExceptionLog(e);
            }
           
        } catch (Exception e) {
            System.debug('Exception in IRNUpdateQueueableForService: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());

            // Retry for row lock/contention cases up to 3 retries (4 total attempts)
            if (attempt < 4 && (
                e.getMessage().contains('UNABLE_TO_LOCK_ROW') ||
                e.getMessage().contains('currently being modified')
            )) {
                System.debug('Retrying IRN update. Attempt #' + (attempt + 1));
                System.enqueueJob(new IRNUpdateQueueableForService(workOrderId, irnNumber, attempt + 1));
            } else {
                System.debug('Max retries reached or unrecoverable error. Logging exception...');
                ExceptionHelper.createExceptionLog(e);
            }
        }

        System.debug('--- Exiting IRNUpdateQueueableForService.execute ---');
    }
}