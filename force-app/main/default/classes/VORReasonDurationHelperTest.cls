@isTest
public class VORReasonDurationHelperTest {
    @isTest
    static void testVORReasonDurationUpdate_AllPaths() {
        List<VOR__c> newList = new List<VOR__c>();
        Map<Id, VOR__c> oldMap = new Map<Id, VOR__c>();

        ProductRequest po = new ProductRequest(ShipmentType = 'VOR');
        insert po;

        // All reasons exactly as per helper class
        List<String> reasons = new List<String>{
            'Awaiting Diagnosis', // (note the typo must match your helper)
            'Awaiting Parts',
            'Insurance Stage 1',
            'Insurance Stage 2',
            'Awaiting Allotment',
            'Customer Approval',
            'Ready for Delivery',
            'Rework'
        };

        // Step 1: Create original VOR records
        for (String reason : reasons) {
            VOR__c vor = new VOR__c(
                VOR_Reason__c = reason,
                Reason_Entered_Date__c = System.now().addDays(-1),
                Purchase_Order__c = po.Id
            );
            newList.add(vor);
        }
        insert newList;

        // Step 2: Clone for oldMap and simulate new changes
        List<VOR__c> updatedList = new List<VOR__c>();
        for (VOR__c vor : newList) {
            VOR__c oldCopy = vor.clone(false, true, false, false);
            oldMap.put(vor.Id, oldCopy);

            vor.VOR_Reason__c = 'Changed Reason'; // Triggers reason update logic
            updatedList.add(vor);
        }

        // Step 3: Call helper
        Test.startTest();
        VORReasonDurationHelper.VORReasonDurationUpdate(updatedList, oldMap);
        Test.stopTest();

        // Step 4: Assert each duration field
        for (VOR__c vor : updatedList) {
            System.assertNotEquals(null, vor.Reason_Entered_Date__c);

            String oldReason = oldMap.get(vor.Id).VOR_Reason__c;
            /*if (oldReason == 'Awaiting Diagnosis') {
                System.assert(vor.Awaiting_Diagnosis_in_Days__c > 0);
            }*/
            if (oldReason == 'Awaiting Parts') {
                System.assert(vor.Awaiting_Parts_in_Days__c > 0);
            }
            if (oldReason == 'Insurance Stage 1') {
                System.assert(vor.Insurance_Stage_1_in_Days__c > 0);
            }
            if (oldReason == 'Insurance Stage 2') {
                System.assert(vor.Insurance_Stage_2_in_Days__c > 0);
            }
            if (oldReason == 'Awaiting Allotment') {
                System.assert(vor.Awaiting_Allotment_in_Days__c > 0);
            }
            if (oldReason == 'Customer Approval') {
                System.assert(vor.Customer_Approval_in_Days__c > 0);
            }
            if (oldReason == 'Ready for Delivery') {
                System.assert(vor.Ready_for_Delivery_in_Days__c > 0);
            }
            if (oldReason == 'Rework') {
                System.assert(vor.Rework_in_Days__c > 0);
            }
        }
    }
}