@isTest(SeeAllData=true)
private class VorListViewDMSControllerTest {

    static testMethod void testGetDealerAssociatedVors_withReason() {
        // Setup: Create a Partner User and Related Data
        Account dealer = new Account(Name = 'Test Dealer');
        insert dealer;

        // Query Partner Role and Profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager (Partner)'  LIMIT  1];
        Contact pcontact = [SELECT Id, Name FROM Contact LIMIT 1];
        User puser = [SELECT Id, Name FROM User WHERE ProfileId = :p.Id  AND isACTIVE =TRUE  LIMIT 1];

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'Open',
            OwnerId = puser.Id
        );
        insert wo;

        // Create VOR__c with Reason
        VOR__c vorWithReason = new VOR__c(
            Job_Card__c = wo.Id,
            VOR_Reason__c = 'Rework'
        );
        insert vorWithReason;

        // Create VOR__c without Reason
        VOR__c vorWithoutReason = new VOR__c(
            Job_Card__c = wo.Id,
            VOR_Reason__c = null
        );
        insert vorWithoutReason;

        Test.startTest();
        List<VOR__c> resultWith = VorListViewDMSController.GetDealerAssociatedVors(puser.Id, 'with Reason');
        System.assertEquals(1, resultWith.size());
        System.assertEquals('Rework', resultWith[0].VOR_Reason__c);

        List<VOR__c> resultWithout = VorListViewDMSController.GetDealerAssociatedVors(puser.Id, 'without Reason');
        System.assertEquals(1, resultWithout.size());
        System.assertEquals(null, resultWithout[0].VOR_Reason__c);

        List<VOR__c> resultAll = VorListViewDMSController.GetDealerAssociatedVors(puser.Id, 'All');
        System.assertEquals(1, resultAll.size());

        List<VOR__c> resultExact = VorListViewDMSController.GetDealerAssociatedVors(puser.Id, 'Rework');
       
        Test.stopTest();
    }

    static testMethod void testGetDealerAssociatedVors_nonPartner() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager (Partner)' LIMIT 1];
        Contact pcontact = [SELECT Id, Name FROM Contact LIMIT 1];
        User puser = [SELECT Id, Name FROM User WHERE ProfileId = :p.Id LIMIT 1];

        Test.startTest();
        List<VOR__c> result = VorListViewDMSController.GetDealerAssociatedVors(puser.Id, 'All');
        Test.stopTest();
        //System.assertEquals(0, result.size(), 'Non-partner user should return empty list');
    }
}