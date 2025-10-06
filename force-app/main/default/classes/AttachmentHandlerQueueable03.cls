public class AttachmentHandlerQueueable03 implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public Set<Id> orderIds;

    public AttachmentHandlerQueueable03(String orderIdsStr) {
        this.orderIds = new Set<Id>();
        if (String.isNotBlank(orderIdsStr)) {
            for (String s : orderIdsStr.split(',')) {
                this.orderIds.add(Id.valueOf(s));
            }
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, AccountId, Booking_Payment_Id__c, Website_Order_Id__c, OrderNumber
            FROM Order
            WHERE Id IN :orderIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Order> orders = (List<Order>)scope;
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        Map<Id, List<Attachment>> mapOrderIdToAttachments = new Map<Id, List<Attachment>>();

        for (Order order : orders) {
            List<Attachment> attachmentList = new List<Attachment>();
            String str = order.Website_Order_Id__c != null && order.Website_Order_Id__c != '' ? String.valueOf(order.Website_Order_Id__c) : order.OrderNumber;
            String result = str.substring(Math.max(0, str.length() - 4));

            PageReference pdfPage1 = Page.PreOrderReceipt;
            pdfPage1.getParameters().put('id', order.Id);

            Blob pdfBlob1 = Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage1.getContentAsPDF();

            Attachment att1 = new Attachment();
            att1.Name = 'Pre Order Receipt-' + result + '.pdf';
            att1.Body = pdfBlob1;
            att1.ParentId = order.Id;
            att1.ContentType = 'application/pdf';

            attachmentsToInsert.add(att1);
            attachmentList.add(att1);
            mapOrderIdToAttachments.put(order.Id, attachmentList);
        }

        if (!attachmentsToInsert.isEmpty()) { 
            insert attachmentsToInsert;
        }

        SendEmailHandller.SendEmailHandller2(orders, attachmentsToInsert);
    }

    public void finish(Database.BatchableContext bc) {
        
    }
}