@isTest(seeAllData = true)
public class ActionPlanCheckerControllerTest {
    
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
            ProductCode = 'PART123',
            IsActive = true,
            HSN_Code__c='R112081466',
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
        
        ActionPlanCheckerController.getActionPlansForJobCard(testJobCard.id);
        try{
            delete newAp;
        } catch(Exception ex){
            System.debug('Error Message : ' + ex);
        }
    }
    
    
}