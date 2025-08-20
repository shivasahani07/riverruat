/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 04-10-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class WorkOrderLineItemController {
    
    public class ProductHandlerWrapper{
        @AuraEnabled public PricebookEntry returnPriceBook;
        @AuraEnabled public TFR_Part_Effect__c EffectedParts;
    }
    
    
    @AuraEnabled
    public static ProductHandlerWrapper getPricebookEntry(String productId) {
        system.debug('productId----'+productId);
        ProductHandlerWrapper prepareData = new ProductHandlerWrapper();
        
        try {
            // Fetch PricebookEntry
            List<PricebookEntry> pricebookList = [
                SELECT Id, UnitPrice, Product2.Name, Product2.ProductCode 
                FROM PricebookEntry 
                WHERE Product2Id = :productId 
                AND Pricebook2.IsStandard = TRUE 
                LIMIT 1
            ];
            
            if (!pricebookList.isEmpty()) {
                prepareData.returnPriceBook = pricebookList[0];
            } else {
                throw new AuraHandledException('No Pricebook Entry found for this Product.');
            }
            
            // Fetch TFR_Part_Effect__c
            List<TFR_Part_Effect__c> partEffectList = [
                SELECT Id, Comments__c, Consequence__c, Product__c, Root_Cause__c, TFR__c, Name 
                FROM TFR_Part_Effect__c 
                WHERE Product__c = :productId AND TFR__r.Is_Active__c = TRUE 
                LIMIT 1
            ];
            
            if (!partEffectList.isEmpty()) {
                prepareData.EffectedParts = partEffectList[0];
            }
            
            System.debug('prepareData----' + prepareData);
            return prepareData;
            
        } catch (AuraHandledException e) {
            throw e; // rethrow custom handled exception
        } catch (Exception ex) {
            throw new AuraHandledException('An unexpected error occurred: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void createWorkOrderLineItemsold(List<WorkOrderLineItem> lineItems) {
        try {
            system.debug('lineItems---'+lineItems);
            insert lineItems;
        } catch (DmlException ex) {
            throw new AuraHandledException('Error inserting Work Order Line Items: ' + ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException('Unexpected error: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void createWorkOrderLineItems(List<WorkOrderLineItem> lineItems) {
        system.debug('lineItems---'+lineItems);
        Savepoint sp = Database.setSavepoint();
        try {
            // First, sort items to ensure parents come before children
            List<WorkOrderLineItem> sortedItems = new List<WorkOrderLineItem>();
            
            // Add parent items first (those without parent sequence)
            for (WorkOrderLineItem item : lineItems) {
                if (item.Parent_Sequence_Number__c == null) {
                    sortedItems.add(item);
                }
            }
            
            // Then add child items
            for (WorkOrderLineItem item : lineItems) {
                if (item.Parent_Sequence_Number__c != null) {
                    sortedItems.add(item);
                }
            }
            
            // Insert all items
            insert sortedItems;
            
            // Create a map of sequence numbers to record IDs
            Map<Decimal, Id> sequenceToId = new Map<Decimal, Id>();
            for (WorkOrderLineItem item : sortedItems) {
                sequenceToId.put(item.Sequence_Number__c, item.Id);
            }
            
            // Update child items with parent relationships
            List<WorkOrderLineItem> itemsToUpdate = new List<WorkOrderLineItem>();
            for (WorkOrderLineItem item : sortedItems) {
                if (item.Parent_Sequence_Number__c != null && sequenceToId.containsKey(item.Parent_Sequence_Number__c)) {
                    itemsToUpdate.add(new WorkOrderLineItem(
                        Id = item.Id,
                        Part__c = sequenceToId.get(item.Parent_Sequence_Number__c)
                    ));
                }
            }
            
            if (!itemsToUpdate.isEmpty()) {
                update itemsToUpdate;
            }
            
        } catch (Exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException('Error creating line items: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<WorkOrderLineItem> getRelatedWorkOrderLineItems(Id workOrderId){
        try{
            System.debug('Fetching related Products for Work Order Id: ' + workOrderId);
            List<WorkOrderLineItem> WorkOrderLineItems = [SELECT WorkOrderId, Id, LineItemNumber,Part__c, PricebookEntryId, PricebookEntry.Product2.Name,
                                                          Quantity, RR_Parts_Category__c, Status,WorkOrder.Status,WorkOrder.Vehicle_Identification_Number__c,Replacement_Type__c,
                                                          PricebookEntry.Product2.ProductCode,CreatedDate,WorkOrder.WorkOrderNumber, PricebookEntry.Product2Id,Labour_Code__c,Labour_Code__r.Name, Product2.ProductCode
                                                          FROM WorkOrderLineItem
                                                          WHERE WorkOrderId=: workOrderId
                                                          ORDER BY CreatedDate ASC limit 20];
            System.debug('Retrieved related WorkOrderLineItems: ' + WorkOrderLineItems);
            
            RETURN WorkOrderLineItems;
        }catch(exception e){
            system.debug('Error Message'+e.getMessage()+ ' at Line Number'+ e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static Warranty_Prior__c getWarrantyForJobCard(Id workOrderId) {
        system.debug('workOrderId'+workOrderId);
        // check here wgich workorderid is coming
        try{
            Warranty_Prior__c warranty = [
                SELECT Id,Status__c
                FROM Warranty_Prior__c
                WHERE Job_Card__c = :workOrderId
                LIMIT 1
            ];
            return warranty != null ? warranty : null;
        }catch(exception e){
            system.debug('Error Message'+e.getMessage()+ ' at Line Number'+ e.getLineNumber());
            return null;
        }
    }
    //additional code by Aniket on 20/01/2025 for Deleting added Parts added code by Astitva for deletion of the jobcard 
    @AuraEnabled
    public static void deleteWorkOrderLineItemApex(String rowId , Id workOrderId){
        system.debug('JobCard'+ workOrderId);
        WorkOrder JobCard = [Select Id ,Status from WorkOrder WHERE Id = :workOrderId LIMIT 1];
        If( JobCard.Status == 'Completed'|| JobCard.Status == 'Cancellation Requested' || JobCard.Status == 'Canceled' ){
            system.debug('you cannot delete this record as it is already in Final Stage');
        }else{
            system.debug('ProductConsumed'+ [Select Id, WorkOrderLineItemId  from ProductConsumed where WorkOrderLineItemId =:rowId]);
            delete [Select Id, WorkOrderLineItemId from ProductConsumed where WorkOrderLineItemId =:rowId];
            
            delete [Select Id from WorkOrderLineItem WHERE Id=:rowId];
        }
        
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getAvailableQuantity(Id productId, Id workOrderId) {
        try {
            System.debug('Fetching available quantity of Product ' + productId + ' in WorkOrder ' + workOrderId);
            
            
            WorkOrder wo = [SELECT Dealer_Contact__r.Location__c FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
            System.debug('Fetched WorkOrder: ' + wo);
            
            if (wo.Dealer_Contact__r.Location__c == null) {
                System.debug('No Location found for the WorkOrder: ' + workOrderId);
                throw new AuraHandledException('No Location found for this Work Order.');
            }
            
            Id locationId = wo.Dealer_Contact__r.Location__c;
            // Id locationId = wo.Contact.Location__c;
            System.debug('Location ID for WorkOrder ' + workOrderId + ': ' + locationId);
            
            // ProductItem productInventory = [SELECT Quantity_In_Hand__c FROM ProductItem WHERE Product2Id = :productId AND LocationId = :locationId LIMIT 1];
            // System.debug('Fetched ProductItem: ' + productInventory);
            
            List<ProductItem> productInventories = [
                SELECT Quantity_In_Hand__c,Product2Id,LocationId
                FROM ProductItem
                WHERE Product2Id = :productId AND LocationId = :locationId
            ];
            System.debug('productInventories==>'+productInventories);
            if (!productInventories.isEmpty()) {
                return productInventories[0].Quantity_In_Hand__c;
            } else {
                return 0;
            }
            
        } catch (Exception e) {
            System.debug('Error fetching available quantity: ' + e.getMessage());
            return -1;
        }
    }
    
    /*
@AuraEnabled(cacheable=true)
public static Decimal getAvailableQuantity(Id productId, Id workOrderId) {
try {
System.debug('Fetching available quantity of Product ' + productId + ' in WorkOrder ' + workOrderId);

WorkOrder wo = [SELECT Contact.Location__c FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];

if (wo.Contact.Location__c == null) {
throw new AuraHandledException('No Location found for this Work Order.');
}

Id locationId = wo.Contact.Location__c;
System.debug('Location ID: ' + locationId);

ProductItem productInventory = [SELECT Quantity_In_Hand__c 
FROM ProductItem 
WHERE Product2Id = :productId 
AND LocationId = :locationId 
LIMIT 1];

Decimal availableStock = productInventory != null ? productInventory.Quantity_In_Hand__c : 0;
System.debug('Current Stock: ' + availableStock);

Decimal allocatedQuantity = 0;
List<WorkOrderLineItem> existingLines = [SELECT Quantity 
FROM WorkOrderLineItem 
WHERE WorkOrderId = :workOrderId 
AND Product2Id = :productId];

for (WorkOrderLineItem line : existingLines) {
allocatedQuantity += line.Quantity;
}

System.debug('Allocated Quantity: ' + allocatedQuantity);

Decimal remainingStock = availableStock - allocatedQuantity;
System.debug('Final Available Stock: ' + remainingStock);

return remainingStock > 0 ? remainingStock : 0; 
} catch (Exception e) {
System.debug('Error fetching available quantity: ' + e.getMessage());
return -1; 
}
}
*/
    
    
}