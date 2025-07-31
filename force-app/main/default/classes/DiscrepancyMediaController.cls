public without sharing class DiscrepancyMediaController {
    @AuraEnabled(cacheable=true)
    public static List<Discrepancy_Line_Item__c> getDiscrepancyLineItems(Id shipmentId) {
        System.debug('Shipment ID: ' + shipmentId);
        if (shipmentId == null) {
            throw new AuraHandledException('Shipment ID is required.');
        }

        return [
            SELECT Id, Name,Product_Name__c,Quantity__c,Claimed_Amount__c,Supporting_Media__c,Discrepancy__r.Name	
            FROM Discrepancy_Line_Item__c
            WHERE Discrepancy__r.Shipment__c = :shipmentId AND Type__c != 'MIT'
        ];
    }

   @AuraEnabled
public static void updateMediaUrls(List<Discrepancy_Line_Item__c> items) {
     
    update items;
    
     
    Set<Id> discrepancyIds = new Set<Id>();
    List<Discrepancy_Line_Item__c> updatelist = new List<Discrepancy_Line_Item__c>();
    for (Discrepancy_Line_Item__c item : items) {

        if (item.Discrepancy__c != null) {
            Discrepancy_Line_Item__c dliRec = new Discrepancy_Line_Item__c();
            discrepancyIds.add(item.Discrepancy__c);
            dliRec.id = item.id;
            dliRec.Status__c = 'Under SPM Review';
            updatelist.add(dliRec);
        }
    }
    update updatelist;

    if (!discrepancyIds.isEmpty()) {
        
        List<Discrepancy__c> discrepancyList = [
            SELECT Id, Status__c 
            FROM Discrepancy__c 
            WHERE Id IN :discrepancyIds
        ];

         
        for (Discrepancy__c discrepancy : discrepancyList) {
            discrepancy.Status__c = 'Under SPM Review';
        }

         
        update discrepancyList;
    }
}


}