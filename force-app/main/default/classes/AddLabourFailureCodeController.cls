public without sharing class AddLabourFailureCodeController {
    
    public class OperationResult {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        @AuraEnabled public String recordId;
        @AuraEnabled public String failureCodeName;
        
        public OperationResult(Boolean success, String msg) {
            this.isSuccess = success;
            this.message = msg;
        }
        
        public OperationResult(Boolean success, String msg, String id, String name) {
            this.isSuccess = success;
            this.message = msg;
            this.recordId = id;
            this.failureCodeName = name;
        }
    }
    
    @AuraEnabled
    //public static OperationResult createPostVINFCLabourVIN(String fcName, String labourCode, String newVINCutOff) {
    public static OperationResult createPostVINFCLabourVIN(String fcName, String labourCode, String newVINCutOff, Integer sampleRequired){

        try {
            System.debug('sampleRequired : ' + sampleRequired);

            // Validate input parameters
            if (String.isBlank(fcName) || String.isBlank(labourCode)) {
                return new OperationResult(false, 'Failure code name and labour code are required.');
            }
            
            // Find existing active failure code
            List<Failure_Code__c> fcList = [
                SELECT Id, Name, Labour_Code__c, VIN_Cut_off_No__c, VIN_Cut_off__c, Is_Active__c,CodeSetId__c
                FROM Failure_Code__c
                WHERE Name = :fcName
                AND CodeSetId__c = :labourCode 
                AND Is_Active__c = true
                LIMIT 1
            ];
            System.debug('****** fcList ****** : ' + fcList.size());
            
            if (fcList.isEmpty()) {
                OperationResult tfrResult;
                Integer stringLength = (newVINCutOff != null) ? newVINCutOff.length() : 0;
                
                if (stringLength == 17) {
                    tfrResult = checkandCreateVIN(newVINCutOff);
                    if (tfrResult == null || !tfrResult.isSuccess) {
                        return (tfrResult != null) ? tfrResult : new OperationResult(false, 'VIN check failed');
                    }
                }
                
                // Ensure recordId is not null
                if (tfrResult == null) {
                    tfrResult = new OperationResult(true, 'VIN not required');
                }
                tfrResult.recordId = (tfrResult.recordId != null) ? tfrResult.recordId : null;
                
                OperationResult labourEffectResult = checkLabourEffect(labourCode, tfrResult.recordId);
                if (labourEffectResult == null || !labourEffectResult.isSuccess) {
                    return (labourEffectResult != null) ? labourEffectResult : new OperationResult(false, 'Labour effect check failed');
                }
                
                OperationResult fcResult = createFailureCode(
                    fcName,
                    labourEffectResult.recordId,
                    tfrResult.recordId,
                    sampleRequired
                );
                return (fcResult != null) ? fcResult : new OperationResult(false, 'Failure code creation failed');
            }
            
            Failure_Code__c fc = fcList[0];
            System.debug('fc.VIN_Cut_off_No__c : ' + fc.VIN_Cut_off_No__c);
            Integer comparisonResult;
            
            if (fc.VIN_Cut_off__c != null) {
                
                System.debug('fc.VIN_Cut_off_No__c : ' + fc.VIN_Cut_off_No__c);
                System.debug('newVINCutOff : ' + newVINCutOff);
                
                // Compare VINs
                VINCutOffManagement.ComparisonResult compResult = 
                    VINCutOffManagement.compareVINFormat(fc.VIN_Cut_off_No__c, newVINCutOff);
                
                if (!compResult.isSuccess) {
                    return new OperationResult(false, 'VIN comparison failed: ' + compResult.message);
                }
                
                comparisonResult = compResult.resultCode;
                System.debug('comparisonResult : ' + comparisonResult);
                
                if (comparisonResult == 0) {
                    return new OperationResult(false, 'VIN cutoff already exists for this failure code.');
                } else if (comparisonResult == 1) {
                    // New VIN is greater - create new records
                    OperationResult tfrResult = checkandCreateVIN(newVINCutOff);
                    if (!tfrResult.isSuccess) return tfrResult;
                    
                    OperationResult labourEffectResult = checkLabourEffect(labourCode, tfrResult.recordId);
                    if (!labourEffectResult.isSuccess) return labourEffectResult;
                    
                    OperationResult fcResult = checkFailureCode(fc, fcName, labourEffectResult.recordId, tfrResult.recordId, sampleRequired);
                    return fcResult;
                } else if (comparisonResult == -1) {
                    return new OperationResult(false, 'New VIN is older than existing VIN cutoff.');
                }
            } else {
                /*
                // No VIN cutoff exists yet
                OperationResult fcResult = checkFailureCode(fc, null);
                return fcResult;
                */

                //No VIN cutoff exists yet
                OperationResult tfrResult = checkandCreateVIN(newVINCutOff);
                if (!tfrResult.isSuccess) return tfrResult;

                OperationResult fcResult = checkfailureCode(fc,tfrResult.recordId, sampleRequired);
                return fcResult;
            }
            
            return new OperationResult(false, 'Unexpected error occurred.');
        } catch (Exception e) {
            return new OperationResult(false, 'Error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
    
    private static OperationResult checkandCreateVIN(String newVINCutOff) {
        try {
            List<TFR__c> tfrList = [
                SELECT Id, Name FROM TFR__c WHERE VIN_Start__c = :newVINCutOff LIMIT 1
            ];
            
            if (!tfrList.isEmpty()) {
                return new OperationResult(true, 'TFR already exists', tfrList[0].Id, null);
            }
            
            TFR__c newTFR = new TFR__c(
                VIN_Start__c = newVINCutOff,
                Is_Active__c = true
            );
            insert newTFR;
            return new OperationResult(true, 'Created new TFR', newTFR.Id, null);
        } catch (Exception e) {
            return new OperationResult(false, 'Error creating TFR: ' + e.getMessage());
        }
    }
    
    private static OperationResult checkLabourEffect(String labourCode, String tfrId) {
        try {
            List<TFR_Labour_Effect__c> leList = [
                SELECT Id, Name, Labour_Code__c 
                FROM TFR_Labour_Effect__c 
                WHERE TFR__c = :tfrId AND Labour_Code__c = :labourCode 
                LIMIT 1
            ];
            
            if (!leList.isEmpty()) {
                return new OperationResult(true, 'Labour effect already exists', leList[0].Id, null);
            }
            
            List<CodeSet> codeSetList = [SELECT Id, Name FROM CodeSet WHERE Id = :labourCode AND IsActive = true LIMIT 1];
            if (codeSetList.isEmpty()) {
                return new OperationResult(false, 'No active Labour Code found with code: ' + labourCode);
            }
            
            TFR_Labour_Effect__c labourEffect = new TFR_Labour_Effect__c(
                Code_Set__c = codeSetList[0].Id,
                TFR__c = tfrId
            );
            insert labourEffect;
            return new OperationResult(true, 'Created new labour effect', labourEffect.Id, null);
        } catch (Exception e) {
            return new OperationResult(false, 'Error creating labour effect: ' + e.getMessage());
        }
    } 
    
    private static OperationResult checkFailureCode(Failure_Code__c OldFC, String fcName, String labourEffectId, String tfrId, Integer batchSize) {
        try {
            Failure_Code__c newFC = new Failure_Code__c(
                Name = fcName,
                Batch_Size__c = batchSize, 
                Is_Active__c = true,
                TFR_Labour_Effect__c = labourEffectId,
                VIN_Cut_off__c = tfrId
            );
            insert newFC;
            
            OldFC.Is_Active__c = false;
            //OldFc.VIN_Cut_off__c = tfrId;
            update OldFC;
            
            return new OperationResult(true, 'Created new failure code and deactivated old one', newFC.Id, fcName);
        } catch (Exception e) {
            return new OperationResult(false, 'Error creating failure code: ' + e.getMessage());
        }
    }
    
    private static OperationResult createFailureCode(String fcName, String labourEffectId, String tfrId, Integer batchSize) {
        try {
            Failure_Code__c newFC = new Failure_Code__c(
                Name = fcName,
                Batch_Size__c = batchSize, 
                Is_Active__c = true,
                TFR_Labour_Effect__c = labourEffectId,
                VIN_Cut_off__c = tfrId
            );
            insert newFC;
            
            return new OperationResult(true, 'Created new failure code', newFC.Id, fcName);
        } catch (Exception e) {
            return new OperationResult(false, 'Error creating failure code: ' + e.getMessage());
        }
    }
    
    private static OperationResult checkFailureCode(Failure_Code__c OldFC, String tfrId, Integer batchSize) {
        try {
            System.debug('EXECUTING CHECKFAILURECODE WITH 3 PARAMETERS : ' + batchSize);
            OldFC.VIN_Cut_off__c = tfrId;
            OldFC.Batch_Size__c = batchSize;
            update OldFC;
            System.debug('After Updating OlfFC : ' + OldFC.Batch_Size__c);

            return new OperationResult(true, 'Updated failure code with VIN cutoff', OldFC.Id, OldFC.Name);
        } catch (Exception e) {
            return new OperationResult(false, 'Error updating failure code: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static OperationResult validateInputs(String fcName, String labourCode, String newVINCutOff) {
        try {
            if (String.isBlank(fcName)) {
                return new OperationResult(false, 'Failure code name is required.');
            }
            
            if (String.isBlank(labourCode)) {
                return new OperationResult(false, 'Labour code is required.');
            }
            
            // Validate VIN format if provided
            if (!String.isBlank(newVINCutOff)) {
                VINCutOffManagement.ComparisonResult vinResult = VINCutOffManagement.validateVIN(newVINCutOff);
                System.debug('vinResult : ' + vinResult);
                
                if (!vinResult.isSuccess) {
                    return new OperationResult(false, 'Invalid VIN format: ' + vinResult.message);
                }
            }
            
            // Check if labour code exists in CodeSet
            List<CodeSet> codeSets = [SELECT Id FROM CodeSet WHERE Id = :labourCode AND IsActive = true LIMIT 1];
            if (codeSets.isEmpty()) {
                return new OperationResult(false, 'Active labour code not found: ' + labourCode);
            }
            
            return new OperationResult(true, 'Input validation successful');
        } catch (Exception e) {
            return new OperationResult(false, 'Validation error: ' + e.getMessage());
        }
    }
}