@isTest
public class RecordAddProductRequestLineItemNew_Test {
	   
    @testSetup
    static void setupData() {

        // Create Account
        Account acc = new Account(
            Name = 'Test Partner Account'
        );
        insert acc;
        
        // Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'contact@example.com',
            AccountId = acc.Id,
            Designation__c = 'WM',
            Phone = '8990785678'
        );
        insert con;
        
        // Create ProductRequest
        ProductRequest pr = new ProductRequest(
            Status = 'Draft',
            AccountId = acc.Id,
            Account__c = acc.Id,
            ShipmentType = 'STK'
        );
        insert pr;
    }
    
    @isTest
    static void testNotifyAndSendApproval() {
        
        ProductRequest pr = [SELECT Id FROM ProductRequest LIMIT 1];
        
        // Build productsnotSelected JSON
        List<Map<String, Object>> prodList = new List<Map<String, Object>>();
        Map<String, Object> prod1 = new Map<String, Object>{
            'ProductName' => 'Test Product A',
            'ProductCode' => 'TPA001',
            'AllocatedQuantity' => 10,
            'MOQ' => 5,
            'AvailableInventory' => 100
        };
        prodList.add(prod1);
        
        String jsonProducts = JSON.serialize(prodList);
        
        Test.startTest();
        String result = RecordAddProductRequestLineItemNew.notifyAndSendApprovalForUnselectedItems(
            jsonProducts,
            pr.Id
        );
        Test.stopTest();
        
        System.assertEquals('Done', result, 'The method should return Done for valid data');
    }
    
    
    // Method to create Test User
    private static User createTestUser(String alias, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Phone = '7899037383'
        );
        insert con;
        
        User u = new User(
            Username = alias + DateTime.now().getTime() + '@test.com',
            Alias = alias,
            Email = alias + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id
            //ContactId = con.Id
        );
        insert u;
        return u;
    }
    
    @IsTest
    static void testGetAllForecastQuantityUpdated() {
        User u = createTestUser('tusr', 'Standard User');
        
        // Create product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            Type__c = 'Parts',
            IsActive = true,
            HSN_Code__c = 'HSN-3874'
        );
        insert prod;
        
        // Create FortnightlyForecastInventory__c record
        FortnightlyForecastInventory__c fRec = new FortnightlyForecastInventory__c(
            Account__c = u.Contact.AccountId,
            Product__c = prod.Id,
            Six_Months_Average_Consumption__c = 10,
            Batch_Executed_Date__c = Date.today(),
            PO_Status__c = '',
            Quantity_Ordered__c = 5,
            Available_Inventory_Qty__c = 2
        );
        insert fRec;
        
        Test.startTest();
        
        List<String> filters = new List<String>{'Service','Sales','Merchandise','Accessories'};
        
        for (String filterVal : filters) {
            List<RecordAddProductRequestLineItemNew.ForecastWrapper> result =
                RecordAddProductRequestLineItemNew.getAllForcastQuantityUpdated(u.Id, filterVal);
            
            System.assertNotEquals(null, result, 'Result should not be null for filter: ' + filterVal);
        }
        Test.stopTest();
    }
}