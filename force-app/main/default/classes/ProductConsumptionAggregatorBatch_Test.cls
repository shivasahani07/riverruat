@isTest
private class ProductConsumptionAggregatorBatch_Test {
    
    @testSetup
    static void setupTestData() {
        
		Schema.Location loc = new Schema.Location(
			Name = 'Store - Indiranagar',
            LocationType = 'Secondary',
            Dealer_Code__c = '291002',
            isInventoryLocation = true
        );
        insert loc;
        
        // Create Dealer Account
        Account dealer = new Account(
            Name = 'Test Dealer',
            Type = 'Dealer',
            Location__c = loc.Id,
            Center_Code__c = '378437'
        );
        insert dealer;
        
        // Create Dealer Account
        Account serviceCenter = new Account(
            Name = 'Test Service Center',
            Type = 'Service Center',
            Location__c = loc.Id,
            Center_Code__c = '378437'
        );
        insert serviceCenter;
        
        // Create Product
        Product2 prod = new Product2(
            Name = 'Side Step',
            ProductCode = 'P-001',
            Type__c = 'Parts',
            IsActive = true,
            Minimum_Order_Qty__c = 5,
            HSN_Code__c = 'HSN23455'
        );
        insert prod;

        // Create ProductItem
        ProductItem pi = new ProductItem(
            Product2Id = prod.Id,
            //Quantity_On_Hand = 50,
            //Quantity_In_Hand__c = 50,
            LocationId = loc.Id,
            Manual_Created_Date__c = System.today().addDays(-30) // within 6 months
        );
        insert pi;
        
        // Create Order linked to Dealer account
        Order ord = new Order(
            AccountId = dealer.Id,
            EffectiveDate = System.today(),
            Status = 'Draft'
        );
        insert ord;
		
        // Work Order
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'Open',
            Service_Center__c = serviceCenter.Id
        );
        insert wo;
        
        
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new ProductConsumptionAggregatorBatch(), 200);
        Test.stopTest();
    }
}