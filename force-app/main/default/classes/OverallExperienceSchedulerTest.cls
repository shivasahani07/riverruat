@isTest
public class OverallExperienceSchedulerTest {

    static Order testOrder;

    
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account', Type='Customer');
        insert acc;

        Contact con = new Contact(LastName='Test', Phone='9876543210', AccountId=acc.Id, Primary_Contact__c=true);
        insert con;

        Product2 prod = new Product2(Name='Test Product', IsActive=true, ProductCode='TP123', Type__c='Vehicle',HSN_Code__c='c342');
        insert prod;

        Id stdPricebookId = Test.getStandardPricebookId();
       PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPricebookId,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;

        Asset ast = new Asset(Name='Test Asset', AccountId=acc.Id, Product2Id=prod.Id);
        insert ast;

        VehicleDefinition vDef = new VehicleDefinition(Name='Test Def', ProductId=prod.Id);
        insert vDef;

        Software_Version__c sv = new Software_Version__c(Name='SV-Test');
        insert sv;

        Vehicle veh = new Vehicle(
            Name='Test Veh',
            Account__c=acc.Id,
            AssetId=ast.Id,
            VehicleDefinitionId=vDef.Id,
            Software_Version__c=sv.Id,
            PDI_Status_Pass__c=true,
            VehicleIdentificationNumber='v4et5', 
            Charger_PC_Number__c='w5vy'
        );
        insert veh;

        testOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            Status__c = 'Draft',
            Assigned_Vehicle__c = veh.Id,
            Delivery_Date__c = Date.today().addDays(-30),
            EffectiveDate = Date.today().addDays(-40),
            Pricebook2Id = stdPricebookId,
            Contact__c = con.Id,
            Payment_Status__c = 'Completed'
        );
        insert testOrder;
        
        OrderItem testOrderItem = new OrderItem( OrderId = testOrder.Id, Product2Id = prod.Id, UnitPrice = 100.0,Quantity = 1, PricebookEntryId = testPricebookEntry.Id);
        insert testOrderItem;
        
        testOrder.Status='Vehicle Delivered';
        update testOrder;
    }

    @isTest
    static void testSchedulerExecution() {
        setupTestData();

        Test.startTest();
        String jobId = System.schedule(
            'Test OverallExperienceScheduler',
            '0 0 12 * * ?', 
            new OverallExperienceScheduler()
        );
        Test.stopTest();

        
        List<Order> fetchedOrders = [
            SELECT Id, Delivery_Date__c
            FROM Order
            WHERE Delivery_Date__c = :Date.today().addDays(-30)
        ];
        System.assertEquals(1, fetchedOrders.size(), 'One Order should be scheduled for follow-up.');
    }
}