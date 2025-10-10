@isTest
public class BatchRecordControllerPDFTest  {
    
    @isTest
    static void testfetchDCCustomMetaDetails() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Create_Batch__c batch = new Create_Batch__c(
            Status__c = 'New', 
            Is_GRN_Received__c = false, 
            Batch_Dispatch_Date__c = Date.today(), 
            E_Way_Bill_No__c = 'E-QAY-00029',
            Vehicle_No__c = 'KA-0001', 
            Transporter_ID__c = 'TR-001', 
            Transport_Name__c = 'defg',  
            LR_Attachment__c ='https://river.com', 
            LR_Number__c = 'defsgb',
            Mode_of_Transport__c = 'Road'
        );
        insert batch;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            State__c = 'Karnataka',
            IsActive = true
        );
        update standardPricebook;
        
        Product2 product1 = new Product2(Name = 'Test Product 1', IsActive = true, ProductCode = 'SDFGH3456', HSN_Code__c = 'FGHJK367', Type__c = 'Parts');
        insert product1;
        
        PricebookEntry pricebookEntry1 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product1.Id, UnitPrice = 100, IsActive = true);
        insert pricebookEntry1;
        
        WorkOrder workOrder = new WorkOrder(AccountId = acc.Id, Status = 'New', Subject = 'Test Work Order');
        insert workOrder;
        
        WorkOrderLineItem workOrderLineItem1 = new WorkOrderLineItem(
            WorkOrderId = workOrder.Id,  
            Quantity = 2, 
            UnitPrice = 120,  
            PricebookEntryId = pricebookEntry1.Id 
        );
        insert workOrderLineItem1;
        
        OrgWideEmailAddress owea = [SELECT Id, DisplayName 
                                        FROM OrgWideEmailAddress 
                                        WHERE DisplayName = :System.Label.OrgWideEmail 
                                        LIMIT 1];
        
       
        DeliveryChallanPDF__mdt d = new DeliveryChallanPDF__mdt();
        d.Bill_From__c='987';
        d.Bill_To__c='0986';
        d.CIN__c='98';
        d.Company_Email__c='a@test.com';
        d.CompanyName__c='987';
        d.Company_Phone__c='0987654321';
        d.Company_Website__c='https://www.example.com';
        d.Factory_Address__c='987';
        d.Former_Address__c='097';
        d.GST__c='098';
        d.PartA__c='09';
        d.Registered_Office__c='098';
        d.Small_CName__c='098';
        Claim claim = new Claim(Name='Test Claim', Create_Batch__c=batch.Id, AccountId = acc.Id);
        insert claim;
        
        // Create test ClaimItem
        ClaimItem claimItem = new ClaimItem(Name='Test Claim Item', ClaimId=claim.Id, Claim_Type__c='Labour', Status__c='Approved', FaultDate= System.now(),Part__c =workOrderLineItem1.id  );
        insert claimItem;
        
        PageReference pageRef = Page.BatchDetailPDF; 
        Test.setCurrentPage(pageRef);        
        ApexPages.StandardController standardController = new ApexPages.StandardController(batch);
        BatchRecordControllerPDF controller = new BatchRecordControllerPDF(standardController);
        BatchRecordControllerPDF.saveBatchAsPdf(batch.id,false);
        BatchRecordControllerPDF.saveGenerateReciptAsPdf(batch.id,false);
        ConvertAmountToWords var = new ConvertAmountToWords();
        var.convert();
        ConvertAmountToWords.convert(10000);
    }
    
}