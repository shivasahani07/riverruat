@IsTest
public class JobCardHandlerTest {

    /************ TEST DATA HELPERS ************/

    private static WorkOrder createWorkOrderBaseData() {
        Account acc = new Account(Name = 'Test Account', Type = 'Customer');
        insert acc;

        Contact con = new Contact(LastName = 'Test', AccountId = acc.Id, Phone = '2345678930');
        insert con;

        Asset asst = new Asset(Name = 'Test Asset', AccountId = acc.Id, ContactId = con.Id);
        insert asst;

        Software_Version__c sv = new Software_Version__c(Name = 'SW 1.0', Latest_Software_Version__c = true);
        insert sv;

        Product2 prod = new Product2(Name = 'Test Vehicle', ProductCode='P001', Type__c = 'Vehicle', HSN_Code__c = '234566');
        insert prod;

        VehicleDefinition vd = new VehicleDefinition(Name='Def', ProductId = prod.Id);
        insert vd;

        Vehicle vac = new Vehicle(
            Name='Vehicle1',
            CurrentOwnerId=acc.Id,
            VehicleIdentificationNumber='VIN123',
            VehicleDefinitionId=vd.Id,
            Software_Version__c=sv.Id,
            AssetId=asst.Id,
            Charger_PC_Number__c = '3232325'
        );
        insert vac;

        Warehouse__c wh = new Warehouse__c(Name='WH Test');
        insert wh;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Vehicle__c = vac.Id,
            Warehouse__c = wh.Id,
            Status = 'Draft'
        );
        insert wo;

        return wo;
    }

    private static Warranty_Prior__c createWarranty(Id woId) {
        Warranty_Prior__c wp = new Warranty_Prior__c(
            Status__c = 'Approved',
            Job_Card__c = woId
        );
        insert wp;
        return wp;
    }

    private static void createPartLabour(Id woId) {
        // Activate & assign Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pricebookId, IsActive = true);
        update pb;

        // Assign pricebook to WorkOrder
        WorkOrder wo = [SELECT Id, Pricebook2Id FROM WorkOrder WHERE Id = :woId LIMIT 1];
        wo.Pricebook2Id = pricebookId;
        update wo;

        Product2 p = new Product2(
            Name = 'Part',
            ProductCode='PAR1',
            HSN_Code__c='123',
            Type__c='Accessories',
            IsActive=true
        );
        insert p;
        
        PricebookEntry pe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = p.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pe;

        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = woId,
            PricebookEntryId = pe.Id,
            Quantity = 1,
            Status = 'Approved'
        );
        insert woli;

        WorkPlan wp = new WorkPlan(
            WorkOrderId = woId,
            Name = 'Labour1',
            Status__c = 'Approved'
        );
        insert wp;
    }

    /************ TESTS ************/

    @IsTest
    static void testClaimAndClaimItemCreation() {
        WorkOrder wo = createWorkOrderBaseData();
        Warranty_Prior__c wp = createWarranty(wo.Id);
        createPartLabour(wo.Id);

        WorkOrder oldWO = wo.clone(false, false, false, false);
        oldWO.Status = 'Draft';
        wo.Status = 'Completed';

        Test.startTest();
        JobCardHandler.createClaimAndClaimItemOnWorkOrderCompletion(
            new List<WorkOrder>{ wo },
            new Map<Id, WorkOrder>{ wo.Id => oldWO }
        );
        Test.stopTest();
    }

    @IsTest
    static void testNoDuplicateClaimItems() {
        WorkOrder wo = createWorkOrderBaseData();
        Warranty_Prior__c wp = createWarranty(wo.Id);
        createPartLabour(wo.Id);

        Claim c = new Claim(
            Name='Dup Test',
            Status='Draft',
            Job_Card__c = wo.Id,
            Warranty_Prior__c = wp.Id,
            AccountId = wo.AccountId,
            Vehicle__c = wo.Vehicle__c
        );
        insert c;

        WorkOrderLineItem p = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id LIMIT 1];
        ClaimItem ci = new ClaimItem(
            ClaimId = c.Id,
            Part__c = p.Id,
            Claim_Type__c = 'Part',
            Name = 'tsts',
            FaultDate = System.today()
        );
        insert ci;

        WorkOrder oldWO = wo.clone(false,false,false,false);
        oldWO.Status = 'Draft';
        wo.Status = 'Completed';

        Test.startTest();
        JobCardHandler.createClaimAndClaimItemOnWorkOrderCompletion(
            new List<WorkOrder>{ wo },
            new Map<Id, WorkOrder>{ wo.Id => oldWO }
        );
        Test.stopTest();
    }
}