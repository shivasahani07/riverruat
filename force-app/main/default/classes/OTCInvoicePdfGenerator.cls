/**
 * @description       : 
 * @author            : Ram Kumar
 * @group             : 
 * @last modified on  : 07-16-2025
 * @last modified by  : Ram Kumar
**/
public class OTCInvoicePdfGenerator {
    public static final Id otcRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('OTC').getRecordTypeId();

    public static void handleOrderUpdate(List<Order> newList, Map<Id, Order> oldMap) {
        Datetime startTime = Datetime.now();
        System.debug('=====> [OTC] handleOrderUpdate START');

        Set<Id> recordTypeIds = new Set<Id>();
        Map<Id, Order> eligibleOrders = new Map<Id, Order>();
        Set<Id> dealerIds = new Set<Id>();

        for (Order ord : newList) {
            if (ord.Status == 'Invoice Generation' && oldMap.containsKey(ord.Id) && oldMap.get(ord.Id).Status != ord.Status) {
                recordTypeIds.add(ord.RecordTypeId);
                eligibleOrders.put(ord.Id, ord);
                if (ord.Dealer__c != null) {
                    dealerIds.add(ord.Dealer__c);
                }
                System.debug('Eligible order found: ' + ord.Id);
            }
        }

        if (recordTypeIds.isEmpty() || eligibleOrders.isEmpty()) {
            System.debug('No eligible orders or record types found. Exiting.');
            return;
        }

        Map<Id, RecordType> rtMap = new Map<Id, RecordType>([
            SELECT Id, Name FROM RecordType WHERE Id IN :recordTypeIds
        ]);

        List<Id> finalEligibleOrderIds = new List<Id>();
        for (Order ord : eligibleOrders.values()) {
            RecordType rt = rtMap.get(ord.RecordTypeId);
            if (rt != null && rt.Name == 'OTC') {
                finalEligibleOrderIds.add(ord.Id);
                System.debug('Order ' + ord.Id + ' is OTC and eligible for PDF generation.');
            }
        }

        if (finalEligibleOrderIds.isEmpty()) {
            System.debug('No OTC orders found for PDF generation.');
            return;
        }

        List<AggregateResult> invoiceAggList = [
            SELECT Order__c, COUNT(Id)
            FROM Order_Invoice__c
            WHERE Order__c IN :finalEligibleOrderIds
            GROUP BY Order__c
        ];
        System.debug('invoiceAggList==>' + invoiceAggList);

        Set<Id> ordersWithInvoice = new Set<Id>();
        for (AggregateResult ar : invoiceAggList) {
            ordersWithInvoice.add((Id) ar.get('Order__c'));
        }

        List<Id> missingInvoiceOrderIds = new List<Id>();
        for (Id orderId : finalEligibleOrderIds) {
            if (!ordersWithInvoice.contains(orderId)) {
                missingInvoiceOrderIds.add(orderId);
            }
        }

        if (!missingInvoiceOrderIds.isEmpty()) {
            String errorMsg = 'Please create Order Invoice record(s) for the following Order(s): ' + String.join(missingInvoiceOrderIds, ', ');
            System.debug('ERROR: ' + errorMsg);

            for (Order ord : newList) {
                if (missingInvoiceOrderIds.contains(ord.Id)) {
                     ord.addError('Please create Order Invoice record to generate invoices.');
                }
            }
            return;
        }

        System.debug('Calling generateInvoicePdfAsync with Order IDs: ' + finalEligibleOrderIds);
        generateInvoicePdfAsync(finalEligibleOrderIds, dealerIds);

        System.debug('=====> [OTC] handleOrderUpdate END. Duration: ' + (Datetime.now().getTime() - startTime.getTime()) + ' ms');
    }

    @future(callout=true)
    private static void generateInvoicePdfAsync(List<Id> orderIds, Set<Id> dealerIds) {
        System.debug('=====> [OTC] generateInvoicePdfAsync START');
        List<Attachment> attachmentsToInsert = new List<Attachment>();

        List<Order> orders = [
            SELECT Id, Dealer__c, OrderNumber FROM Order WHERE Id IN :orderIds
        ];

        Map<Id, Account> accMap = new Map<Id, Account>([
            SELECT Id, Center_Code__c FROM Account WHERE Id IN :dealerIds
        ]);

        Map<Id, Set<String>> orderIdToProductTypes = getProductTypesForOrders(orderIds);

        for (Order ord : orders) {
            try {
                if (ord.Dealer__c == null || !accMap.containsKey(ord.Dealer__c)) {
                    continue;
                }

                Set<String> productTypes = orderIdToProductTypes.get(ord.Id);
                if (productTypes == null || productTypes.isEmpty()) {
                    continue;
                }

                // Combine Parts and Accessories into one invoice
                Boolean hasPartsOrAccessories = productTypes.contains('Parts') || productTypes.contains('Accessories');
                if (hasPartsOrAccessories) {
                    try {
                        String invoiceType = 'Accessories Invoice';
                        String productLabel = 'Accessories';

                        List<Order_Invoice__c> orderInvoices = [
                            SELECT Id, Name, Invoice_Number__c, Invoice_Type__c
                            FROM Order_Invoice__c
                            WHERE Order__c = :ord.Id AND Invoice_Type__c = :invoiceType
                            ORDER BY CreatedDate DESC
                            LIMIT 1
                        ];

                        String invoiceSequenceVH = !orderInvoices.isEmpty() ? orderInvoices[0].Invoice_Number__c : 'RV_INVOICE_VH';

                        PageReference pdfPage = Page.NewAccessoriesInvoicePDF;
                        pdfPage.getParameters().put('id', ord.Id);
                        pdfPage.getParameters().put('sequence', invoiceSequenceVH);

                        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage.getContentAsPDF();

                        String attachmentName = 'OTC ' + productLabel + ' Invoice ' +
                            ord.OrderNumber + '-' + Date.today().format() + ' ' +
                            System.now().format('h:mm a') + '.pdf';

                        Attachment attach = new Attachment(
                            ParentId = ord.Id,
                            Name = attachmentName,
                            Body = pdfBlob,
                            ContentType = 'application/pdf'
                        );

                        attachmentsToInsert.add(attach);
                    } catch (Exception eInner) {
                        System.debug('Exception during Accessories/Parts invoice for Order ' + ord.Id + ': ' + eInner.getMessage());
                    }
                }

                // Handle Merchandise separately
                if (productTypes.contains('Merchandise')) {
                    try {
                        String invoiceType = 'Merchandise Invoice';

                        List<Order_Invoice__c> orderInvoices = [
                            SELECT Id, Name, Invoice_Number__c, Invoice_Type__c
                            FROM Order_Invoice__c
                            WHERE Order__c = :ord.Id AND Invoice_Type__c = :invoiceType
                            ORDER BY CreatedDate DESC
                            LIMIT 1
                        ];

                        String invoiceSequenceVH = !orderInvoices.isEmpty() ? orderInvoices[0].Invoice_Number__c : 'RV_INVOICE_VH';

                        PageReference pdfPage = Page.NewMerchandiseInvoicePDF;
                        pdfPage.getParameters().put('id', ord.Id);
                        pdfPage.getParameters().put('sequence', invoiceSequenceVH);

                        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage.getContentAsPDF();

                        String attachmentName = 'OTC Merchandise Invoice ' +
                            ord.OrderNumber + '-' + Date.today().format() + ' ' +
                            System.now().format('h:mm a') + '.pdf';

                        Attachment attach = new Attachment(
                            ParentId = ord.Id,
                            Name = attachmentName,
                            Body = pdfBlob,
                            ContentType = 'application/pdf'
                        );

                        attachmentsToInsert.add(attach);
                    } catch (Exception eInner) {
                        System.debug('Exception during Merchandise invoice for Order ' + ord.Id + ': ' + eInner.getMessage());
                    }
                }

            } catch (Exception e) {
                System.debug('Exception while processing Order ' + ord.Id + ': ' + e.getMessage());
            }
        }

        if (!attachmentsToInsert.isEmpty()) {
            insert attachmentsToInsert;
            System.debug('Inserted ' + attachmentsToInsert.size() + ' attachment(s).');
        } else {
            System.debug('No attachments were created for insertion.');
        }

        System.debug('=====> [OTC] generateInvoicePdfAsync END');
    }

    private static Map<Id, Set<String>> getProductTypesForOrders(List<Id> orderIds) {
        Map<Id, Set<String>> orderIdToProductTypes = new Map<Id, Set<String>>();

        List<OrderItem> orderItems = [
            SELECT OrderId, Type__c FROM OrderItem
            WHERE OrderId IN :orderIds AND Type__c != null
        ];

        for (OrderItem oi : orderItems) {
            if (!orderIdToProductTypes.containsKey(oi.OrderId)) {
                orderIdToProductTypes.put(oi.OrderId, new Set<String>());
            }
            orderIdToProductTypes.get(oi.OrderId).add(oi.Type__c);
        }

        return orderIdToProductTypes;
    }
}