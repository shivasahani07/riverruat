@isTest
public class TriggerOnFailureCodeHelperv2_Test {
	
    // Helper method to create common setup data
    private static Map<String, Id> setupTestData() {
        Map<String, Id> ids = new Map<String, Id>();

        // Create TFR record
        TFR__c tfr = new TFR__c(VIN_Start__c = 'VIN12345');
        insert tfr;
        ids.put('TFR', tfr.Id);

        // Create Product
        Product2 prod = new Product2(Name = 'Brake Pad', ProductCode = 'P123', isActive = true, HSN_Code__c='HSN-34U', Type__c='Parts');
        insert prod;
        ids.put('Product', prod.Id);

        // Create CodeSet
        CodeSet cs = new CodeSet(Name = 'CS-01', Code = 'C01');
        insert cs;
        ids.put('CodeSet', cs.Id);

        // Create TFR_Part_Effect record
        TFR_Part_Effect__c tfrPart = new TFR_Part_Effect__c(
            TFR__c = tfr.Id,
            Product__c = prod.Id
        );
        insert tfrPart;
        ids.put('TFR_Part_Effect', tfrPart.Id);

        // Create TFR_Labour_Effect record
        TFR_Labour_Effect__c tfrLabour = new TFR_Labour_Effect__c(
            TFR__c = tfr.Id,
            Code_Set__c = cs.Id
        );
        insert tfrLabour;
        ids.put('TFR_Labour_Effect', tfrLabour.Id);

        return ids;
    }

    @IsTest
    static void testBeforeInsertPartEffect() {
        Map<String, Id> ids = setupTestData();

        // Create Failure Code with Part Effect
        Failure_Code__c fc = new Failure_Code__c(
            Name = 'FC-Part',
            TFR_Part_Effect__c = ids.get('TFR_Part_Effect')
        );
		
        Test.startTest();
        insert fc;
        List<Failure_Code__c> fcList = new List<Failure_Code__c>{fc};
        TriggerOnFailureCodeHelper.BeforeInsert(fcList);
        Test.stopTest();
    }
	
    @IsTest
    static void testBeforeInsertLabourEffect() {
        Map<String, Id> ids = setupTestData();

        // Create Failure Code with Labour Effect
        Failure_Code__c fc = new Failure_Code__c(
            Name = 'FC-Labour',
            TFR_Labour_Effect__c = ids.get('TFR_Labour_Effect')
        );

        Test.startTest();
        insert fc;
        Test.stopTest();
    }
    
    @IsTest
    static void testBeforeUpdatePartEffectChange() {
        Map<String, Id> ids = setupTestData();

        // Insert a Failure Code
        Failure_Code__c fc = new Failure_Code__c(
            Name = 'FC-Update',
            TFR_Part_Effect__c = ids.get('TFR_Part_Effect')
        );
        insert fc;

        // Create a second TFR_Part_Effect
        Product2 newProd = new Product2(Name = 'Clutch Plate', ProductCode = 'P234', isActive = true, HSN_Code__c='HSN-44U', Type__c='Parts');
        insert newProd;

        TFR_Part_Effect__c newPartEff = new TFR_Part_Effect__c(
            TFR__c = ids.get('TFR'),
            Product__c = newProd.Id
        );
        insert newPartEff;

        // Update Failure Code to point to new Part Effect
        fc.TFR_Part_Effect__c = ids.get('TFR_Part_Effect');

        Test.startTest();
        update fc;
        Test.stopTest();

        Failure_Code__c updatedFC = [SELECT Id, FPV_Key__c, Type__c FROM Failure_Code__c WHERE Id = :fc.Id];
        
    }
    
    @IsTest
    static void testBeforeUpdatePartEffectChange2() {
        Map<String, Id> ids = setupTestData();

        // Insert a Failure Code
        Failure_Code__c fc = new Failure_Code__c(
            Name = 'FC-Update',
            TFR_Part_Effect__c = ids.get('TFR_Part_Effect')
        );
        insert fc;

        // Create a second TFR_Part_Effect
        Product2 newProd = new Product2(Name = 'Clutch Plate', ProductCode = 'P234', isActive = true, HSN_Code__c='HSN-44U', Type__c='Parts');
        insert newProd;

        TFR_Part_Effect__c newPartEff = new TFR_Part_Effect__c(
            TFR__c = ids.get('TFR'),
            Product__c = newProd.Id
        );
        insert newPartEff;

        // Update Failure Code to point to new Part Effect
        //fc.TFR_Part_Effect__c = newPartEff.Id;

        Test.startTest();
        update fc;
        Test.stopTest();
        
    }

    @IsTest
    static void testBeforeUpdateValidationError() {
        Map<String, Id> ids = setupTestData();

        // Insert Failure Code
        Failure_Code__c fc = new Failure_Code__c(
            Name = 'FC-Validation',
            TFR_Part_Effect__c = ids.get('TFR_Part_Effect')
        );
        insert fc;

        // Try to update FPV_Key__c directly
        fc.FPV_Key__c = 'TamperedValue';
        Test.startTest();
        try {
            update fc;
        } catch (DmlException e) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testAfterInsertAndAfterUpdate() {
        Map<String, Id> ids = setupTestData();

        // Insert Failure Code
        Failure_Code__c fc = new Failure_Code__c(
            Name = 'FC-After',
            TFR_Labour_Effect__c = ids.get('TFR_Labour_Effect')
        );
        insert fc;

        // Update Failure Code to trigger AfterUpdate logic
        fc.TFR_Labour_Effect__c = ids.get('TFR_Labour_Effect');

        Test.startTest();
        update fc;
        Test.stopTest();

	}
	
    @IsTest
    static void mytest_Test(){
        TriggerOnFailureCodeHelperv2.mytest();
    }
}