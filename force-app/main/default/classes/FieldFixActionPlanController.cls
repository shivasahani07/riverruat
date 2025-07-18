public class FieldFixActionPlanController extends BaseVINProcessor {
    
    public FieldFixActionPlanController(String vinCSV, Id fieldFixId) {
        super(vinCSV, fieldFixId);
    }
    
    public override String execute() {
        processVINsAsync(vinList, fieldFixId);
        return 'Processing VINs asynchronously. You will receive a notification when complete.';
    }
    
    @Future
    public static void processVINsAsync(List<String> vinList, Id fieldFixId) {
        Id batchLogId;
        try {
            if (vinList.isEmpty() || fieldFixId == null) {
                sendErrorNotification('VIN input or Field Fix ID is missing.', fieldFixId);
                return;
            }
            batchLogId = BatchLogUtil.createSummary('VIN Processing', 'Vehicle', vinList.size());
            
            List<Vehicle> vehicles = [SELECT Id, Name, VehicleIdentificationNumber FROM Vehicle WHERE VehicleIdentificationNumber IN :vinList];
            System.debug('vehicles ========>' + vehicles);
            
            if (vehicles.isEmpty()) {
                sendErrorNotification('No matching vehicles found for provided VINs.', fieldFixId);
                BatchLogUtil.updateSummary(batchLogId, 0, vinList.size());
                return;
            }
            
            Field_Fix__c ff = [SELECT Id, Action_Plan_Template__c, Name FROM Field_Fix__c WHERE Id = :fieldFixId];
            String ffName = ff.Name;
            
            List<ActionPlanTemplateVersion> versions = [SELECT Id, ActionPlanTemplate.ActionPlanType FROM ActionPlanTemplateVersion 
                                                        WHERE ActionPlanTemplateId = :ff.Action_Plan_Template__c 
                                                        ORDER BY CreatedDate DESC LIMIT 1];
            System.debug('versions ========>' + versions);
            
            if (versions.isEmpty()) {
                sendErrorNotification('No Action Plan Template Versions found.', fieldFixId);
                return;
            }
            
            String actionPlanType = versions[0].ActionPlanTemplate.ActionPlanType;
            Id latestVersionId = versions[0].Id;
            
            List<ActionPlan> existingPlans = [SELECT TargetId, Name, ActionPlanTemplateVersionId 
                                              FROM ActionPlan 
                                              WHERE TargetId IN :vehicles 
                                              AND ActionPlanTemplateVersionId = :latestVersionId];
            System.debug('existingPlans ========>' + existingPlans);
            Set<Id> existingVINs = new Set<Id>();
            for (ActionPlan ap : existingPlans) {
                existingVINs.add(ap.TargetId);
            }
            
            
            Map<Id, Integer> vehicleSequenceMap = new Map<Id, Integer>();
            for (ActionPlan apRec : existingPlans) {
                if (apRec.TargetId != null) {
                    String alpha = apRec.Name.replace(ff.Name, '');
                    if (isNumeric(alpha)) {
                        Integer count = Integer.valueOf(alpha);
                        if (vehicleSequenceMap.containsKey(apRec.TargetId)) {
                            if (count > vehicleSequenceMap.get(apRec.TargetId)) {
                                vehicleSequenceMap.put(apRec.TargetId, count);
                            }
                        } else {
                            vehicleSequenceMap.put(apRec.TargetId, count);
                        }
                    }
                }
            }
            
            List<ActionPlan> plansToInsert = new List<ActionPlan>();
            List<Batch_Processing_Detail__c> detailLogs = new List<Batch_Processing_Detail__c>();
            Integer successCount = 0;
            Integer failCount = 0;
            
            
            for (Vehicle v : vehicles) {
                
                Batch_Processing_Detail__c detail = new Batch_Processing_Detail__c(Batch_Processing__c = batchLogId, External_Id__c = v.VehicleIdentificationNumber);
                System.debug('existingVINs.contains(v.Id)' + existingVINs.contains(v.Id));
                if (existingVINs.contains(v.Id)) {
                    detail.Status__c = 'Skipped';
                    detail.Is_Success__c = false;
                    detail.Object_Record_Id__c=v.Id;
                    detail.Stack_Trace__c = 'Action Plan already exists for this VIN';
                    failCount++;
                } else {
                    Integer nextCount = vehicleSequenceMap.containsKey(v.Id) ? vehicleSequenceMap.get(v.Id) + 1 : 1;
                    vehicleSequenceMap.put(v.Id, nextCount);
                    
                    ActionPlan ap = new ActionPlan(
                        Name = ffName + String.valueOf(nextCount),
                        TargetId = v.Id,
                        Field_Fix__c = ff.Id,
                        ActionPlanTemplateVersionId = latestVersionId,
                        ActionPlanState = 'Not Started',
                        StartDate = Date.today(),
                        ActionPlanType = actionPlanType
                    );
                    plansToInsert.add(ap);
                    
                    detail.Status__c = 'Created';
                    detail.Is_Success__c = true;
                    detail.Object_Record_Id__c=v.Id;
                    successCount++;
                }
                
                detailLogs.add(detail);
                
            }
            
            
            if (!plansToInsert.isEmpty()) {
                insert plansToInsert;
            }
            System.debug('detailLogs::>>' + detailLogs);
            BatchLogUtil.logDetails(detailLogs);
            System.debug('batchLogId::>>' + batchLogId + '::::' + +':::::');
            BatchLogUtil.updateSummary(batchLogId, successCount, failCount);
            
            sendCompletionNotification(successCount, new List<String>(), fieldFixId);
            
            Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
            customNotificationObj.setBody(successCount + ' Action Plans created. Skipped: ' + failCount);
            customNotificationObj.setTitle('VIN Update Bulk Upload');
            customNotificationObj.setNotificationTypeId([
                SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Avalailable_Qunatity_is_Zero' LIMIT 1
            ].Id);
            customNotificationObj.setSenderId(Userinfo.getUserId());
            customNotificationObj.setTargetId(fieldFixId);
            customNotificationObj.send(new Set<String> {Userinfo.getUserId()});
            
        } catch (Exception e) {
            sendErrorNotification('Error processing VINs: ' + e.getMessage(), fieldFixId);
            BatchLogUtil.logError('VIN Processing', 'Vehicle', vinList, e);
        }
        
    }
    
    @TestVisible private static void sendCompletionNotification(Integer createdCount, List<String> skippedVINs, Id fieldFixId) {
        String message = createdCount + ' Action Plans created.';
        if (!skippedVINs.isEmpty()) {
            message += ' Skipped VINs (already have plans): ' + String.join(skippedVINs, ', ');
        }
        
        EventBus.publish(new ProcessingCompleteEvent__e(
            RecordId__c = fieldFixId,
            Message__c = message,
            IsSuccess__c = true
        ));
    }
    
    @TestVisible private static void sendErrorNotification(String errorMessage, Id fieldFixId) {
        EventBus.publish(new ProcessingCompleteEvent__e(
            RecordId__c = fieldFixId,
            Message__c = errorMessage,
            IsSuccess__c = false
        ));
    }
    
    @AuraEnabled
    public static String processVINs(String vinCSV, Id fieldFixId) {
        FieldFixActionPlanController processor = new FieldFixActionPlanController(vinCSV, fieldFixId);
        return processor.execute();
    }
}