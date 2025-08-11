global class ProductConsumedRollupBatch implements Database.Batchable<Id>, Database.Stateful {
    
    private Set<Id> productInventoryIds;
    
    global ProductConsumedRollupBatch(Set<Id> productInventoryIds) {
        this.productInventoryIds = productInventoryIds;
    }
    
    global Iterable<Id> start(Database.BatchableContext BC) {
        // Return the ProductItem IDs to process
        return productInventoryIds;
    }
    
    global void execute(Database.BatchableContext BC, List<Id> scope) {
        try {
            List<ProductItem> productItemsToUpdate = new List<ProductItem>();
            
            // Process each ProductItem ID in the current scope
            for (Id productItemId : scope) {
                // Get the total consumed quantity for this ProductItem
                List<AggregateResult> consumptionResults = [
                    SELECT SUM(Quantity_Consumed__c) totalConsumed
                    FROM ProductConsumed 
                    WHERE ProductItemId = :productItemId
                ];
                
                Decimal totalConsumed = 0;
                if (!consumptionResults.isEmpty() && consumptionResults[0].get('totalConsumed') != null) {
                    totalConsumed = (Decimal)consumptionResults[0].get('totalConsumed');
                }
                
                // Create ProductItem update record
                ProductItem itemToUpdate = new ProductItem();
                itemToUpdate.Id = productItemId;
                itemToUpdate.Consumed_Quantity__c = totalConsumed;
                
                productItemsToUpdate.add(itemToUpdate);
            }
            
            // Perform DML outside the loop - industry best practice
            if (!productItemsToUpdate.isEmpty()) {
                update productItemsToUpdate;
                System.debug('Batch updated ' + productItemsToUpdate.size() + ' ProductItem records in scope');
            }
            
        } catch (Exception e) {
            System.debug('Error in ProductConsumedRollupBatch execute: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('ProductConsumedRollupBatch completed processing for ' + productInventoryIds.size() + ' ProductItems');
        
        // Log batch job details
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate
            FROM AsyncApexJob 
            WHERE Id = :BC.getJobId()
        ];
        
        System.debug('Batch Job Status: ' + job.Status);
        System.debug('Items Processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
        System.debug('Errors: ' + job.NumberOfErrors);
    }
}