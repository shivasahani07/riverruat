@isTest
public class OTCOrderAPI_Test {
    
    @isTest
    static void testCreateStandardOrder() {
       
        Pricebook2 standardPricebook = new Pricebook2(Name = 'Standard Pricebook',isActive = true);
        insert standardPricebook;
        
        Account acc1 = new account();
        acc1.name = 'test customer';
        acc1.Type = 'Customer';
        acc1.Phone = '9011110246';
        acc1.email__c = 'ctest@gmail.com';
        insert acc1;
        
        Account acc = new account();
        acc.name = 'test service center';
        acc.Center_Code__c = 'test';
        acc.Type = 'Dealer';
        acc.Phone = '9011113246';
        acc.email__c = 'stest@gmail.com';
        insert acc;
        
        Subsidy__c sub = new Subsidy__c();
        sub.Name = 'subsidy';
        sub.Subsidy_Code__c = 'Subsidy';
        insert sub;
        
        Insurance__c insurance = new Insurance__c();
        insurance.Name = 'insurance';
        insurance.Insurer_Code__c = 'INS';
        insert insurance;
        
        Finance__c finance = new Finance__c();
        finance.name = 'test';
        finance.Finance_Code__c = 'Loan';
        insert finance;
        
        City__c city = new City__c();
        city.Name = 'Bengaluru';
        city.City_Masking_Name__c = 'Bengaluru';
        city.Price_Book__c = standardPricebook.Id;
        Insert city;
        
        
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('crm_account_id', acc1.Id);
        requestBody.put('order_id', 'RIVERBP87654345678');
        requestBody.put('seller_code', 'test');
        List<Map<String, Object>> productSkuIds = new List<Map<String, Object>>();
        
        Map<String, Object> productInfo = new Map<String, Object>{'product_sku_id' => 'TestSKU', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Parts', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
        Map<String, Object> productInfo1 = new Map<String, Object>{'product_sku_id' => 'TestSKU1', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Accessories', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
                
        productSkuIds.add(productInfo);
        productSkuIds.add(productInfo1);
        
        requestBody.put('products', productSkuIds);
        requestBody.put('delivery_timeline_description', 'Expected Delivery 16 Apr 2024 - 30 Apr 2024');
        requestBody.put('item_payment_type', 'Booking Amount');
        requestBody.put('billing_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('shipping_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('order_status', 'Draft');
        requestBody.put('payment_info', new Map<String, Object>{'payment_id' => 'RIVERBP87654345678', 'payment_type' => 'Booking Amount', 'payment_amount' => 2000, 'payment_status' => 'PAID', 'is_payment_completed' => true, 'pay_gwy_info' => new Map<String, Object>{'bank_ref_no' => '325124124', 'card_name' => 'Visa', 'payment_mode' => 'CREDIT-CARD', 'tracking_id' => '5246246162', 'status' => 'Success', 'failure_message' => 'ErrorMessage'}});
        requestBody.put('subsidy_info', new Map<String, Object>{'eligible_for_subsidy' => true, 'subsidy_code' => 'Subsidy', 'amount' => 0});
        requestBody.put('insurance_info', new Map<String, Object>{'insurer_code' => 'INS', 'amount' => 100});
        requestBody.put('loan_info', new Map<String, Object>{'finance_code' => 'Loan', 'amount' => 100, 'tenure_type' => 'Year','tenure' => 0});
        requestBody.put('offer_info', new Map<String, Object>{'offer_amount' => 0, 'offer_description' => ''});
        requestBody.put('warranty_info', new Map<String, Object>{'warranty_amount' => 0, 'is_extended' => false});
        requestBody.put('notify_by_sms', true);
        requestBody.put('notify_by_email', true);
        requestBody.put('city', 'Bengaluru');
        requestBody.put('payment_info', new Map<String, Object>{
        'payment_id' => 'TXN001',
        'payment_type' => 'Booking Amount',
        'payment_amount' => 500,
        'pay_gwy_info' => new Map<String, Object>{
            'bank_ref_no' => 'BRN001',
            'card_name' => 'VISA',
            'payment_mode' => 'CARD',
            'tracking_id' => 'TRK001',
            'status' => 'Success',
            'failure_message' => 'None'
        }
    });

       
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        Product2 testProduct = new Product2(Name = 'Test Product', StockKeepingUnit = 'TestSKU', HSN_Code__c='HSN123', Type__c = 'Parts', ProductCode= 'MS123', IsActive = true);
        insert testProduct;
        
        Product2 testProduct1 = new Product2(Name = 'Test Product1', StockKeepingUnit = 'TestSKU1', HSN_Code__c='HSN1231', Type__c = 'Accessories', ProductCode= 'MS456', IsActive = true);
        insert testProduct1;
        
        Id standardPricebookId = test.getStandardPricebookId();

        PriceBookEntry pricebookEntry = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry;
        
        PriceBookEntry pricebookEntry1 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry1;
        
        PriceBookEntry pricebookEntry3 = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry3;
        
        PriceBookEntry pricebookEntry2 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry2;
        
        Order existingOrder = new Order(
            AccountId = acc1.Id,
            Dealer__c = acc.Id,
            Website_Order_Id__c = 'WEBORDER001',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebook.Id
        );
        insert existingOrder;
        
        Website_Creds__c mockIntegrations = new Website_Creds__c(
                Name = 'Website Creds',
                BaseURL__c = 'https://river-crm-apis.dev.rideriver.com',
                ClientId__c = '7f2a1bk826eb5179ec8e357340408fd444ab3ssbb1d5fb40a06f6eac590f6b8d51bea40886bf80cd388813f296effa4269550ce98d4e4e5c7e582da19e9faff0',
                ClientSecret__c = 'a7ebb3r90eaa4eac1a356c351a0f7c5fdesa87c87010298fa84bc728d6db305638b68b6bce984110e8d70fd2e39eab0dbcdd2b5264570ae77e320acb6937afe32'
            );
            insert mockIntegrations;
        
        
        Test.startTest();
        OTCOrderAPI.createOTCOrderFromWebsite();
        OTCOrderAPI.responseUtility('Success', '200', true);
        OTCOrderAPI.successResponse('Success', '200', true, existingOrder.id);
        Test.stopTest();
        
        
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        
     
    }
    
    

@isTest
    static void testCreateStandardOrder2() {
       
        Pricebook2 standardPricebook = new Pricebook2(Name = 'Standard Pricebook',isActive = true);
        insert standardPricebook;
        
        Account acc1 = new account();
        acc1.name = 'test customer';
        acc1.Type = 'Customer';
        acc1.Phone = '9011110246';
        acc1.email__c = 'ctest@gmail.com';
        insert acc1;
        
        Account acc = new account();
        acc.name = 'test service center';
        acc.Center_Code__c = 'test';
        acc.Type = 'Dealer';
        acc.Phone = '9011113246';
        acc.email__c = 'stest@gmail.com';
        insert acc;
        
        Subsidy__c sub = new Subsidy__c();
        sub.Name = 'subsidy';
        sub.Subsidy_Code__c = 'Subsidy';
        insert sub;
        
        Insurance__c insurance = new Insurance__c();
        insurance.Name = 'insurance';
        insurance.Insurer_Code__c = 'INS';
        insert insurance;
        
        Finance__c finance = new Finance__c();
        finance.name = 'test';
        finance.Finance_Code__c = 'Loan';
        insert finance;
        
        City__c city = new City__c();
        city.Name = 'Bengaluru';
        city.City_Masking_Name__c = 'Bengaluru';
        city.Price_Book__c = standardPricebook.Id;
        Insert city;
        
        
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('crm_account_id', acc1.Id);
        requestBody.put('order_id', 'RIVERBP87654345678');
        requestBody.put('seller_code', 'testvv');
        List<Map<String, Object>> productSkuIds = new List<Map<String, Object>>();
        
        Map<String, Object> productInfo = new Map<String, Object>{'product_sku_id' => 'TestSKU', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Parts', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
        Map<String, Object> productInfo1 = new Map<String, Object>{'product_sku_id' => 'TestSKU1', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Accessories', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
                
        productSkuIds.add(productInfo);
        productSkuIds.add(productInfo1);
        
        requestBody.put('products', productSkuIds);
        requestBody.put('delivery_timeline_description', 'Expected Delivery 16 Apr 2024 - 30 Apr 2024');
        requestBody.put('item_payment_type', 'Booking Amount');
        requestBody.put('billing_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('shipping_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('order_status', 'Draft');
        requestBody.put('payment_info', new Map<String, Object>{'payment_id' => 'RIVERBP87654345678', 'payment_type' => 'Booking Amount', 'payment_amount' => 2000, 'payment_status' => 'PAID', 'is_payment_completed' => true, 'pay_gwy_info' => new Map<String, Object>{'bank_ref_no' => '325124124', 'card_name' => 'Visa', 'payment_mode' => 'CREDIT-CARD', 'tracking_id' => '5246246162', 'status' => 'Success', 'failure_message' => 'ErrorMessage'}});
        requestBody.put('subsidy_info', new Map<String, Object>{'eligible_for_subsidy' => true, 'subsidy_code' => 'Subsidy', 'amount' => 0});
        requestBody.put('insurance_info', new Map<String, Object>{'insurer_code' => 'INS', 'amount' => 100});
        requestBody.put('loan_info', new Map<String, Object>{'finance_code' => 'Loan', 'amount' => 100, 'tenure_type' => 'Year','tenure' => 0});
        requestBody.put('offer_info', new Map<String, Object>{'offer_amount' => 0, 'offer_description' => ''});
        requestBody.put('warranty_info', new Map<String, Object>{'warranty_amount' => 0, 'is_extended' => false});
        requestBody.put('notify_by_sms', true);
        requestBody.put('notify_by_email', true);
        requestBody.put('city', 'Bengaluru');
        requestBody.put('payment_info', new Map<String, Object>{
        'payment_id' => 'TXN001',
        'payment_type' => 'Booking Amount',
        'payment_amount' => 500,
        'pay_gwy_info' => new Map<String, Object>{
            'bank_ref_no' => 'BRN001',
            'card_name' => 'VISA',
            'payment_mode' => 'CARD',
            'tracking_id' => 'TRK001',
            'status' => 'Success',
            'failure_message' => 'None'
        }
    });

       
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        Product2 testProduct = new Product2(Name = 'Test Product', StockKeepingUnit = 'TestSKU', HSN_Code__c='HSN123', Type__c = 'Parts', ProductCode= 'MS123', IsActive = true);
        insert testProduct;
        
        Product2 testProduct1 = new Product2(Name = 'Test Product1', StockKeepingUnit = 'TestSKU1', HSN_Code__c='HSN1231', Type__c = 'Accessories', ProductCode= 'MS456', IsActive = true);
        insert testProduct1;
        
        Id standardPricebookId = test.getStandardPricebookId();

        PriceBookEntry pricebookEntry = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry;
        
        PriceBookEntry pricebookEntry1 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry1;
        
        PriceBookEntry pricebookEntry3 = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry3;
        
        PriceBookEntry pricebookEntry2 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry2;
        
        Order existingOrder = new Order(
            AccountId = acc1.Id,
            Dealer__c = acc.Id,
            Website_Order_Id__c = 'WEBORDER001',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebook.Id
        );
        insert existingOrder;
        
        Website_Creds__c mockIntegrations = new Website_Creds__c(
                Name = 'Website Creds',
                BaseURL__c = 'https://river-crm-apis.dev.rideriver.com',
                ClientId__c = '7f2a1bk826eb5179ec8e357340408fd444ab3ssbb1d5fb40a06f6eac590f6b8d51bea40886bf80cd388813f296effa4269550ce98d4e4e5c7e582da19e9faff0',
                ClientSecret__c = 'a7ebb3r90eaa4eac1a356c351a0f7c5fdesa87c87010298fa84bc728d6db305638b68b6bce984110e8d70fd2e39eab0dbcdd2b5264570ae77e320acb6937afe32'
            );
            insert mockIntegrations;
        
        
        Test.startTest();
        OTCOrderAPI.createOTCOrderFromWebsite();
        OTCOrderAPI.responseUtility('Success', '200', true);
        OTCOrderAPI.successResponse('Success', '200', true, existingOrder.id);
        Test.stopTest();
        
        
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        
     
    }
    
    @isTest
    static void testCreateStandardOrder3() {
       
        Pricebook2 standardPricebook = new Pricebook2(Name = 'Standard Pricebook',isActive = true);
        insert standardPricebook;
        
        Account acc1 = new account();
        acc1.name = 'test customer';
        acc1.Type = 'Customer';
        acc1.Phone = '9011110246';
        acc1.email__c = 'ctest@gmail.com';
        insert acc1;
        
        Account acc = new account();
        acc.name = 'test service center';
        acc.Center_Code__c = 'test';
        acc.Type = 'Dealer';
        acc.Phone = '9011113246';
        acc.email__c = 'stest@gmail.com';
        insert acc;
        
        Subsidy__c sub = new Subsidy__c();
        sub.Name = 'subsidy';
        sub.Subsidy_Code__c = 'Subsidy';
        insert sub;
        
        Insurance__c insurance = new Insurance__c();
        insurance.Name = 'insurance';
        insurance.Insurer_Code__c = 'INS';
        insert insurance;
        
        Finance__c finance = new Finance__c();
        finance.name = 'test';
        finance.Finance_Code__c = 'Loan';
        insert finance;
        
        City__c city = new City__c();
        city.Name = 'Bengaluru';
        city.City_Masking_Name__c = 'Bengaluru';
        city.Price_Book__c = standardPricebook.Id;
        Insert city;
        
        
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('crm_account_id', acc1.Id);
        requestBody.put('order_id', 'RIVERBP87654345678');
        requestBody.put('seller_code', 'test');
        List<Map<String, Object>> productSkuIds = new List<Map<String, Object>>();
        
        Map<String, Object> productInfo = new Map<String, Object>{'product_sku_id' => 'TestSKU', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Parts', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
        Map<String, Object> productInfo1 = new Map<String, Object>{'product_sku_id' => 'TestSKU1', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Accessories', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
                
        productSkuIds.add(productInfo);
        productSkuIds.add(productInfo1);
        
        requestBody.put('products', productSkuIds);
        requestBody.put('delivery_timeline_description', 'Expected Delivery 16 Apr 2024 - 30 Apr 2024');
        requestBody.put('item_payment_type', 'Booking Amount');
        requestBody.put('billing_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('shipping_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('order_status', 'Draft');
        requestBody.put('payment_info', new Map<String, Object>{'payment_id' => 'RIVERBP87654345678', 'payment_type' => 'Booking Amount', 'payment_amount' => 2000, 'payment_status' => 'PAID', 'is_payment_completed' => true, 'pay_gwy_info' => new Map<String, Object>{'bank_ref_no' => '325124124', 'card_name' => 'Visa', 'payment_mode' => 'CREDIT-CARD', 'tracking_id' => '5246246162', 'status' => 'Success', 'failure_message' => 'ErrorMessage'}});
        requestBody.put('subsidy_info', new Map<String, Object>{'eligible_for_subsidy' => true, 'subsidy_code' => 'Subsidy', 'amount' => 0});
        requestBody.put('insurance_info', new Map<String, Object>{'insurer_code' => 'INS', 'amount' => 100});
        requestBody.put('loan_info', new Map<String, Object>{'finance_code' => 'Loan', 'amount' => 100, 'tenure_type' => 'Year','tenure' => 0});
        requestBody.put('offer_info', new Map<String, Object>{'offer_amount' => 0, 'offer_description' => ''});
        requestBody.put('warranty_info', new Map<String, Object>{'warranty_amount' => 0, 'is_extended' => false});
        requestBody.put('notify_by_sms', true);
        requestBody.put('notify_by_email', true);
        requestBody.put('city', 'Bengaluru');
        requestBody.put('payment_info', new Map<String, Object>{
        'payment_id' => 'TXN001',
        'payment_type' => 'Booking Amount',
        'payment_amount' => 500,
        'pay_gwy_info' => new Map<String, Object>{
            'bank_ref_no' => 'BRN001',
            'card_name' => 'VISA',
            'payment_mode' => 'CARD',
            'tracking_id' => 'TRK001',
            'status' => 'Success',
            'failure_message' => 'None'
        }
    });

       
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        Product2 testProduct = new Product2(Name = 'Test Product', StockKeepingUnit = 'TestSKU', HSN_Code__c='HSN123', Type__c = 'Parts', ProductCode= 'MS123', IsActive = true);
        insert testProduct;
        
        Product2 testProduct1 = new Product2(Name = 'Test Product1', StockKeepingUnit = 'TestSKU1', HSN_Code__c='HSN1231', Type__c = 'Accessories', ProductCode= 'MS456', IsActive = true);
        insert testProduct1;
        
        Id standardPricebookId = test.getStandardPricebookId();

        PriceBookEntry pricebookEntry = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry;
        
        PriceBookEntry pricebookEntry1 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry1;
        
        PriceBookEntry pricebookEntry3 = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry3;
        
        PriceBookEntry pricebookEntry2 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry2;
        
        Order existingOrder = new Order(
            AccountId = acc1.Id,
            Dealer__c = acc.Id,
            Website_Order_Id__c = 'WEBORDER001',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebook.Id
        );
        insert existingOrder;
        
        Website_Creds__c mockIntegrations = new Website_Creds__c(
                Name = 'Website Creds',
                BaseURL__c = 'https://river-crm-apis.dev.rideriver.com',
                ClientId__c = '7f2a1bk826eb5179ec8e357340408fd444ab3ssbb1d5fb40a06f6eac590f6b8d51bea40886bf80cd388813f296effa4269550ce98d4e4e5c7e582da19e9faff0',
                ClientSecret__c = 'a7ebb3r90eaa4eac1a356c351a0f7c5fdesa87c87010298fa84bc728d6db305638b68b6bce984110e8d70fd2e39eab0dbcdd2b5264570ae77e320acb6937afe32'
            );
            insert mockIntegrations;
        
        
        Test.startTest();
        OTCOrderAPI.createOTCOrderFromWebsite();
        OTCOrderAPI.responseUtility('Success', '200', true);
        OTCOrderAPI.successResponse('Success', '200', true, existingOrder.id);
        Test.stopTest();
        
        
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        
     
    }
    
    @isTest
    static void testCreateStandardOrder4() {
       
        Pricebook2 standardPricebook = new Pricebook2(Name = 'Standard Pricebook',isActive = true);
        insert standardPricebook;
        
        Account acc1 = new account();
        acc1.name = 'test customer';
        acc1.Type = 'Customer';
        acc1.Phone = '9011110246';
        acc1.email__c = 'ctest@gmail.com';
        insert acc1;
        
        Account acc = new account();
        acc.name = 'test service center';
        acc.Center_Code__c = 'test';
        acc.Type = 'Dealer';
        acc.Phone = '9011113246';
        acc.email__c = 'stest@gmail.com';
        insert acc;
        
        Subsidy__c sub = new Subsidy__c();
        sub.Name = 'subsidy';
        sub.Subsidy_Code__c = 'Subsidy';
        insert sub;
        
        Insurance__c insurance = new Insurance__c();
        insurance.Name = 'insurance';
        insurance.Insurer_Code__c = 'INS';
        insert insurance;
        
        Finance__c finance = new Finance__c();
        finance.name = 'test';
        finance.Finance_Code__c = 'Loan';
        insert finance;
        
        City__c city = new City__c();
        city.Name = 'Bengaluru';
        city.City_Masking_Name__c = 'Bengaluru';
        city.Price_Book__c = standardPricebook.Id;
        Insert city;
        
        
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('crm_account_id', acc1.Id);
        requestBody.put('order_id', 'RIVERBP87654345678');
        requestBody.put('seller_code', 'test');
        List<Map<String, Object>> productSkuIds = new List<Map<String, Object>>();
        
        Map<String, Object> productInfo = new Map<String, Object>{'product_sku_id' => 'TestSKU', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Parts', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
        Map<String, Object> productInfo1 = new Map<String, Object>{'product_sku_id' => 'TestSKU1', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Accessories', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
                
        productSkuIds.add(productInfo);
        productSkuIds.add(productInfo1);
        
        requestBody.put('products', productSkuIds);
        requestBody.put('delivery_timeline_description', 'Expected Delivery 16 Apr 2024 - 30 Apr 2024');
        requestBody.put('item_payment_type', 'Booking Amount');
        requestBody.put('billing_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('shipping_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('order_status', 'Draft');
        requestBody.put('payment_info', new Map<String, Object>{'payment_id' => 'RIVERBP87654345678', 'payment_type' => 'Booking Amount', 'payment_amount' => 2000, 'payment_status' => 'PAID', 'is_payment_completed' => true, 'pay_gwy_info' => new Map<String, Object>{'bank_ref_no' => '325124124', 'card_name' => 'Visa', 'payment_mode' => 'CREDIT-CARD', 'tracking_id' => '5246246162', 'status' => 'Success', 'failure_message' => 'ErrorMessage'}});
        requestBody.put('subsidy_info', new Map<String, Object>{'eligible_for_subsidy' => true, 'subsidy_code' => 'Subsidy', 'amount' => 0});
        requestBody.put('insurance_info', new Map<String, Object>{'insurer_code' => 'INS', 'amount' => 100});
        requestBody.put('loan_info', new Map<String, Object>{'finance_code' => 'Loan', 'amount' => 100, 'tenure_type' => 'Year','tenure' => 0});
        requestBody.put('offer_info', new Map<String, Object>{'offer_amount' => 0, 'offer_description' => ''});
        requestBody.put('warranty_info', new Map<String, Object>{'warranty_amount' => 0, 'is_extended' => false});
        requestBody.put('notify_by_sms', true);
        requestBody.put('notify_by_email', true);
        requestBody.put('city', 'Bengalurui');
        requestBody.put('payment_info', new Map<String, Object>{
        'payment_id' => 'TXN001',
        'payment_type' => 'Booking Amount',
        'payment_amount' => 500,
        'pay_gwy_info' => new Map<String, Object>{
            'bank_ref_no' => 'BRN001',
            'card_name' => 'VISA',
            'payment_mode' => 'CARD',
            'tracking_id' => 'TRK001',
            'status' => 'Success',
            'failure_message' => 'None'
        }
    });

       
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        Product2 testProduct = new Product2(Name = 'Test Product', StockKeepingUnit = 'TestSKU', HSN_Code__c='HSN123', Type__c = 'Parts', ProductCode= 'MS123', IsActive = true);
        insert testProduct;
        
        Product2 testProduct1 = new Product2(Name = 'Test Product1', StockKeepingUnit = 'TestSKU1', HSN_Code__c='HSN1231', Type__c = 'Accessories', ProductCode= 'MS456', IsActive = true);
        insert testProduct1;
        
        Id standardPricebookId = test.getStandardPricebookId();

        PriceBookEntry pricebookEntry = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry;
        
        PriceBookEntry pricebookEntry1 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry1;
        
        PriceBookEntry pricebookEntry3 = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry3;
        
        PriceBookEntry pricebookEntry2 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry2;
        
        Order existingOrder = new Order(
            AccountId = acc1.Id,
            Dealer__c = acc.Id,
            Website_Order_Id__c = 'WEBORDER001',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebook.Id
        );
        insert existingOrder;
        
        Website_Creds__c mockIntegrations = new Website_Creds__c(
                Name = 'Website Creds',
                BaseURL__c = 'https://river-crm-apis.dev.rideriver.com',
                ClientId__c = '7f2a1bk826eb5179ec8e357340408fd444ab3ssbb1d5fb40a06f6eac590f6b8d51bea40886bf80cd388813f296effa4269550ce98d4e4e5c7e582da19e9faff0',
                ClientSecret__c = 'a7ebb3r90eaa4eac1a356c351a0f7c5fdesa87c87010298fa84bc728d6db305638b68b6bce984110e8d70fd2e39eab0dbcdd2b5264570ae77e320acb6937afe32'
            );
            insert mockIntegrations;
        
        
        Test.startTest();
        OTCOrderAPI.createOTCOrderFromWebsite();
        OTCOrderAPI.responseUtility('Success', '200', true);
        OTCOrderAPI.successResponse('Success', '200', true, existingOrder.id);
        Test.stopTest();
        
        
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        
     
    }
    


    
    @isTest
    static void testCreateStandardOrder5() {
       
        Pricebook2 standardPricebook = new Pricebook2(Name = 'Standard Pricebook',isActive = true);
        insert standardPricebook;
        
        Account acc1 = new account();
        acc1.name = 'test customer';
        acc1.Type = 'Customer';
        acc1.Phone = '9011110246';
        acc1.email__c = 'ctest@gmail.com';
        insert acc1;
        
        Account acc = new account();
        acc.name = 'test service center';
        acc.Center_Code__c = 'test';
        acc.Type = 'Dealer';
        acc.Phone = '9011113246';
        acc.email__c = 'stest@gmail.com';
        insert acc;
        
        Subsidy__c sub = new Subsidy__c();
        sub.Name = 'subsidy';
        sub.Subsidy_Code__c = 'Subsidy';
        insert sub;
        
        Insurance__c insurance = new Insurance__c();
        insurance.Name = 'insurance';
        insurance.Insurer_Code__c = 'INS';
        insert insurance;
        
        Finance__c finance = new Finance__c();
        finance.name = 'test';
        finance.Finance_Code__c = 'Loan';
        insert finance;
        
        City__c city = new City__c();
        city.Name = 'Bengaluru';
        city.City_Masking_Name__c = 'Bengaluru';
        city.Price_Book__c = standardPricebook.Id;
        Insert city;
        
        
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('crm_account_id', acc1.Id);
        requestBody.put('order_id', 'RIVERBP87654345678');
        requestBody.put('seller_code', 'test');
        List<Map<String, Object>> productSkuIds = new List<Map<String, Object>>();
        
        Map<String, Object> productInfo = new Map<String, Object>{'product_sku_id' => 'TestSKU', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Parts', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
        Map<String, Object> productInfo1 = new Map<String, Object>{'product_sku_id' => 'TestSKU1', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Accessories', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
                
        productSkuIds.add(productInfo);
        productSkuIds.add(productInfo1);
        
        requestBody.put('products', productSkuIds);
        requestBody.put('delivery_timeline_description', 'Expected Delivery 16 Apr 2024 - 30 Apr 2024');
        requestBody.put('item_payment_type', 'Booking Amount');
        requestBody.put('billing_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('shipping_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('order_status', 'Draft');
        requestBody.put('payment_info', new Map<String, Object>{'payment_id' => 'RIVERBP87654345678', 'payment_type' => 'Booking Amount', 'payment_amount' => 2000, 'payment_status' => 'PAID', 'is_payment_completed' => true, 'pay_gwy_info' => new Map<String, Object>{'bank_ref_no' => '325124124', 'card_name' => 'Visa', 'payment_mode' => 'CREDIT-CARD', 'tracking_id' => '5246246162', 'status' => 'Success', 'failure_message' => 'ErrorMessage'}});
        requestBody.put('subsidy_info', new Map<String, Object>{'eligible_for_subsidy' => true, 'subsidy_code' => 'Subsidy', 'amount' => 0});
        requestBody.put('insurance_info', new Map<String, Object>{'insurer_code' => 'INS', 'amount' => 100});
        requestBody.put('loan_info', new Map<String, Object>{'finance_code' => 'Loan', 'amount' => 100, 'tenure_type' => 'Year','tenure' => 0});
        requestBody.put('offer_info', new Map<String, Object>{'offer_amount' => 0, 'offer_description' => ''});
        requestBody.put('warranty_info', new Map<String, Object>{'warranty_amount' => 0, 'is_extended' => false});
        requestBody.put('notify_by_sms', true);
        requestBody.put('notify_by_email', true);
        requestBody.put('vin', '98u');
        requestBody.put('city', 'Bengaluru');
        requestBody.put('payment_info', new Map<String, Object>{
        'payment_id' => 'TXN001',
        'payment_type' => 'Booking Amount',
        'payment_amount' => 500,
        'pay_gwy_info' => new Map<String, Object>{
            'bank_ref_no' => 'BRN001',
            'card_name' => 'VISA',
            'payment_mode' => 'CARD',
            'tracking_id' => 'TRK001',
            'status' => 'Success',
            'failure_message' => 'None'
        }
    });

       
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        Product2 testProduct = new Product2(Name = 'Test Product', StockKeepingUnit = 'TestSKU', HSN_Code__c='HSN123', Type__c = 'Parts', ProductCode= 'MS123', IsActive = true);
        insert testProduct;
        
        Product2 testProduct1 = new Product2(Name = 'Test Product1', StockKeepingUnit = 'TestSKU1', HSN_Code__c='HSN1231', Type__c = 'Accessories', ProductCode= 'MS456', IsActive = true);
        insert testProduct1;
        
        Id standardPricebookId = test.getStandardPricebookId();

        PriceBookEntry pricebookEntry = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry;
        
        PriceBookEntry pricebookEntry1 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry1;
        
        PriceBookEntry pricebookEntry3 = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry3;
        
        PriceBookEntry pricebookEntry2 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry2;
        
        Order existingOrder = new Order(
            AccountId = acc1.Id,
            Dealer__c = acc.Id,
            Website_Order_Id__c = 'WEBORDER001',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebook.Id
        );
        insert existingOrder;
        
        Website_Creds__c mockIntegrations = new Website_Creds__c(
                Name = 'Website Creds',
                BaseURL__c = 'https://river-crm-apis.dev.rideriver.com',
                ClientId__c = '7f2a1bk826eb5179ec8e357340408fd444ab3ssbb1d5fb40a06f6eac590f6b8d51bea40886bf80cd388813f296effa4269550ce98d4e4e5c7e582da19e9faff0',
                ClientSecret__c = 'a7ebb3r90eaa4eac1a356c351a0f7c5fdesa87c87010298fa84bc728d6db305638b68b6bce984110e8d70fd2e39eab0dbcdd2b5264570ae77e320acb6937afe32'
            );
            insert mockIntegrations;
        
        
        Test.startTest();
        OTCOrderAPI.createOTCOrderFromWebsite();
        OTCOrderAPI.responseUtility('Success', '200', true);
        OTCOrderAPI.successResponse('Success', '200', true, existingOrder.id);
        Test.stopTest();
        
        
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        
     
    }
     @isTest
    static void testCreateStandardOrder6() {
       
        Pricebook2 standardPricebook = new Pricebook2(Name = 'Standard Pricebook',isActive = true);
        insert standardPricebook;
        
        Account acc1 = new account();
        acc1.name = 'test customer';
        acc1.Type = 'Customer';
        acc1.Phone = '9011110246';
        acc1.email__c = 'ctest@gmail.com';
        insert acc1;
        
        Account acc = new account();
        acc.name = 'test service center';
        acc.Center_Code__c = 'test';
        acc.Type = 'Dealer';
        acc.Phone = '9011113246';
        acc.email__c = 'stest@gmail.com';
        insert acc;
        
        Subsidy__c sub = new Subsidy__c();
        sub.Name = 'subsidy';
        sub.Subsidy_Code__c = 'Subsidy';
        insert sub;
        
        Insurance__c insurance = new Insurance__c();
        insurance.Name = 'insurance';
        insurance.Insurer_Code__c = 'INS';
        insert insurance;
        
        Finance__c finance = new Finance__c();
        finance.name = 'test';
        finance.Finance_Code__c = 'Loan';
        insert finance;
        
        City__c city = new City__c();
        city.Name = 'Bengaluru';
        city.City_Masking_Name__c = 'Bengaluru';
        city.Price_Book__c = standardPricebook.Id;
        Insert city;
        
        
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('crm_account_id', acc1.Id);
        requestBody.put('order_id', 'RIVERBP87654345678');
        requestBody.put('seller_code', 'test');
        List<Map<String, Object>> productSkuIds = new List<Map<String, Object>>();
        
        Map<String, Object> productInfo = new Map<String, Object>{'product_sku_id' => 'TestSKU', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Parts', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
        Map<String, Object> productInfo1 = new Map<String, Object>{'product_sku_id' => 'TestSKU1', 'product_qty' => 1, 'product_unit_price' => 147462, 'product_order_status' => 'Activated', 'product_type' => 'Accessories', 'offer_amount' => 100, 'offer_description' => 'Diwali'};
                
        productSkuIds.add(productInfo);
        productSkuIds.add(productInfo1);
        
        requestBody.put('products', productSkuIds);
        requestBody.put('delivery_timeline_description', 'Expected Delivery 16 Apr 2024 - 30 Apr 2024');
        requestBody.put('item_payment_type', 'Booking Amount');
        requestBody.put('billing_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('shipping_address', new Map<String, Object>{'address_1' => 'Address line 1', 'address_2' => 'Address line 2', 'city' => 'Ulhasnagar', 'pincode' => '421005', 'state' => 'Karnataka'});
        requestBody.put('order_status', 'Draft');
        requestBody.put('payment_info', new Map<String, Object>{'payment_id' => 'RIVERBP87654345678', 'payment_type' => 'Booking Amount', 'payment_amount' => 2000, 'payment_status' => 'PAID', 'is_payment_completed' => true, 'pay_gwy_info' => new Map<String, Object>{'bank_ref_no' => '325124124', 'card_name' => 'Visa', 'payment_mode' => 'CREDIT-CARD', 'tracking_id' => '5246246162', 'status' => 'Success', 'failure_message' => 'ErrorMessage'}});
        requestBody.put('subsidy_info', new Map<String, Object>{'eligible_for_subsidy' => true, 'subsidy_code' => 'Subsidy', 'amount' => 0});
        requestBody.put('insurance_info', new Map<String, Object>{'insurer_code' => 'INS', 'amount' => 100});
        requestBody.put('loan_info', new Map<String, Object>{'finance_code' => 'Loan', 'amount' => 100, 'tenure_type' => 'Year','tenure' => 0});
        requestBody.put('offer_info', new Map<String, Object>{'offer_amount' => 0, 'offer_description' => ''});
        requestBody.put('warranty_info', new Map<String, Object>{'warranty_amount' => 0, 'is_extended' => false});
        requestBody.put('notify_by_sms', true);
        requestBody.put('notify_by_email', true);
        requestBody.put('city', 'Bengaluru');
        requestBody.put('payment_info', new Map<String, Object>{
        'payment_id' => 'TXN001',
        'payment_type' => 'Booking Amount Gullu',
        'payment_amount' => 500,
        'pay_gwy_info' => new Map<String, Object>{
            'bank_ref_no' => 'BRN001',
            'card_name' => 'VISA',
            'payment_mode' => 'CARD',
            'tracking_id' => 'TRK001',
            'status' => 'Success',
            'failure_message' => 'None'
        }
    });

       
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = request;
        RestContext.response = response;
        
        Product2 testProduct = new Product2(Name = 'Test Product', StockKeepingUnit = 'TestSKU', HSN_Code__c='HSN123', Type__c = 'Parts', ProductCode= 'MS123', IsActive = true);
        insert testProduct;
        
        Product2 testProduct1 = new Product2(Name = 'Test Product1', StockKeepingUnit = 'TestSKU1', HSN_Code__c='HSN1231', Type__c = 'Accessories', ProductCode= 'MS456', IsActive = true);
        insert testProduct1;
        
        Id standardPricebookId = test.getStandardPricebookId();

        PriceBookEntry pricebookEntry = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry;
        
        PriceBookEntry pricebookEntry1 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry1;
        
        PriceBookEntry pricebookEntry3 = new PriceBookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry3;
        
        PriceBookEntry pricebookEntry2 = new PriceBookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 1000000,
            IsActive = true
        );
        insert pricebookEntry2;
        
        Order existingOrder = new Order(
            AccountId = acc1.Id,
            Dealer__c = acc.Id,
            Website_Order_Id__c = 'WEBORDER001',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebook.Id
        );
        insert existingOrder;
        
        Website_Creds__c mockIntegrations = new Website_Creds__c(
                Name = 'Website Creds',
                BaseURL__c = 'https://river-crm-apis.dev.rideriver.com',
                ClientId__c = '7f2a1bk826eb5179ec8e357340408fd444ab3ssbb1d5fb40a06f6eac590f6b8d51bea40886bf80cd388813f296effa4269550ce98d4e4e5c7e582da19e9faff0',
                ClientSecret__c = 'a7ebb3r90eaa4eac1a356c351a0f7c5fdesa87c87010298fa84bc728d6db305638b68b6bce984110e8d70fd2e39eab0dbcdd2b5264570ae77e320acb6937afe32'
            );
            insert mockIntegrations;
        
        
        Test.startTest();
        OTCOrderAPI.createOTCOrderFromWebsite();
        OTCOrderAPI.responseUtility('Success', '200', true);
        OTCOrderAPI.successResponse('Success', '200', true, existingOrder.id);
        Test.stopTest();
        
        
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        
     
    }
    


    
}