public with sharing class BatchRecordControllerPDF {
    public Create_Batch__c batchRecord { get; set; }
    public DeliveryChallanPDF__mdt dcPdf { get; set; }
    public Bill_To_Addresse__mdt bOAPdf { get; set; }
    public Id batchId { get; set; }
    public String batchCreatedDate { get; set; }
    public String accountAddress { get; set; }
    public String nameAddress1 { get; set; }
    public String nameAddress2 { get; set; }
    public String nameAddress3 { get; set; }
    public String nameAddress4 { get; set; }
    public List<ClaimItem> claimItems { get; set; }
    public List<WorkOrderLineItem> parts { get; set; }
    public Decimal totalAmount { get; set; }
    public String amountInWords { get; set; }
    
    public BatchRecordControllerPDF(ApexPages.StandardController controller) {
        this.batchId = controller.getId();
        System.debug('Batch ID ==> ' + batchId);
        fetchDCCustomMetaDetails();
        batchRecordData();
        fetchPartsData();
    }
    
    public void fetchDCCustomMetaDetails() {
        try {
            dcPdf = [SELECT Id, CIN__c, Company_Email__c, Company_Phone__c, Company_Website__c, CompanyName__c, Factory_Address__c, Former_Address__c, GST__c, Registered_Office__c, Bill_From__c, Bill_To__c, PartA__c, Small_CName__c  FROM DeliveryChallanPDF__mdt] ;
            System.debug('dcPdf ==>' + dcPdf);
        } catch (Exception e) {
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    
    public void batchRecordData(){
        try{
            batchRecord = [SELECT Id, Name,Address_of_Consignee__c,Contact__r.Account.Name, Contact__r.Account.BillingStreet, Contact__r.Account.BillingCity,Contact__r.Account.BillingCountry, Contact__r.Account.BillingPostalCode, CreatedDate , Name_and_Adress_of_Consignee__c, Mode_of_Transport__c, E_Way_Bill_No__c, Transport_Name__c, Transporter_ID__c, Contact__r.Location__r.Name, Contact__r.Name, Terms_of_Delivery__c, River_GST__c,  Requestor_Name__c, Vehicle_No__c, Handover_Person_Store__c, Phone__c, Purpose__c, State_Code__c, Purpose_of_Sending__c FROM Create_Batch__c WHERE Id = :batchId LIMIT 1];
            System.debug('nameAddress ==>' +batchRecord.Contact__r.Location__r.Name);
            System.debug('Name_and_Adress_of_Consignee__c ==>' +batchRecord.Name_and_Adress_of_Consignee__c);
            
            if (batchRecord.Contact__r.Location__r.Name != null) {
                accountAddress = batchRecord.Contact__r.Account.Name;
                nameAddress1 = batchRecord.Contact__r.Account.BillingStreet; 
                nameAddress2 = batchRecord.Contact__r.Account.BillingCity;
                nameAddress3 = batchRecord.Contact__r.Account.BillingCountry;
                nameAddress4 = batchRecord.Contact__r.Account.BillingPostalCode;
            }
            batchCreatedDate = DateUtils.formatDateInMMDDYYYY(batchRecord.CreatedDate.date());
            System.debug('batchCreatedDate ==>' +batchCreatedDate);
        }
        catch (Exception e) {
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    public void fetchPartsData() {
        try {
            claimItems = [  SELECT Id, ClaimId, Part__r.LineItemNumber, Part__r.Part_Description__c, Part__r.RR_Product__r.HSN_Code__c, Part__r.Unit_of_Measurement__c, Part__r.ListPrice, Part__r.Quantity, Part__r.PricebookEntry.Name,   Part__r.Grand_Total__c, Part__r.NDP__c, Part__r.Total_NDP__c, Part__r.RR_Product__r.ProductCode FROM ClaimItem   WHERE Claim.Create_Batch__c = :batchId ];
            System.debug('Claim Items ==> ' + claimItems);
            parts = new List<WorkOrderLineItem>();
            totalAmount = 0;
            for (ClaimItem item : claimItems) {
                if (item.Part__r != null) {
                    WorkOrderLineItem part = new WorkOrderLineItem(
                        item.Part__r.LineItemNumber,
                        item.Part__r.RR_Product__r.ProductCode,
                        //item.Part__r.Description,
                        item.Part__r.Part_Description__c,
                        item.Part__r.RR_Product__r.HSN_Code__c,
                        item.Part__r.Unit_of_Measurement__c,
                        //item.Part__r.UnitPrice,
                        item.Part__r.ListPrice,
                        item.Part__r.Quantity,
                        item.Part__r.PricebookEntry.Name,
                        item.Part__r.Grand_Total__c,
                        item.Part__r.NDP__c,
                        item.Part__r.Total_NDP__c
                    );
                    totalAmount += part.TotalAmount;
                    parts.add(part);
                    System.debug('Claim Items ==> ' + claimItems);   
                }
            }
            amountInWords = ConvertAmountToWords.numberToEnglish(totalAmount) + + ' Rupees Only';
            System.debug('Total Amount in Words ==> ' + amountInWords);
            System.debug('parts === >'+parts);
        } catch (Exception e) {
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    public class WorkOrderLineItem {
        public String LineItemNumber { get; set; }
        public String ProductCode { get; set; }
        public String Part_Description { get; set; }
        public String HSN_Code { get; set; }
        public String Unit_of_Measurement { get; set; }
        public Decimal ListPrice { get; set; }
        public Decimal Quantity { get; set; }
        public Decimal TotalAmount { get; set; }
        public String PricebookEntryId { get; set; }
        public Decimal Grand_Total { get; set; }
        public Decimal NDP { get; set; }
        public Decimal Total_NDP { get; set; }
        
        public WorkOrderLineItem(String lineItemNumber,String productCode , String description, String hsnCode, String uom, Decimal listPrice, Decimal quantity, String pricebookEntryId, Decimal claimAmount, Decimal ndp, Decimal totalNdp) {
            this.LineItemNumber = lineItemNumber;
            this.ProductCode = productCode;
            this.Part_Description = description;
            this.HSN_Code = hsnCode;
            this.Unit_of_Measurement = uom;
            //this.UnitPrice = unitPrice;
            this.ListPrice = listPrice;
            this.Quantity = quantity;
            //this.TotalAmount = unitPrice * quantity;
            //this.TotalAmount = (listPrice * quantity).setScale(2, RoundingMode.HALF_UP);
            this.TotalAmount = (totalNdp).setScale(2, RoundingMode.HALF_UP);
            this.PricebookEntryId = pricebookEntryId;
            this.Grand_Total = claimAmount;
            this.NDP = ndp;
            this.Total_NDP = totalNdp;
        }
    }
    
    @AuraEnabled
    public static String saveBatchAsPdf(Id batchId, Boolean bypassTestCheck) {
        try {
            PageReference pdfPage = Page.BatchDetailPDF; 
            pdfPage.getParameters().put('id', batchId);
            
            String pdfTitle = 'Batch' + batchId;
            Blob pdfContent;
            
            if (Test.isRunningTest() && !bypassTestCheck) {
                pdfContent = Blob.valueOf('Test PDF');
            } else {
                pdfContent = pdfPage.getContentAsPDF();
            }
            
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.VersionData = pdfContent;
            contentVersion.Title = pdfTitle;
            contentVersion.PathOnClient = 'Batch' + batchId + '.pdf';
            insert contentVersion;
            
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = [ SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1 ].ContentDocumentId;
            contentDocumentLink.LinkedEntityId = batchId;
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;
            
            return 'PDF saved successfully as a related file.';
        } catch (Exception e) {
            System.debug('Error Message : ' + e.getMessage() + ' && Error Line == >' + e.getLineNumber()); 
        }
        return null;
    }
    
    @AuraEnabled
    public static String saveGenerateReciptAsPdf(Id batchId, Boolean bypassTestCheck) {
        try {
            PageReference pdfPage = Page.GenerateReciptBatchPDF; 
            pdfPage.getParameters().put('id', batchId);
            
            String pdfTitle = 'Batch Recipt';
            Blob pdfContent;
            
            if (Test.isRunningTest() && !bypassTestCheck) {
                pdfContent = Blob.valueOf('Test PDF');
            } else {
                pdfContent = pdfPage.getContentAsPDF();
            }
            
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.VersionData = pdfContent;
            contentVersion.Title = pdfTitle;
            contentVersion.PathOnClient = 'Batch' + batchId + '.pdf';
            insert contentVersion;
            
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = [ SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1].ContentDocumentId;
            contentDocumentLink.LinkedEntityId = batchId;
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;
            
            return 'PDF saved successfully as a related file.';
        } catch (Exception e) {
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        return null;
    }
    
}