public without sharing class DMLLoggerQueueable implements Queueable, Database.AllowsCallouts {

    private List<Object_DML_Log__c> logsToInsert;

    public DMLLoggerQueueable(List<Object_DML_Log__c> logs) {
        this.logsToInsert = logs;
    }
  
    public void execute(QueueableContext qc) {
        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
            } catch (Exception e) {
                System.debug('Failed to insert logs: ' + e.getMessage());
                // You could even write to Platform Events if log insert fails
            }
        }
    }
}