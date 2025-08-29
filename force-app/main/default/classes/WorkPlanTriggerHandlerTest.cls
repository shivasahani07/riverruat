@isTest
public class WorkPlanTriggerHandlerTest {
  
    @testSetup
    static void setupTestData() {
        // Create Warranty Prior records
        List<Warranty_Prior__c> warrantyList = new List<Warranty_Prior__c>();
        for (Integer i = 0; i < 2; i++) {
            warrantyList.add(new Warranty_Prior__c( ));
        }
        insert warrantyList;
        
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '9876543210',
            Type = 'Customer'
        );
        insert testAccount;

        // Create a test WorkOrder
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = testAccount.Id
        );
        insert testWorkOrder;
        
        List<WorkPlan> workPlans = new List<WorkPlan>();
        for (Warranty_Prior__c wp : warrantyList) {
            workPlans.add(new WorkPlan(Name = 'Test WorkPlan', Warranty_Prior__c = wp.Id,ParentRecordId = testWorkOrder.id));
        }
        insert workPlans;
        
        // Create WorkOrderLineItem records linked to one Warranty Prior
        //insert new WorkOrderLineItem(Warranty_Prior__c = warrantyList[0].Id);
    }

    @isTest
    static void testHandleAfterDelete() {
        // Fetch WorkPlan records for deletion
        List<WorkPlan> workPlansToDelete = [SELECT Id, Warranty_Prior__c FROM WorkPlan];
        
        // Delete WorkPlan records
        delete workPlansToDelete;
        
        // Call the method explicitly (if needed in a different context)
        WorkPlanTriggerHandler.handleAfterDelete(workPlansToDelete);
    }
}