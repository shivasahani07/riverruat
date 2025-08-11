/**
 * Industry-standard trigger handler following Salesforce best practices
 * for handling large data volumes using asynchronous processing
 */
public class ProductConsumedTriggerHandler {
    
    // Static variable to prevent recursive execution - industry best practice
    private static Boolean isExecuting = false;
    
    /**
     * Main method to handle ProductConsumed rollup calculation
     * Follows industry best practices: bulkification, asynchronous processing for large datasets
     */
    public static void rollUpOfQuantityConsumed(List<ProductConsumed> newProductConsumedList, Map<Id,ProductConsumed> oldMapOfProductConsumed){
        try{
            // Prevent recursive execution - industry standard pattern
            if (isExecuting) {
                return;
            }
            isExecuting = true;
            
            // Use Set for better performance - industry best practice
            Set<Id> productInventoryIds = new Set<Id>();
            
            // Bulkify: Process all records in collection - industry best practice
            for(ProductConsumed p : newProductConsumedList){
                // Add ProductItem IDs for new records
                if(p.ProductItemId != null){
                    productInventoryIds.add(p.ProductItemId); 
                }
                
                // Handle update scenarios - compare old vs new values
                if (oldMapOfProductConsumed != null && oldMapOfProductConsumed.containsKey(p.Id)) {
                    ProductConsumed oldRecord = oldMapOfProductConsumed.get(p.Id);
                    if (p.Quantity_Consumed__c != oldRecord.Quantity_Consumed__c) {
                        // Add both old and new ProductItem IDs for updates
                        if (p.ProductItemId != null) {
                            productInventoryIds.add(p.ProductItemId);
                        }
                        if (oldRecord.ProductItemId != null) {
                            productInventoryIds.add(oldRecord.ProductItemId);
                        }
                    }
                }
            }  
            
            System.debug('ProductInventory IDs to process: ' + productInventoryIds.size());
            
            // Industry best practice: Always use Batch Apex for bulk operations
            if (!productInventoryIds.isEmpty()) {
                // Check if we're already in an async context to avoid chaining issues
                if (!System.isBatch() && !System.isQueueable() && !System.isFuture()) {
                    // Use Batch Apex for ALL scenarios - industry recommended approach
                    Database.executeBatch(new ProductConsumedRollupBatch(productInventoryIds), 200);
                    System.debug('Processing ' + productInventoryIds.size() + ' ProductItems using Batch Apex (industry best practice)');
                } else {
                    // Already in async context, log and skip to avoid chaining issues
                    System.debug('Already in async context. Skipping batch processing for ' + productInventoryIds.size() + ' ProductItems to avoid chaining');
                }
            }
            
        } catch(Exception e){
            System.debug('Error in ProductConsumedTriggerHandler: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        } finally {
            isExecuting = false;
        }
    }
   
}