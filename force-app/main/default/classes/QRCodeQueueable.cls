public class QRCodeQueueable implements Queueable, Database.AllowsCallouts {
    private String data;
    private String recordId;
    private String productType;

    public QRCodeQueueable(String data, String recordId, String productType) {
        this.data = data;
        this.recordId = recordId;
        this.productType = productType;
    }

    public void execute(QueueableContext context) {
        try {
            Integer xsize = 170;
            Integer ysize = 170;
            String qrApiUrl = System.Label.QRCodeBaseURL + EncodingUtil.urlEncode(data, 'UTF-8') + '&size=' + ysize + 'x' + xsize + '&format=png';

            Order ord = [SELECT Id, OrderNumber FROM Order WHERE Id = :recordId LIMIT 1];
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(qrApiUrl);
            request.setMethod('GET');

            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                Blob qrCodeBlob = response.getBodyAsBlob();
                Attachment attachment = new Attachment();
                attachment.ParentId = recordId;
                attachment.Name = productType + '_QRCode_' + ord.OrderNumber + '_' + System.now().format('h:mm a') + '.png';
                attachment.Body = qrCodeBlob;
                attachment.ContentType = 'image/png';
                insert attachment;
            }
        } catch (Exception e) {
            ExceptionHelper.createExceptionLog(e);
        }
    }
}