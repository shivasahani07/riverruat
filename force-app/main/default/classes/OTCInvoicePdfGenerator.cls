/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-16-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
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
    System.debug('invoiceAggList==>'+invoiceAggList);

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
                //ord.addError('Please create Order Invoice record to generate invoices.');
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
        System.debug('Processing Order IDs: ' + orderIds);
        
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        
        List<Order> orders = [
            SELECT Id, Dealer__c, OrderNumber FROM Order WHERE Id IN :orderIds
        ];
        System.debug('Fetched Orders: ' + orders);
        
        Map<Id, Account> accMap = new Map<Id, Account>([
            SELECT Id, Center_Code__c
            FROM Account
            WHERE Id IN :dealerIds
        ]);
        System.debug('Fetched Accounts: ' + accMap);
        
        Map<Id, Set<String>> orderIdToProductTypes = getProductTypesForOrders(orderIds);
        System.debug('Order ID to Product Types mapping: ' + orderIdToProductTypes);
        
        for (Order ord : orders) {
            try {
                System.debug('Processing Order: ' + ord.Id);
                if (ord.Dealer__c == null || !accMap.containsKey(ord.Dealer__c)) {
                    System.debug('Skipping order ' + ord.Id + ' due to missing or unmatched Dealer__c.');
                    continue;
                }
                
                Set<String> productTypes = orderIdToProductTypes.get(ord.Id);
                if (productTypes == null || productTypes.isEmpty()) {
                    System.debug('Skipping order ' + ord.Id + ' due to missing product types.');
                    continue;
                }
                
                for (String productType : productTypes) {
                    try {
                        String invoiceType = (productType == 'Accessories' || productType == 'Parts' ) ? 'Accessories Invoice' :
                        (productType == 'Merchandise') ? 'Merchandise Invoice' : '';
                        System.debug('Processing Product Type: ' + productType + ', Invoice Type: ' + invoiceType);
                        
                        if (String.isBlank(invoiceType)) {
                            System.debug('Skipping product type ' + productType + ' for order ' + ord.Id + ' due to missing invoice type.');
                            continue;
                        }
                        
                        List<Order_Invoice__c> orderInvoices = [
                            SELECT Id, Name, Invoice_Number__c, Invoice_Type__c 
                            FROM Order_Invoice__c 
                            WHERE Order__c = :ord.Id AND Invoice_Type__c = :invoiceType
                            ORDER BY CreatedDate DESC 
                            LIMIT 1
                        ];
                        System.debug('Fetched Order Invoices: ' + orderInvoices);
                        
                        String invoiceSequenceVH = '';
                        if (!orderInvoices.isEmpty()) {
                            invoiceSequenceVH = orderInvoices[0].Invoice_Number__c;
                            System.debug('Using Invoice Number from Order Invoice: ' + invoiceSequenceVH);
                        } else {
                            invoiceSequenceVH = 'RV_INVOICE_VH'; 
                            System.debug('No existing invoice found, using default: ' + invoiceSequenceVH);
                        }
                        
                        PageReference pdfPage = (productType == 'Accessories' || productType == 'Parts') ? Page.NewAccessoriesInvoicePDF
                            : (productType == 'Merchandise') ? Page.NewMerchandiseInvoicePDF
                                : null;
                        
                        if (pdfPage == null) {
                            System.debug('No VF page found for product type: ' + productType);
                            continue;
                        }
                        
                        pdfPage.getParameters().put('id', ord.Id);
                        pdfPage.getParameters().put('sequence', invoiceSequenceVH);
                        
                        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage.getContentAsPDF();
                        System.debug('Generated PDF Blob for Order: ' + ord.Id);
                        
                        String productLabel = (productType == 'Accessories' || productType == 'Parts') ? 'Accessories' : productType;
                        
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
                        System.debug('Prepared attachment for Order ' + ord.Id + ', Product: ' + productType);
                        
                    } catch (Exception eInner) {
                        System.debug('Exception while processing Order ' + ord.Id + ', Product: ' + productType + ': ' + eInner.getMessage());
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
            System.debug('Mapped Order ' + oi.OrderId + ' to product type: ' + oi.Type__c);
        }
        
        return orderIdToProductTypes;
    }
}