public class gatePassQRGeneratorHelper implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    private List<Order> ordersToProcess;
    private Map<Id, String> orderIdToUrlMap;
    private Set<Id> processedOrderIds;
    
    public gatePassQRGeneratorHelper(List<Id> orderIds) {
        this.ordersToProcess = new List<Order>();
        this.orderIdToUrlMap = new Map<Id, String>();
        this.processedOrderIds = new Set<Id>();
        
        String siteBaseUrl = Label.Site_Base_URL; 
        String vfPageName = 'gatePass';
        
        for (Order ord : [SELECT Id, OrderNumber, Gate_Pass_QR_Link__c FROM Order WHERE Id IN :orderIds]) {
            String fullUrl = siteBaseUrl + '/' + vfPageName + '?id=' + ord.Id;
            orderIdToUrlMap.put(ord.Id, fullUrl);
            ordersToProcess.add(ord);
        }
    }
    
    public Iterable<Order> start(Database.BatchableContext BC) {
        return ordersToProcess;
    }
    
    public void execute(Database.BatchableContext BC, List<Order> scope) {
        try {
            System.debug('Processing batch with ' + scope.size() + ' orders');
            
            for (Order ord : scope) {
                try {
                    generateAndStoreQRCode(ord);
                    processedOrderIds.add(ord.Id);
                } catch (Exception e) {
                    System.debug('Error processing order ' + ord.Id + ': ' + e.getMessage());
                    ExceptionHelper.createExceptionLog(e);
                }
            }
            
        } catch (Exception batchEx) {
            System.debug('Exception in batch execute: ' + batchEx.getMessage());
            ExceptionHelper.createExceptionLog(batchEx);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        try {
            System.debug('Batch processing completed. Processed ' + processedOrderIds.size() + ' orders');
            
            if (!processedOrderIds.isEmpty()) {
                List<Order> ordersToUpdate = new List<Order>();
                for (Id orderId : processedOrderIds) {
                    ordersToUpdate.add(new Order(
                        Id = orderId, 
                        Is_Gate_Pass_Generated__c = true, 
                        Gate_Pass_Generated_Date_Time__c = System.now()
                    ));
                }
                
                if (!ordersToUpdate.isEmpty()) {
                    update ordersToUpdate;
                    System.debug('Updated ' + ordersToUpdate.size() + ' orders with gate pass generation status');
                }
            }
            
        } catch (Exception e) {
            System.debug('Exception in batch finish: ' + e.getMessage());
            ExceptionHelper.createExceptionLog(e);
        }
    }
    
    private void generateAndStoreQRCode(Order ord) {
        try {
            System.debug('Starting QR code generation for order: ' + ord.Id);
            
            String data = orderIdToUrlMap.get(ord.Id);
            System.debug('Data to encode in QR: ' + data);
            
            Integer xsize = 170;
            Integer ysize = 170;
            
            String qrApiUrl = System.Label.QRCodeBaseURL 
                + EncodingUtil.urlEncode(data, 'UTF-8') 
                + '&size=' + ysize + 'x' + xsize + '&format=png';

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(qrApiUrl);
            request.setMethod('GET');
            request.setTimeout(120000);

            HttpResponse response = http.send(request);
            System.debug('QR API response status: ' + response.getStatusCode());

            if (response.getStatusCode() == 200) {
                Blob qrCodeBlob = response.getBodyAsBlob();
                System.debug('QR code image blob size: ' + qrCodeBlob.size());

                Attachment qrAttachment = new Attachment();
                qrAttachment.ParentId = ord.Id;
                qrAttachment.Name = 'Temp_QRCode_' + System.now().format('yyyyMMdd_HHmmss') + '.png';
                qrAttachment.Body = qrCodeBlob;
                qrAttachment.ContentType = 'image/png';

                insert qrAttachment;
                System.debug('Temporary QR attachment inserted: ' + qrAttachment.Name);

                System.enqueueJob(new GatePassPDFQueueableDelayed(ord.Id, qrAttachment.Id), 1);
                
            } else {
                System.debug('Failed to get QR code from API. Status: ' + response.getStatusCode());
                throw new CalloutException('QR API call failed with status: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception in generateAndStoreQRCode for order ' + ord.Id + ': ' + e.getMessage());
            throw e;
        }
    }
}