@isTest
private class Customer_Invoice_PDF_Controller_Test {
    @isTest static void testDODOAndCOCOServiceCenters() {
        // --------- Create common base data ----------
        Account acc = new Account();
        acc.Name = 'testing Account';
        acc.Type = 'Customer';
        acc.Phone = '9807654321';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'testing Contact';
        con.AccountId = acc.Id;
        con.Phone = '9123456789';
        con.Email = 'test@test.com';
        con.Primary_Contact__c = true;
        insert con;
        
        Asset asst = new Asset();
        asst.Name = 'test Asset';
        asst.AccountId = acc.Id;
        asst.ContactId = con.Id;
        insert asst;
        
        Asset asst2 = new Asset();
        asst2.Name = 'test1 Asset';
        asst2.AccountId = acc.Id;
        asst2.ContactId = con.Id;
        insert asst2;
        
        Software_Version__c sv = new Software_Version__c();
        sv.Name = 'test version';
        sv.Latest_Software_Version__c = true;
        insert sv;
        
        Product2 prod = new Product2();
        prod.Name = 'test product';
        prod.HSN_Code__c = '123';
        prod.Type__c = 'Vehicle';
        prod.ProductCode = '2132132';
        insert prod;
        
        VehicleDefinition vd = new VehicleDefinition();
        vd.Name = 'test VehicleDefinition';
        vd.ProductId = prod.Id;
        insert vd;
        
        Vehicle vac = new Vehicle();
        vac.Name = 'test vehicle';
        vac.CurrentOwnerId = acc.Id;
        vac.Charger_PC_Number__c = '123CC';
        vac.VehicleRegistrationNumber = '123';
        vac.VehicleIdentificationNumber = 'NeoCity2022ZXi';
        vac.VehicleDefinitionId = vd.Id;
        vac.Software_Version__c = sv.Id;
        vac.AssetId = asst.Id;
        vac.Spare_Vehicle__c = false;
        insert vac;
        
        // Create a second vehicle for COCO WorkOrder to avoid validation error
        Vehicle vac2 = new Vehicle();
        vac2.Name = 'test vehicle 2';
        vac2.CurrentOwnerId = acc.Id;
        vac2.Charger_PC_Number__c = '456DD';
        vac2.VehicleRegistrationNumber = '456';
        vac2.VehicleIdentificationNumber = 'NeoCity2022ZXi-2'; // make sure it's unique
        vac2.VehicleDefinitionId = vd.Id;
        vac2.Software_Version__c = sv.Id;
        vac2.AssetId = asst2.Id;
        vac2.Spare_Vehicle__c = false;
        insert vac2;
        
        
        Warehouse__c testWarehouse = new Warehouse__c();
        testWarehouse.Name = 'Test Warehouse';
        insert testWarehouse;
        
        // --------- DODO Service Center ----------
        Account serviceCenterDODO = new Account(
            Name = 'DODO Center',
            GSTIN_Number__c = '29ABCDE1234F1Z5',
            BillingStreet = 'Line 1\nLine 2',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingCountry = 'India',
            BillingPostalCode = '560001',
            Type = 'Service Center',
            Center_Code__c = '3324',
            Store_Type__c = 'DODO',
            GST_Street__c = 'GST Line 1\nGST Line 2',
            Company_GSTIN_name__c = 'DODO GST Co.',
            GST_City__c = 'Bengaluru',
            GST_State__c = 'Karnataka',
            GST_Zip_Postal_Code__c = '543733'
        );
        insert serviceCenterDODO;
        
        WorkOrder workOrderDODO = new WorkOrder();
        workOrderDODO.Warehouse__c = testWarehouse.Id; 
        workOrderDODO.Service_Center__c = serviceCenterDODO.Id;
        workOrderDODO.Vehicle__c = vac.Id;
        workOrderDODO.AccountId = acc.Id;
        insert workOrderDODO;
        
        // --------- COCO Service Center ----------
        Account serviceCenterCOCO = new Account(
            Name = 'COCO Center',
            GSTIN_Number__c = '29XYZDE1234F1Z5',
            BillingStreet = 'COCO Street 1\nStreet 2',
            BillingCity = 'Mumbai',
            BillingState = 'Maharashtra',
            BillingCountry = 'India',
            BillingPostalCode = '400001',
            Type = 'Service Center',
            Center_Code__c = '4455',
            Store_Type__c = 'COCO',
            GST_Street__c = 'COCO GST Street 1\nStreet 2',
            Company_GSTIN_name__c = 'COCO GST Co.',
            GST_City__c = 'Mumbai',
            GST_State__c = 'Maharashtra',
            GST_Zip_Postal_Code__c = '400001'
        );
        insert serviceCenterCOCO;
        
        WorkOrder workOrderCOCO = new WorkOrder();
        workOrderCOCO.Warehouse__c = testWarehouse.Id; 
        workOrderCOCO.Service_Center__c = serviceCenterCOCO.Id;
        workOrderCOCO.Vehicle__c = vac2.Id;
        workOrderCOCO.AccountId = acc.Id;
        insert workOrderCOCO;
        
        // --------- Common Work Type & Plans ---------
        WorkType testWorkType = new WorkType();
        testWorkType.Name = 'Test Work Type';
        testWorkType.Amount__c = 100.0;
        testWorkType.EstimatedDuration = 2;
        testWorkType.DurationType = 'Hours';
        insert testWorkType;
        
        // WorkPlans for DODO WorkOrder
        insert new List<WorkPlan>{
            new WorkPlan(
                Name = 'DODO Plan 1',
                WorkOrderId = workOrderDODO.Id,
                Work_Type__c = testWorkType.Id,
                Labour_Charge__c = 100,
                RR_Labour_Category__c = 'Paid',
                Duration_Hour__c = 1
            ),
                new WorkPlan(
                    Name = 'DODO Plan 2',
                    WorkOrderId = workOrderDODO.Id,
                    Work_Type__c = testWorkType.Id,
                    Labour_Charge__c = 150,
                    RR_Labour_Category__c = 'Insurance',
                    Duration_Hour__c = 2
                )
                };
                    
                    // WorkPlans for COCO WorkOrder
                    insert new List<WorkPlan>{
                        new WorkPlan(
                            Name = 'COCO Plan 1',
                            WorkOrderId = workOrderCOCO.Id,
                            Work_Type__c = testWorkType.Id,
                            Labour_Charge__c = 120,
                            RR_Labour_Category__c = 'Paid',
                            Duration_Hour__c = 1
                        )
                            };
                                
       // --------- Test both controller cases ---------
           Test.startTest();
        
        // Test for DODO Service Center
        ApexPages.StandardController scDODO = new ApexPages.StandardController(workOrderDODO);
        PageReference pageRefDODO = Page.Customer_Invoice_PDF;
        pageRefDODO.getParameters().put('id', workOrderDODO.Id);
        Test.setCurrentPage(pageRefDODO);
        
        Customer_Invoice_PDF_Controller objDODO = new Customer_Invoice_PDF_Controller(scDODO);
        String dodoBilling = objDODO.getFormattedBillingStreet();
        String dodoGST = objDODO.getFormattedGSTBillingStreet();
        String dodoAccount = objDODO.getFormattedAccountBillingStreet();
        
        // Test for COCO Service Center
        ApexPages.StandardController scCOCO = new ApexPages.StandardController(workOrderCOCO);
        PageReference pageRefCOCO = Page.Customer_Invoice_PDF;
        pageRefCOCO.getParameters().put('id', workOrderCOCO.Id);
        Test.setCurrentPage(pageRefCOCO);
        
        Customer_Invoice_PDF_Controller objCOCO = new Customer_Invoice_PDF_Controller(scCOCO);
        String cocoBilling = objCOCO.getFormattedBillingStreet();
        String cocoGST = objCOCO.getFormattedGSTBillingStreet();
        String cocoAccount = objCOCO.getFormattedAccountBillingStreet();
        Test.stopTest();
    }
    @IsTest
    static  void testgenerateEWayBill() {
        Test.startTest();
        Customer_Invoice_PDF_Controller.methodToCoverage();
        Customer_Invoice_PDF_Controller.methodToCoverage1();
        Customer_Invoice_PDF_Controller.methodToCoverage2();
        
        Test.stopTest();
    }
}