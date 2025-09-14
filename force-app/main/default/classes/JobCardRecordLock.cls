/**
* @author Ram Kumar
* @email ram.k@utilitarainlabs.com
* @create 26 june 2025
* @modify 
* @desc This Class prevents updates or deletions on child records if the related WorkOrder (Job Card) has a blocked status.
**/

public class JobCardRecordLock {
    
    
    public static void PreventUpdateForJobCardStatus(List<SObject> childRecords) {
        try {
            // If the input list is null or empty, there's nothing to process, so return early.
            if (childRecords == null || childRecords.isEmpty()) {
                return;
            }
            String currentProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
            if (currentProfileName == 'System Administrator') {
                return;
            }
            
            // Set to collect all unique WorkOrder IDs related to the child records.
            Set<Id> workOrderIds = new Set<Id>();
            
            // Iterate over each record to extract the WorkOrder Id, which may be stored under different fields.
            for (SObject record : childRecords) {
                Id workOrderId = null;
                
                // Check if the record has the standard WorkOrderId field, else check for custom fields.
                if (record.getSObjectType().getDescribe().fields.getMap().containsKey('WorkOrderId')) {
                    workOrderId = (Id) record.get('WorkOrderId');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('RR_Work_Order__c')) {
                    workOrderId = (Id) record.get('RR_Work_Order__c');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('Job_Card__c')) {
                    workOrderId = (Id) record.get('Job_Card__c');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('ParentRecordId')) {
                    workOrderId = (Id) record.get('ParentRecordId');
                }
                
                // Add the extracted WorkOrderId to the set if it's not null.
                if (workOrderId != null) {
                    workOrderIds.add(workOrderId);
                }
            }
            
            // If no WorkOrder IDs were found, no need to proceed.
            if (workOrderIds.isEmpty()) {
                return;
            }
            
            // Query WorkOrder records that have an ID in the collected set and whose Status is in the blockedStatuses list.
            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
                [SELECT Id, Status FROM WorkOrder WHERE Id IN :workOrderIds AND Status IN :ConstantData.blockedStatuses]
            );
            
            // Iterate again over each child record to enforce the lock if the WorkOrder has a blocked status.
            for (SObject record : childRecords) {
                Id workOrderId = null;
                
                // Extract WorkOrderId again using the same logic as above.
                if (record.getSObjectType().getDescribe().fields.getMap().containsKey('WorkOrderId')) {
                    workOrderId = (Id) record.get('WorkOrderId');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('RR_Work_Order__c')) {
                    workOrderId = (Id) record.get('RR_Work_Order__c');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('Job_Card__c')) {
                    workOrderId = (Id) record.get('Job_Card__c');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('ParentRecordId')) {
                    workOrderId = (Id) record.get('ParentRecordId');
                }
                
                // If the WorkOrderId exists and it is in the map (i.e., has a blocked status), add an error to the record.
                if (workOrderId != null && workOrderMap.containsKey(workOrderId)) {
                    WorkOrder wo = workOrderMap.get(workOrderId);
                    
                    // Add an error message to prevent update/delete if the WorkOrder status is blocked.
                    if (wo.Status != null && ConstantData.blockedStatuses.contains(wo.Status)) {
                        record.addError(
                            'You cannot update or delete this record because the related Job Card status is "' + wo.Status + '".'
                        );
                    }
                } 
            }
        } catch (Exception e) {
            // Log any unexpected exceptions with the error message and the line number.
            System.debug('Error Message ==> ' + e.getMessage() + ' | Error Line ==> ' + e.getLineNumber());
        }
    }
    public static void addTest(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        
        
    }
    public static void addTest2(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        
        
    }
    public static void addTest3(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        
        
    }
}