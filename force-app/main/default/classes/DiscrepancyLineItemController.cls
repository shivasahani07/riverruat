public without sharing class DiscrepancyLineItemController {
    @AuraEnabled(cacheable=true)
    public static List<Discrepancy_Line_Item__c> getDiscrepancyLineItems(String discrepancyId) {
        return [
            SELECT Id, Name, Approved_Quantity__c,Request_Part_Quantity__c,Recived_Request_Part_Quantity__c from Discrepancy_Line_Item__c
            WHERE Discrepancy_Lot__c = :discrepancyId
        ];
    }

    @AuraEnabled
    public static void updateApproval(List<Discrepancy_Line_Item__c> itemsToUpdate,String lotID) {
        update itemsToUpdate;
        system.debug('lotID===='+lotID);
		Discrepancy_Lot__c dislotRec = [Select id ,Status__C from Discrepancy_Lot__c where id =:lotID limit 1];
		dislotRec.Status__C = 'Received';
		update dislotRec;

    }
}