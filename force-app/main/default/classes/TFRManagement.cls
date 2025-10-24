public without sharing class TFRManagement {
    
    @AuraEnabled(cacheable=true)
    public static List<Failure_Code__c> getFailureCodes() {
        return [
            SELECT Id, Name, Batch_Size__c, Sample_Collected__c, Is_Active__c, 
            TFR_Part_Effect__c, TFR_Part_Effect__r.Product__r.Name, 
            TFR_Part_Effect__r.Product__r.ProductCode, TFR_Labour_Effect__c,
            TFR_Labour_Effect__r.Code_Set__r.Name, TFR_Labour_Effect__r.Code_Set__r.Code,
            VIN_Cut_off__c, VIN_Cut_off__r.Is_Active__c, VIN_Cut_off__r.VIN_Start__c,
            CreatedBy.Name, CreatedDate, FPV_Validation__c, Type__c
            FROM Failure_Code__c
            WHERE (TFR_Part_Effect__c != NULL OR TFR_Labour_Effect__c != NULL)
            ORDER BY CreatedDate DESC
            LIMIT 1000
        ];
    }
    
    @AuraEnabled
    public static void deleteFailureCode(Id recordId) {
        delete [SELECT Id FROM Failure_Code__c WHERE Id = :recordId];
    }
    
    @AuraEnabled
    public static TFRValidationResult checkTFRValidation(String VINno, String FailureCodeId) {
        try {
            // First, check if failure code exists regardless of VIN
            Failure_Code__c fc;
            
            
            fc = [SELECT Id, Name, Is_Active__c, TFR_Part_Effect__c, 
                  TFR_Part_Effect__r.TFR__r.VIN_Start__c,VIN_Cut_off_No__c,
                  TFR_Part_Effect__r.Product__r.ProductCode,Status__c
                  FROM Failure_Code__c 
                  WHERE Id = :FailureCodeId limit 1];
            
            
            // If no VIN provided, just check if failure code is active
            if (String.isBlank(VINno)) {
                return new TFRValidationResult(
                    fc.Is_Active__c, 
                    false,
                    fc.Is_Active__c ? 'Active failure code' : 'Inactive failure code'
                );
            }
            
            // If VIN is provided, perform VIN-based validation
            String vinCutoff;
            
            //vinCutoff = fc.TFR_Part_Effect__c != null ? fc.TFR_Part_Effect__r.TFR__r.VIN_Start__c : null;
            vinCutoff = fc.VIN_Cut_off_No__c;
            if (vinCutoff != null) {
                VINCutOffManagement.ComparisonResult result = VINCutOffManagement.compareVINFormat(vinCutoff,VINno);
                
                boolean isTFRApplicable=fc.Status__c=='TFR Completed'? false:true;
                return new TFRValidationResult(isTFRApplicable, result.isSuccess && result.resultCode == 1, result.message);
            }
            
            // No VIN cutoff defined for this failure code
            return new TFRValidationResult(true, false, 'No VIN cutoff defined for this failure code');
        } catch (Exception e) {
            system.debug('Error at'+ e.getLineNumber());
            return new TFRValidationResult(false, false, 'Error: ' + e.getMessage());
        }
    }
    
    public class TFRValidationResult {
        @AuraEnabled public Boolean isTFRApplicable;
        @AuraEnabled public Boolean isPostVinCuttoff;
        @AuraEnabled public String message;
        
        public TFRValidationResult(Boolean applicable, Boolean postCutoff, String msg) {
            isTFRApplicable = applicable;
            isPostVinCuttoff = postCutoff;
            message = msg;
        }
    }
    
    @AuraEnabled
    public static actionPlanWrapper VeripartWithActionWithPlanApex(String workOrderId) {
        try {
            actionPlanWrapper prepareData = new actionPlanWrapper();
            Set<String> allAPTids = new Set<String>();
            
            List<ActionPlan> ins = [SELECT Id, Name, To_be_Completed_in_JC__c, 
                                    ActionPlanTemplateVersion.Name, Field_Fix__r.Action_Plan_Template__c
                                    FROM ActionPlan
                                    WHERE Job_Card__c = :workOrderId
                                    AND To_be_Completed_in_JC__c = false];
            
            for (ActionPlan aps : ins) {
                allAPTids.add(aps.Field_Fix__r.Action_Plan_Template__c);
            }
            
            List<Required_Labour__c> RequiredLabours = [SELECT Id, Code_Set__c 
                                                        FROM Required_Labour__c 
                                                        WHERE Action_Plan_Template__c IN :allAPTids];
            
            List<Required_Product__c> RequiredProducts = [SELECT Id, Product__c 
                                                          FROM Required_Product__c 
                                                          WHERE Action_Plan_Template__c IN :allAPTids];
            
            prepareData.RequiredLabours = RequiredLabours;
            prepareData.RequiredProducts = RequiredProducts;
            return prepareData;
        } catch (Exception ex) {
            throw new AuraHandledException('Error in VeripartWithActionWithPlanApex: ' + ex.getMessage());
        }
    }
    
    public class actionPlanWrapper {
        @AuraEnabled public List<Required_Labour__c> RequiredLabours;
        @AuraEnabled public List<Required_Product__c> RequiredProducts;
    }
    
    @future
    public static void addSampleSizeONjcCloser(List<Id> closedJcIds) {
        if (closedJcIds == null || closedJcIds.isEmpty()) {
            return;
        }
        
        // Step 1: Collect Failure_Code__c IDs from related TFR_Sample__c
        Set<Id> failureCodeIds = new Set<Id>();
        for (TFR_Sample__c sample : [
            SELECT Failure_Code__c 
            FROM TFR_Sample__c 
            WHERE Job_Card__c IN :closedJcIds 
            AND Failure_Code__c != null
        ]) {
            failureCodeIds.add(sample.Failure_Code__c);
        }
        
        if (failureCodeIds.isEmpty()) {
            return;
        }
        
        // Step 2: Fetch Failure_Code__c records
        List<Failure_Code__c> failureCodes = [
            SELECT Id, Name, Sample_Collected__c, Batch_Size__c, Status__c
            FROM Failure_Code__c
            WHERE Id IN :failureCodeIds
        ];
        
        // Step 3: Update Sample_Collected__c and Status__c
        for (Failure_Code__c fc : failureCodes) {
            // Increment Sample_Collected__c by 1 for each related Job Card closed
            // (if that’s the logic you want)
            fc.Sample_Collected__c = (fc.Sample_Collected__c == null ? 0 : fc.Sample_Collected__c) + 1;
            
            // If collected samples meet or exceed batch size, mark as closed
            if (fc.Batch_Size__c != null && fc.Sample_Collected__c >= fc.Batch_Size__c) {
                fc.Status__c = 'Closed';
            }
        }
        
        // Step 4: Perform DML update
        if (!failureCodes.isEmpty()) {
            update failureCodes;
        }
    }
    
    
}