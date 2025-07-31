global class RVR_TestDataGenerator implements Database.Batchable<Integer>, Database.Stateful {
    
    private Integer totalRecords = 500;
    private List<Id> dealerIds = new List<Id>();
    private List<Id> productIds = new List<Id>();
    private List<Id> workOrderIds = new List<Id>();
    private List<Id> orderIds = new List<Id>();
    
    global RVR_TestDataGenerator() {
        // Get existing dealers
        List<Account> dealers = [SELECT Id FROM Account WHERE Type = 'Dealer'];
        for (Account dealer : dealers) {
            dealerIds.add(dealer.Id);
        }
        
        List<String> productIdsnew = new List<String>{'01tF4000008zqWmIAI', '01tF4000008zfjmIAA'};
        // Get existing products
        List<Product2> products = [SELECT Id FROM Product2 limit 5];
        for (Product2 product : products) {
            productIds.add(product.Id);
        }
        
        // Get existing work orders
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder LIMIT 50];
        for (WorkOrder wo : workOrders) {
            workOrderIds.add(wo.Id);
        }
        
        // Get existing orders
        List<Order> orders = [SELECT Id FROM Order LIMIT 50];
        for (Order order : orders) {
            orderIds.add(order.Id);
        }
        
        // If no existing data, create some basic records
        if (dealerIds.isEmpty()) {
            createBasicData();
        }
    }
    
    private void createBasicData() {
        // Create test dealers
        List<Account> testDealers = new List<Account>();
        for (Integer i = 1; i <= 5; i++) {
            testDealers.add(new Account(
                Name = 'Test Dealer ' + i,
                Type = 'Dealer'
            ));
        }
        //insert testDealers;
        
        for (Account dealer : testDealers) {
            dealerIds.add(dealer.Id);
        }
        
        // Create test products
        List<Product2> testProducts = new List<Product2>();
        for (Integer i = 1; i <= 10; i++) {
            testProducts.add(new Product2(
                Name = 'Test Product ' + i,
                ProductCode = 'TP' + String.valueOf(i).leftPad(3, '0')
            ));
        }
        //insert testProducts;
        
        for (Product2 product : testProducts) {
            //productIds.add(product.Id);
        }
        
        // Create test work orders
        List<WorkOrder> testWorkOrders = new List<WorkOrder>();
        for (Integer i = 1; i <= 20; i++) {
            testWorkOrders.add(new WorkOrder(
                Subject = 'Test Work Order ' + i,
                Service_Center__c = dealerIds[Math.mod(i, dealerIds.size())]
            ));
        }
        insert testWorkOrders;
        
        for (WorkOrder wo : testWorkOrders) {
            workOrderIds.add(wo.Id);
        }
        
        // Create test orders
        List<Order> testOrders = new List<Order>();
        for (Integer i = 1; i <= 20; i++) {
            testOrders.add(new Order(
                AccountId = dealerIds[Math.mod(i, dealerIds.size())],
                EffectiveDate = Date.today(),
                Status = 'Draft'
            ));
        }
        //insert testOrders;
        
        for (Order order : testOrders) {
            orderIds.add(order.Id);
        }
    }
    
    global Iterable<Integer> start(Database.BatchableContext BC) {
        List<Integer> recordNumbers = new List<Integer>();
        for (Integer i = 1; i <= totalRecords; i++) {
            recordNumbers.add(i);
        }
        return recordNumbers;
    }
    
    global void execute(Database.BatchableContext BC, List<Integer> scope) {
        List<ProductConsumed> productConsumedRecords = new List<ProductConsumed>();
        List<Sales_Consumption__c> salesConsumptionRecords = new List<Sales_Consumption__c>();
        
        for (Integer recordNum : scope) {
            // Create ProductConsumed records (60% of total)
            if (recordNum <= totalRecords * 0.6) {
                ProductConsumed pc = new ProductConsumed();
                pc.Product__c ='01tF4000008zfjmIAA';
                pc.Quantity_Consumed__c = getRandomQuantity();
                pc.Manual_Created_Date__c = getRandomDate();
                pc.WorkOrderId ='0WOBh000003T5fJOAS';
                PC.ProductItemId='0CoBh00000621sbKAA';
                pc.PricebookEntryId='01uF40000088DUWIA2';
                pc.QuantityConsumed =7;
                productConsumedRecords.add(pc);
            }
            // Create Sales_Consumption__c records (40% of total)
            else {
                Sales_Consumption__c sc = new Sales_Consumption__c();
                sc.Product__c = getRandomProductId(productIds);
                sc.Quantity_Consumed__c = getRandomQuantity();
                sc.Manual_Date_Test__c = getRandomDate();
                sc.Order__c = getRandomId(orderIds);
                salesConsumptionRecords.add(sc);
            }
        }
        
        // Insert records
        if (!productConsumedRecords.isEmpty()) {
            insert productConsumedRecords;
        }
        
        if (!salesConsumptionRecords.isEmpty()) {
            //insert salesConsumptionRecords;
        }
        
        System.debug('Created ' + productConsumedRecords.size() + ' ProductConsumed records');
        System.debug('Created ' + salesConsumptionRecords.size() + ' Sales_Consumption__c records');
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Test data generation completed!');
        System.debug('Total ProductConsumed records created: ~' + (totalRecords * 0.6));
        System.debug('Total Sales_Consumption__c records created: ~' + (totalRecords * 0.4));
    }
    
    private Id getRandomId(List<Id> idList) {
        if (idList.isEmpty()) return null;
        return idList[Math.mod(Integer.valueOf(Math.random() * 1000), idList.size())];
    }
    
    private Id getRandomProductId(List<Id> idList) {
    if (idList == null || idList.isEmpty()) {
        return null; // handle empty list
    }
    Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), idList.size());
    return idList[randomIndex];
}

    
    private Decimal getRandomQuantity() {
        // Generate random quantity between 1 and 100
        return Math.random() * 100 + 1;
    }
    
    private Date getRandomDate() {
        // Generate random date within last 6 months
        Date startDate = Date.today().addMonths(-8);
        Date endDate = Date.today();
        Integer daysDiff = startDate.daysBetween(endDate);
        Integer randomDays = Integer.valueOf(Math.random() * daysDiff);
        return startDate.addDays(randomDays);
    }
}