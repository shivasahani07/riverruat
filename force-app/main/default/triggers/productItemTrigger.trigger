trigger productItemTrigger on ProductItem (before insert, before update) {
    for (ProductItem item : Trigger.new) {
        item.Quantity_Inhand_New__c = 
            (item.Inward_Quantity__c != null ? item.Inward_Quantity__c : 0) -
            ((item.Transfer_Quantity__c != null ? item.Transfer_Quantity__c : 0) +
             (item.Consumed_Quantity__c != null ? item.Consumed_Quantity__c : 0));
    }
}