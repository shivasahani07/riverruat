public class TriggerOnFailureCodeHelper {

    public static void BeforeInsert(List<Failure_Code__c> beforeInsertFC) {
        // Collect all unique TFR_Part_Effect__c Ids
        Set<Id> tfrPartEffectIds = new Set<Id>();
        for (Failure_Code__c fcRec : beforeInsertFC) {
            if (fcRec.TFR_Part_Effect__c != null) {
                tfrPartEffectIds.add(fcRec.TFR_Part_Effect__c);
            }
        }

        // Query all related TFR_Part_Effect__c records in a single SOQL
        Map<Id, TFR_Part_Effect__c> partEffectMap = new Map<Id, TFR_Part_Effect__c>(
            [SELECT Id, TFR__c, TFR__r.VIN_Start__c FROM TFR_Part_Effect__c WHERE Id IN :tfrPartEffectIds]
        );

        // Set the VIN_Cut_off__c field on each Failure_Code__c record
        for (Failure_Code__c fcRec : beforeInsertFC) {
            if (fcRec.TFR_Part_Effect__c != null && partEffectMap.containsKey(fcRec.TFR_Part_Effect__c)) {
                TFR_Part_Effect__c related = partEffectMap.get(fcRec.TFR_Part_Effect__c);
                fcRec.VIN_Cut_off__c = related.TFR__c;
            }
        }
    }
}