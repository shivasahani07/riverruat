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
		
        // Create Sales Consumption
        List<Sales_Consumption__c> lstSalesConsumption = new List<Sales_Consumption__c>();
        
        for(Integer i = 6; i >= 1; i--){
            Sales_Consumption__c sale = new Sales_Consumption__c(
                Product__c = prod.Id,
                Quantity_Consumed__c = 10,
                Manual_Date_Test__c = System.today().addMonths(-i), // inside 6 months
                Product_Inventory__c = pi.Id,
                Order__c = ord.Id
            );
            lstSalesConsumption.add(sale);
        }
        insert lstSalesConsumption;
        
        // Work Order
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'Open',
            Service_Center__c = serviceCenter.Id
        );
        insert wo;
        
        // Product Consumed
        ProductConsumed pc = new ProductConsumed(
            //Product2Id = prod.Id,
            ProductItemId = pi.Id,
            WorkOrderId = wo.Id,
            QuantityConsumed = 5,
            Manual_Created_Date__c = System.today().addDays(-10)
        );
        insert pc;
        
        
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new ProductConsumptionAggregatorBatch(), 200);
        Test.stopTest();
    }
}