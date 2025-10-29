public class sendPDFForOTCOrder {
    public static void sendPdf(List<Order> newList, Map<Id, Order> oldMap){
        Id oTCRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('OTC').getRecordTypeId();
        System.debug('oTCRecordTypeId==>'+oTCRecordTypeId);
        try{
        Set<Id> ordersToProcess = new Set<Id>();
        for (Order ord : newList) {
            Order oldOrd = oldMap.get(ord.Id);

            if (ord.RecordTypeId == oTCRecordTypeId && ord.Status == 'Invoice Generation' && oldOrd.Status != 'Invoice Generation') {
                ordersToProcess.add(ord.Id);
            }
        }
            System.debug('ordersToProcess==>'+ordersToProcess);

        if (ordersToProcess.isEmpty()) return;

        List<Order_Payment__c> orderPayments = [
            SELECT Id, Order__c
            FROM Order_Payment__c
            WHERE Order__c IN :ordersToProcess
        ];

        System.debug('orderPayments==>'+orderPayments);
            
        if (orderPayments.isEmpty()) return;

        
        List<Attachment> attachments = [
            SELECT Id, Name, Body, ParentId
            FROM Attachment
            WHERE ParentId IN :orderPayments
        ];
        
            System.debug('attachments==>'+attachments);
        
        Map<Id, List<Attachment>> attachmentsByPayment = new Map<Id, List<Attachment>>();
        for (Attachment att : attachments) {
            if (!attachmentsByPayment.containsKey(att.ParentId)) {
                attachmentsByPayment.put(att.ParentId, new List<Attachment>());
            }
            attachmentsByPayment.get(att.ParentId).add(att);
        }

        
        for (Order_Payment__c op : orderPayments) {
            List<Attachment> relatedAtt = attachmentsByPayment.get(op.Id);
            if (relatedAtt != null && !relatedAtt.isEmpty()) {
                SendEmailHandller.sendPreAttchamnetsForOTC(op.Id, relatedAtt);
            }
        }
        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is==>'+e.getLineNumber());
        }
    }

}