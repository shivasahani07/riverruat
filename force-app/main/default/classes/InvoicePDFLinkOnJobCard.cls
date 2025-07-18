/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 07-10-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class InvoicePDFLinkOnJobCard {

     public static void afterUpdate(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
        List<Id> eligibleIds = new List<Id>();
        for (WorkOrder wo : newList) {
            if (wo.Status == 'Ready for Delivery' && oldMap.get(wo.Id).Status != 'Ready for Delivery') {
                eligibleIds.add(wo.Id);
            }
        }

        if (!eligibleIds.isEmpty()) {
            InvoicePDFLinkOnJobCard.getPublicInvoiceLink(eligibleIds);
        }
    }

    @future(callout=true)
    public static void getPublicInvoiceLink(List<Id> workOrderIds) {
        try {
            System.debug('Received WorkOrder Ids: ' + workOrderIds);

            List<WorkOrder> jobcardList = [SELECT Id,Status FROM WorkOrder WHERE Id IN :workOrderIds];

            List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
            Map<Id, Blob> workOrderToPdfBlobMap = new Map<Id, Blob>();

            for (WorkOrder w : jobcardList) {
                if (w.Status == 'Ready for Delivery') {
                    PageReference pdfPage = Page.Customer_Invoice_PDF;
                    pdfPage.getParameters().put('id', w.Id);

                    Blob pdfBlob;
                    if (!Test.isRunningTest()) {
                        pdfBlob = pdfPage.getContentAsPDF(); 
                    } else {
                        pdfBlob = Blob.valueOf('Test');
                    }

                    ContentVersion cv = new ContentVersion();
                    cv.Title = 'Customer_Invoice';
                    cv.PathOnClient = 'Customer_Invoice.pdf';
                    cv.VersionData = pdfBlob;
                    cv.FirstPublishLocationId = w.Id;

                    contentVersionsToInsert.add(cv);
                    workOrderToPdfBlobMap.put(w.Id, pdfBlob); 
                }
            }

            if (!contentVersionsToInsert.isEmpty()) {
                insert contentVersionsToInsert;
                System.debug('Inserted ContentVersions');

                List<ContentDistribution> cdsToInsert = new List<ContentDistribution>();
                Map<Id, Id> cvIdToWorkOrderId = new Map<Id, Id>();

                for (ContentVersion cv : contentVersionsToInsert) {
                    ContentVersion insertedCV = [
                        SELECT Id, ContentDocumentId 
                        FROM ContentVersion 
                        WHERE Id = :cv.Id 
                        LIMIT 1
                    ];

                    Id workOrderId = cv.FirstPublishLocationId;

                    ContentDistribution cd = new ContentDistribution();
                    cd.Name = 'Customer Invoice - ' + workOrderId;
                    cd.ContentVersionId = insertedCV.Id;
                    cd.PreferencesAllowOriginalDownload = true;
                    cd.PreferencesLinkLatestVersion = true;

                    cdsToInsert.add(cd);
                    cvIdToWorkOrderId.put(insertedCV.Id, workOrderId);
                }

                insert cdsToInsert;

                List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();

                for (ContentDistribution cd : cdsToInsert) {
                    ContentDistribution cdl = [
                        SELECT Id, DistributionPublicUrl 
                        FROM ContentDistribution 
                        WHERE Id = :cd.Id 
                        LIMIT 1
                    ];

                    Id relatedWorkOrderId = cvIdToWorkOrderId.get(cd.ContentVersionId);
                    if (relatedWorkOrderId != null) {
                        WorkOrder wo = new WorkOrder(Id = relatedWorkOrderId);
                        wo.Invoice_PDF_Link__c = cdl.DistributionPublicUrl; 
                        workOrdersToUpdate.add(wo);
                    }
                }

                if (!workOrdersToUpdate.isEmpty()) {
                    update workOrdersToUpdate;
                    System.debug('Updated WorkOrders with public invoice links');
                }
            }

        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            System.debug('Line Number: ' + e.getLineNumber());
        }
    }
}