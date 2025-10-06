public without sharing class ProformaInvoiceController {


    @AuraEnabled(cacheable=true)
    public static String getOrderStatus(Id recordId) {
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('recordId not found');
            }

            Order ord = [
                SELECT Status 
                FROM Order 
                WHERE Id = :recordId 
                LIMIT 1
            ];

            return ord.Status;

        } catch (Exception e) {
            System.debug('Error in getOrderStatus: ' + e.getMessage());
            return null;
        }
    }


    
    @AuraEnabled
    public static String generateProforma(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is required');
        }

        try {

            List<Order>OrdList = [SELECT Id, OrderNumber FROM Order Where Id =:recordId];
            PageReference vf = Page.NewProformaInvoice;
            vf.getParameters().put('id', String.valueOf(recordId));

            Blob pdfBlob = vf.getContentAsPDF();

            Attachment att = new Attachment();
            att.ParentId = recordId;
            att.Name = 'Proforma Invoice - ' + OrdList[0].OrderNumber + ' ' + System.now() + '.pdf';
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