/**
* @description       : 
* @author            : Ram Kumar
* @group             : 
* @Created On        : 06/10/2025
* @last modified on  : 
* @last modified by  : 
**/

public class JobCardHandler {
    
    public static void createClaimAndClaimItemOnWorkOrderCompletion(List<WorkOrder> newWOs, Map<Id, WorkOrder> oldWOMap) {
    System.debug('Inside WorkOrder Completion Trigger - Claim Creation Logic');

    try {
        Set<Id> completedWorkOrderIds = new Set<Id>();

        for (WorkOrder wo : newWOs) {
            WorkOrder oldWO = oldWOMap.get(wo.Id);
            if (wo.Status == 'Completed' && (oldWO == null || oldWO.Status != 'Completed')) {
                completedWorkOrderIds.add(wo.Id);
            }
        }

        System.debug('Completed WorkOrders: ' + completedWorkOrderIds);
        if (completedWorkOrderIds.isEmpty()) return;

        
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(
            [SELECT Id, AccountId, Vehicle__c, OwnerId
             FROM WorkOrder
             WHERE Id IN :completedWorkOrderIds]
        );

        
       
        Map<Id, List<Warranty_Prior__c>> woToWarrantyMap = new Map<Id, List<Warranty_Prior__c>>();
        for (Warranty_Prior__c wp : [
            SELECT Id, Name, Job_Card__c
            FROM Warranty_Prior__c
            WHERE Job_Card__c IN :completedWorkOrderIds
        ]) {
            if (!woToWarrantyMap.containsKey(wp.Job_Card__c)) {
                woToWarrantyMap.put(wp.Job_Card__c, new List<Warranty_Prior__c>());
            }
            woToWarrantyMap.get(wp.Job_Card__c).add(wp);
        }


        
        Map<Id, Claim> woToClaimMap = new Map<Id, Claim>();
        for (Claim c : [
            SELECT Id, Name, Job_Card__c, Warranty_Prior__c
            FROM Claim
            WHERE Job_Card__c IN :completedWorkOrderIds
        ]) {
            woToClaimMap.put(c.Job_Card__c, c);
        }

        
        List<WorkOrderLineItem> workLineItems = [
            SELECT Id, WorkOrderId, Status
            FROM WorkOrderLineItem
            WHERE Status = 'New' AND WorkOrderId IN :completedWorkOrderIds
        ];

        List<WorkPlan> workPlans = [
            SELECT Id, WorkOrderId, Status__c
            FROM WorkPlan
            WHERE Status__c = 'New' AND WorkOrderId IN :completedWorkOrderIds
        ];

       
        List<Claim> claimsToInsert = new List<Claim>();
        List<ClaimItem> claimItemsToInsert = new List<ClaimItem>();
        List<WorkOrderLineItem> partsToUpdate = new List<WorkOrderLineItem>();
        List<WorkPlan> workPlansToUpdate = new List<WorkPlan>();

        
        for (WorkOrder wo : woMap.values()) {
            if (!woToClaimMap.containsKey(wo.Id)) {
                Claim c = new Claim();
                c.Name = 'Claim_' + woToWarrantyMap.get(wo.Id)[0].Name;
                c.AccountId = wo.AccountId;
                c.Vehicle__c = wo.Vehicle__c;
                c.Job_Card__c = wo.Id;
                c.Status = 'Draft';
                c.OwnerId = wo.OwnerId;
                c.Warranty_Prior__c = woToWarrantyMap.get(wo.Id)[0].Id; 
                claimsToInsert.add(c);
            }
        }

        if (!claimsToInsert.isEmpty()) {
            insert claimsToInsert;
            for (Claim c : claimsToInsert) {
                woToClaimMap.put(c.Job_Card__c, c);
            }
            System.debug('Inserted Claims: ' + claimsToInsert);
        }

        
        Set<Id> claimIds = new Set<Id>();
        for (Claim c : woToClaimMap.values()) {
            claimIds.add(c.Id);
        }

        Set<Id> existingPartIds = new Set<Id>();
        Set<Id> existingLabourIds = new Set<Id>();

        if (!claimIds.isEmpty()) {
            for (ClaimItem ci : [
                SELECT Id, ClaimId, Part__c, Labour_Code__c
                FROM ClaimItem
                WHERE ClaimId IN :claimIds
            ]) {
                if (ci.Part__c != null) existingPartIds.add(ci.Part__c);
                if (ci.Labour_Code__c != null) existingLabourIds.add(ci.Labour_Code__c);
            }
        }

        
        for (WorkOrderLineItem p : workLineItems) {
            Claim relatedClaim = woToClaimMap.get(p.WorkOrderId);
            if (relatedClaim != null && !existingPartIds.contains(p.Id)) {
                ClaimItem ci = new ClaimItem();
                ci.Name = 'Claim_Item_' + relatedClaim.Name + '_Part';
                ci.ClaimId = relatedClaim.Id;
                ci.Part__c = p.Id;
                ci.FaultDate = Date.today();
                ci.Status__c = 'Pending';
                ci.Claim_Type__c = 'Part';
                claimItemsToInsert.add(ci);

                p.Status = 'Approved';
                partsToUpdate.add(p);
            }
        }

        
        for (WorkPlan wp : workPlans) {
            Claim relatedClaim = woToClaimMap.get(wp.WorkOrderId);
            if (relatedClaim != null && !existingLabourIds.contains(wp.Id)) {
                ClaimItem ci = new ClaimItem();
                ci.Name = 'Claim_Item_' + relatedClaim.Name + '_Labour';
                ci.ClaimId = relatedClaim.Id;
                ci.FaultDate = Date.today();
                ci.Status__c = 'Pending';
                ci.Claim_Type__c = 'Labour';
                ci.Labour_Code__c = wp.Id;
                claimItemsToInsert.add(ci);

                wp.Status__c = 'Approved';
                workPlansToUpdate.add(wp);
            }
        }

        
        if (!claimItemsToInsert.isEmpty()) insert claimItemsToInsert;
        if (!partsToUpdate.isEmpty()) update partsToUpdate;
        if (!workPlansToUpdate.isEmpty()) update workPlansToUpdate;

    } catch (Exception e) {
        System.debug('Error in createClaimAndClaimItemOnWorkOrderCompletion: ' + e.getMessage() + ' at line ' + e.getLineNumber());
    }
}

}