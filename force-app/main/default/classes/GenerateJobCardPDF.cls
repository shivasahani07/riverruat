public class GenerateJobCardPDF implements Queueable {
    Set<Id> jobCardIds;

    public GenerateJobCardPDF(Set<Id> ids) {
        this.jobCardIds = ids;
    }

    public static void queue(Set<Id> ids) {
        System.enqueueJob(new GenerateJobCardPDF(ids));
    }

    public void execute(QueueableContext context) {
        for (Id jobCardId : jobCardIds) {
            PageReference pdfPage = Page.TFRPDFPage;
            pdfPage.getParameters().put('id', jobCardId);

            Blob pdfBlob = pdfPage.getContentAsPDF();

            ContentVersion cv = new ContentVersion(
                Title = 'JobCard_' + jobCardId,
                PathOnClient = 'JobCard_' + jobCardId + '.pdf',
                VersionData = pdfBlob
            );
            insert cv;
        }
    }
}