public class POReviewCompController {

    @AuraEnabled(cacheable=true)
    public static List<POReviewWrapper> getPOLineItems(Id poId) {
        List<POReviewWrapper> wrapper = new List<POReviewWrapper>();

        for (ProductRequestLineItem line : [
            SELECT Id, Product2Id, Product2.Name, Forecast_Quantity__c, QuantityRequested, Approval_Status__c, Was_Previously_Deleted__c
            FROM ProductRequestLineItem
            WHERE ParentId = :poId AND Is_Deleted_Item__c = false
        ]) {
            wrapper.add(new POReviewWrapper(
                line.Id, 
                line.Product2Id, 
                line.Product2.Name,
                line.Forecast_Quantity__c, 
                line.QuantityRequested,
                line.Approval_Status__c,
                line.Was_Previously_Deleted__c
            ));
        }
        System.debug('wrapper :  ' + wrapper.size());
        return wrapper;
    }

    @AuraEnabled(cacheable = true)
    public static void getProductMOQ(){

    }

    @AuraEnabled
    public static void updatePOLineItems(Id poId, String jsonString) {
        List<ProductRequestLineItem> updateList = new List<ProductRequestLineItem>();
        List<POReviewWrapper> incoming = (List<POReviewWrapper>) JSON.deserialize(jsonString, List<POReviewWrapper>.class);

        for (POReviewWrapper item : incoming) {
            if (item.Id == null && item.IsNew) {
                ProductRequestLineItem pli = new ProductRequestLineItem(
                    ParentId = poId,
                    Product2Id = item.Product2Id,
                    QuantityRequested = item.QuantityRequested,
                    Forecast_Quantity__c = 0,
                    //Approval_Status__c = item.ApprovalStatus,
                    Is_Manually_Added__c = true
                );
                updateList.add(pli);
            } else {
                ProductRequestLineItem pli = new ProductRequestLineItem(
                    Id = item.Id,
                    QuantityRequested = item.QuantityRequested
                    //Approval_Status__c = item.ApprovalStatus
                );
                updateList.add(pli);
            }
        }

        if (!updateList.isEmpty()) {
            upsert updateList;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getAllProducts() {
        return [SELECT Id, Name, Minimum_Order_Qty__c FROM Product2 WHERE IsActive = true LIMIT 200];
    }

    @AuraEnabled
    public static void softDeleteLineItem(Id lineItemId) {
        ProductRequestLineItem lineItem = [SELECT Id, Product2Id, AccountId, ParentId, QuantityRequested, Forecast_Quantity__c, Related_Tracking_IDs_c__c
            FROM ProductRequestLineItem 
            WHERE Id = :lineItemId 
            LIMIT 1];
        
        //delete lineItem;

        /*
        lineItem.Is_Deleted_Item__c = true;
        update lineItem;
        */
        
        /*
        Deleted_POLI__c d = new Deleted_POLI__c(
            Product__c = lineItem.Product2Id,
            Account__c = lineItem.AccountId,
            Purchase_Order__c = lineItem.ParentId,
            Deleted_POLI_Id__c = lineItem.Id,
            Quantity_Requested__c = lineItem.QuantityRequested,
            Forecast_Quantity__c = lineItem.Forecast_Quantity__c,
            Is_Deleted_Item__c = true
        );
        insert d;
        */

        // Update Product Consumption Tracking to unmark Processed_for_PO__c
        if(lineItem.Related_Tracking_IDs_c__c != null && lineItem.Related_Tracking_IDs_c__c != ''){

            // Split into List<String> first
            List<String> idStrings = lineItem.Related_Tracking_IDs_c__c.split(',');

            // Convert to List<Id>
            List<Id> idList = new List<Id>();
            for (String s : idStrings) {
                idList.add(Id.valueOf(s.trim()));
            }

            List<ProductConsumptionTracking__c> trackingRecords = [
                SELECT Id, Processed_for_PO__c 
                FROM ProductConsumptionTracking__c 
                WHERE Id IN : idList
            ];

            for (ProductConsumptionTracking__c record : trackingRecords) {
                record.Processed_for_PO__c = false;
            }

            if (!trackingRecords.isEmpty()) {
                update trackingRecords;
            }
        }
        
        delete lineItem;
        
    }

    @AuraEnabled
    public static void markPOSubmitted(Id poId) {
        ProductRequest po = [SELECT Id, PO_Submitted__c FROM ProductRequest WHERE Id = :poId LIMIT 1];
        po.PO_Submitted__c = true;
        po.PO_Approval_Status__c = 'Submitted';
        
        try {
            update po;
            System.debug('*** PO updated successfully');
        } catch (Exception e) {
            System.debug('*** Error updating PO: ' + e.getMessage());
            throw new AuraHandledException('Failed to update PO: ' + e.getMessage());
        }

    }


    public class POReviewWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public Id Product2Id;
        @AuraEnabled public String ProductName;
        @AuraEnabled public Decimal ForecastQty;
        @AuraEnabled public Decimal QuantityRequested;
        @AuraEnabled public String ApprovalStatus;
        @AuraEnabled public Boolean WasPreviouslyDeleted;
        @AuraEnabled public Boolean IsNew;

        public POReviewWrapper(Id Id, Id Product2Id, String ProductName, Decimal ForecastQty, Decimal QuantityRequested, String ApprovalStatus, Boolean WasPreviouslyDeleted) {
            this.Id = Id;
            this.Product2Id = Product2Id;
            this.ProductName = ProductName;
            this.ForecastQty = ForecastQty;
            this.QuantityRequested = QuantityRequested;
            this.ApprovalStatus = ApprovalStatus;
            this.WasPreviouslyDeleted = WasPreviouslyDeleted;
        }
    }
}