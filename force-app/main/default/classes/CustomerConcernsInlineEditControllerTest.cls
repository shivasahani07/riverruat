@isTest
public class CustomerConcernsInlineEditControllerTest {

    @isTest
    static void testCustomerConcernListSuccess() {
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone'
        );
        insert testCase;

        Customer_Concern__c cc1 = new Customer_Concern__c( Case__c = testCase.Id);
        Customer_Concern__c cc2 = new Customer_Concern__c( Case__c = testCase.Id);
        insert new List<Customer_Concern__c>{ cc1, cc2 };

        Test.startTest();
        	CustomerConcernsInlineEditController.customerConcernList(testCase.Id);
        Test.stopTest();
    }

    @isTest
    static void testCustomerConcernListCatchBlock() {
        Test.startTest();
            CustomerConcernsInlineEditController.customerConcernList(null);
        Test.stopTest();
    }
}