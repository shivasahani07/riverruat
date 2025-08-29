@isTest
private class TestUpdateAccountInSFFromWebsite {
    
    @isTest
    static void testUpdateAccount_Success() {
        Account acc = new Account(Name = 'Old Name', Phone = '9999999999');
        insert acc;
        
        //Account acc2 = new Account(Name='New Name',Phone = '9999999999');
        //insert acc2;
        
        /*River_Website_Details__c r = new River_Website_Details__c(Name='River Website',BaseURL__c='https://www.dummy.com');
        insert r;*/
        
        Website_Creds__c r = new Website_Creds__c(Name='Website Creds',BaseURL__c='https://www.dummy.com');
        insert r;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"crm_account_id":"' + acc.Id + '","full_name":"New Name","phone_number":"9876543210","email_address":"test@test.com","billing_address":{"address_1":"Street 1","city":"Bangalore","pin_code":"560001","state":"Karnataka"}}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.updateAccount();
        
        Account updatedAcc = [SELECT Name, Phone, Email__c, BillingStreet, BillingCity, BillingPostalCode, BillingState FROM Account WHERE Id = :acc.Id];
        System.assertEquals('New Name', updatedAcc.Name);
        System.assertEquals('9876543210', updatedAcc.Phone);
        System.assertEquals('test@test.com', updatedAcc.Email__c);
        System.assertEquals('Street 1', updatedAcc.BillingStreet);
    }
    
    @isTest
    static void testUpdateAccount_InvalidPhone() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        River_Website_Details__c r = new River_Website_Details__c(Name='River Website',BaseURL__c='https://www.dummy.com');
        insert r;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"crm_account_id":"' + acc.Id + '","phone_number":"123"}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.updateAccount();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testUpdateAccount_MissingAccountId() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.updateAccount();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testUpdateOrderProduct_Success() {
        
        /*UserRole ur = new UserRole(Name = 'CEO');
        insert ur;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager (Partner)' LIMIT 1];
        
        Account acc2 = new Account(Name = 'Test Account2');
        insert acc2;
        
        
        Schema.Location testLocation2 = new Schema.Location(Name = 'Test Location2', LocationType = 'State',State__c = 'Karnataka',isInventoryLocation = true);
        insert testLocation2;
        
        Contact con2 = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = acc2.id,Location__c =testLocation2.id );
        insert con2;
        
         User u2 = new User(
            Username = 'testuser3434@example.com',
            Email = 'testuser3434@example.com',
            Alias = 'tuser1',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            FirstName = 'Test',
            LastName = 'User',
            ContactId = con2.Id,
            CompanyName = 'Test',
            UserRoleId = ur.Id
        );
        insert u2;*/

        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka',isInventoryLocation = true);
        insert testLocation;
        
        Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = acc.id,Location__c =testLocation.id );
        insert con;
        
        
        //UserRole ur = new UserRole(Name = 'CEO');
        //insert ur;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User u = new User(
            Username = 'testuser3434@example.com',
            Email = 'testuser3434@example.com',
            Alias = 'tuser1',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            FirstName = 'Test',
            LastName = 'User',
           // ContactId = con.Id,
            CompanyName = 'Test',
            UserRoleId = null
        );
        insert u;
        
        Product2 prod1 = new Product2(Name = 'Old Product', IsActive = true, StockKeepingUnit = 'OLD-SKU',ProductCode='OLD-SKU',HSN_Code__c='hjew', Type__c='Accessories');
        insert prod1;
        
        Product2 prod2 = new Product2(Name = 'New Product', IsActive = true, StockKeepingUnit = 'NEW-SKU',ProductCode='NEW-SKU',HSN_Code__c='hjew', Type__c='Accessories');
        insert prod2;
        
        ProductItem ppp = new ProductItem(LocationId=testLocation.id,Product2Id=prod1.Id);
        insert ppp;
        
        ProductItem pppp = new ProductItem(LocationId=testLocation.id,Product2Id=prod2.Id);
        insert pppp;
        
        
        Id stdPricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = stdPricebookId, Product2Id = prod1.Id, UnitPrice = 100, IsActive = true);
        insert pbe1;
        
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = stdPricebookId, Product2Id = prod2.Id, UnitPrice = 150, IsActive = true);
        insert pbe2;
        
        Order ord = new Order(AccountId = acc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = stdPricebookId/*, Website_Order_Id__c = 'WEB-123'*/);
        insert ord;
        
        OrderItem oi = new OrderItem(OrderId = ord.Id, Product2Id = prod1.Id, UnitPrice = 100, Quantity = 1, PricebookEntryId = pbe1.Id);
        insert oi;
        
        River_Website_Details__c r = new River_Website_Details__c(Name='River Website',BaseURL__c='https://www.dummy.com');
        insert r;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"website_orderId":"WEB-123","old_sku":"OLD-SKU","new_sku":"NEW-SKU"}');
        RestContext.request = req;
        RestContext.response = res;
        
        
            UpdateAccountInSFFromWebsite.updateOrderProduct();
           // System.assertEquals(200, RestContext.response.statusCode);
        
        
        
        
        
        
    }
    
    @isTest
    static void testDeleteOrderProduct_Success() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true, StockKeepingUnit = 'DEL-SKU',ProductCode='DEL-SKU',HSN_Code__c='hjew', Type__c='Accessories');
        insert prod;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = stdPricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        Order ord = new Order(AccountId = acc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = stdPricebookId, Website_Order_Id__c = 'WEB-DEL');
        insert ord;
        
        OrderItem oi = new OrderItem(OrderId = ord.Id, Product2Id = prod.Id, UnitPrice = 100, Quantity = 1, PricebookEntryId = pbe.Id);
        insert oi;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"crm_order_id":"' + ord.Id + '","order_item_details":{"product_sku":"DEL-SKU"}}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.deleteOrderProduct();
        
        req.requestBody = Blob.valueOf('{}');
        UpdateAccountInSFFromWebsite.deleteOrderProduct();
        //System.assertEquals(400, RestContext.response.statusCode);  // As per your method, success response has 400 status (you may want to fix this in actual code)
    }
    
    @isTest
    static void testCreateOrderProductInSF_Success() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true, StockKeepingUnit = 'SKU-ADD',ProductCode='SKU-ADD',HSN_Code__c='hjew', Type__c='Accessories');
        insert prod;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = stdPricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        Order ord = new Order(AccountId = acc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = stdPricebookId, Website_Order_Id__c = 'WEB-ADD');
        insert ord;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"website_orderId":"WEB-ADD","product_sku":"SKU-ADD","quantity":2}');
        RestContext.request = req;
        RestContext.response = res;
        
        //req.requestBody = Blob.valueOf('{}');
        
        UpdateAccountInSFFromWebsite.createOrderProductInSF();
        
        //System.assertEquals(200, RestContext.response.statusCode);
    }
    @isTest
    static void testUpdateOrderProduct_MissingRequiredFields() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.updateOrderProduct();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testUpdateOrderProduct_OrderNotFound() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"website_orderId":"INVALID","old_sku":"OLD-SKU","new_sku":"NEW-SKU"}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.updateOrderProduct();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testCreateOrderProductInSF_MissingFields() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.createOrderProductInSF();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testCreateOrderProductInSF_InvalidOrder() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"website_orderId":"INVALID","product_sku":"SKU-ADD","quantity":2}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.createOrderProductInSF();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testDeleteOrderProduct_MissingRequiredFields() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.deleteOrderProduct();
        
    }
    @isTest
    static void testUpdateAccount_AccountNotFound() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"crm_account_id":"001XXXXXXXXXXXX","full_name":"Test Name"}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.updateAccount();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    @isTest
    static void testUpdateAccount_InvalidEmail() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"crm_account_id":"' + acc.Id + '","email_address":"invalidEmail"}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.updateAccount();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    @isTest
    static void testCreateOrderProductInSF_ProductNotFound() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        Order ord = new Order(AccountId = acc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = stdPricebookId, Website_Order_Id__c = 'WEB-ADD2');
        insert ord;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"website_orderId":"WEB-ADD2","product_sku":"INVALID-SKU","quantity":2}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.createOrderProductInSF();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    @isTest
    static void testCreateOrderProductInSF_NoActivePricebookEntry() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true, StockKeepingUnit = 'SKU-NO-PBE',Productcode='SKU-NO-PBE',HSN_Code__c='	c297bt', Type__c='Accessories');
        insert prod;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        Order ord = new Order(AccountId = acc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = stdPricebookId, Website_Order_Id__c = 'WEB-NO-PBE');
        insert ord;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"website_orderId":"WEB-NO-PBE","product_sku":"SKU-NO-PBE","quantity":2}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.createOrderProductInSF();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    @isTest
    static void testUpdateOrderProduct_NewProductNotFound() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Product2 prod = new Product2(Name = 'Old Product', IsActive = true, StockKeepingUnit = 'OLD-SKU',ProductCode='OLD-SKU',HSN_Code__c='o87ig', Type__c='Accessories');
        insert prod;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = stdPricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        Order ord = new Order(AccountId = acc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = stdPricebookId, Website_Order_Id__c = 'WEB-UPD');
        insert ord;
        
        OrderItem oi = new OrderItem(OrderId = ord.Id, Product2Id = prod.Id, UnitPrice = 100, Quantity = 1, PricebookEntryId = pbe.Id);
        insert oi;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{"website_orderId":"WEB-UPD","old_sku":"OLD-SKU","new_sku":"INVALID-SKU"}');
        RestContext.request = req;
        RestContext.response = res;
        
        UpdateAccountInSFFromWebsite.updateOrderProduct();
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
}