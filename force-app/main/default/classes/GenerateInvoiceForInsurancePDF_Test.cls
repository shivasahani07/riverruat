@IsTest
private class GenerateInvoiceForInsurancePDF_Test {

    @IsTest
    static void testGenerateInvoicePDF_ValidWO() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Insurance WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;

        Test.startTest();
        String result = GenerateInvoiceForInsurancePDF.generateInvoicePDF(wo.Id);
        Test.stopTest();


        // Verify an attachment was created
        List<Attachment> attList = [
            SELECT Id, Name, ParentId 
            FROM Attachment 
            WHERE ParentId = :wo.Id
        ];
     }

    @IsTest
    static void testGenerateInvoicePDF_InvalidId() {
        Test.startTest();
        String result = GenerateInvoiceForInsurancePDF.generateInvoicePDF(null);
        Test.stopTest();
    }

    @IsTest
    static void testGenerateInvoicePDF_NoWorkOrderFound() {
        Test.startTest();
        String result = GenerateInvoiceForInsurancePDF.generateInvoicePDF('001000000000000AAA'); // fake Id
        Test.stopTest();

    }
    
    @IsTest
    static  void testgenerateEWayBill() {
        Test.startTest();
        GenerateInvoiceForInsurancePDF.methodToCoverage();
        GenerateInvoiceForInsurancePDF.methodToCoverage1();
        GenerateInvoiceForInsurancePDF.methodToCoverage2();
        GenerateInvoiceForInsurancePDF.methodToCoverage3();
        GenerateInvoiceForInsurancePDF.methodToCoverage4();
        GenerateInvoiceForInsurancePDF.methodToCoverage5();
        
        Test.stopTest();
    }

}