public without sharing class TFRControllerNew {
    
    @AuraEnabled(Cacheable=true)
    Public Static List<TFR__c> getExistingVIN(){
        return [SELECT Id, VIN_Start__c, Createddate, Description__c, Is_Active__c 
                FROM TFR__c 
                WHERE Is_Active__c = true 
                ORDER BY VIN_Start__c];
    }
    
    @AuraEnabled
    public static void createTFRWithParts(String vin, String errorCode, String description, List<Object> parts) {
        try {
            // Validate inputs
            if (String.isBlank(vin)) {
                throw new AuraHandledException('VIN is required');
            }
            
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
                    Consequence__c = (String)part.get('consequence'),
                    Root_Cause__c = (String)part.get('rootCause'),
                    Comments__c = (String)part.get('comments')
                ));
            }
            
            if (!partRecords.isEmpty()) {
                insert partRecords;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error creating TFR: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void createMultipleTFRs(List<TFRWrapper> tfrs) {
        try {
            List<TFR__c> tfrToInsert = new List<TFR__c>();
            List<TFR_Part_Effect__c> partsToInsert = new List<TFR_Part_Effect__c>();
            
            for (TFRWrapper tfr : tfrs) {
                TFR__c tfrRec = new TFR__c(
                    VIN_Start__c = tfr.vin,
                    Error_Code__c = tfr.errorCode,
                    Description__c = tfr.description,
                    Sample_Size__c = tfr.Required_Sampe_No
                );
                tfrToInsert.add(tfrRec);
            }
            
            insert tfrToInsert;
            
            for (Integer i = 0; i < tfrToInsert.size(); i++) {
                TFR__c insertedTFR = tfrToInsert[i];
                for (ImpactedPartWrapper part : tfrs[i].impactedParts) {
                    TFR_Part_Effect__c partRec = new TFR_Part_Effect__c(
                        TFR__c = insertedTFR.Id,
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
        } catch (Exception e) {
            throw new AuraHandledException('Error creating multiple TFRs: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static TFRWrapperSample verifyExistingTFR(String partId) {
        try {
            WorkOrderLineItem workOrderLineItemRec = null;
            TFR_Sample__c tfrSampleRecord = null;
            
            // Query for WorkOrderLineItem
            List<WorkOrderLineItem> woliList = [
                SELECT Id, LineItemNumber, PricebookEntryId, Warranty_Prior__c, 
                       PricebookEntry.Product2.Name, TFR_Required__c, Warranty_Prior__r.Status__c,
                       Failure_Code__c, PricebookEntry.Product2.ProductCode, Quantity, 
                       RR_Parts_Category__c, Status, Tax__c, Amount_per_Hour__c, CreatedDate, 
                       WorkOrder.WorkOrderNumber, PricebookEntry.Product2Id, Total_Labour_Charges__c, 
                       Total_NDP__c, Grand_Total__c, IGST_Percentage_formula__c, WorkOrder.Status,
                       TotalAmount__c, Labour_Code__r.Name, Labour_Code__r.RR_Labour_Charge__c, 
                       Replacement_Type__c, Labour_Code__r.RR_Efforts_Hours__c, Hours__c, 
                       Part_Description__c, Consequential_Part__c, Electrical_Value__c,
                       FFIR_Number__c, FFIR_Links__c
                FROM WorkOrderLineItem
                WHERE Id = :partId
                LIMIT 1
            ];
            
            if (!woliList.isEmpty()) {
                workOrderLineItemRec = woliList[0];
            }
            
            // Query for TFR_Sample__c
            List<TFR_Sample__c> tfrList = [
                SELECT Actions_Taken__c, Approved_by__c, CreatedById, CreatedDate, 
                       Customer_Account__c, Customer_Contact__c, Job_card__r.Status,
                       Date_of_Complaint__c, Date_of_Repair__c, Date_of_Sale__c, 
                       Failure_Code__c, Id, IsDeleted, Issue_Severity__c, Job_Card__c, 
                       LastModifiedById, LastModifiedDate, LastViewedDate, Media__c, 
                       Name, Name__c, Observations__c, Odometer_Reading__c, OwnerId,
                       Part__c, Service_Center__c, SystemModstamp, TFR__c, VIN_No__c, 
                       VOC__c, Warranty_Claim_Number__c
                FROM TFR_Sample__c
                WHERE Part__c = :partId
                LIMIT 1
            ];
            
            if (!tfrList.isEmpty()) {
                tfrSampleRecord = tfrList[0];
            }
            
            return new TFRWrapperSample(workOrderLineItemRec, tfrSampleRecord);
        } catch (Exception e) {
            throw new AuraHandledException('Error verifying TFR: ' + e.getMessage());
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

    @AuraEnabled
	public static TFRValidationResult checkTFRValidationOld(String VINno, String FailureCodeId, String productCode, Boolean isLabour) {
        try {
            
            List<TFR_Part_Effect__c> getPartEffects = [
                SELECT Id, Product_Name__c, Product_Code__c, TFR__c
                FROM TFR_Part_Effect__c
                WHERE Product_Code__c = :productCode
            ];
            System.debug('getPartEffects : ' + getPartEffects);
            System.debug('getPartEffects : ' + getPartEffects.size());



            return new TFRValidationResult(false, false, 'No VIN cutoff defined for this failure code');
        } catch (Exception e) {
            system.debug('Error at'+ e.getLineNumber());
            return new TFRValidationResult(false, false, 'Error: ' + e.getMessage());
        }
    }


    
    @AuraEnabled
    public static void deleteFailureCode(String recordId) {
        try {
            Failure_Code__c fc = [SELECT Id FROM Failure_Code__c WHERE Id = :recordId];
            delete fc;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting record: ' + e.getMessage());
        }
    }
    
  
    public static String updatePartsTFRform(List<WorkOrderLineItem> listtoUpdated) {
        try {
            update listtoUpdated;
            return 'success';
        } catch (Exception e) {
            System.debug('Error update tfr on parts: ' + e.getMessage());
            System.debug('Error at line ' + e.getLineNumber());
            return 'failed: ' + e.getMessage();
        }
    }
    
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
    
    // Wrapper Classes
    public class TFRWrapper {
        @AuraEnabled public String vin;
        @AuraEnabled public String errorCode;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal Required_Sampe_No;
        @AuraEnabled public List<ImpactedPartWrapper> impactedParts;
        @AuraEnabled public Boolean isLabour;
    }
    
    public class ImpactedPartWrapper {
        @AuraEnabled public String partName;
        @AuraEnabled public String partCode;
        @AuraEnabled public String labourCode;
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
    
    public class TFRValidationWrapper {
        @AuraEnabled 
        public String vinNo;
        @AuraEnabled 
        public Boolean isTFRApplicable;
        @AuraEnabled 
        public Boolean isPostVinCuttoff;
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
    
    public class actionPlanWrapper {
        @AuraEnabled
        public List<Required_Labour__c> RequiredLabours;
        @AuraEnabled 
        public List<Required_Product__c> RequiredProducts;
    }
}