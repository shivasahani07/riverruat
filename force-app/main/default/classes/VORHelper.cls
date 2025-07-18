public without sharing class VORHelper {

    @AuraEnabled(cacheable=true)
    public static List<VOR__c> getRecentVORRecorDetails(Id jobcardId) {
        System.debug('Received Job Card ID: ' + jobcardId);

        if (jobcardId == null) {
            System.debug('Job Card ID must be provided');
            return new List<VOR__c>(); // Return empty list instead of throwing error
        }

        try {
            List<VOR__c> vorRecords = [
                SELECT Id, Name, VOR_Reason__c, Reason_Entered_Date__c, Last_Updated_VOR_Reason__c,
                       Job_Card__c, Job_Card__r.WorkOrderNumber, Job_Type__c, Job_Card__r.CreatedDate,
                       LastModifiedById, LastModifiedBy.Name
                FROM VOR__c
                WHERE Job_Card__c = :jobcardId
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
            System.debug('Fetched VOR records: ' + vorRecords);
            return vorRecords;
        } catch (Exception e) {
            System.debug('Error retrieving VOR records: ' + e.getMessage());
            return new List<VOR__c>(); // Return empty list if something fails
        }
    }

    @AuraEnabled
    public static void updateVORRecords(Id vorId, String newStatus) {
        System.debug('Updating VOR record. Id: ' + vorId + ', New Status: ' + newStatus);

        try {
            if (!Schema.sObjectType.VOR__c.isUpdateable()) {
                System.debug('User does not have permission to update VOR__c');
                return;
            }

            VOR__c vorToUpdate = new VOR__c(
                Id = vorId,
                VOR_Reason__c = newStatus
            );

            update vorToUpdate;
            System.debug('Successfully updated VOR record: ' + vorId);
        } catch (DmlException e) {
            System.debug('DML Exception while updating VOR record: ' + e.getDmlMessage(0));
        } catch (Exception ex) {
            System.debug('General Exception while updating VOR record: ' + ex.getMessage());
        }
    }
}