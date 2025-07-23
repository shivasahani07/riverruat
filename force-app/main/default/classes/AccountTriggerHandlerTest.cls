@Istest
public class AccountTriggerHandlerTest {
    @IsTest
    static void testMethodForAccount(){
        Account testAccount = new Account(Name = 'Test Account 1',Type='Customer',Store_Type__c='DODO',Email__c='test@gmail.com');
        insert testAccount;
        Website_Creds__c rwd = new Website_Creds__c(Name='Website Creds', BaseURL__c='https://dummywebsite.com');
        insert rwd;
        testAccount.Email__c='notest@gmail.com';
        Test.startTest();
        update testAccount;
        Test.stopTest();
    }

}