public without sharing class AddFailureCodeController {
    
    
    public class SaveFailureCodeResult {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        
        public SaveFailureCodeResult(Boolean success, String msg) {
            this.isSuccess = success;
            this.message = msg;
        }
    }
    
    
    public class CustomException extends Exception {}
    
    @AuraEnabled
    public static List<SaveFailureCodeResult> saveFailureCodeRecords(List<FailureCodeWrapper> fCodes) {
        List<SaveFailureCodeResult> results = new List<SaveFailureCodeResult>();
        
        if (fCodes == null || fCodes.isEmpty()) {
            results.add(new SaveFailureCodeResult(false, 'No data received'));
            return results;
        }
        
        for (FailureCodeWrapper f : fCodes) {
            Integer fFCodeResult;
            try {
                // Step 1: Find or create TFR
                TFR__c tfr;
                try {
                    tfr = [
                        SELECT Id, Name
                        FROM TFR__c
                        WHERE VIN_Start__c = :f.vinCutOff
                        LIMIT 1
                    ];
                } catch (QueryException qe) {
                    tfr = null;
                }
                
                if (tfr == null) {
                    tfr = new TFR__c(
                        VIN_Start__c = f.vinCutOff,
                        Is_Active__c = true
                    );
                    insert tfr;
                    results.add(new SaveFailureCodeResult(true, 'Created new TFR for VIN ' + f.vinCutOff));
                }
                
                // Step 2: Find or create Part Effect
                TFR_Part_Effect__c partEffect;
                try {
                    partEffect = [
                        SELECT Id, Name, Product_Code__c
                        FROM TFR_Part_Effect__c
                        WHERE TFR__c = :tfr.Id
                        AND Product_Code__c = :f.productCode
                        LIMIT 1
                    ];
                } catch (QueryException qe) {
                    partEffect = null;
                }
                
                Product2 prod;
                if (partEffect == null) {
                    prod = [SELECT Id, Name FROM Product2 WHERE ProductCode = :f.productCode LIMIT 1];
                    partEffect = new TFR_Part_Effect__c(
                        Product__c = prod.Id,
                        TFR__c = tfr.Id
                    );
                    insert partEffect;
                    results.add(new SaveFailureCodeResult(true, 'Created new Part Effect for ' + f.productCode));
                }
                
                // Step 3: Check for existing Failure Code
                Failure_Code__c existing;
                try {
                    existing = [
                        SELECT Id, Name
                        FROM Failure_Code__c
                        WHERE TFR_Part_Effect__c = :partEffect.Id
                        AND Name = :f.fName
                        LIMIT 1
                    ];
                } catch (QueryException qe) {
                    existing = null;
                }
                
                if (existing != null) {
                    
                    //getFailureCode(existing, f.fName, f.productCode, f.vinCutOff, prod.Id);
                    
                    throw new CustomException('Duplicate Failure Code "' + f.fName + '" already exists.');
                }
                
                /*
// Step 4: Create Failure Code
Failure_Code__c newFC = new Failure_Code__c(
Name = f.fName,
Batch_Size__c = (String.isNotBlank(f.batchSize) ? Decimal.valueOf(f.batchSize) : null),
Is_Active__c = f.isActive,
TFR_Part_Effect__c = partEffect.Id
);
insert newFC;
*/
                results.add(new SaveFailureCodeResult(true, 'Inserted Failure Code "' + f.fName + '" successfully'));
                
            } catch (CustomException ce) {
                results.add(new SaveFailureCodeResult(false, ce.getMessage()));
            } catch (Exception e) {
                results.add(new SaveFailureCodeResult(false, 'Error for "' + f.fName + '": ' + e.getMessage()));
            }
        }
        
        return results;
    }
    
    
    
    public class FailureCodeWrapper {
        @AuraEnabled public String fName {get; set;}
        @AuraEnabled public String batchSize {get; set;}
        @AuraEnabled public Boolean isActive {get; set;}
        @AuraEnabled public String productCode {get; set;}
        @AuraEnabled public String vinCutOff {get; set;}
        @AuraEnabled public String failureCodeId {get; set;} // For update case
    }
    
    @AuraEnabled(cacheable=true)
    public static List<FailureCodeWrapper> getFailureCodes() {
        List<FailureCodeWrapper> result = new List<FailureCodeWrapper>();
        
        for(Failure_Code__c fc : [
            SELECT Id, Name, Batch_Size__c, Is_Active__c,
            TFR_Part_Effect__r.Product__r.ProductCode,
            VIN_Cut_off__r.VIN_Start__c, VIN_Cut_off__r.Is_Active__c
            FROM Failure_Code__c
            LIMIT 100
        ]){
            FailureCodeWrapper wrap = new FailureCodeWrapper();
            wrap.fName = fc.Name;
            wrap.batchSize = String.valueOf(fc.Batch_Size__c);
            wrap.isActive = fc.Is_Active__c;
            wrap.productCode = (fc.TFR_Part_Effect__r != null && fc.TFR_Part_Effect__r.Product__r != null) 
                ? fc.TFR_Part_Effect__r.Product__r.ProductCode : null;
            wrap.vinCutOff = (fc.VIN_Cut_off__r != null) ? fc.VIN_Cut_off__r.VIN_Start__c : null;
            wrap.failureCodeId = fc.Id;
            result.add(wrap);
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Failure_Code__c> getExistingFailureCodes(list<String> failureNames, list<String> productCodes) {
        return [
            SELECT Id, Name,
            TFR_Part_Effect__r.Product__r.ProductCode,
            VIN_Cut_off__c, VIN_Cut_off__r.VIN_Start__c, VIN_Cut_off__r.Is_Active__c
            FROM Failure_Code__c
            WHERE Name IN :failureNames
            OR TFR_Part_Effect__r.Product__r.ProductCode IN :productCodes
        ];
    }
    
    @AuraEnabled
    public static String saveFailureCodes(List<FailureCodeWrapper> codes) {
        try {
            List<Failure_Code__c> toUpsert = new List<Failure_Code__c>();
            
            for(FailureCodeWrapper w : codes){
                Failure_Code__c fc = (String.isNotBlank(w.failureCodeId))
                    ? new Failure_Code__c(Id = w.failureCodeId)
                    : new Failure_Code__c();
                
                fc.Name = w.fName;
                fc.Batch_Size__c = (String.isNotBlank(w.batchSize)) ? Decimal.valueOf(w.batchSize) : null;
                fc.Is_Active__c = w.isActive;
                
                // TODO: set lookup fields (Product, VIN Cut-Off) if you pass IDs from UI
                toUpsert.add(fc);
            }
            
            if(!toUpsert.isEmpty()){
                upsert toUpsert;
            }
            return 'Success';
        }catch(Exception ex){
            throw new AuraHandledException(
                'Line Number : ' + ex.getLineNumber() + ' Error : ' + ex.getMessage()
            );
        }
    }
    
    // Return Failure Code record
    @AuraEnabled
    public static List<Failure_Code__c> getFailureCode(String tfrPEId){
        
        return [
            SELECT Id, Name, VIN_Cut_off_No__c, TFR_Part_Effect__c, Product_Name__c, Product_Code__c
            FROM Failure_Code__c
            WHERE TFR_Part_Effect__c = :tfrPEId
            And Is_Active__c = true
        ];
    }
    
    @AuraEnabled
    public static Failure_Code__c getFailureCodeNew(String vinCutOff, String productCode){
        
        return [
            SELECT Id, Name, VIN_Cut_off_No__c, TFR_Part_Effect__c, Product_Name__c, Product_Code__c
            FROM Failure_Code__c
            WHERE VIN_Cut_off_No__c = :vinCutOff
            AND Product_Code__c = :productCode
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static List<Failure_Code__c> getFailureCodeUpdated(String productId, String newVIN){
        
        System.debug('productId : ' + productId);
        /*
        List<Failure_Code__c> lstFC = [
            SELECT Id, Name, VIN_Cut_off_No__c, VIN_Cut_off__c, VIN_Cut_off__r.VIN_Start__c, TFR_Part_Effect__c, Product_Name__c, Product_Code__c
            FROM Failure_Code__c
            WHERE TFR_Part_Effect__c = :tfrPEId
            And Is_Active__c = true
        ];
        */
        List<Failure_Code__c> lstFC = [
            SELECT Id, Name, VIN_Cut_off_No__c, VIN_Cut_off__c, VIN_Cut_off__r.VIN_Start__c, TFR_Part_Effect__c, Product_Name__c, Product_Code__c, TFR_Part_Effect__r.Product__c
            FROM Failure_Code__c
            WHERE TFR_Part_Effect__r.Product__c = :productId
            AND Status__c !='Closed'
            And Is_Active__c = true
        ];

        System.debug('lstFC : ' + lstFC);
        System.debug('lstFC Size : ' + lstFC.size());
        System.debug('newVIN : ' + newVIN);


        List<Failure_Code__c> fcToReturn = new List<Failure_Code__c>();

        for(Failure_Code__c fc : lstFC){

            if (String.isBlank(fc.VIN_Cut_off__r.VIN_Start__c)) {
                fcToReturn.add(fc);
                continue;
            }

            VINCutOffManagement.ComparisonResult cResult = VINCutOffManagement.compareVINFormat(fc.VIN_Cut_off__r.VIN_Start__c, newVIN);
            System.debug('cResult :  ' + cResult);

            // if(cResult != null && (cResult.resultCode == -1 || cResult.resultCode == -99)){
            if(cResult != null && cResult.resultCode == 1){
                fcToReturn.add(fc);
            }
        }
        System.debug('fcToReturn : ' + fcToReturn.size());
        return fcToReturn;
        
    }
    
    
    @AuraEnabled
    public static void processFailureCodes() {
        List<Failure_Code__c> allCodes = [
            SELECT Id, Name, VIN_Cut_off_No__c, Product_Name__c, Product_Code__c, Is_Active__c
            FROM Failure_Code__c
            WHERE VIN_Cut_off_No__c != null
        ];
        
        Map<String, List<Failure_Code__c>> groupedMap = new Map<String, List<Failure_Code__c>>();
        
        for (Failure_Code__c fc : allCodes) {
            String key = fc.Product_Code__c + '::' + fc.Name;  // Product Code + Failure Code Name
            
            if (!groupedMap.containsKey(key)) {
                groupedMap.put(key, new List<Failure_Code__c>());
            }
            groupedMap.get(key).add(fc);
        }
        
        List<Failure_Code__c> toUpdate = new List<Failure_Code__c>();
        
        for (String key : groupedMap.keySet()) {
            List<Failure_Code__c> fcGroup = groupedMap.get(key);
            
            Failure_Code__c highest;
            Integer maxVin = -1;
            
            // Find the record with the highest VIN cutoff
            for (Failure_Code__c fc : fcGroup) {
                if (fc.VIN_Cut_off_No__c != null && fc.VIN_Cut_off_No__c.length() >= 6) {
                    Integer vinNum = Integer.valueOf(fc.VIN_Cut_off_No__c.right(6));
                    
                    if (vinNum > maxVin) {
                        maxVin = vinNum;
                        highest = fc;
                    }
                }
            }
            
            // Mark highest as active, others as inactive
            for (Failure_Code__c fc : fcGroup) {
                if (fc.Id == highest.Id) {
                    if (fc.Is_Active__c != true) {
                        fc.Is_Active__c = true;
                        toUpdate.add(fc);
                    }
                } 
                /*
else {
if (fc.Is_Active__c != false) {
fc.Is_Active__c = false;
toUpdate.add(fc);
}
}
*/
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
    
    public static String getFailureCode(Failure_Code__c fcData, String fcName, String prodCode, String newVINCutOff, String productId){
        
        /*
Failure_Code__c fcData = [
SELECT Id, Name, Product_Code__c, VIN_Cut_off_No__c
FROM Failure_Code__c
WHERE Name = :fcName
AND Product_Code__c = :prodCode
LIMIT 1
];
*/
        System.debug('fcData : ' + fcData);
        
        // Calling the VIN Comparision Method
        System.debug('Calling the VIN Comparision Method');
         VINCutOffManagement.ComparisonResult compResult = VINCutOffManagement.compareVINFormat(fcData.VIN_Cut_off_No__c, newVINCutOff);
        Integer comparisonResult;
        System.debug('comparisonResult : ' + comparisonResult);
        
        if(comparisonResult == 0){
            System.debug('PreVIN and PostVIN are SAME !!');
            
        }else if(comparisonResult == 1){
            System.debug('PostVIN is GREATER !!');
            
            // Create Records
            createPostVINFCPCVIN(fcData, fcName, prodCode, newVINCutOff, productId);
            
            
        }else if(comparisonResult == -1){
            System.debug('PostVIN is SMALLER !!');
        }else{
            System.debug('Invalid Result !!');
        }
        
        return 'Success';
    }
    
    
    public static void createPostVINFCPCVIN(Failure_Code__c fcData, String fcName, String prodCode, String newVINCutOff, String productId){
        
        Failure_Code__c fc = [
            SELECT Id, Name, Product_Code__c, VIN_Cut_off_No__c, VIN_Cut_off__c
            FROM Failure_Code__c
            WHERE Name = :fcName
            AND Product_Code__c = :prodCode
            LIMIT 1
        ];
        
        
        
        // Check for VIN Duplication
        Integer comparisonResult;
        
        if(fc != null && fc.VIN_Cut_off__c != null){
            VINCutOffManagement.ComparisonResult compResult = VINCutOffManagement.compareVINFormat(fcData.VIN_Cut_off_No__c, newVINCutOff);
        
            System.debug('comparisonResult : ' + comparisonResult);
            
            if(comparisonResult == 1){
                System.debug('PostVIN is GREATER !!');
                
                TFR__c existingTFR = [
                    SELECT Id, Name
                    FROM TFR__c
                    WHERE VIN_Start__c = :newVINCutOff
                    LIMIT 1
                ];
                
                if(existingTFR != null){
                    TFR_Part_Effect__c partEffect = [
                        SELECT Id, Name, Product_Code__c
                        FROM TFR_Part_Effect__c
                        WHERE TFR__c = :existingTFR.Id
                        AND Product_Code__c = :prodCode
                        LIMIT 1
                    ];
                    
                    if(partEffect != null){
                        Failure_Code__c newFC = new Failure_Code__c(
                            Name = 'Test',
                            //Batch_Size__c = (String.isNotBlank(f.batchSize) ? Decimal.valueOf(f.batchSize) : null),
                            Is_Active__c = true,
                            TFR_Part_Effect__c = partEffect.Id,
                            VIN_Cut_off__c = existingTFR.Id
                        );
                        insert newFC;
                    }
                    else{
						TFR_Part_Effect__c partEffectNew = new TFR_Part_Effect__c(
                            Product__c = productId,
                            TFR__c = existingTFR.Id
                        );
                        insert partEffectNew;
                        
                        Failure_Code__c newFC = new Failure_Code__c(
                            Name = 'Test',
                            //Batch_Size__c = (String.isNotBlank(f.batchSize) ? Decimal.valueOf(f.batchSize) : null),
                            Is_Active__c = true,
                            TFR_Part_Effect__c = partEffect.Id,
                            VIN_Cut_off__c = existingTFR.Id
                        );
                        insert newFC;
                    }
                      
                }
                else{
                	TFR__c newTFR;
                    if (existingTFR == null) {
                        newTFR = new TFR__c(
                            VIN_Start__c = newVINCutOff,
                            Is_Active__c = true
                        );
                        insert newTFR;
                    }
                    else{
                        fc.VIN_Cut_off__c = existingTFR.Id;
                    }   
                }
                
                

                
                TFR_Part_Effect__c partEffect = new TFR_Part_Effect__c(
                    Product__c = productId,
                    TFR__c = existingTFR.Id
                );
                insert partEffect;
                
                
                
                fc.Is_Active__c = FALSE;
                update fc;
                
                
            }
        }
        
        else if(fc != null && fc.VIN_Cut_off__c == null){
            // Search for existing VIN
            TFR__c existingTFR = [
                SELECT Id, Name
                FROM TFR__c
                WHERE VIN_Start__c = :newVINCutOff
                LIMIT 1
            ];
            
            TFR__c newTFR;
            if (existingTFR == null) {
                newTFR = new TFR__c(
                    VIN_Start__c = newVINCutOff,
                    Is_Active__c = true
                );
                insert newTFR;
            }
            else{
                fc.VIN_Cut_off__c = existingTFR.Id;
            }   
        }
        
        if(comparisonResult == 0){
            System.debug('PreVIN and PostVIN are SAME !!');
            
        }
        else if(comparisonResult == 1){
            System.debug('PostVIN is GREATER !!');
            
            // Create Records
            // createPostVINFCPCVIN(fcData, fcName, prodCode, newVINCutOff, productId);
            
            TFR__c tfr = new TFR__c(
                VIN_Start__c = newVINCutOff,
                Is_Active__c = true
            );
            insert tfr;
            
            TFR_Part_Effect__c partEffect = new TFR_Part_Effect__c(
                Product__c = productId,
                TFR__c = tfr.Id
            );
            insert partEffect;
            
            Failure_Code__c newFC = new Failure_Code__c(
                Name = 'Test',
                //Batch_Size__c = (String.isNotBlank(f.batchSize) ? Decimal.valueOf(f.batchSize) : null),
                Is_Active__c = true,
                TFR_Part_Effect__c = partEffect.Id,
                VIN_Cut_off__c = tfr.Id
            );
            insert newFC;
            
            fc.Is_Active__c = FALSE;
            update fc;
            
            
        }
        else if(comparisonResult == -1){
            System.debug('PostVIN is SMALLER !!');
        }
        else{
            System.debug('Invalid Result !!');
        }
        
        
    }
    
    
    
    
    public static void getComparisonResult(){
        
    }
    

    
    
}