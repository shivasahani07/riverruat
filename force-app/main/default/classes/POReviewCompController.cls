public class POReviewCompController {

    @AuraEnabled(cacheable=true)
    public static POResponseWrapper getPOLineItems(Id poId) {
        List<POReviewWrapper> wrapper = new List<POReviewWrapper>();

        List<ProductRequestLineItem> lineItems = [
            SELECT Id, Product2Id, Product2.Name, Forecast_Quantity__c, QuantityRequested, Approval_Status__c, Was_Previously_Deleted__c
            FROM ProductRequestLineItem
            WHERE ParentId = :poId AND Is_Deleted_Item__c = false
        ];

        for (ProductRequestLineItem line : lineItems) {
            wrapper.add(new POReviewWrapper(
                line.Id, 
                line.Product2Id, 
                line.Product2.Name,
                line.Forecast_Quantity__c, 
                line.QuantityRequested,
                line.Approval_Status__c,
                line.Was_Previously_Deleted__c
            ));
        }

        // Fetch Parent PO Status
        String poStatus = '';
        ProductRequest po = [SELECT PO_Approval_Status__c FROM ProductRequest WHERE Id = :poId LIMIT 1];
        poStatus = po.PO_Approval_Status__c;

        return new POResponseWrapper(wrapper, poStatus);
    }

    @AuraEnabled(cacheable=true)
    public static POResponseWrapper getPOLineItems2(Id poId) {
        List<POReviewWrapper> wrapper = new List<POReviewWrapper>();

        List<ProductRequestLineItem> lineItems = [
            SELECT Id, Product2Id, Product2.Name, Forecast_Quantity__c, QuantityRequested, Approval_Status__c, Was_Previously_Deleted__c
            FROM ProductRequestLineItem
            WHERE ParentId = :poId 
            AND Is_Deleted_Item__c = false
            AND Requested_Qty_Less_Than_Forecast__c = true
        ];

        for (ProductRequestLineItem line : lineItems) {
            wrapper.add(new POReviewWrapper(
                line.Id, 
                line.Product2Id, 
                line.Product2.Name,
                line.Forecast_Quantity__c, 
                line.QuantityRequested,
                line.Approval_Status__c,
                line.Was_Previously_Deleted__c
            ));
        }

        // Fetch Parent PO Status
        String poStatus = '';
        ProductRequest po = [SELECT PO_Approval_Status__c FROM ProductRequest WHERE Id = :poId LIMIT 1];
        poStatus = po.PO_Approval_Status__c;

        return new POResponseWrapper(wrapper, poStatus);
    }


    @AuraEnabled
    public static void updatePOLineItems(Id poId, String jsonString) {
        List<ProductRequestLineItem> updateList = new List<ProductRequestLineItem>();
        List<POReviewWrapper> incoming = (List<POReviewWrapper>) JSON.deserialize(jsonString, List<POReviewWrapper>.class);

        for (POReviewWrapper item : incoming) {
            if (item.Id == null && item.IsNew) {
                ProductRequestLineItem pli = new ProductRequestLineItem(
                    ParentId = poId,
                    Product2Id = item.Product2Id,
                    QuantityRequested = item.QuantityRequested,
                    Forecast_Quantity__c = 0,
                    //Approval_Status__c = item.ApprovalStatus,
                    Is_Manually_Added__c = true
                );
                updateList.add(pli);
            } else {
                ProductRequestLineItem pli = new ProductRequestLineItem(
                    Id = item.Id,
                    QuantityRequested = item.QuantityRequested
                    //Approval_Status__c = item.ApprovalStatus
                );
                updateList.add(pli);
            }
        }

        if (!updateList.isEmpty()) {
            upsert updateList;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getAllProducts() {
        return [SELECT Id, Name, Minimum_Order_Qty__c FROM Product2 WHERE IsActive = true LIMIT 200];
    }

    @AuraEnabled
    public static void softDeleteLineItem(Id lineItemId) {
        ProductRequestLineItem lineItem = [SELECT Id, Product2Id, AccountId, ParentId, QuantityRequested, Forecast_Quantity__c, Related_Tracking_IDs_c__c
            FROM ProductRequestLineItem 
            WHERE Id = :lineItemId 
            LIMIT 1];
        
        //delete lineItem;

        /*
        lineItem.Is_Deleted_Item__c = true;
        update lineItem;
        */
        
        /*
        Deleted_POLI__c d = new Deleted_POLI__c(
            Product__c = lineItem.Product2Id,
            Account__c = lineItem.AccountId,
            Purchase_Order__c = lineItem.ParentId,
            Deleted_POLI_Id__c = lineItem.Id,
            Quantity_Requested__c = lineItem.QuantityRequested,
            Forecast_Quantity__c = lineItem.Forecast_Quantity__c,
            Is_Deleted_Item__c = true
        );
        insert d;
        */

        // Update Product Consumption Tracking to unmark Processed_for_PO__c
        if (String.isNotBlank(lineItem.Related_Tracking_IDs_c__c)) {
            try {
                List<String> idStrings = lineItem.Related_Tracking_IDs_c__c.split(',');
                List<Id> idList = new List<Id>();
                for (String s : idStrings) {
                    s = s.trim();
                    if (String.isNotBlank(s)) {
                        idList.add(Id.valueOf(s));
                    }
                }

                if (!idList.isEmpty()) {
                    List<ProductConsumptionTracking__c> trackingRecords = [
                        SELECT Id, Processed_for_PO__c 
                        FROM ProductConsumptionTracking__c 
                        WHERE Id IN :idList
                    ];

                    for (ProductConsumptionTracking__c record : trackingRecords) {
                        record.Processed_for_PO__c = false;
                    }

                    update trackingRecords;
                }

            } catch (Exception e) {
                System.debug('Failed to unmark tracking records: ' + e.getMessage());
                // Optional: throw custom error or skip silently
            }
        }

        // Finally delete the line item
        delete lineItem;        
    }

    @AuraEnabled
    public static void markPOSubmitted(Id poId) {
        ProductRequest po = [SELECT Id, ProductRequestNumber, PO_Submitted__c, OwnerId, Owner.Name, Owner.Email 
            FROM ProductRequest 
            WHERE Id = :poId LIMIT 1];

        po.PO_Submitted__c = true;
        po.PO_Approval_Status__c = 'Submitted';
        
        try {
            update po;
            System.debug('*** PO Approval Submitted Successfully');

            String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
            String poLink = baseUrl + '/' + poId;

            // Sending an Email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            email.setToAddresses(new List<String>{'saurabh4sfdc@gmail.com'});
            email.setSubject('PO Approval Request !');

            String htmlBody = '<html>' +
                '<body style="font-family: Arial, sans-serif; font-size: 14px; color: #333;">' +
                '<p>Dear Sir/Madam,</p>' +

                '<p>' +
                'Kindly review and approve the following Purchase Order (PO) at your earliest convenience. ' +
                'Your timely action will help ensure smooth processing.' +
                '</p>' +

                '<p>' +
                '<strong>Action Required:</strong><br/>' +
                'Please log in to the system and navigate to the PO Review section to approve or reject the PO.' +
                '<p>PO Number : ' + po.ProductRequestNumber + '</p>' +
                '<p>' +
                    '<strong>PO Link:</strong><br/>' +
                    '<a href="' + poLink + '">Click here to view the Purchase Order</a>' +
                '</p>' +
                '</p>' +

                '<p>' +
                'If you have any questions or require additional information, feel free to contact the concerned team.' +
                '</p>' +

                '<p>Thank you for your attention.</p>' +

                '<br/>' +

                'Best regards, <br/>' +
                '<em> ' + po.Owner.Name + ' </em><br/>' +
                '<em> ' + po.Owner.Email + ' </em><br/>' + 
                '</body>' +
                '</html>';

            email.setHtmlBody(htmlBody);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } 
        catch (Exception e) {
            System.debug('*** Error updating PO: ' + e.getMessage());
            throw new AuraHandledException('Failed to update PO: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void submitApprovalDecision(List<Id> approvedIds, List<Id> rejectedIds) {
        List<ProductRequestLineItem> approvalIst = new List<ProductRequestLineItem>();
        List<ProductRequestLineItem> rejectlIst = new List<ProductRequestLineItem>();
        for (Id id : approvedIds) {
            ProductRequestLineItem prodLineItemRec = new ProductRequestLineItem();
            prodLineItemRec.Approval_Status__c = 'Approved';
            prodLineItemRec.Id = id;
            approvalIst.add(prodLineItemRec);
        }

        for (Id id : rejectedIds) {
            ProductRequestLineItem prodLineItemRec = new ProductRequestLineItem();
            prodLineItemRec.Approval_Status__c = 'Rejected';
            prodLineItemRec.Id = id;
            rejectlIst.add(prodLineItemRec);

        }

        List<Id> allIds = new List<Id>();
        allIds.addAll(approvedIds);
        allIds.addAll(rejectedIds);

        List<ProductRequestLineItem> prodLineItemList = [
            SELECT Id, ParentId 
            FROM ProductRequestLineItem 
            WHERE Id IN :allIds
        ];

        if(!approvalIst.isempty()){
            update approvalIst;
        }if(!rejectlIst.isempty()){
            update rejectlIst;
        }
    }


    public class POReviewWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public Id Product2Id;
        @AuraEnabled public String ProductName;
        @AuraEnabled public Decimal ForecastQty;
        @AuraEnabled public Decimal QuantityRequested;
        @AuraEnabled public String ApprovalStatus;
        @AuraEnabled public Boolean WasPreviouslyDeleted;
        @AuraEnabled public Boolean IsNew;

        public POReviewWrapper(Id Id, Id Product2Id, String ProductName, Decimal ForecastQty, Decimal QuantityRequested, String ApprovalStatus, Boolean WasPreviouslyDeleted) {
            this.Id = Id;
            this.Product2Id = Product2Id;
            this.ProductName = ProductName;
            this.ForecastQty = ForecastQty;
            this.QuantityRequested = QuantityRequested;
            this.ApprovalStatus = ApprovalStatus;
            this.WasPreviouslyDeleted = WasPreviouslyDeleted;
        }
    }

    public class POResponseWrapper {
        @AuraEnabled public List<POReviewWrapper> lineItems;
        @AuraEnabled public String poApprovalStatus;

        public POResponseWrapper(List<POReviewWrapper> lineItems, String poApprovalStatus) {
            this.lineItems = lineItems;
            this.poApprovalStatus = poApprovalStatus;
        }
    }
}