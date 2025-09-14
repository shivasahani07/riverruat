public without sharing class ProformaInvoiceController {
    
    @AuraEnabled
    public static String generateProforma(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is required');
        }

        try {
            PageReference vf = Page.NewProformaInvoice;
            vf.getParameters().put('id', String.valueOf(recordId));

            Blob pdfBlob = vf.getContentAsPDF();

            Attachment att = new Attachment();
            att.ParentId = recordId;
            att.Name = 'Proforma Invoice - ' + String.valueOf(recordId) + '.pdf';
            att.ContentType = 'application/pdf';
            att.Body = pdfBlob;
            insert att;
            System.debug('attachment Inserted Successfully==>'+att);
            return 'SUCCESS';
        } catch (Exception e) {
            System.debug('Error at ==>'+ e.getMessage());
            System.debug('Error at ==>'+ e.getLineNumber());
            throw new AuraHandledException('PDF generation failed: ' + e.getMessage());
        }
    }

}