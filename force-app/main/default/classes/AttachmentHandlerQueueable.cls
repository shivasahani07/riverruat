public class AttachmentHandlerQueueable implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public Set<Id> orderIds;
    public Map<Id, Set<String>> orderToItemTypeMap;

    public AttachmentHandlerQueueable(Set<Id> orderIds, String mapString) {
        this.orderIds = orderIds;
        System.debug('orderIds>>' + orderIds);
        System.debug('mapString>>' + mapString);
        if (String.isNotBlank(mapString)) {
            this.orderToItemTypeMap = (Map<Id, Set<String>>) JSON.deserialize(mapString, Map<Id, Set<String>>.class);
        } else {
            this.orderToItemTypeMap = new Map<Id, Set<String>>();
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, AccountId, Dealer__c, Website_Order_Id__c,
                   Handling_Charges__c, Warranty_Amount__c, RTO_Charges__c, Insurance_Amount__c,
                   OrderNumber, Is_DC_Generated__c, Is_Vehicle_Invoice_Generated__c,
                   Is_RTO_and_IR_Generated__c, IS_OCT_Generated__c, IsAccessories_Generated__c,
                   IsMerchandise_Generated__c
            FROM Order
            WHERE Id IN :orderIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Order> orders = (List<Order>)scope;

        Map<Id, List<Attachment>> mapOrderIdToAttachments = new Map<Id, List<Attachment>>();
        Map<Id, Map<String, String>> orderIdToInvTypeToInvNoMap = new Map<Id, Map<String, String>>();
        Map<Id, Map<String, String>> orderIdToInvTypeToInvDateMap = new Map<Id, Map<String, String>>();
        List<Attachment> attachmentsToInsert = new List<Attachment>();

        Set<Id> scopeIds = new Set<Id>();
        for (Order o : orders) scopeIds.add(o.Id);

        // Map invoice numbers and dates
        for (Order_Invoice__c orderInvoice : [
            SELECT Id, Invoice_Number__c, Invoice_Type__c, Order__c, Invoice_date__c
            FROM Order_Invoice__c
            WHERE Order__c IN :scopeIds
        ]) {
            if (!orderIdToInvTypeToInvNoMap.containsKey(orderInvoice.Order__c)) {
                orderIdToInvTypeToInvNoMap.put(orderInvoice.Order__c, new Map<String,String>{ orderInvoice.Invoice_Type__c => orderInvoice.Invoice_Number__c });
                orderIdToInvTypeToInvDateMap.put(orderInvoice.Order__c, new Map<String,String>{ orderInvoice.Invoice_Type__c => orderInvoice.Invoice_date__c != null ? orderInvoice.Invoice_date__c.format() : System.today().format() });
            } else {
                orderIdToInvTypeToInvNoMap.get(orderInvoice.Order__c).put(orderInvoice.Invoice_Type__c, orderInvoice.Invoice_Number__c);
                orderIdToInvTypeToInvDateMap.get(orderInvoice.Order__c).put(orderInvoice.Invoice_Type__c, orderInvoice.Invoice_date__c != null ? orderInvoice.Invoice_date__c.format() : System.today().format());
            }
        }

        // Process each order
        for (Order order : orders) {
            List<Attachment> attachmentList = new List<Attachment>();
            Set<String> itemTypes = orderToItemTypeMap.get(order.Id);
            if (itemTypes == null) {
                itemTypes = new Set<String>();
            }

            String str = (order.Website_Order_Id__c != null && order.Website_Order_Id__c != '') ? String.valueOf(order.Website_Order_Id__c) : order.OrderNumber;
            String result = str.substring(Math.max(0, str.length() - 4));

            // Vehicle Attachments
            if (itemTypes.contains('Vehicle')) {
                if (orderIdToInvTypeToInvNoMap.get(order.Id) != null && orderIdToInvTypeToInvNoMap.get(order.Id).containsKey('Vehicle Invoice')) {
                    PageReference pdfPage = Page.NewCreateReceiptVehicle;
                    Attachment attVehicle = createInvoicePDF(order.Id, orderIdToInvTypeToInvNoMap.get(order.Id).get('Vehicle Invoice'),
                        'Vehicle Tax Invoice - ' + result, pdfPage, orderIdToInvTypeToInvDateMap.get(order.Id).get('Vehicle Invoice'));
                    attachmentsToInsert.add(attVehicle);
                    attachmentList.add(attVehicle);
                    order.Is_Vehicle_Invoice_Generated__c = true;
                } else {
                    throw new MyException('Vehicle Invoice record is not found for the order: ' + order.OrderNumber);
                }

                if (!order.Is_DC_Generated__c) {
                    PageReference pdfDC = Page.CreateDeliveryChallan;
                    Attachment attDC = createReceiptPDF(order.Id, 'Delivery Challan - ' + result, pdfDC);
                    attachmentsToInsert.add(attDC);
                    attachmentList.add(attDC);
                    order.Is_DC_Generated__c = true;
                }

                if (order.RTO_Charges__c != null || order.Insurance_Amount__c != null) {
                    PageReference pdfRtoIns = Page.NewCreateReceiptRtoInsurance;
                    Attachment attRtoIns = createReceiptPDF(order.Id, 'RTO & Insurance Receipt - ' + result, pdfRtoIns);
                    attachmentsToInsert.add(attRtoIns);
                    attachmentList.add(attRtoIns);
                    order.Is_RTO_and_IR_Generated__c = true;
                }

                if ((order.Handling_Charges__c != null) || (order.Warranty_Amount__c != null)) {
                    if (orderIdToInvTypeToInvNoMap.get(order.Id).containsKey('Other Charges Invoice')) {
                        PageReference pdfOtherCharges = Page.NewCreateReceiptOtherCharges;
                        Attachment attOtherCharges = createInvoicePDF(order.Id,
                            orderIdToInvTypeToInvNoMap.get(order.Id).get('Other Charges Invoice'),
                            'Other Charges Tax Invoice - ' + result, pdfOtherCharges, orderIdToInvTypeToInvDateMap.get(order.Id).get('Other Charges Invoice'));
                        attachmentsToInsert.add(attOtherCharges);
                        attachmentList.add(attOtherCharges);
                        order.IS_OCT_Generated__c = true;
                    }
                }

                // Extra Files from Metadata
                List<River_Files_To_Customer__mdt> filesMetadata = [SELECT File_Name__c FROM River_Files_To_Customer__mdt WHERE Active__c = true];
                List<String> fileNamesToSend = new List<String>();
                for (River_Files_To_Customer__mdt file : filesMetadata) fileNamesToSend.add(file.File_Name__c);

                for (ContentVersion resource : [SELECT VersionData, ContentDocument.FileType, ContentDocument.Title, FileExtension 
                                                FROM ContentVersion WHERE ContentDocument.Title IN :fileNamesToSend]) {
                    Attachment extraAtt = new Attachment();
                    extraAtt.Name = resource.ContentDocument.Title + '.' + resource.FileExtension;
                    extraAtt.Body = resource.VersionData;
                    extraAtt.ContentType = resource.ContentDocument.FileType;
                    extraAtt.ParentId = order.Id;
                    attachmentList.add(extraAtt);
                    attachmentsToInsert.add(extraAtt);
                }
            }

            // Accessories / Parts / Merchandise
            if (itemTypes.contains('Accessories') || itemTypes.contains('Parts') || itemTypes.contains('Merchandise')) {
                if (orderIdToInvTypeToInvNoMap.get(order.Id) != null && orderIdToInvTypeToInvNoMap.get(order.Id).containsKey('Accessories Invoice')) {
                    PageReference pdfAccessories = Page.NewAccessoriesInvoicePDF;
                    Attachment attAccessories = createInvoicePDF(order.Id, orderIdToInvTypeToInvNoMap.get(order.Id).get('Accessories Invoice'),
                        'Accessories Tax Invoice - ' + result, pdfAccessories, orderIdToInvTypeToInvDateMap.get(order.Id).get('Accessories Invoice'));
                    attachmentsToInsert.add(attAccessories);
                    attachmentList.add(attAccessories);
                    order.IsAccessories_Generated__c = true;
                }
                if (orderIdToInvTypeToInvNoMap.get(order.Id) != null && orderIdToInvTypeToInvNoMap.get(order.Id).containsKey('Merchandise Invoice')) {
                    PageReference pdfMerchandise = Page.NewMerchandiseInvoicePDF;
                    Attachment attMerchandise = createInvoicePDF(order.Id, orderIdToInvTypeToInvNoMap.get(order.Id).get('Merchandise Invoice'),
                        'Merchandise Tax Invoice - ' + result, pdfMerchandise, orderIdToInvTypeToInvDateMap.get(order.Id).get('Merchandise Invoice'));
                    attachmentsToInsert.add(attMerchandise);
                    attachmentList.add(attMerchandise);
                    order.IsMerchandise_Generated__c = true;
                }
            }

            mapOrderIdToAttachments.put(order.Id, attachmentList);
        }

        if (!orders.isEmpty()) update orders;
        if (!attachmentsToInsert.isEmpty()) insert attachmentsToInsert;

        SendEmailHandller.SendEmailHandller(orders, mapOrderIdToAttachments);
    }

    public void finish(Database.BatchableContext bc) {
        
    }

    public static Attachment createInvoicePDF(Id orderId, String invoiceSequence, String fileName, PageReference pdfPage, String invoiceDate) {
        pdfPage.getParameters().put('id', orderId);
        pdfPage.getParameters().put('sequence', invoiceSequence);
        pdfPage.getParameters().put('date', invoiceDate);
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage.getContentAsPDF();
        Attachment attachment = new Attachment();
        attachment.Name = fileName + '.pdf';
        attachment.Body = pdfBlob;
        attachment.ParentId = orderId;
        attachment.ContentType = 'application/pdf';
        return attachment;
    }

    public static Attachment createReceiptPDF(Id orderId, String fileName, PageReference pdfPage) {
        pdfPage.getParameters().put('id', orderId);
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage.getContentAsPDF();
        Attachment attachment = new Attachment();
        attachment.Name = fileName + '.pdf';
        attachment.Body = pdfBlob;
        attachment.ParentId = orderId;
        attachment.ContentType = 'application/pdf';
        return attachment;
    }

    public class MyException extends Exception {}
}