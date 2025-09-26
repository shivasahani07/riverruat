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
            [SELECT Id, TFR__c, TFR__r.VIN_Start__c, Product__r.Name, Product__r.ProductCode FROM TFR_Part_Effect__c WHERE Id IN :tfrPartEffectIds]
        );

        // Set the VIN_Cut_off__c field on each Failure_Code__c record
        for (Failure_Code__c fcRec : beforeInsertFC) {
            if (fcRec.TFR_Part_Effect__c != null && partEffectMap.containsKey(fcRec.TFR_Part_Effect__c)) {
                TFR_Part_Effect__c related = partEffectMap.get(fcRec.TFR_Part_Effect__c);
                String fpv_key = fcRec.Name + '-' + related.Product__r.Name + '-' + related.TFR__r.VIN_Start__c;
                fcRec.VIN_Cut_off__c = related.TFR__c;
                fcRec.FPV_Key__c = fpv_key;
            }
        }
        
        //update beforeInsertFC;
    }

    public static void validateDataBeforeInsertUdate(map<id,Failure_Code__c> oldmap ,List<Failure_Code__c> newList){

        for(Failure_Code__c newObject :newList){
            Failure_Code__c oldObject =oldmap.get(newObject.id);
            if(newObject.FPV_Key__c != oldObject.FPV_Key__c){
                 newObject.addError('well tried but you can not edit this value');
            }
        }
    }
}