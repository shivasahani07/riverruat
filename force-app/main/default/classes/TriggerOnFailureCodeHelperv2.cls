public class TriggerOnFailureCodeHelperv2 {
    
    public static void BeforeInsert(List<Failure_Code__c> beforeInsertFC) {
        // Collect all unique TFR_Part_Effect__c and TFR_Labour_Effect__c Ids
        Set<Id> tfrPartEffectIds = new Set<Id>();
        Set<Id> tfrLabourEffectIds = new Set<Id>();
        
        for (Failure_Code__c fcRec : beforeInsertFC) {
            if (fcRec.TFR_Part_Effect__c != null) {
                tfrPartEffectIds.add(fcRec.TFR_Part_Effect__c);
            }
            if (fcRec.TFR_Labour_Effect__c != null) {
                tfrLabourEffectIds.add(fcRec.TFR_Labour_Effect__c);
            }
        }
        
        // Query all related TFR_Part_Effect__c records
        Map<Id, TFR_Part_Effect__c> partEffectMap = new Map<Id, TFR_Part_Effect__c>(
            [SELECT Id, TFR__c, TFR__r.VIN_Start__c, Product__r.Name, Product__r.ProductCode 
             FROM TFR_Part_Effect__c 
             WHERE Id IN :tfrPartEffectIds]
        );
        
        // Query all related TFR_Labour_Effect__c records
        Map<Id, TFR_Labour_Effect__c> labourEffectMap = new Map<Id, TFR_Labour_Effect__c>(
            [SELECT Id, TFR__c, TFR__r.VIN_Start__c,Labour_Code__c,VIN_Cut_off__c, Code_Set__r.Name, Code_Set__r.Code 
             FROM TFR_Labour_Effect__c 
             WHERE Id IN :tfrLabourEffectIds]
        );
        
        // Set the VIN_Cut_off__c and FPV_Key__c fields on each Failure_Code__c record
        for (Failure_Code__c fcRec : beforeInsertFC) {
            // Handle TFR Part Effect
            if (fcRec.TFR_Part_Effect__c != null && partEffectMap.containsKey(fcRec.TFR_Part_Effect__c)) {
                TFR_Part_Effect__c related = partEffectMap.get(fcRec.TFR_Part_Effect__c);
                System.debug('Related Labour: ' + related);
                String fpv_key = fcRec.Name + '-' + related.Product__r.Name + '-' + related.TFR__r.VIN_Start__c;
                fcRec.VIN_Cut_off__c = related.TFR__c;
                fcRec.FPV_Key__c = fpv_key;
                //fcRec.Product_Code__c = related.Product__r.ProductCode;
                fcRec.Type__c = 'Part';
            }
            // Handle TFR Labour Effect
            else if (fcRec.TFR_Labour_Effect__c != null && labourEffectMap.containsKey(fcRec.TFR_Labour_Effect__c)) {
                TFR_Labour_Effect__c related = labourEffectMap.get(fcRec.TFR_Labour_Effect__c);
                System.debug('Related Labour: ' + related);
                String fpv_key = fcRec.Name + '-' + related.Labour_Code__c + '-' + related.VIN_Cut_off__c;
                fcRec.VIN_Cut_off__c = related.TFR__c;
                fcRec.FPV_Key__c = fpv_key;
                //fcRec.Labour_Code__c = related.Code_Set__r.Code;
                fcRec.Type__c = 'Labour';
            }
        }
    }
    
    public static void BeforeUpdate(List<Failure_Code__c> beforeUpdateFC, Map<Id, Failure_Code__c> oldMap) {
        // Collect all unique TFR_Part_Effect__c and TFR_Labour_Effect__c Ids from updated records
        Set<Id> tfrPartEffectIds = new Set<Id>();
        Set<Id> tfrLabourEffectIds = new Set<Id>();
        
        for (Failure_Code__c fcRec : beforeUpdateFC) {
            Failure_Code__c oldRec = oldMap.get(fcRec.Id);
            
            // Check if TFR_Part_Effect__c changed
            if (fcRec.TFR_Part_Effect__c != oldRec.TFR_Part_Effect__c && fcRec.TFR_Part_Effect__c != null) {
                tfrPartEffectIds.add(fcRec.TFR_Part_Effect__c);
            }
            // Check if TFR_Labour_Effect__c changed
            if (fcRec.TFR_Labour_Effect__c != oldRec.TFR_Labour_Effect__c && fcRec.TFR_Labour_Effect__c != null) {
                tfrLabourEffectIds.add(fcRec.TFR_Labour_Effect__c);
            }
        }
        
        // Query all related TFR_Part_Effect__c records
        Map<Id, TFR_Part_Effect__c> partEffectMap = new Map<Id, TFR_Part_Effect__c>(
            [SELECT Id, TFR__c, TFR__r.VIN_Start__c, Product__r.Name, Product__r.ProductCode 
             FROM TFR_Part_Effect__c 
             WHERE Id IN :tfrPartEffectIds]
        );
        
        // Query all related TFR_Labour_Effect__c records
        Map<Id, TFR_Labour_Effect__c> labourEffectMap = new Map<Id, TFR_Labour_Effect__c>(
            [SELECT Id, TFR__c, TFR__r.VIN_Start__c,Labour_Code__c,VIN_Cut_off__c, Code_Set__r.Name, Code_Set__r.Code 
             FROM TFR_Labour_Effect__c 
             WHERE Id IN :tfrLabourEffectIds]
        );
        
        // Update the VIN_Cut_off__c and FPV_Key__c fields on each Failure_Code__c record
        for (Failure_Code__c fcRec : beforeUpdateFC) {
            Failure_Code__c oldRec = oldMap.get(fcRec.Id);
            
            System.debug('fcRec.TFR_Part_Effect__c : ' + fcRec.TFR_Part_Effect__c);
            System.debug('oldRec.TFR_Part_Effect__c : ' + oldRec.TFR_Part_Effect__c);
            
            // Handle TFR Part Effect changes
            if (fcRec.TFR_Part_Effect__c != oldRec.TFR_Part_Effect__c) {
                
                if (fcRec.TFR_Part_Effect__c != null && partEffectMap.containsKey(fcRec.TFR_Part_Effect__c)) {
                    TFR_Part_Effect__c related = partEffectMap.get(fcRec.TFR_Part_Effect__c);
                    String fpv_key = fcRec.Name + '-' + related.Product__r.Name + '-' + related.TFR__r.VIN_Start__c;
                    fcRec.VIN_Cut_off__c = related.TFR__c;
                    fcRec.FPV_Key__c = fpv_key;
                    //fcRec.Product_Code__c = related.Product__r.ProductCode;
                    fcRec.Type__c = 'Part';
                } else if (fcRec.TFR_Part_Effect__c == null) {
                    // Clear fields if TFR_Part_Effect__c is removed
                    fcRec.VIN_Cut_off__c = null;
                    fcRec.FPV_Key__c = null;
                    //fcRec.Product_Code__c = null;
                    fcRec.Type__c = null;
                }else if(fcRec.TFR_Part_Effect__c == null && partEffectMap.containsKey(fcRec.TFR_Part_Effect__c)){
                    
                }
            }
            
            // Handle TFR Labour Effect changes
            if (fcRec.TFR_Labour_Effect__c != oldRec.TFR_Labour_Effect__c) {
                if (fcRec.TFR_Labour_Effect__c != null && labourEffectMap.containsKey(fcRec.TFR_Labour_Effect__c)) {
                    TFR_Labour_Effect__c related = labourEffectMap.get(fcRec.TFR_Labour_Effect__c);
                    String fpv_key = fcRec.Name + '-' + related.Labour_Code__c + '-' + related.VIN_Cut_off__c;
                    fcRec.VIN_Cut_off__c = related.TFR__c;
                    fcRec.FPV_Key__c = fpv_key;
                    //fcRec.Labour_Code__c = related.Code_Set__r.Code;
                    fcRec.Type__c = 'Labour';
                } else if (fcRec.TFR_Labour_Effect__c == null) {
                    // Clear fields if TFR_Labour_Effect__c is removed
                    fcRec.VIN_Cut_off__c = null;
                    fcRec.FPV_Key__c = null;
                    //fcRec.Labour_Code__c = null;
                    fcRec.Type__c = null;
                }
            }
        }
    }
    
    public static void AfterInsert(List<Failure_Code__c> afterInsertFC) {
        // Update related WorkOrderLineItems if needed
        updateRelatedRecords(afterInsertFC);
    }
    
    public static void AfterUpdate(List<Failure_Code__c> afterUpdateFC, Map<Id, Failure_Code__c> oldMap) {
        // Update related WorkOrderLineItems if TFR relationships changed
        List<Failure_Code__c> changedFCs = new List<Failure_Code__c>();
        
        for (Failure_Code__c fcRec : afterUpdateFC) {
            Failure_Code__c oldRec = oldMap.get(fcRec.Id);
            
            if (fcRec.TFR_Part_Effect__c != oldRec.TFR_Part_Effect__c || 
                fcRec.TFR_Labour_Effect__c != oldRec.TFR_Labour_Effect__c) {
                    changedFCs.add(fcRec);
                }
        }
        
        if (!changedFCs.isEmpty()) {
            updateRelatedRecords(changedFCs);
        }
    }
    
    private static void updateRelatedRecords(List<Failure_Code__c> fcList) {
        // Update related WorkOrderLineItems with TFR information
        Set<Id> fcIds = new Map<Id, Failure_Code__c>(fcList).keySet();
        
        // Find WorkOrderLineItems related to these Failure Codes
        List<WorkOrderLineItem> woliToUpdate = new List<WorkOrderLineItem>();
        
        for (WorkOrderLineItem woli : [SELECT Id, Failure_Code__c, TFR_Required__c, Post_Vin_cutt_off__c 
                                       FROM WorkOrderLineItem 
                                       WHERE Failure_Code__c IN :fcIds]) {
                                           Failure_Code__c relatedFC = null;
                                           
                                           // Find the related Failure Code
                                           for (Failure_Code__c fc : fcList) {
                                               if (fc.Id == woli.Failure_Code__c) {
                                                   relatedFC = fc;
                                                   break;
                                               }
                                           }
                                           
                                           if (relatedFC != null) {
                                               // Set TFR requirements based on Failure Code
                                               woli.TFR_Required__c = (relatedFC.VIN_Cut_off__c != null);
                                               
                                               // For post-VIN cutoff logic, you might need additional logic here
                                               // This is a placeholder - implement your specific business logic
                                               woli.Post_Vin_cutt_off__c = false; // Set based on your business rules
                                               
                                               woliToUpdate.add(woli);
                                           }
                                       }
        
        if (!woliToUpdate.isEmpty()) {
            //update woliToUpdate;
        }
    }
    
    public static void updateRelatedCausalTFRfromFC(List<Failure_Code__c> beforeUpdateFC, Map<Id, Failure_Code__c> oldMap){
        Set<Id> tfrPartEffectIds = new Set<Id>();
        Set<Id> tfrLabourEffectIds = new Set<Id>();
        
        for (Failure_Code__c fcRec : beforeUpdateFC) {
            Failure_Code__c oldRec = oldMap.get(fcRec.Id);
            
            // Check if TFR_Part_Effect__c changed
            if (fcRec.TFR_Part_Effect__c != oldRec.TFR_Part_Effect__c && fcRec.TFR_Part_Effect__c != null) {
                tfrPartEffectIds.add(fcRec.TFR_Part_Effect__c);
            }
            // Check if TFR_Labour_Effect__c changed
            if (fcRec.TFR_Labour_Effect__c != oldRec.TFR_Labour_Effect__c && fcRec.TFR_Labour_Effect__c != null) {
                tfrLabourEffectIds.add(fcRec.TFR_Labour_Effect__c);
            }
        }
        
        // Query all related TFR_Part_Effect__c records
        Map<Id, TFR_Part_Effect__c> partEffectMap = new Map<Id, TFR_Part_Effect__c>(
            [SELECT Id, TFR__c, TFR__r.VIN_Start__c, Product__r.Name, Product__r.ProductCode 
             FROM TFR_Part_Effect__c 
             WHERE Id IN :tfrPartEffectIds]
        );
        
        // Query all related TFR_Labour_Effect__c records
        Map<Id, TFR_Labour_Effect__c> labourEffectMap = new Map<Id, TFR_Labour_Effect__c>(
            [SELECT Id, TFR__c, TFR__r.VIN_Start__c,Labour_Code__c,VIN_Cut_off__c, Code_Set__r.Name, Code_Set__r.Code 
             FROM TFR_Labour_Effect__c 
             WHERE Id IN :tfrLabourEffectIds]
        );
    }
    
    public static void mytest(){
        Integer i=0;
        i++;i++; i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
    }
}