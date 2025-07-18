public class WarrantyPriorTriggerHandler {
    
    
    public static void handleWarrantyApproval(List<Warranty_Prior__c> newRecords, Map<Id, Warranty_Prior__c> oldMap) {
        List<Claim> claimsToInsert = new List<Claim>();
        List<ClaimItem> claimItemsToUpdate = new List<ClaimItem>();
        List<WorkOrderLineItem> woItemsToUpdate = new List<WorkOrderLineItem>();
        List<WorkPlan> workPlansToUpdate = new List<WorkPlan>();
        
        // Step 1: Collect Approved Warranty IDs
        Set<Id> approvedWarrantyIds = new Set<Id>();
        for (Warranty_Prior__c warranty : newRecords) {
            Warranty_Prior__c oldWarranty = oldMap.get(warranty.Id);
            if (warranty.Status__c == 'Approved' && (oldWarranty == null || oldWarranty.Status__c != 'Approved')) {
                approvedWarrantyIds.add(warranty.Id);
            }
        }
        
        if (approvedWarrantyIds.isEmpty()) {
            return; // No relevant warranty records to process
        }
        
        // Step 2: Get related WorkOrders
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
            [SELECT Id, AccountId, Vehicle__c
             FROM WorkOrder
             WHERE Id IN (SELECT Job_Card__c FROM Warranty_Prior__c WHERE Id IN :approvedWarrantyIds)]
        );
        
        // Step 3: Get existing Claims
        Set<Id> warrantyIdsWithExistingClaims = new Set<Id>();
        for (Claim claim : [SELECT Id, Warranty_Prior__c FROM Claim WHERE Warranty_Prior__c IN :approvedWarrantyIds]) {
            warrantyIdsWithExistingClaims.add(claim.Warranty_Prior__c);
        }
        
        // Step 4: Pre-query WorkOrderLineItems and WorkPlans
        Map<Id, List<WorkOrderLineItem>> workOrderItemsMap = new Map<Id, List<WorkOrderLineItem>>();
        for (WorkOrderLineItem item : [
            SELECT Id, Status, WorkOrderId
            FROM WorkOrderLineItem
            WHERE WorkOrderId IN :workOrderMap.keySet()
        ]) {
            if (!workOrderItemsMap.containsKey(item.WorkOrderId)) {
                workOrderItemsMap.put(item.WorkOrderId, new List<WorkOrderLineItem>());
            }
            workOrderItemsMap.get(item.WorkOrderId).add(item);
        }
        
        Map<Id, List<WorkPlan>> workPlanMap = new Map<Id, List<WorkPlan>>();
        for (WorkPlan plan : [
            SELECT Id, Status__c, WorkOrderId
            FROM WorkPlan
            WHERE WorkOrderId IN :workOrderMap.keySet()
        ]) {
            if (!workPlanMap.containsKey(plan.WorkOrderId)) {
                workPlanMap.put(plan.WorkOrderId, new List<WorkPlan>());
            }
            workPlanMap.get(plan.WorkOrderId).add(plan);
        }
        
        // Step 5: Process each Warranty record
        for (Warranty_Prior__c warranty : newRecords) {
            Warranty_Prior__c oldWarranty = oldMap.get(warranty.Id);
            if (warranty.Status__c == 'Approved' && (oldWarranty == null || oldWarranty.Status__c != 'Approved')) {
                WorkOrder relatedWorkOrder = workOrderMap.get(warranty.Job_Card__c);
                if (relatedWorkOrder != null && relatedWorkOrder.AccountId != null) {
                        List<WorkOrderLineItem> relatedLineItems = workOrderItemsMap.get(relatedWorkOrder.Id);
                        if (relatedLineItems != null) {
                            for (WorkOrderLineItem woItem : relatedLineItems) {
                                woItem.Status = 'Approved';
                                woItemsToUpdate.add(woItem);
                            }
                        }
                        
                        List<WorkPlan> relatedWorkPlans = workPlanMap.get(relatedWorkOrder.Id);
                        if (relatedWorkPlans != null) {
                            for (WorkPlan wp : relatedWorkPlans) {
                                wp.Status__c = 'Approved';
                                workPlansToUpdate.add(wp);
                            }
                        }                    
                    if (!warrantyIdsWithExistingClaims.contains(warranty.Id)) {
                    
                    // Create a new Claim
                    Claim newClaim = new Claim(
                        Name = 'Claim_' + warranty.Name,
                        Warranty_Prior__c = warranty.Id,
                        AccountId = relatedWorkOrder.AccountId,
                        Vehicle__c = relatedWorkOrder.Vehicle__c,
                        Job_Card__c = relatedWorkOrder.Id,
                        Status = 'Draft'
                    );
                    claimsToInsert.add(newClaim);
                    }

                    
                } else {
                    System.debug('Missing WorkOrder or Account for Warranty: ' + warranty.Id);
                }
            }
        }
        
        // Step 6: DML Operations
        if (!claimsToInsert.isEmpty()) {
            insert claimsToInsert;
            System.debug('Inserted Claims: ' + claimsToInsert);
        }
        
        if (!woItemsToUpdate.isEmpty()) {
            update woItemsToUpdate;
            System.debug('Updated WorkOrderLineItems: ' + woItemsToUpdate);
        }
        
        if (!workPlansToUpdate.isEmpty()) {
            update workPlansToUpdate;
            System.debug('Updated WorkPlans: ' + workPlansToUpdate);
        }
    }
    
    
    public static void creatClaimLineItemPartJobsAdded(List<Warranty_Prior__c> newRecords, Map<Id, Warranty_Prior__c> oldMap) {
        Set<Id> warrantyIds = new Set<Id>();
        for (Warranty_Prior__c warranty : newRecords) {
            Warranty_Prior__c oldWarranty = oldMap.get(warranty.Id);
            if (warranty.Status__c == 'Approved' && (oldWarranty == null || oldWarranty.Status__c != 'Approved')) {
                warrantyIds.add(warranty.Id);
            }
        }
        if (warrantyIds.isEmpty()) return;
        
        Map<Id, Claim> claimsById = new Map<Id, Claim>(
            [SELECT Id, Name, Warranty_Prior__c, AccountId, Status, Vehicle__c, Job_Card__c
             FROM Claim
             WHERE Warranty_Prior__c IN :warrantyIds]
        );
        
        // Job card to Claim map to backtrack later
        Map<Id, Id> jobCardIdToClaimId = new Map<Id, Id>();
        for (Claim c : claimsById.values()) {
            if (c.Job_Card__c != null) {
                jobCardIdToClaimId.put(c.Job_Card__c, c.Id);
            }
        }
        
        Set<Id> jobCardIds = jobCardIdToClaimId.keySet();
        
        List<WorkOrderLineItem> workLineItems = [
            SELECT Id, Amount__c, Warranty_Prior__c, Description, Quantity, Hours__c, TotalAmount__c, WorkOrderId
            FROM WorkOrderLineItem 
            WHERE Status='New' AND  WorkOrderId IN :jobCardIds
        ];
        
        List<WorkPlan> workPlans = [
            SELECT Id, Warranty_Prior__c, TotalAmount__c, WorkOrderId
            FROM WorkPlan
            WHERE Status__c='New' AND WorkOrderId IN :jobCardIds
        ];
        
        List<ClaimItem> claimItemsToInsert = new List<ClaimItem>();
        
        // Create ClaimItems from WorkOrderLineItems (Parts)
        for (WorkOrderLineItem woli : workLineItems) {
            Id claimId = jobCardIdToClaimId.get(woli.WorkOrderId);
            Claim claim = claimsById.get(claimId);
            if (claim != null) {
                ClaimItem item = new ClaimItem(
                    Name = 'Claim_Item_' + claim.Name,
                    ClaimId = claim.Id,
                    Part__c = woli.Id,
                    Amount__c = woli.TotalAmount__c,
                    FaultDate = Date.today(),
                    Status__c = 'Pending',
                    Claim_Type__c = 'Part'
                );
                claimItemsToInsert.add(item);
            }
        }
        
        // Create ClaimItems from WorkPlans (Labour)
        for (WorkPlan wp : workPlans) {
            Id claimId = jobCardIdToClaimId.get(wp.WorkOrderId);
            Claim claim = claimsById.get(claimId);
            if (claim != null) {
                ClaimItem item = new ClaimItem(
                    Name = 'Claim_Item_' + claim.Name + '_Labour',
                    ClaimId = claim.Id,
                    Claim_Type__c = 'Labour',
                    Status__c = 'Pending',
                    FaultDate = Date.today(),
                    Labour_Code__c = wp.Id
                );
                claimItemsToInsert.add(item);
            }
        }
        
        if (!claimItemsToInsert.isEmpty()) {
            insert claimItemsToInsert;
        }
        
        System.debug('Claim Items Inserted: ' + claimItemsToInsert.size());
    }
    
}