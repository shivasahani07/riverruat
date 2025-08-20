public without sharing class TFRController {
    
    @AuraEnabled(Cacheable=true)
    Public Static  List<TFR__c> getExistingVIN(){
         return [SELECT Id,VIN_Start__c,Createddate,Description__c,Is_Active__c FROM  TFR__c where Is_Active__c=true];
    }
    @AuraEnabled
    public static void createTFRWithParts(String vin, String errorCode, String description, List<Object> parts) {
        TFR__c tfr = new TFR__c(
            VIN_Start__c = vin,
            Error_Code__c = errorCode,
            Description__c = description
        );
        insert tfr;
        
        List<TFR_Part_Effect__c> partRecords = new List<TFR_Part_Effect__c>();
        
        for (Object partObj : parts) {
            Map<String, Object> part = (Map<String, Object>)partObj;
            partRecords.add(new TFR_Part_Effect__c(
                TFR__c = tfr.Id,
                Product__c = (String)part.get('partName'),
                //Part_Code__c = (String)part.get('partCode'),
                Consequence__c = (String)part.get('consequence'),
                Root_Cause__c = (String)part.get('rootCause'),
                Comments__c = (String)part.get('comments')
            ));
        }
        
        if (!partRecords.isEmpty()) {
            insert partRecords;
        }
    }
    
    @AuraEnabled
    public static void createMultipleTFRs(List<TFRWrapper> tfrs) {
        system.debug('tfrs---'+tfrs);
        List<TFR__c> tfrToInsert = new List<TFR__c>();
        List<TFR_Part_Effect__c> partsToInsert = new List<TFR_Part_Effect__c>();
        
        for (TFRWrapper tfr : tfrs) {
            TFR__c tfrRec = new TFR__c(
                VIN_Start__c = tfr.vin,
                Error_Code__c = tfr.errorCode,
                Description__c = tfr.description,
                Sample_Size__c=tfr.Required_Sampe_No
            );
            tfrToInsert.add(tfrRec);
        }
        
        insert tfrToInsert;
        
        for (Integer i = 0; i < tfrToInsert.size(); i++) {
            TFR__c insertedTFR = tfrToInsert[i];
            for (ImpactedPartWrapper part : tfrs[i].impactedParts) {
                TFR_Part_Effect__c partRec = new TFR_Part_Effect__c(
                    TFR__c = insertedTFR.Id,
                    //Name__c = part.partName,
                    Product__c = part.partCode,
                    Consequence__c = part.consequence,
                    Root_Cause__c = part.rootCause,
                    Comments__c = part.comments
                );
                partsToInsert.add(partRec);
            }
        }
        
        if (!partsToInsert.isEmpty()) {
            insert partsToInsert;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static TFRWrapperSample verifyExistingTFR(String partId) {
        WorkOrderLineItem workOrderLineItemRec = null;
        TFR_Sample__c tfrSampleRecord = null;
        
        // Null-safe query for WorkOrderLineItem
        List<WorkOrderLineItem> woliList = [
            SELECT Id, LineItemNumber, PricebookEntryId, Warranty_Prior__c, PricebookEntry.Product2.Name, TFR_Required__c,Warranty_Prior__r.Status__c,
            Failure_Code__c, PricebookEntry.Product2.ProductCode, Quantity, RR_Parts_Category__c, Status, Tax__c,
            Amount_per_Hour__c, CreatedDate, WorkOrder.WorkOrderNumber, PricebookEntry.Product2Id,
            Total_Labour_Charges__c, Total_NDP__c, Grand_Total__c, IGST_Percentage_formula__c,WorkOrder.Status,
            TotalAmount__c, Labour_Code__r.Name, Labour_Code__r.RR_Labour_Charge__c, Replacement_Type__c,
            Labour_Code__r.RR_Efforts_Hours__c, Hours__c, Part_Description__c, Consequential_Part__c, Electrical_Value__c,
            FFIR_Number__c, FFIR_Links__c
            FROM WorkOrderLineItem
            WHERE Id = :partId
            LIMIT 1
        ];
        if (!woliList.isEmpty()) {
            workOrderLineItemRec = woliList[0];
        }
        
        // Null-safe query for TFR_Sample__c
        List<TFR_Sample__c> tfrList = [
            SELECT Actions_Taken__c, Approved_by__c, CreatedById, CreatedDate, Customer_Account__c, Customer_Contact__c,Job_card__r.Status,
            Date_of_Complaint__c, Date_of_Repair__c, Date_of_Sale__c, Failure_Code__c, Id, IsDeleted,
            Issue_Severity__c, Job_Card__c, LastModifiedById, LastModifiedDate, LastReferencedDate,
            LastViewedDate, Media__c, Name, Name__c, Observations__c, Odometer_Reading__c, OwnerId,
            Part__c, Service_Center__c, SystemModstamp, TFR__c, VIN_No__c, VOC__c, Warranty_Claim_Number__c
            FROM TFR_Sample__c
            WHERE Part__c = :partId
            LIMIT 1
        ];
        if (!tfrList.isEmpty()) {
            tfrSampleRecord = tfrList[0];
        }
        
        return new TFRWrapperSample(workOrderLineItemRec, tfrSampleRecord);
    }
    
    
    public static Boolean isVIN2AfterVIN1(String n1, String n2) {
        if (String.isBlank(n1) || String.isBlank(n2) || n1.length() != 17 || n2.length() != 17) {
            return false; // Invalid VINs
        }
        
        try {
            // Extract last 6 digits (production serial number)
            String serial1 = n1.substring(11); // position 12 to 17 (0-based index)
            String serial2 = n2.substring(11);
            
            Integer serialNum1 = Integer.valueOf(serial1);
            Integer serialNum2 = Integer.valueOf(serial2);
            System.debug('serialNum2 > serialNum1'+ (serialNum2 > serialNum1));
            //return serialNum2 > serialNum1;
            return serialNum2 > serialNum1;
        } catch (Exception e) {
            // If serial is not a number or any issue occurs
            System.debug('Error parsing VIN serial numbers: ' + e.getMessage());
            return false;
        }
    }
    
    @AuraEnabled
    Public Static TFRValidationWrapper checkTFRValidation(String VINno,String FailureCodeId){
        // Step 1: Get VIN cutoff from Failure_Code__c
        
        TFRValidationWrapper tfrData = new TFRValidationWrapper(); 
        tfrData.vinNo=VINno;
        tfrData.isTFRApplicable=false;
        tfrData.isPostVinCuttoff=false;
        Boolean isAfterCutoff=false;
        Failure_Code__c fc = [
            SELECT Id, VIN_Cut_off__c, TFR_Part_Effect__c,VIN_Cut_off_No__c 
            FROM Failure_Code__c 
            WHERE Id = :FailureCodeId 
            LIMIT 1
        ];
        
        if(!String.isBlank(fc.VIN_Cut_off__c)){
            System.debug('VIN cutoff found for Failure Code');
            System.debug('VIN cutt off found---'+fc.VIN_Cut_off_No__c);
            System.debug('Job Card Vin---'+VINno);
            isAfterCutoff = isVIN2AfterVIN1(fc.VIN_Cut_off_No__c, VINno);
            if (isAfterCutoff) {
                System.debug('Given VIN is after the cutoff VIN');
                tfrData.isTFRApplicable=true;
                tfrData.isPostVinCuttoff=true;
            } else {
                System.debug('Given VIN is before or equal to the cutoff VIN');
                tfrData.isTFRApplicable=false;
            }
        }else{
            System.debug('No VIN cutoff found for Failure Code');
            tfrData.isTFRApplicable=true;
        }
        
        
        // Step 2 (Optional): You can find existing TFR__c related to this VIN or FailureCode if needed
        List<TFR__c> matchingTFRs = [
            SELECT Id, Name, VIN_Start__c, Error_Code__c 
            FROM TFR__c 
            WHERE VIN_Start__c != null
        ];
        
        for (TFR__c tfr : matchingTFRs) {
            if (!String.isBlank(tfr.VIN_Start__c) && isVIN2AfterVIN1(tfr.VIN_Start__c, VINno)) {
                System.debug('VIN is after TFR VIN start: ' + tfr.Name);
            }
        }
        
        System.debug('tfrData---'+tfrData);
        return tfrData;
        
    }
    
    
    @AuraEnabled
    public static void createMultipleTFRsNew(List<Object> tfrWrappers) {
        system.debug('tfrWrappers---'+tfrWrappers);
        List<TFR__c> tfrRecords = new List<TFR__c>();
        List<Failure_Code__c> fcRecords = new List<Failure_Code__c>();
        List<TFR_Part_Effect__c> partEffectRecords = new List<TFR_Part_Effect__c>();
        
        for (Object wrapper : tfrWrappers) {
            Map<String, Object> tfrMap = (Map<String, Object>)wrapper;
            
            TFR__c tfr = new TFR__c(
                VIN_Start__c = (String)tfrMap.get('vin'),
                Error_Code__c = (String)tfrMap.get('errorCode'),
                Description__c = (String)tfrMap.get('description'),
                Sample_Size__c = Integer.valueOf((String)tfrMap.get('Required_Sampe_No'))
            );
            tfrRecords.add(tfr);
        }
        
        insert tfrRecords;
        
        // Now for each inserted TFR, create related Failure_Code and TFR_Part_Effect
        Integer i = 0;
        for (Object wrapper : tfrWrappers) {
            Map<String, Object> tfrMap = (Map<String, Object>)wrapper;
            TFR__c currentTFR = tfrRecords[i];
            
            // 1. Create Failure_Code__c
            Failure_Code__c fc = new Failure_Code__c(
                Name = 'Auto-Gen FC ' + currentTFR.VIN_Start__c,
                VIN_Cut_off__c = currentTFR.Id
            );
            fcRecords.add(fc);
            i++;
        }
        
        insert fcRecords;
        
        // Now attach TFR_Part_Effect__c
        Integer index = 0;
        for (Object wrapper : tfrWrappers) {
            Map<String, Object> tfrMap = (Map<String, Object>)wrapper;
            List<Object> parts = (List<Object>)tfrMap.get('impactedParts');
            
            TFR__c currentTFR = tfrRecords[index];
            Failure_Code__c relatedFC = fcRecords[index];
            
            for (Object partObj : parts) {
                Map<String, Object> part = (Map<String, Object>)partObj;
                
                TFR_Part_Effect__c pe = new TFR_Part_Effect__c(
                    TFR__c = currentTFR.Id,
                    Failure_Code__c = relatedFC.Id,
                    Product__c = (String)part.get('partName'), // custom field you might need
                    //Product__c = (String)part.get('partCode'),
                    Consequence__c = (String)part.get('consequence'),
                    Root_Cause__c = (String)part.get('rootCause'),
                    Comments__c = (String)part.get('comments')
                );
                partEffectRecords.add(pe);
            }
            
            index++;
        }
        
        insert partEffectRecords;
    }
    
    public static string updatePartsTFRform(list<WorkOrderLineItem> listtoUpdated){
        try{
            update listtoUpdated;
            return 'sucess';
        }Catch (Exception e){
            System.debug('Error update tfr on parts: ' + e.getMessage());
            System.debug('Error at line ' + e.getLineNumber());
            return 'failed';
        }
    }
    
    
    
    // Wrapper Classes
    public class TFRWrapper {
        @AuraEnabled public String vin;
        @AuraEnabled public String errorCode;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal Required_Sampe_No;
        @AuraEnabled public List<ImpactedPartWrapper> impactedParts;
    }
    
    public class ImpactedPartWrapper {
        @AuraEnabled public String partName;
        @AuraEnabled public String partCode;
        @AuraEnabled public String consequence;
        @AuraEnabled public String rootCause;
        @AuraEnabled public String comments;
    }
    
    public class TFRWrapperSample {
        @AuraEnabled public WorkOrderLineItem workOrderLineItemRec { get; set; }
        @AuraEnabled public TFR_Sample__c tfrSampleRecord { get; set; }
        
        public TFRWrapperSample(WorkOrderLineItem woli, TFR_Sample__c tfr) {
            this.workOrderLineItemRec = woli;
            this.tfrSampleRecord = tfr;
        }
    }
    
    public class  TFRValidationWrapper{
        @AuraEnabled 
        public String vinNo;
        @AuraEnabled 
        public Boolean isTFRApplicable;
        @AuraEnabled 
        public Boolean isPostVinCuttoff;
    }
    
}