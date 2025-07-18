trigger SalesConsumptionTrigger on Sales_Consumption__c (after insert) {
	
    if(Trigger.isAfter && Trigger.isInsert){
        
        // Get the Order Ids
        Set<Id> orderIds = new Set<Id>();
        for(Sales_Consumption__c con : Trigger.new){
            orderIds.add(con.Order__C);
        }
        
        // Query Order with Dealer / Account Info
        Map<Id, Order> orderMap = new Map<Id, Order>(
        	[SELECT Id, AccountId FROM Order WHERE Id IN :orderIds]
        );
        
        // Prepare Unique Dealer + Product Combination Key
        Set<String> dealerProductKeys = new Set<String>();
		Map<String, Date> dealerProductToDateMap = new Map<String, Date>();
        
        for(Sales_Consumption__c con : Trigger.new){
            if(con.Product__c != null && con.Order__c != null && orderMap.containsKey(con.Order__c)) {
                Id dealerId = orderMap.get(con.Order__c).AccountId;
                if(dealerId == null) continue;
    
                String key = dealerId + '-' + con.Product__c;
                dealerProductKeys.add(key);
    
                Date consumptionDate = con.CreatedDate.date(); // Assuming CreatedDate as consumption date
                if(!dealerProductToDateMap.containsKey(key) || consumptionDate < dealerProductToDateMap.get(key)) {
                    dealerProductToDateMap.put(key, consumptionDate);
                }
        	}
        }
        
        
        
    }
}