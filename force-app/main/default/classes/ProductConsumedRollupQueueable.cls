public class ProductConsumedRollupQueueable implements Queueable {
    Set<Id> productInventoryIds;

    public ProductConsumedRollupQueueable(Set<Id> ids) {
        productInventoryIds = ids;
    }

    public void execute(QueueableContext qc) {
        processRollup(productInventoryIds);
    }

    private void processRollup(Set<Id> productInventoryIds) {
        List<ProductItem> productItemToUpdate = new List<ProductItem>();

        List<AggregateResult> totalQuantityCosumedCalculation = [
            SELECT ProductItemId, SUM(Quantity_Consumed__c) totalCount
            FROM ProductConsumed
            WHERE ProductItemId IN :productInventoryIds
            GROUP BY ProductItemId
        ];

        Set<Id> productItemIdsWithValue = new Set<Id>();
        for (AggregateResult ag : totalQuantityCosumedCalculation) {
            Id productItemId = (Id)ag.get('ProductItemId');
            productItemIdsWithValue.add(productItemId);
            productItemToUpdate.add(new ProductItem(
                Id = productItemId,
                Consumed_Quantity__c = (Double)ag.get('totalCount')
            ));
        }

        List<ProductItem> productInventoryList = [
            SELECT Id FROM ProductItem WHERE Id IN :productInventoryIds
        ];
        for (ProductItem pI : productInventoryList) {
            if (!productItemIdsWithValue.contains(pI.Id)) {
                productItemToUpdate.add(new ProductItem(
                    Id = pI.Id,
                    Consumed_Quantity__c = 0
                ));
            }
        }

        if (!productItemToUpdate.isEmpty()) {
            update productItemToUpdate;
        }
    }
}