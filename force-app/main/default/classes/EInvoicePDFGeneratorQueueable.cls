public class EInvoicePDFGeneratorQueueable implements Queueable, Database.AllowsCallouts {
    private String recordId;

    public EInvoicePDFGeneratorQueueable(String recordId) {
        this.recordId = recordId;
    }

    public void execute(QueueableContext context) {
        try {
            if (recordId == null) return;

            Order ord = [
                SELECT Id, OrderNumber, Is_QR_Generated__c, IRN_No__c, RecordType.DeveloperName
                FROM Order 
                WHERE Id = :recordId 
                LIMIT 1
                FOR UPDATE
            ];
            System.debug('Fetched Order => ' + ord);

            Boolean hasVehicle = false;
            Set<String> productTypes = new Set<String>();

            for (OrderItem oi : [
                SELECT Type__c FROM OrderItem WHERE OrderId = :ord.Id AND Type__c != null
            ]) {
                productTypes.add(oi.Type__c);
                System.debug('Detected Product Type => ' + oi.Type__c);
                if (oi.Type__c == 'Vehicle') {
                    hasVehicle = true;
                }
            }

            // Generate main vehicle invoice PDF
            if (hasVehicle) {
                System.debug('Generating Vehicle (Main) E-Invoice PDF...');
                PageReference vfPagepdf = Page.NewE_invoicePDF;
                vfPagepdf.getParameters().put('id', recordId);
                Blob pdfBlob = vfPagepdf.getContentAsPDF();

                Attachment attachment = new Attachment();
                attachment.ParentId = recordId;
                attachment.Name = 'E-Invoice-' + ord.OrderNumber + '-' + Date.today().format() + ' ' + System.now().format('h:mm a') + '.pdf';
                attachment.Body = pdfBlob;
                attachment.ContentType = 'application/pdf';
                insert attachment;
                System.debug('Inserted Main E-Invoice Attachment: ' + attachment.Id);

                ord.Is_E_invoice_Generated__c = true;
                update ord;
            }

            System.debug('Generating additional product PDFs...');
            List<Attachment> productAttachments = new List<Attachment>();
            Boolean isOTC = (ord.RecordType.DeveloperName == 'OTC');

            for (String productType : productTypes) {
                PageReference pdfPage;

                if (productType == 'Accessories' || productType == 'Parts') {
                    pdfPage = Page.NewAccessoriesInvoiceE_Invoice;
                } else if (productType == 'Merchandise') {
                    pdfPage = Page.NewMerchandiseE_Invoice;
                } else {
                    System.debug('Skipping unsupported product type: ' + productType);
                    continue;
                }

                pdfPage.getParameters().put('id', ord.Id);
                Blob otherBlob = pdfPage.getContentAsPDF();

                String namePrefix = isOTC ? 'OTC ' : '';

                Attachment productAttachment = new Attachment();
                productAttachment.ParentId = ord.Id;
                productAttachment.Name = namePrefix + productType + ' E-Invoice ' + ord.OrderNumber + '-' + Date.today().format() + ' ' + System.now().format('h:mm a') + '.pdf';
                productAttachment.Body = otherBlob;
                productAttachment.ContentType = 'application/pdf';
                productAttachments.add(productAttachment);

                System.debug('Prepared Attachment for ' + productType);
            }

            if (!productAttachments.isEmpty()) {
                insert productAttachments;
                System.debug('Inserted Product Attachments count: ' + productAttachments.size());
            }
        } catch (Exception e) {
            ExceptionHelper.createExceptionLog(e);
            System.debug('Error in EInvoicePDFGeneratorQueueable: ' + e.getMessage());
        }
    }
}