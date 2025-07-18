@isTest
public class LeadPhoneValidatorTest {

    @isTest
    static void testDuplicatePhoneValidation() {
        Lead existing = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Acme Inc',
            Phone = '(123) 456-7890'
        );
        insert existing;

        Lead duplicate = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Beta Inc',
            Phone = '121212'
        );

        Test.startTest();
        try {
            LeadPhoneValidator.checkForDuplicatePhones(new List<Lead>{duplicate});
        } catch (Exception e) {
            System.debug('Caught expected error: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testNoDuplicatePhoneValidation() {
        Lead existing = new Lead(
            FirstName = 'Anna',
            LastName = 'Williams',
            Company = 'Gamma Corp',
            Phone = '5656767890'
        );
        insert existing;

        Lead unique = new Lead(
            FirstName = 'Tom',
            LastName = 'Johnson',
            Company = 'Zeta Ltd',
            Phone = '9998887777'
        );

        Test.startTest();
        LeadPhoneValidator.checkForDuplicatePhones(new List<Lead>{unique});
        Test.stopTest();
    }
}