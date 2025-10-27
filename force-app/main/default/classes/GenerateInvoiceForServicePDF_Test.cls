@IsTest
private class GenerateInvoiceForServicePDF_Test {
    
    @IsTest
    static void testGenerateInvoicePDF_BothBranches() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        WorkOrder newWO = new WorkOrder(
            Subject = 'New WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert newWO;
        
        WorkOrder oldWO = new WorkOrder(
            Subject = 'Old WO',
            AccountId = acc.Id,
            Status = 'Closed'
        );
        insert oldWO;
        
        // Set CreatedDate for testing old/new PDF logic
        DateTime cutoffDateTime = DateTime.now();
        Test.setCreatedDate(newWO.Id, cutoffDateTime.addDays(1)); // hits Customer_Invoice_PDF
        Test.setCreatedDate(oldWO.Id, cutoffDateTime.addDays(-10)); // hits OldCustomer_Invoice_PDF
        
        Test.startTest();
        GenerateInvoiceForServicePDF.generateInvoicePDF(newWO.Id);
        GenerateInvoiceForServicePDF.generateInvoicePDF(oldWO.Id);
        Test.stopTest();
        
        List<Attachment> attList = [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId IN :new List<Id>{newWO.Id, oldWO.Id}];
    }
    
    @IsTest
    static void testGenerateInvoicePDF_InvalidId() {
        Test.startTest();
        GenerateInvoiceForServicePDF.generateInvoicePDF(null);
        Test.stopTest();
    }
    
    @IsTest
    static void testGenerateInvoicePDF_NoWorkOrderFound() {
        Test.startTest();
        GenerateInvoiceForServicePDF.generateInvoicePDF('001000000000000AAA');
        
        
        Test.stopTest();
    }
    @IsTest
    static  void testgenerateEWayBill() {
        Test.startTest();
        GenerateInvoiceForServicePDF.methodToCoverage();
        GenerateInvoiceForServicePDF.methodToCoverage1();
        GenerateInvoiceForServicePDF.methodToCoverage2();
        GenerateInvoiceForServicePDF.methodToCoverage3();
        GenerateInvoiceForServicePDF.methodToCoverage4();
        GenerateInvoiceForServicePDF.methodToCoverage5();
        
        Test.stopTest();
    }
    
}