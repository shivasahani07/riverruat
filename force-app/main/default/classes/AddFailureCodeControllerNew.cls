public without sharing class AddFailureCodeControllerNew {
    
    public static void createPostVINFCPCVIN(String fcName, String productcode, String newVINCutOff) {
        try {
            Failure_Code__c fc = null;
            List<Failure_Code__c> fcList = [
                SELECT Id, Name, Product_Code__c, VIN_Cut_off_No__c, VIN_Cut_off__c, Is_Active__c
                FROM Failure_Code__c
                WHERE Name = :fcName
                AND Product_Code__c = :productcode 
                AND Is_Active__c = true
                LIMIT 1
            ];
            if (!fcList.isEmpty()) {
                fc = fcList[0];
            }

            Integer comparisonResult; 
            if (fc != null && fc.VIN_Cut_off__c != null && fc.Is_Active__c) {
                // fc pc found with vin
                comparisonResult = VINCutOffManagement.compareVINFormat(fc.VIN_Cut_off_No__c, newVINCutOff);

                if (comparisonResult == 0) {
                    System.debug('SAME VIN FOUND WITH SAME FC PC!!');
                    // NOTHING TO DO
                } else if (comparisonResult == 1) {
                    System.debug('PostVIN is GREATER !!');
                    TFR__c existingTFR = checkandCreateVIN(newVINCutOff);
                    TFR_Part_Effect__c partEffect = checkCausalPartEF(productcode, existingTFR.Id);
                    Failure_Code__c newFC = checkfailureCode(fc, fcName, partEffect.Id, existingTFR.Id, null);

                } else if (comparisonResult == -1) {
                    System.debug('PostVIN is SMALLER !!');
                    // NOTHING TO DO
                } else {
                    System.debug('Invalid Result !!');
                }

                System.debug('comparisonResult---' + comparisonResult);

            } else if (fc != null && fc.VIN_Cut_off__c == null) {
                TFR__c existingTFR = checkandCreateVIN(newVINCutOff);
                Failure_Code__c newFC = checkfailureCode(fc, existingTFR.Id);
            } else {
                System.debug('No matching Failure Code found or not active.');
            }
        } catch (Exception e) {
            System.debug('Error in createPostVINFCPCVIN: ' + e.getMessage());
        }
    }
    
    private static TFR__c checkandCreateVIN(String newVINCutOff) {
        try {
            List<TFR__c> tfrList = [
                SELECT Id, Name FROM TFR__c WHERE VIN_Start__c = :newVINCutOff LIMIT 1
            ];
            if (!tfrList.isEmpty()) {
                return tfrList[0];
            }
            TFR__c newTFR = new TFR__c(
                VIN_Start__c = newVINCutOff,
                Is_Active__c = true
            );
            insert newTFR;
            return newTFR;
        } catch (Exception e) {
            System.debug('Error in checkandCreateVIN: ' + e.getMessage());
            return null;
        }
    }
    
    private static TFR_Part_Effect__c checkCausalPartEF(String productcode, String tfrId) {
        try {
            List<TFR_Part_Effect__c> peList = [
                SELECT Id, Name, Product_Code__c 
                FROM TFR_Part_Effect__c 
                WHERE TFR__c = :tfrId AND Product_Code__c = :productcode 
                LIMIT 1
            ];
            if (!peList.isEmpty()) {
                return peList[0];
            }

            Product2 prod;
            List<Product2> prodList = [SELECT Id, Name FROM Product2 WHERE ProductCode = :productcode LIMIT 1];
            if (prodList.isEmpty()) {
                System.debug('No Product found with code: ' + productcode);
                return null;
            }
            prod = prodList[0];

            TFR_Part_Effect__c partEffect = new TFR_Part_Effect__c(
                Product__c = prod.Id,
                TFR__c = tfrId
            );
            insert partEffect;
            return partEffect;
        } catch (Exception e) {
            System.debug('Error in checkCausalPartEF: ' + e.getMessage());
            return null;
        }
    } 
    
    private static Failure_Code__c checkfailureCode(Failure_Code__c OldFC, String fcName, String partEffectId, String tfrId, Integer batchSize) {
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
            return newFC;
        } catch (Exception e) {
            System.debug('Error in checkfailureCode (create new): ' + e.getMessage());
            return null;
        }
    }
    
    private static Failure_Code__c checkfailureCode(Failure_Code__c OldFC, String tfrId) {
        try {
            OldFC.VIN_Cut_off__c = tfrId;
            update OldFC;
            return OldFC;
        } catch (Exception e) {
            System.debug('Error in checkfailureCode (update only): ' + e.getMessage());
            return null;
        }
    }
}