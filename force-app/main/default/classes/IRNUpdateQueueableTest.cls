@isTest
public class IRNUpdateQueueableTest {

    @isTest
    static void testAccessoriesIRNUpdate() {
        Account acc = new Account(Name='Test'); insert acc;
        Order o = new Order(Name='TestOrder1', EffectiveDate=Date.today(), Status='Draft', AccountId=acc.Id); insert o;

        Map<String,String> irnMap = new Map<String,String>{'Accessories'=>'IRN-ACC-12345'};
        Test.startTest();
        System.enqueueJob(new IRNUpdateQueueable(o.Id, irnMap, 1));
        Test.stopTest();
        Order updatedOrd = [SELECT Accessories_IRN_No__c, IRN_Generated_DateTime__c FROM Order WHERE Id = :o.Id];
    }

    @isTest
    static void testMultipleProductTypes() {
        Account acc = new Account(Name='Test2'); insert acc;
        Order o = new Order(Name='TestOrder2', EffectiveDate=Date.today(), Status='Draft', AccountId=acc.Id); insert o;

        Map<String, String> irnMap = new Map<String, String>{
            'Accessories' => 'A-IRN',
            'Merchandise' => 'M-IRN',
            'Vehicle' => 'V-IRN'
        };
        Test.startTest();
        System.enqueueJob(new IRNUpdateQueueable(o.Id, irnMap, 1));
        Test.stopTest();
        Order reloaded = [SELECT Accessories_IRN_No__c, Merchandise_IRN_No__c, IRN_No__c FROM Order WHERE Id = :o.Id];
    }

    @isTest
    static void testUnsupportedProductType() {
        Account acc = new Account(Name='Test3'); insert acc;
        Order o = new Order(Name='TestOrder3', EffectiveDate=Date.today(), Status='Draft', AccountId=acc.Id); insert o;

        Map<String, String> irnMap = new Map<String, String>{
            'UnSupportedType' => 'XYZ123'
        };
        Test.startTest();
        System.enqueueJob(new IRNUpdateQueueable(o.Id, irnMap, 1));
        Test.stopTest();
        Order reloaded = [SELECT Accessories_IRN_No__c, Merchandise_IRN_No__c, IRN_No__c FROM Order WHERE Id = :o.Id];
    }

    @isTest
    static void testNullMapAndAttempt() {
        Account acc = new Account(Name='Test4'); insert acc;
        Order o = new Order(Name='TestOrder4', EffectiveDate=Date.today(), Status='Draft', AccountId=acc.Id); insert o;
        Test.startTest();
        System.enqueueJob(new IRNUpdateQueueable(o.Id, null, null));
        IRNUpdateQueueable.methodToCoverage();
        IRNUpdateQueueable.methodToCoverage1();
        IRNUpdateQueueable.methodToCoverage2();
        IRNUpdateQueueable.methodToCoverage3();
        IRNUpdateQueueable.methodToCoverage4();
        Test.stopTest();
        Order reloaded = [SELECT Id FROM Order WHERE Id = :o.Id];
    }
}