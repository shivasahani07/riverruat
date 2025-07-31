global class GetFirstProductConsumptionDate_Batch implements Database.Batchable<SObject>{

    global static Database.QueryLocator start(Database.BatchableContext bc){
        
        System.debug('------------------- GetFirstProductConsumptionDate_Batch ---------------------');
        System.debug([SELECT Id FROM Account WHERE Type != 'Customer'].size());
        
        return Database.getQueryLocator([
            SELECT Id FROM Account WHERE Type != 'Customer'
        ]);
    }
    
    global static void execute(Database.BatchableContext bc, List<Account> scope){
        Set<Id> accountIds = new Set<Id>();
        
        for (Account acc : scope) {
            accountIds.add(acc.Id);
        }

        // Map to store First Consumption Date → key = AccountId|ProductId
        Map<String, Date> firstConsumptionMap = new Map<String, Date>();

        // -------- 1. Query Sales Consumption --------
        for (Sales_Consumption__c sc : [
            SELECT Dealer__c, Product__c, CreatedDate
            FROM Sales_Consumption__c
            WHERE Dealer__c IN :accountIds
            AND Order__r.Account.Type != 'Customer'
        ]) {
            if (sc.Dealer__c == null || sc.Product__c == null) continue;
            
            String key = sc.Dealer__c + '|' + sc.Product__c;
            Date consDate = sc.CreatedDate.date();
            
            if (!firstConsumptionMap.containsKey(key) || consDate < firstConsumptionMap.get(key)) {
                firstConsumptionMap.put(key, consDate);
            }
        }
        System.debug('------- firstConsumptionMap (Sales_Consumption__c) -------- ' + firstConsumptionMap.size());

        // -------- 2. Query ProductConsumed --------
        for (ProductConsumed pc : [
            SELECT WorkOrder.Service_Center__c, Product2Id, CreatedDate
            FROM ProductConsumed
            WHERE WorkOrder.Service_Center__c IN :accountIds
            AND WorkOrder.Service_Center__r.Type != 'Customer'
        ]) {
            if (pc.WorkOrder.Service_Center__c == null || pc.Product2Id == null) continue;
            
            String key = pc.WorkOrder.Service_Center__c + '|' + pc.Product2Id;
            Date consDate = pc.CreatedDate.date();
            
            if (!firstConsumptionMap.containsKey(key) || consDate < firstConsumptionMap.get(key)) {
                firstConsumptionMap.put(key, consDate);
            }
        }
        
        System.debug('------- firstConsumptionMap (ProductConsumed) -------- ' + firstConsumptionMap.size());
        
        // -------- 3. Prepare Parent → Child Records --------
        Map<Id, List<Month_Split__c>> accountToChildList = new Map<Id, List<Month_Split__c>>();

        for (String key : firstConsumptionMap.keySet()) {
            String[] parts = key.split('\\|');
            Id accId = (Id) parts[0];
            Id productId = (Id) parts[1];
            Date firstDate = firstConsumptionMap.get(key);

            if (!accountToChildList.containsKey(accId)) {
                accountToChildList.put(accId, new List<Month_Split__c>());
            }
            
            accountToChildList.get(accId).add(
                new Month_Split__c(
                    Product__c = productId,
                    First_Consumed_Date__c = firstDate
                )
            );
        }
        
        // -------- 4. Insert Parent and Child --------
        List<MSL_Batch_Summary__c> parents = new List<MSL_Batch_Summary__c>();
        for (Id accId : accountToChildList.keySet()) {
            parents.add(new MSL_Batch_Summary__c(Dealer__c = accId));
        }
        insert parents;

        // Map parent AccountId → inserted parent Id
        Map<Id, Id> accToParentId = new Map<Id, Id>();
        for (MSL_Batch_Summary__c parent : parents) {
            accToParentId.put(parent.Dealer__c, parent.Id);
        }
        
        // Prepare child records
        List<Month_Split__c> children = new List<Month_Split__c>();
        for (Id accId : accountToChildList.keySet()) {
            for (Month_Split__c child : accountToChildList.get(accId)) {
                child.MSL_Batch_Summary__c = accToParentId.get(accId);
                children.add(child);
            }
        }

        if (!children.isEmpty()) {
            insert children;
        }
        
    }
    
    global static void finish(Database.BatchableContext bc){
        System.debug('First Consumption Date capture completed.');
    }
    
}