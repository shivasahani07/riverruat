/**
* Scheduled Apex to generate Purchase Orders every 15 days based on stored MSL values
**/
global class POGenerationScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        
        System.debug('---------------- POGenerationScheduler ---------------- ');
        List<ProductConsumptionTracking__c> eligibleList = [
            SELECT Id, Account__c, Product__c, MSL_Value__c
            FROM ProductConsumptionTracking__c
            WHERE Is_MSL_Eligible__c = true AND MSL_Value__c != null
        ];
        System.debug('eligibleList : ' + eligibleList);
        
        Map<Id, ProductRequest> poMap = new Map<Id, ProductRequest>();
        List<ProductRequest> poList = new List<ProductRequest>();
        
        // 1. Collect unique POs
        for(ProductConsumptionTracking__c track : eligibleList) {
            if(!poMap.containsKey(track.Account__c)) {
                ProductRequest po = new ProductRequest();
                po.Account__c = track.Account__c;
                po.Status = 'Draft';
                po.ShipmentType = 'STK';
                poList.add(po);
                poMap.put(track.Account__c, po);
            }
        }
        
        // 2. Insert POs
        if(!poList.isEmpty()){
        	insert poList;   
        }
        
        // 3. Map inserted PO Ids back to Accounts
        Map<Id, Id> accountToPoIdMap = new Map<Id, Id>();
        for(ProductRequest po : poList) {
            accountToPoIdMap.put(po.Account__c, po.Id);
        }
        
        // 4. Create Line Items
        List<ProductRequestLineItem> lineItems = new List<ProductRequestLineItem>();
        
        for(ProductConsumptionTracking__c track : eligibleList) {
            ProductRequestLineItem line = new ProductRequestLineItem();
            line.Product2Id = track.Product__c;
            line.Forecast_Quantity__c = track.MSL_Value__c;
            line.ParentId = accountToPoIdMap.get(track.Account__c);
            line.QuantityRequested = track.MSL_Value__c;	// Mandatory Field
            lineItems.add(line);
        }
        
        if(!lineItems.isEmpty()){
        	insert lineItems;    
        }
        
        // Notification logic to Dealer Principal, WM, Parts In-Charge would be added here
    }
}