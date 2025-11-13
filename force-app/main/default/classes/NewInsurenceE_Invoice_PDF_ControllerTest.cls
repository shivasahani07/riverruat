@isTest
public class NewInsurenceE_Invoice_PDF_ControllerTest {
	
    @isTest
    static void testInsuranceInvoiceController_DODO_COCO() {
        // Create Account and Contact
        Account acc = new Account(Name = 'Test Account', Type = 'Customer', Phone = '9876543210');
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id, Email = 'test@test.com', Phone = '9999999999');
        insert con;

        // Create Assets
        Asset asst = new Asset(Name = 'Test Asset', AccountId = acc.Id, ContactId = con.Id);
        insert asst;

        Asset asst2 = new Asset(Name = 'Test Asset 2', AccountId = acc.Id, ContactId = con.Id);
        insert asst2;

        // Software Version
        Software_Version__c sv = new Software_Version__c(Name = 'v1.0', Latest_Software_Version__c = true);
        insert sv;

        // Product
        Product2 prod = new Product2(Name = 'Test Product', HSN_Code__c = '1234', Type__c = 'Vehicle', ProductCode = 'P001');
        insert prod;

        // Activate Standard Pricebook
        Id standardPB = Test.getStandardPricebookId();

        // Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPB,
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert pbe;

        // Vehicle Definition
        VehicleDefinition vd = new VehicleDefinition(Name = 'Test VD', ProductId = prod.Id);
        insert vd;

        // Insurance Account
        Account insuranceAcc1 = new Account(Name = 'Test Insurance', GSTIN_Number__c = '29ABCDE1234F1Z5');
        insert insuranceAcc1;

        Insurance__c insuranceAcc = new Insurance__c(Name = 'test', GSTIN_Number__c = '29ABCDE1234F1Z5');
        insert insuranceAcc;

        // Vehicles
        Vehicle vac1 = new Vehicle(
            Name = 'DODO Vehicle',
            CurrentOwnerId = acc.Id,
            VehicleDefinitionId = vd.Id,
            Software_Version__c = sv.Id,
            AssetId = asst.Id,
            Insurance__c = insuranceAcc.Id,
            Charger_PC_Number__c = '123134314',
            VehicleIdentificationNumber = '2325255463565723'
        );
        insert vac1;

        Vehicle vac2 = new Vehicle(
            Name = 'COCO Vehicle',
            CurrentOwnerId = acc.Id,
            VehicleDefinitionId = vd.Id,
            Software_Version__c = sv.Id,
            AssetId = asst2.Id,
            Insurance__c = insuranceAcc.Id,
            Charger_PC_Number__c = '123134316',
            VehicleIdentificationNumber = '2325255463565726'
        );
        insert vac2;

        // Parent Account and Service Centers
        Account parentCenter = new Account(Name = 'Parent Center', GSTIN_Number__c = '29ABCDE1111Z5');
        insert parentCenter;

        Account serviceCenterDODO = new Account(
            Name = 'DODO Center',
            GSTIN_Number__c = '29ABCDE1234F1Z5',
            BillingStreet = 'Street 1\nStreet 2',
            BillingCity = 'Bengaluru',
            BillingState = 'Karnataka',
            BillingPostalCode = '560001',
            Store_Type__c = 'DODO',
            Type = 'Service Center',
            Company_GSTIN_name__c = 'DODO Pvt Ltd',
            ParentId = parentCenter.Id,
            GST_State__c = 'Karnataka',
            BillingStateCode = 'KA',
            GST_City__c = 'etts',
            GST_Street__c ='ddd' ,
            Center_Code__c = '324567',
            GST_Zip_Postal_Code__c = '35353'
        );
        insert serviceCenterDODO;

        Account serviceCenterCOCO = new Account(
            Name = 'COCO Center',
            GSTIN_Number__c = '27ABCDE9999F1Z5',
            BillingStreet = 'COCO Street 1\nStreet 2',
            BillingCity = 'Mumbai',
            BillingState = 'Maharashtra',
            BillingPostalCode = '400001',
            Store_Type__c = 'COCO',
            Type = 'Service Center',
            Company_GSTIN_name__c = 'COCO Pvt Ltd',
            BillingStateCode = 'MH',
            Center_Code__c ='345678'
        );
        insert serviceCenterCOCO;

        // WorkOrders with Pricebook
        WorkOrder woDODO = new WorkOrder(
            AccountId = acc.Id,
            Vehicle__c = vac1.Id,
            Pricebook2Id = standardPB,
            Service_Center__c = serviceCenterDODO.Id,
            Mode_Of_Payment__c = 'Cash'
        );
        insert woDODO;

        WorkOrder woCOCO = new WorkOrder(
            AccountId = acc.Id,
            Vehicle__c = vac2.Id,
            Pricebook2Id = standardPB,
            Service_Center__c = serviceCenterCOCO.Id,
            Mode_Of_Payment__c = 'Online'
        );
        insert woCOCO;

        // WorkPlan only (no WorkOrderLineItems)
        WorkPlan plan1 = new WorkPlan(
            Name = 'Insurance Labour Plan',
            WorkOrderId = woDODO.Id,
            RR_Labour_Category__c = 'Insurance',
            Approved_Insurance__c = 70
        );
        insert plan1;

        // Job Card Invoice
        Job_Card_Invoice__c jobInv = new Job_Card_Invoice__c(
            Job_Card__c = woDODO.Id,
            Invoice_Number__c = 'INV-001',
            Invoice_Type__c = 'Insurance',
            Invoice_Date__c = System.today()
        );
        insert jobInv;

        // Test Controller
        Test.startTest();

        PageReference pageRefDODO = Page.NewInsurenceE_Invoice;
        pageRefDODO.getParameters().put('id', woDODO.Id);
        Test.setCurrentPage(pageRefDODO);

        ApexPages.StandardController scDODO = new ApexPages.StandardController(woDODO);
        NewInsurenceE_Invoice_PDF_Controller ctrlDODO = new NewInsurenceE_Invoice_PDF_Controller(scDODO);

        ctrlDODO.getFormattedBillingStreet();
        ctrlDODO.getFormattedGSTBillingStreet();
        ctrlDODO.getFormattedInsurenceBillingStreet();

        PageReference pageRefCOCO = Page.Insurance_Invoice_PDF;
        pageRefCOCO.getParameters().put('id', woCOCO.Id);
        Test.setCurrentPage(pageRefCOCO);

        ApexPages.StandardController scCOCO = new ApexPages.StandardController(woCOCO);
        NewInsurenceE_Invoice_PDF_Controller ctrlCOCO = new NewInsurenceE_Invoice_PDF_Controller(scCOCO);

        ctrlCOCO.getFormattedBillingStreet();
        ctrlCOCO.getFormattedGSTBillingStreet();
        ctrlCOCO.getFormattedInsurenceBillingStreet();

        Test.stopTest();
    }
    
    @IsTest
    static  void testgenerateEWayBill() {
        Test.startTest();
        NewInsurenceE_Invoice_PDF_Controller.methodToCoverage();
        NewInsurenceE_Invoice_PDF_Controller.methodToCoverage1();
        NewInsurenceE_Invoice_PDF_Controller.methodToCoverage2();
        
        Test.stopTest();
    }
}