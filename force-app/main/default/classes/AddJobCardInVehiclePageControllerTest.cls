@isTest
public class AddJobCardInVehiclePageControllerTest {

    @isTest
    static void testGetVehicleDetailsAndCreateJobCard() {
        
         Id vehiclePdiRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Vehicle PDI').getRecordTypeId();
         Account testAccount = new Account(Name = 'Test Account 1',Type='Dealer',Center_Code__c = '8789900');
        insert testAccount;
       

         Contact con = new Contact(LastName ='Dinesh 1',Phone = '7834878789',AccountId = testAccount.id );
        insert con;

        Product2 prod = new Product2(Name = 'Test Vehicle Product', IsActive = true, ProductCode = 'V001', HSN_Code__c = '1234', Type__c = 'Vehicle');
        insert prod;
         Id stdPrBk = Test.getStandardPricebookId();
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;

        Asset asset = new Asset(Name = 'Test Asset', AccountId = testAccount.Id, Product2Id = prod.Id);
        insert asset;

        VehicleDefinition vdef = new VehicleDefinition(Name = 'Test VD', ProductId = prod.Id);
        insert vdef;

        Software_Version__c sv = new Software_Version__c(Name = 'SW 1.0');
        insert sv;
        

        Vehicle veh = new Vehicle(
            Name = 'Test Vehicle',
            CurrentOwnerId = testAccount.Id,
            Dealer__c = testAccount.Id,
            AssetId = asset.Id,
            VehicleDefinitionId = vdef.Id,
            VehicleIdentificationNumber = 'VIN123',
            Software_Version__c = sv.Id,
            Charger_PC_Number__c = 'PC123',
            PDI_Status_Pass__c = true
        );
        insert veh;
        Order oldOrder = new Order( AccountId = testAccount.Id, Status__c = 'Processing',Status='Processing',Assigned_Vehicle__c = veh.Id,EffectiveDate = Date.today(),Pricebook2Id = stdPrBk,Payment_Status__c = 'Completed', Contact__c = con.id);
        insert oldOrder;
        AssetMilestone am1 = new AssetMilestone(
            Name = 'Milestone',
            MilestoneDate = Date.today(),
            Stage = 'Active',
            AssetId = asset.Id,
            UsageType = 'Automotive',
            MilestoneType = 'PDI',
            VehicleId = veh.Id
        );
        insert am1;

        AssetMilestone am = new AssetMilestone(
            Name = 'Milestone',
            MilestoneDate = Date.today(),
            Stage = 'Active',
            AssetId = asset.Id,
            UsageType = 'Automotive',
            MilestoneType = 'Sold',
            VehicleId = veh.Id
        );
        insert am;

        Test.startTest();

        
        AddJobCardInVehiclePageController.wrapperForJobCards result =
        AddJobCardInVehiclePageController.getVehicleDetails(veh.Id);
       
        Map<String, Object> jobCardDataMap = new Map<String, Object>{
            'accId' => testAccount.Id,
            'conId' => con.Id,
            'vehId' => veh.Id,
            'oRed' => 70,
            'jobType' => 'Paid Service',
               'RecordTypeId' => vehiclePdiRtId
        };
        String jobCardDataJson = JSON.serialize(jobCardDataMap);

        List<String> workOrderIds = AddJobCardInVehiclePageController.createJobCard(jobCardDataJson);
        Test.stopTest();
    }
}