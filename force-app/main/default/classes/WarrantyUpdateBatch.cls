public class WarrantyUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Set<Id> warrantyPriorIds;
    private Map<Id, Decimal> warrantyToTotalAmountMap;
    
    public WarrantyUpdateBatch(Set<Id> warrantyIds) {
        this.warrantyPriorIds = warrantyIds;
        this.warrantyToTotalAmountMap = new Map<Id, Decimal>();
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query only relevant WorkOrderLineItems
        return Database.getQueryLocator([
            SELECT Id, Warranty_Prior__c, TotalAmount__c 
            FROM WorkOrderLineItem 
            WHERE Warranty_Prior__c IN :warrantyPriorIds
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<WorkOrderLineItem> scope) {
        // Aggregate amounts in-memory
        for (WorkOrderLineItem woli : scope) {
            Id warrantyId = woli.Warranty_Prior__c;
            if (warrantyId == null) continue;
            
            Decimal amount = woli.TotalAmount__c != null ? woli.TotalAmount__c : 0;
            warrantyToTotalAmountMap.put(warrantyId, 
                warrantyToTotalAmountMap.containsKey(warrantyId) 
                    ? warrantyToTotalAmountMap.get(warrantyId) + amount 
                    : amount
            );
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // Update Warranty_Prior__c records
        List<Warranty_Prior__c> warrantiesToUpdate = new List<Warranty_Prior__c>();
        for (Id warrantyId : warrantyPriorIds) {
            Decimal totalAmount = warrantyToTotalAmountMap.get(warrantyId) != null 
                                ? warrantyToTotalAmountMap.get(warrantyId) 
                                : 0;
            
            warrantiesToUpdate.add(new Warranty_Prior__c(
                Id = warrantyId,
                Total_Claim_Amount__c = totalAmount
            ));
        }
        
        if (!warrantiesToUpdate.isEmpty()) {
            update warrantiesToUpdate;
        }
    }
}