@IsTest
public class WarrantyPriorTriggerHandlerTest {

    private static Warranty_Prior__c createWarrantyPrior(String status, Id workOrderId) {
        Warranty_Prior__c wp = new Warranty_Prior__c(
            Status__c = status,
            Job_Card__c = workOrderId
        );
        insert wp;
        return wp;
    }

    private static WorkOrder createWorkOrder() {
        Account acc = new Account(
            Name = 'testing Account',
            Type = 'Customer',
            Phone = '9807654321'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'testing Contact',
            AccountId = acc.Id,
            Phone = '9123456789',
            Email = 'test@test.com',
            Primary_Contact__c = true
        );
        insert con;

        Asset asst = new Asset(
            Name = 'test Asset',
            AccountId = acc.Id,
            ContactId = con.Id
        );
        insert asst;

        Software_Version__c sv = new Software_Version__c(
            Name = 'test version',
            Latest_Software_Version__c = true
        );
        insert sv;

        Product2 prod = new Product2(
            Name = 'test product',
            HSN_Code__c = '123',
            Type__c = 'Vehicle',
            ProductCode = '2132132'
        );
        insert prod;

        VehicleDefinition vd = new VehicleDefinition(
            Name = 'test VehicleDefinition',
            ProductId = prod.Id
        );
        insert vd;

        Vehicle vac = new Vehicle(
            Name = 'test vehicle',
            CurrentOwnerId = acc.Id,
            Charger_PC_Number__c = '123CC',
            VehicleRegistrationNumber = '123',
            VehicleIdentificationNumber = 'NeoCity2022ZXi',
            VehicleDefinitionId = vd.Id,
            Software_Version__c = sv.Id,
            AssetId = asst.Id,
            Spare_Vehicle__c = false
        );
        insert vac;

        Warehouse__c wh = new Warehouse__c(Name = 'Test Warehouse');
        insert wh;

        WorkOrder wo = new WorkOrder(
            Status = 'Draft', // set non-final initially
            AccountId = acc.Id,
            Vehicle__c = vac.Id,
            Warehouse__c = wh.Id
        );
        insert wo;

        return wo;
    }

    private static Claim createClaim(Warranty_Prior__c wp, WorkOrder wo) {
        Claim claim = new Claim(
            Name = 'Test Claim',
            Status = 'Draft',
            Warranty_Prior__c = wp.Id,
            Job_Card__c = wo.Id,
            AccountId = wo.AccountId,
            Vehicle__c = wo.Vehicle__c
        );
        insert claim;
        return claim;
    }

    private static void createLineItems(Id workOrderId, Claim claim) {
    Product2 testProduct = new Product2(
        Name = 'Test Accessory',
        IsActive = true,
        ProductCode = 'abcd',
        HSN_Code__c = 'abcd',
        Type__c = 'Accessories'
    );
    insert testProduct;

    Id stdPrBk = Test.getStandardPricebookId();

    Pricebook2 standardPricebook = new Pricebook2(
        Id = stdPrBk,
        IsActive = true
    );
    update standardPricebook;

    PricebookEntry testPricebookEntry = new PricebookEntry(
        Product2Id = testProduct.Id,
        Pricebook2Id = stdPrBk,
        UnitPrice = 100.0,
        IsActive = true
    );
    insert testPricebookEntry;

    WorkOrder wo = [SELECT Id, Pricebook2Id FROM WorkOrder WHERE Id = :workOrderId];

    if (wo.Pricebook2Id == null || wo.Pricebook2Id != stdPrBk) {
        wo.Pricebook2Id = stdPrBk;
        update wo;
    }

    WorkOrderLineItem woli = new WorkOrderLineItem(
        WorkOrderId = wo.Id,
        RR_Product__c = testProduct.Id,
        PricebookEntryId = testPricebookEntry.Id,
        Quantity = 1,
        Status = 'New'
    );
    insert woli;

    WorkPlan wp = new WorkPlan(
        WorkOrderId = wo.Id,
        Name = 'test',
        Status__c = 'New'
    );
    insert wp;
}


    @IsTest
    static void testHandleWarrantyApproval() {
        WorkOrder wo = createWorkOrder();
        Warranty_Prior__c wp = createWarrantyPrior('Pending', wo.Id);

        Map<Id, Warranty_Prior__c> oldMap = new Map<Id, Warranty_Prior__c>{
            wp.Id => new Warranty_Prior__c(Id = wp.Id, Status__c = 'Draft')
        };

        wp.Status__c = 'Approved';
        update wp;

        Test.startTest();
        WarrantyPriorTriggerHandler.handleWarrantyApproval(new List<Warranty_Prior__c>{ wp }, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testCreatClaimLineItemPartJobsAdded() {
        WorkOrder wo = createWorkOrder();
        Warranty_Prior__c wp = createWarrantyPrior('Pending', wo.Id);

        wp.Status__c = 'Approved';
        update wp;

        Claim claim = createClaim(wp, wo);
        createLineItems(wo.Id, claim);

        Map<Id, Warranty_Prior__c> oldMap = new Map<Id, Warranty_Prior__c>{
            wp.Id => new Warranty_Prior__c(Id = wp.Id, Status__c = 'Draft')
        };

        Test.startTest();
        WarrantyPriorTriggerHandler.creatClaimLineItemPartJobsAdded(new List<Warranty_Prior__c>{ wp }, oldMap);
        Test.stopTest();
    }
}