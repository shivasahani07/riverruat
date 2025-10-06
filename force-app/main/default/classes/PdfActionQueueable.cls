public class PdfActionQueueable implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public Set<Id> orderPaymentIds;

    public PdfActionQueueable(Id orderPaymentId) {
        this.orderPaymentIds = new Set<Id>{orderPaymentId};
    }

    public PdfActionQueueable(Set<Id> orderPaymentIds) {
        this.orderPaymentIds = orderPaymentIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Payments__r.Payment_Status__c, Order__r.Id, Payment_Acknowledgement_Generated__c
            FROM Order_Payment__c
            WHERE Id IN :orderPaymentIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Order_Payment__c> lstOrderPayments = (List<Order_Payment__c>)scope;
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        List<Order_Payment__c> orderPaymentToUpdate = new List<Order_Payment__c>();

        try {
            for (Order_Payment__c obj : lstOrderPayments) {
                if (obj.Payments__r.Payment_Status__c == 'Success' && obj.Payment_Acknowledgement_Generated__c != true) {
                    PageReference pdfPage1 = Page.CreateReceiptPayments;
                    pdfPage1.getParameters().put('id', obj.Id);

                    Blob pdfBlob1 = Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage1.getContentAsPDF();

                    Attachment att1 = new Attachment();
                    att1.Name = 'Payment Acknowledgement.pdf';
                    att1.Body = pdfBlob1;
                    att1.ParentId = obj.Id;
                    att1.ContentType = 'application/pdf';

                    attachmentsToInsert.add(att1);

                    obj.Payment_Acknowledgement_Generated__c = true;
                    orderPaymentToUpdate.add(obj);
                }
            }

            if (!attachmentsToInsert.isEmpty()) {
                insert attachmentsToInsert;
                SendEmailHandller.sendPreAttchamnets(lstOrderPayments[0].Id, attachmentsToInsert);
            }

            if (!orderPaymentToUpdate.isEmpty()) {
                update orderPaymentToUpdate;
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        
    }
}