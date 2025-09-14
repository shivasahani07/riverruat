@isTest(seeAllData = true)
private class actionPlanHandlerTest {
    @isTest
    static void testGetTheCountOfTheActionPlansOfaFieldFix() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account 1', Type='Customer');
        insert testAccount;
        
        // Create test Location
        Schema.Location testLocation = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'State',
            State__c = 'Karnataka',
            IsInventoryLocation = true
        );
        insert testLocation;
        
        // Create test Contact
        Contact con = new Contact(
            LastName = 'Dinesh 1',
            Phone = '7834878789',
            AccountId = testAccount.id,
            Location__c = testLocation.id
        );
        insert con;
        
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product 1',
            IsActive = true,
            ProductCode = 'abcd',
            HSN_Code__c = 'abcd',
            Type__c = 'Vehicle'
        );
        insert testProduct;
        
        // Create Pricebook Entry
        Id stdPrBk = Test.getStandardPricebookId();
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        // Create test Asset
        Asset testAsset = new Asset(
            Name = 'Test Asset 1',
            AccountId = testAccount.Id,
            Product2Id = testProduct.Id
        );
        insert testAsset;
        
        // Create Vehicle Definition
        VehicleDefinition testVD = new VehicleDefinition(
            Name = 'Test VehicleDefinition 1',
            ProductId = testProduct.Id
        );
        insert testVD;
        
        // Create Software Version
        Software_Version__c testSV = new Software_Version__c(
            Name = 'Test Software Version 1'
        );
        insert testSV;
        
        // Create Vehicle
        Vehicle testVehicle = new Vehicle(
            Name = 'Test Vehicle 2',
            Account__c = testAccount.Id,
            AssetId = testAsset.Id,
            VehicleDefinitionId = testVD.Id,
            VehicleIdentificationNumber = 'A2B3',
            Software_Version__c = testSV.Id,
            Charger_PC_Number__c = 'abcd',
            PDI_Status_Pass__c = true
        );
        insert testVehicle;
        
        // Create test Product for parts
        Product2 testPartProduct = new Product2(
            Name = 'Test Part Product',
            ProductCode = 'R112061460',
            IsActive = true,
            HSN_Code__c='65061090',
            Type__c='Parts'
        );
        insert testPartProduct;
        
        // Create test ProductItem (Inventory)
        ProductItem testInventory = new ProductItem(
            Product2Id = testPartProduct.Id,
            LocationId = testLocation.Id
        );
        insert testInventory;
        
        // Create test Job Card (WorkOrder)
        WorkOrder testJobCard = new WorkOrder(
            AccountId = testAccount.Id,
            Vehicle__c = testVehicle.Id,
            Location__c = testLocation.Id,
            Vehicle_Registration_Number__c = 'REG123',
            Odometer_Reading__c = 1000,
            Status = 'In Progress',
            ContactId = con.Id
        );
        insert testJobCard;
        
        // ActionPlanTemplateVersion
        ActionPlanTemplateVersion aptv = [
            SELECT Id, ActionPlanTemplateId, Status 
            FROM ActionPlanTemplateVersion where  ActionPlanTemplate.TargetEntityType='Vehicle'
            LIMIT 1
        ];
        aptv.Status = 'Final';
        update aptv;
        
        // ActionPlanTemplate
        ActionPlanTemplate apt = [
            SELECT Id 
            FROM ActionPlanTemplate 
            WHERE Id = :aptv.ActionPlanTemplateId AND TargetEntityType ='Vehicle'
        ];
        
        // Create Field Fix
        Field_Fix__c testFieldFix = new Field_Fix__c(
            Action_Plan_Template__c = apt.Id
        );
        insert testFieldFix;
        
        // Create ActionPlan
        ActionPlan newAP = new ActionPlan(
            Name = 'Test Action Plan',
            ActionPlanTemplateVersionId = aptv.Id,
            TargetId = testVehicle.Id,
            StartDate = System.today().addDays(-1),
            To_be_Completed_in_JC__c = false,
            ActionPlanType = 'Industries',
            Job_Card__c = testJobCard.Id,
            Field_Fix__c = testFieldFix.Id
        );
        insert newAP;
        
        // Check for Before Update ActionPlan to trigger logic
        newAP.To_be_Completed_in_JC__c = true;
        try{
            update newAP;    
        } catch(Exception ex){
            System.debug('Error Message : ' + ex);
        }
        
        // Create Required Product
        Required_Product__c testRequiredProduct = new Required_Product__c(
            Action_Plan_Template__c = apt.Id,
            Product__c = testPartProduct.Id,
            Quantity__c = 1
        );
        insert testRequiredProduct;
        
        // Check for Before Delete
        try{
            delete newAp;
        } catch(Exception ex){
            System.debug('Error Message : ' + ex);
        }
    }
    
    
    @isTest
    static void testCreateProductAndLabour() {
        
        // Create Account
        Account acc = new Account(Name = 'Test Account', Type = 'Customer');
        insert acc;
        
        // Create Location
        Schema.Location loc = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'State',
            State__c = 'Karnataka',
            IsInventoryLocation = true
        );
        insert loc;
        
        // Create Contact
        Contact con = new Contact(
            LastName = 'Test Contact',
            Phone = '9999999999',
            AccountId = acc.Id,
            Location__c = loc.Id
        );
        insert con;
        
        // Create Vehicle Product
        Product2 vehicleProduct = new Product2(
            Name = 'Test Vehicle',
            IsActive = true,
            ProductCode = 'VEH123',
            Type__c = 'Vehicle',
            HSN_Code__c = 'HSN-3489'
        );
        insert vehicleProduct;
        
        // Pricebook
        Id priceBookId = Test.getStandardPricebookId();
        insert new PricebookEntry(Product2Id = vehicleProduct.Id, Pricebook2Id = priceBookId, UnitPrice = 100, IsActive = true);
        
        // Asset
        Asset asset = new Asset(Name = 'Test Asset', AccountId = acc.Id, Product2Id = vehicleProduct.Id);
        insert asset;
        
        // Vehicle Definition
        VehicleDefinition vd = new VehicleDefinition(Name = 'Test VD', ProductId = vehicleProduct.Id);
        insert vd;
        
        // Software Version
        Software_Version__c sv = new Software_Version__c(Name = 'Test Version');
        insert sv;
        
        // Vehicle
        Vehicle veh = new Vehicle(
            Name = 'Test Vehicle',
            Account__c = acc.Id,
            AssetId = asset.Id,
            VehicleDefinitionId = vd.Id,
            Software_Version__c = sv.Id,
            VehicleIdentificationNumber = 'VIN123',
            PDI_Status_Pass__c = true,
            Charger_PC_Number__c = '348537'
        );
        insert veh;
        
        // Parts Product
        Product2 partsProduct = new Product2(
            Name = 'Test Part',
            ProductCode = 'PART123',
            Type__c = 'Parts',
            IsActive = true,
            HSN_Code__c = 'HSN-3989'
        );
        insert partsProduct;
        
        insert new PricebookEntry(Product2Id = partsProduct.Id, Pricebook2Id = priceBookId, UnitPrice = 100, IsActive = true);
        
        // Inventory with Quantity
        ProductItem pi = new ProductItem(
            Product2Id = partsProduct.Id,
            LocationId = loc.Id
        );
        insert pi;
        
        // Job Card
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Vehicle__c = veh.Id,
            Location__c = loc.Id,
            Vehicle_Registration_Number__c = 'REG123',
            Status = 'In Progress',
            ContactId = con.Id
        );
        insert wo;
        
        // ActionPlanTemplateVersion
        ActionPlanTemplateVersion aptv = [
            SELECT Id, ActionPlanTemplateId, Status 
            FROM ActionPlanTemplateVersion where  ActionPlanTemplate.TargetEntityType='Vehicle'
            LIMIT 1
        ];
        aptv.Status = 'Final';
        update aptv;
        
        
        // ActionPlanTemplate
        ActionPlanTemplate apt = [
            SELECT Id ,
            TargetEntityType
            FROM ActionPlanTemplate 
            WHERE Id = :aptv.ActionPlanTemplateId
        ];
        
        // Required Product
        Required_Product__c rp = new Required_Product__c(
            Action_Plan_Template__c = apt.Id,
            Product__c = partsProduct.Id,
            Quantity__c = 1
        );
        insert rp;
        
        // Create Code Set
        CodeSet cs = new CodeSet(Name='Test',Code='9876');
        insert cs;
        
        // Required Labour
        Required_Labour__c rl = new Required_Labour__c(
            Action_Plan_Template__c = apt.Id,
            Code_Set__c = cs.Id
        );
        insert rl;
        
        // Field Fix
        Field_Fix__c ff = new Field_Fix__c(Action_Plan_Template__c = apt.Id);
        insert ff;
        
        // ActionPlan
        ActionPlan ap = new ActionPlan(
            Name = 'Test AP',
            ActionPlanTemplateVersionId = aptv.Id,
            TargetId = veh.Id,
            StartDate = System.today().addDays(-1),
            To_be_Completed_in_JC__c = false,
            ActionPlanType = 'Industries',
            Job_Card__c = wo.Id,
            Field_Fix__c = ff.Id
        );
        insert ap;
        
        // Trigger logic fires on update to true
        ap.To_be_Completed_in_JC__c = true;
        try{
            update ap;    
        }catch(Exception ex){
            System.debug('ex : ' + ex);
        }
    }
}




/*
// Create Code Set
CodeSet w = new CodeSet(Name='Test',Code='9876');
insert w;

// Create test Required Labour
Required_Labour__c testRequiredLabour = new Required_Labour__c(
Action_Plan_Template__c = apt.Id,
Code_Set__c = w.Id
);
insert testRequiredLabour;

Field_Fix__c testFieldFix1 = [SELECT Id FROM Field_Fix__c LIMIT 1];
WorkOrder testJobCard1 = [SELECT Id FROM WorkOrder LIMIT 1];
List<ActionPlan> testActionPlans = new List<ActionPlan>();
for (Integer i = 0; i < 5; i++) {
ActionPlan ap = new ActionPlan(
Name = 'Test AP ' + i,
Field_Fix__c = testFieldFix.Id,
Job_Card__c = testJobCard.Id,
To_be_Completed_in_JC__c = (i < 3), // First 3 will be marked for completion
ActionPlanTemplateVersionId = ,
ActionPlanType] = 
);
testActionPlans.add(ap);
}
insert testActionPlans;





/*
ActionPlanTemplate apt = new ActionPlanTemplate(
Name = 'Test Template',
ActionPlanType = 'Industries',
TargetEntityType = 'Vehicle'
);
insert apt;

// 2. Query the automatically created version
ActionPlanTemplateVersion aptv = [
SELECT Id, ActionPlanTemplateId, Status	// Draft
FROM ActionPlanTemplateVersion 
WHERE ActionPlanTemplateId = :apt.Id 
LIMIT 1
];
System.debug('------------------ aptv : ' + aptv);

// 3. Insert Action Plan using existing version
ActionPlan newAP = new ActionPlan(
Name = 'Test Action Plan',
ActionPlanTemplateVersionId = aptv.Id,
TargetId = testVehicle.Id,
StartDate = System.today().addDays(-1)
);
insert newAP;

/*
// 3. Query Action Plan linked to the version
List<ActionPlan> actionPlans = [
SELECT Id, Name, ActionPlanTemplateVersionId, TargetId, StartDate, To_be_Completed_in_JC__c
FROM ActionPlan 
WHERE ActionPlanTemplateVersionId = :aptv.Id
];

System.debug('Action Plans: ' + actionPlans);

actionPlans[0].To_be_Completed_in_JC__c = true;
update actionPlans;
*/