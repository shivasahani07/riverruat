public class GatePassPDFQueueableDelayed implements Queueable, Database.AllowsCallouts {
    private Id orderId;
    private Id qrAttachmentId;

    public GatePassPDFQueueableDelayed(Id orderId, Id qrAttachmentId) {
        this.orderId = orderId;
        this.qrAttachmentId = qrAttachmentId;
    }
    
    public void execute(QueueableContext context) {
        try {
            PageReference pdfPage = Page.gatPassPDF;
            pdfPage.getParameters().put('id', orderId);
            pdfPage.getParameters().put('qrAttachmentId', qrAttachmentId);

            Blob pdfBlob = pdfPage.getContentAsPDF();

            Attachment pdfAttachment = new Attachment(
                Name = 'Gate_Pass_' + System.now().format('yyyyMMdd_HHmmss') + '.pdf',
                Body = pdfBlob,
                ContentType = 'application/pdf',
                ParentId = orderId
            );
            insert pdfAttachment;

            if (qrAttachmentId != null) {
                System.debug('QR Attachment ID: ' + qrAttachmentId);
                System.debug('Order ID: ' + orderId);
                
                List<Attachment> listOfAtt =  [ SELECT Id, Body, Name,ParentId FROM Attachment WHERE ParentId =: orderId AND Name LIKE '%Temp_QRCode%' LIMIT 1];
                System.debug('QR Attachment ID =====>' + listOfAtt);
                delete listOfAtt;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception in GatePassPDFQueueableDelayed: ' + e.getMessage());
        }
    }
}