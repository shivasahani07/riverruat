@isTest
public class VORTriggerHelperTest {
    
    @isTest
    static void testVORReasonDurationUpdate() {
        // Step 1: Create a Purchase Order record to use in the test
        ProductRequest po = new ProductRequest();
        po.ShipmentType = 'VOR';
        insert po;

        // Step 2: Insert initial VOR__c record with a reason and a past Reason_Entered_Date__c
        VOR__c vorRecord = new VOR__c(
            VOR_Reason__c = 'Awaiting Parts',
            Reason_Entered_Date__c = System.now().addHours(-2),
            VOR_Reason_Duration_Time__c = 1.0,
            Purchase_Order__c = po.Id // Use dynamically created ID
        );
        insert vorRecord;
        
        // Step 3: Update reason to simulate a change
        vorRecord.VOR_Reason__c = 'Customer Approval';
        
        Test.startTest();
        update vorRecord; // This should invoke your trigger/helper
        Test.stopTest();
        
        // Step 4: Query updated record to validate changes
        VOR__c updated = [
            SELECT Id, VOR_Reason_Duration_Time__c, Reason_Entered_Date__c
            FROM VOR__c
            WHERE Id = :vorRecord.Id
        ];
        
        // Step 5: Assertions
        System.assertNotEquals(null, updated.Reason_Entered_Date__c, 'Reason_Entered_Date__c should be updated');
        System.assert(updated.VOR_Reason_Duration_Time__c > 1.0, 'Duration should have increased');
    }
}