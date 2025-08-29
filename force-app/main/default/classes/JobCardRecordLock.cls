/**
* @author Ram Kumar
* @email ram.k@utilitarainlabs.com
* @create 26 june 2025
* @modify 
* @desc
**/

public class JobCardRecordLock {

    public static void PreventUpdateForJobCardStatus(List<SObject> childRecords) {
        try {
            if (childRecords == null || childRecords.isEmpty()) {
                return;
            }

            Set<Id> workOrderIds = new Set<Id>();

            for (SObject record : childRecords) {
                Id workOrderId = null;

                // Check for different possible field names
                if (record.getSObjectType().getDescribe().fields.getMap().containsKey('WorkOrderId')) {
                    workOrderId = (Id) record.get('WorkOrderId');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('RR_Work_Order__c')) {
                    workOrderId = (Id) record.get('RR_Work_Order__c');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('Job_Card__c')) {
                    workOrderId = (Id) record.get('Job_Card__c');
                }
                else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('ParentRecordId')) {
                    workOrderId = (Id) record.get('ParentRecordId');
                }
                // Add more else if blocks here for other possible field names

                if (workOrderId != null) {
                    workOrderIds.add(workOrderId);
                }
            }

            if (workOrderIds.isEmpty()) {
                return;
            }

            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
                [SELECT Id, Status FROM WorkOrder WHERE Id IN :workOrderIds AND Status IN :ConstantData.blockedStatuses]
            );

            for (SObject record : childRecords) {
                Id workOrderId = null;

                if (record.getSObjectType().getDescribe().fields.getMap().containsKey('WorkOrderId')) {
                    workOrderId = (Id) record.get('WorkOrderId');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('RR_Work_Order__c')) {
                    workOrderId = (Id) record.get('RR_Work_Order__c');
                } else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('Job_Card__c')) {
                    workOrderId = (Id) record.get('Job_Card__c');
                }
                else if (record.getSObjectType().getDescribe().fields.getMap().containsKey('ParentRecordId')) {
                    workOrderId = (Id) record.get('ParentRecordId');
                }

                if (workOrderId != null && workOrderMap.containsKey(workOrderId)) {
                    WorkOrder wo = workOrderMap.get(workOrderId);
                    if (wo.Status != null && ConstantData.blockedStatuses.contains(wo.Status)) {
                        record.addError(
                            'You cannot update or delete this record because the related Job Card status is "' + wo.Status + '".'
                        );
                    }
                } 
            }

        } catch (Exception e) {
            System.debug('Error Message ==> ' + e.getMessage() + ' | Error Line ==> ' + e.getLineNumber());
        }
    }
}