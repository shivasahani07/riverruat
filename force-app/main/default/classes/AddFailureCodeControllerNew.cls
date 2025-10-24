public without sharing class AddFailureCodeControllerNew {
    
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
    public static OperationResult createPostVINFCPCVIN(String fcName, String productcode, String newVINCutOff, Integer batchSize) {
        try {
            System.debug('-----------------createPostVINFCPCVIN-----------------');
            System.debug('fcName: ' + fcName);
            System.debug('productcode: ' + productcode);
            System.debug('newVINCutOff: ' + newVINCutOff);
            System.debug('batchSize: ' + batchSize);

            // Validate input parameters
            if (String.isBlank(fcName) || String.isBlank(productcode)) {
                return new OperationResult(false, 'Failure code name, product code are required.');
            }
            
            // Find existing active failure code
            List<Failure_Code__c> fcList = [
                SELECT Id, Name, Product_Code__c, VIN_Cut_off_No__c, VIN_Cut_off__c, Is_Active__c
                FROM Failure_Code__c
                WHERE Name = :fcName
                AND (Product_Code__c = :productcode OR Productid__c = :productcode ) 
                AND Is_Active__c = true
                LIMIT 1
            ];
            System.debug('****** fcList ****** : ' + fcList.size());
            
            
            if (fcList.isEmpty()) {
                OperationResult tfrResult;
                Integer stringLength = (newVINCutOff != null) ? newVINCutOff.length() : 0;
                System.debug('String Length: ' + stringLength);
                
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
                
                OperationResult partEffectResult = checkCausalPartEF(productcode, tfrResult.recordId);
                if (partEffectResult == null || !partEffectResult.isSuccess) {
                    return (partEffectResult != null) ? partEffectResult : new OperationResult(false, 'Causal part check failed');
                }
                
                OperationResult fcResult = createFailureCode(
                    fcName,
                    partEffectResult.recordId,
                    tfrResult.recordId,
                    batchSize
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
                
                System.debug('compResult : ' + compResult);
                
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
                    
                    OperationResult partEffectResult = checkCausalPartEF(productcode, tfrResult.recordId);
                    if (!partEffectResult.isSuccess) return partEffectResult;
                    
                    OperationResult fcResult = checkfailureCode(fc, fcName, partEffectResult.recordId, tfrResult.recordId, batchSize);
                    return fcResult;
                } else if (comparisonResult == -1) {
                    return new OperationResult(false, 'New VIN is older than existing VIN cutoff.');
                }
            } else {
                 //No VIN cutoff exists yet
                OperationResult tfrResult = checkandCreateVIN(newVINCutOff);
                if (!tfrResult.isSuccess) return tfrResult;
                
                OperationResult fcResult = checkfailureCode(fc,tfrResult.recordId);
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
    
    private static OperationResult checkCausalPartEF(String productcode, String tfrId) {
        try {
            List<TFR_Part_Effect__c> peList = [
                SELECT Id, Name, Product_Code__c 
                FROM TFR_Part_Effect__c 
                WHERE TFR__c = :tfrId AND Product__c = :productcode 
                LIMIT 1
            ];
            
            if (!peList.isEmpty()) {
                return new OperationResult(true, 'Part effect already exists', peList[0].Id, null);
            }
            
            List<Product2> prodList = [SELECT Id, Name FROM Product2 WHERE id = :productcode LIMIT 1];
            if (prodList.isEmpty()) {
                return new OperationResult(false, 'No Product found with code: ' + productcode);
            }
            
            TFR_Part_Effect__c partEffect = new TFR_Part_Effect__c(
                Product__c = prodList[0].Id,
                TFR__c = tfrId
            );
            insert partEffect;
            return new OperationResult(true, 'Created new part effect', partEffect.Id, null);
        } catch (Exception e) {
            return new OperationResult(false, 'Error creating part effect: ' + e.getMessage());
        }
    } 
    
    private static OperationResult checkfailureCode(Failure_Code__c OldFC, String fcName, String partEffectId, String tfrId, Integer batchSize) {
        System.debug('--------------------- checkfailureCode ---------------------');
        System.debug('batchSize : ' + batchSize);

        try {
            Failure_Code__c newFC = new Failure_Code__c(
                Name = fcName,
                Batch_Size__c = batchSize, 
                Is_Active__c = true,
                TFR_Part_Effect__c = partEffectId,
                VIN_Cut_off__c = tfrId
            );
            insert newFC;
            
            OldFC.Is_Active__c = false;
            update OldFC;
            
            return new OperationResult(true, 'Created new failure code and deactivated old one', newFC.Id, fcName);
        } catch (Exception e) {
            return new OperationResult(false, 'Error creating failure code: ' + e.getMessage());
        }
    }
    
    private static OperationResult createFailureCode(String fcName, String partEffectId, String tfrId, Integer batchSize) {
        try {
            Failure_Code__c newFC = new Failure_Code__c(
                Name = fcName,
                Batch_Size__c = batchSize, 
                Is_Active__c = true,
                TFR_Part_Effect__c = partEffectId,
                VIN_Cut_off__c = tfrId
            );
            insert newFC;
            
            return new OperationResult(true, 'Created new failure code', newFC.Id, fcName);
        } catch (Exception e) {
            return new OperationResult(false, 'Error creating failure code: ' + e.getMessage());
        }
    }
    
    private static OperationResult checkfailureCode(Failure_Code__c OldFC, String tfrId) {
        try {
            OldFC.VIN_Cut_off__c = tfrId;
            update OldFC;
            return new OperationResult(true, 'Updated failure code with VIN cutoff', OldFC.Id, OldFC.Name);
        } catch (Exception e) {
            return new OperationResult(false, 'Error updating failure code: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static OperationResult validateInputs(String fcName, String productcode, String newVINCutOff) {
        try {
            if (String.isBlank(fcName)) {
                return new OperationResult(false, 'Failure code name is required.');
            }
            
            if (String.isBlank(productcode)) {
                return new OperationResult(false, 'Product code is required.');
            }
            
            /*if (String.isBlank(newVINCutOff)) {
                return new OperationResult(false, 'VIN cutoff is required.');
            }*/
            
            // Validate VIN format
            VINCutOffManagement.ComparisonResult vinResult;
            if(newVINCutOff !=null){
                vinResult = VINCutOffManagement.validateVIN(newVINCutOff);
            }
            
            if (!vinResult.isSuccess) {
                
                //return new OperationResult(false, 'Invalid VIN format: ' + vinResult.message);
            }
            
            // Check if product exists
            List<Product2> products = [SELECT Id FROM Product2 WHERE Id = :productcode and IsActive =true LIMIT 1];
            if (products.isEmpty()) {
                return new OperationResult(false, 'Product code not found: ' + productcode);
            }
            
            return new OperationResult(true, 'Input validation successful');
        } catch (Exception e) {
            return new OperationResult(false, 'Validation error: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<TFR_Labour_Effect__c> getTFRLabourEffects(Id failureCodeId) {
        return [
            SELECT Id, Name, Labour_Code__c, Code_Set__c, VIN_Cut_off__c, Code_Set__r.Name, Code_Set__r.Code, Code_Set__r.CodeSetType, 
            Failure_Code__c, Failure_Code__r.Name, Active__c
            FROM TFR_Labour_Effect__c
            WHERE Failure_Code__c = :failureCodeId
            AND Active__c = true
        ];
    }

    @AuraEnabled
    public static void CreateLabourCodeForFalireCodes(string failureCodeId, List<String> CodesetsIds){
        try {
            Failure_Code__c activateFC = NEW Failure_Code__c(Id=failureCodeId,Status__c='Activate');
            list<TFR_Labour_Effect__c> tfrLabourEffectTobeinserted = new list<TFR_Labour_Effect__c>();
            for(string codeIds :CodesetsIds){
                TFR_Labour_Effect__c labourEffect = new TFR_Labour_Effect__c(
                    Code_Set__c =codeIds,
                    Failure_Code__c = failureCodeId,
                    Active__c = true
                );
                tfrLabourEffectTobeinserted.add(labourEffect);
            }
            if(tfrLabourEffectTobeinserted.size()>0){
                    insert tfrLabourEffectTobeinserted;
                    update activateFC;
                }
        } catch (Exception ex) {
            System.debug('Error while creating TFR_Labour_Effect__c failure codes---'+ex.getMessage() +'at line ---'+ex.getLineNumber());
        }
        
    }

    @AuraEnabled
    public static List<Failure_Code__c> searchFailureCodes(String searchKey,String productid) {
        return [
            SELECT Id,ProductId__c,Product_Name__c,VIN_Cut_off_No__c,Name
            FROM Failure_Code__c
            WHERE Name LIKE :('%' + searchKey + '%')
            AND productid__c =:productid
            LIMIT 10
        ];
    }

    @AuraEnabled
    public static List<Failure_Code__c> searchlabourFailureCodes(String searchKey,String codesetid) {
        return [
            SELECT Id,ProductId__c,Product_Name__c,VIN_Cut_off_No__c,Name,CodeSetId__c
            FROM Failure_Code__c
            WHERE Name LIKE :('%' + searchKey + '%')
            AND CodeSetId__c =:codesetid
            LIMIT 10
        ];
    }


}