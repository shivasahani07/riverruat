/**
* @File Name : ResubmitDiscrepancyMediaController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 11, 2025 |   | Initial Version
**/

public class ResubmitDiscrepancyMediaController {
	  @AuraEnabled(cacheable=true)
    public static List<Discrepancy_Line_Item__c> getDiscrepancyLineItems(Id shipmentId) {
        System.debug('Shipment ID: ' + shipmentId);
        if (shipmentId == null) {
            throw new AuraHandledException('Shipment ID is required.');
        }

        return [
            SELECT Id, Name,Product_Name__c,Quantity__c,Claimed_Amount__c,Supporting_Media__c,Dealer_Recheck__c
            FROM Discrepancy_Line_Item__c
            WHERE Discrepancy__r.Shipment_Item__r.Parent_Shipment__c = :shipmentId ANd Dealer_Recheck__c = true
        ];
    }

   @AuraEnabled
public static void updateMediaUrls(List<Discrepancy_Line_Item__c> items) {
     
    update items;
    
     
    Set<Id> discrepancyIds = new Set<Id>();
    for (Discrepancy_Line_Item__c item : items) {
        if (item.Discrepancy__c != null) {
            discrepancyIds.add(item.Discrepancy__c);
        }
    }

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