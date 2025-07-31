global class RejectSpareApprovalBatch implements Database.Batchable<SObject>, Schedulable {

   
    /*global Database.QueryLocator start(Database.BatchableContext bc) {
        Date fiveDaysAgo = Date.today().addDays(-5);
        System.debug('Five days ago: ' + fiveDaysAgo);

       /* return Database.getQueryLocator([
            SELECT Id, Spare_Approval__c, Re_Submit_Date__c
            FROM Discrepancy_Line_Item__c
            WHERE Spare_Approval__c = 'Re-Submit'
              AND Re_Submit_Date__c = :fiveDaysAgo
        ]);
    }*/
    global Iterable<SObject> start(Database.BatchableContext bc) {
        Date fiveDaysAgo = Date.today().addDays(-5);
        System.debug('Five days ago: ' + fiveDaysAgo);

        List<Discrepancy_Line_Item__c> diList=[SELECT Id, Spare_Approval__c, Re_Submit_Date__c
            FROM Discrepancy_Line_Item__c
            WHERE Spare_Approval__c = 'Re-Submit'
              AND Re_Submit_Date__c = :fiveDaysAgo];
            
        return diList;
    }

     
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('Processing batch size: ' + scope.size());
        
        List<Discrepancy_Line_Item__c> updates = new List<Discrepancy_Line_Item__c>();

        for (SObject s : scope) {
            Discrepancy_Line_Item__c dli = (Discrepancy_Line_Item__c)s;
            System.debug('Updating DLI Id: ' + dli.Id);
            dli.Spare_Approval__c = 'Rejected';
            updates.add(dli);
        }

        if (!updates.isEmpty()) {
            update updates;
            System.debug('Updated ' + updates.size() + ' records to Rejected');
        }
    }

  
    global void finish(Database.BatchableContext bc) {
        System.debug('RejectSpareApprovalBatch completed.');
    }

     
    global void execute(SchedulableContext sc) {
        RejectSpareApprovalBatch batch = new RejectSpareApprovalBatch();
        Database.executeBatch(batch, 100);
    }
}