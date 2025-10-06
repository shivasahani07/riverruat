public  class TaskLeadController {
    
    @AuraEnabled
    public static Map<String, List<String>> getFieldDependencies(String objectName, String controllingField, String dependentField){
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
        for(Schema.PicklistEntry currControllingValue : controllingValues){
            controllingInfo.put(currControllingValue.getLabel(), new List<String>());
        }
        for(Schema.PicklistEntry currDependentValue : dependentValues){
            String jsonString = JSON.serialize(currDependentValue);
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer baseCount = 0;
            for(Integer curr : hexString.getChars())
            {
                Integer val = 0;
                if(curr >= 65){
                    val = curr - 65 + 10;
                }
                else{
                    val = curr - 48;
                }
                if((val & 8) == 8){
                    controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
                }
                if((val & 4) == 4){
                    controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());                    
                }
                if((val & 2) == 2){
                    controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());                    
                }
                if((val & 1) == 1){
                    controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());                    
                }
                baseCount += 4;
            }            
        }
        System.debug('controllingInfo =======>'+ controllingInfo);        
        return controllingInfo;
    }

    class MyPickListInfo {
        public String active {get; set;}
        public String defaultValue {get; set;}
        public String label {get; set;}
        public String value {get; set;}
        public String validFor {get; set;}
    }

    public static Set<String> statusPicklistValues(String objectName, String fieldName) {
        Set<String> picklistValues = new Set<String>();
        try {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            if (!schemaMap.containsKey(objectName)) {
                return null;
            }
            Schema.SObjectType sobjectType = schemaMap.get(objectName);
            Schema.DescribeSObjectResult describeResult = sobjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
            if (!fieldsMap.containsKey(fieldName)) {
                return null;
            }
            List<Schema.PicklistEntry> picklistEntries = fieldsMap.get(fieldName).getDescribe().getPicklistValues();
            for (Schema.PicklistEntry entry : picklistEntries) {
                picklistValues.add(entry.getValue());
            }
            System.debug('picklistValues =======>'+ picklistValues);
            return picklistValues;
        } catch (Exception e) {
            System.debug('Error Occurred ========> ' + e.getMessage() + 'Error Line Number Is ========> ' + e.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static Boolean leadThreshold(String recordId) {
        try {
            if (String.isNotBlank(recordId)) {
                Lead ld = [SELECT Id, Threshold_Count__c FROM Lead WHERE Id = :recordId LIMIT 1];
                String thresholdLabel = System.Label.Threshold_Count;
                Integer threshold = String.isNotBlank(thresholdLabel) ? Integer.valueOf(thresholdLabel) : 0;

                return ld.Threshold_Count__c >= threshold;
            }
            return false;
        } catch (Exception e) {
            System.debug('Error Occurred: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            return false;
        }
    }

    @AuraEnabled
    public static Task getRecentCallTask(Id leadId) {
        try{
            return [SELECT Id, Subject, Status, Sub_Status__c, OwnerId, ActivityDate FROM Task WHERE WhoId =: leadId AND Subject = 'Call' AND Status != 'Completed' ORDER BY CreatedDate DESC LIMIT 1];
        }catch(Exception e){
            System.debug(' error message'+ e.getMessage() + ' line no. '+ e.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static void handleTaskCompletion(Id taskId, Id leadId,String status, String subStatus, Date dueDate,String LostReason,String LostReasonFeedback) {
        try{
            Lead ld = [SELECT Id, Threshold_Count__c FROM Lead WHERE Id = :leadId];
            
            String thresholdLabel = System.Label.Threshold_Count;
            Integer threshold = thresholdLabel != null ? Integer.valueOf(thresholdLabel) : 0;

            Task originalTask = new Task(
                Id = taskId,
                Status = 'Completed',
                Sub_Status__c = subStatus
            );
            update originalTask;

            if (subStatus == 'RNR' || subStatus == 'Disconnected' || subStatus == 'Callback') {
                Task newTask = new Task(
                    Subject = 'Call',
                    WhoId = leadId,
                    OwnerId = UserInfo.getUserId(),
                    ActivityDate = subStatus == 'Callback' ? dueDate : Date.today().addDays(1)
                );
                insert newTask;
            }

            if (subStatus == 'RNR' || subStatus == 'Disconnected') {
                ld.Threshold_Count__c = ld.Threshold_Count__c == null ? 1 : ld.Threshold_Count__c + 1;
                if (ld.Threshold_Count__c >= threshold) {
                    ld.Status = 'Drop Out';
                    ld.Lost_Reason__c = LostReason;
                    ld.Lost_Feedback__c = LostReasonFeedback;
                }else{
                    ld.Status = 'RNR';
                }
                update ld;
            }else{
                 ld.Threshold_Count__c = ld.Threshold_Count__c == null ? 1 : ld.Threshold_Count__c + 1;
                 update ld;
            }
        }catch(Exception e){
            System.debug(' error message'+ e.getMessage() + ' line no. '+ e.getLineNumber());
        }
    }
}