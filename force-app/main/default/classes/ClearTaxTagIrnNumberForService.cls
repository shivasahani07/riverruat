public without sharing class ClearTaxTagIrnNumberForService {
    
    @AuraEnabled
    public static void deleteOrderQRcode(Id WorkOrderId){
        try{
            WorkOrder WorkOrdRecord = [SELECT Id FROM WorkOrder WHERE Id =:WorkOrderId LIMIT 1];
            List<Attachment> attList = [SELECT Id FROM Attachment WHERE Name LIKE '%QRCode%' AND ParentId = :WorkOrdRecord.Id];
            if(!attList.isEmpty()){
                delete attList;
                System.debug('Deleted QR Code for Order Record === >'+attList);
            }
        }catch(Exception e){
            ExceptionHelper.createExceptionLog(e);
            System.debug('Error Message ==> ' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
        }
    }
    
    // Update Order When IRN is Cancled ##7
    public static void updateOrderIRNCancel(WorkOrder WorkOrdRecord){
        try{
            WorkOrdRecord.IRN_No__c = '';
            WorkOrdRecord.IRN_Generated_DateTime__c = null;
            WorkOrdRecord.Is_IRN_Cancelled__c = true;
            WorkOrdRecord.Can_Cancel_IRN__c = false;
            WorkOrdRecord.Is_E_invoice_Generated__c = false;
            WorkOrdRecord.Is_QR_Generated__c = false;
            update WorkOrdRecord;
            System.debug('Update WorkOrder Record without IRN  === >'+WorkOrdRecord);
            DeleteGenerateE_InvoiceOnIRNCancel(WorkOrdRecord);
        }catch(Exception e){
            ExceptionHelper.createExceptionLog(e);
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    // Delete E-invoice Attachment when IRN is get Cancled ##8
    public static void DeleteGenerateE_InvoiceOnIRNCancel(WorkOrder WorkOrdRecord) {
        try {
            String WorkorderName = WorkOrdRecord.WorkOrderNumber.trim();
            String searchPattern = '%E-invoice%' + WorkorderName + '%'; 
            System.debug('searchPattern === >' + searchPattern);
            List<Attachment> attList = [SELECT Id FROM Attachment WHERE Name LIKE :searchPattern LIMIT 1];
            if (!attList.isEmpty()) {
                delete attList;
                System.debug('Deleted E-Invoice for Order Record === >' + attList);
            } else {
                System.debug('No matching E-Invoice found for Order Number ==> ' + WorkorderName);
            }
        } catch (Exception e) {
            ExceptionHelper.createExceptionLog(e);
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
        }
    }
    
    @future(callout=true)
    public static void generateAndStoreQRCode(String data, String recordId) {
        Integer xsize = 170;
        Integer ysize = 170;
        String qrApiUrl = System.Label.QRCodeBaseURL + EncodingUtil.urlEncode(data, 'UTF-8') 
            + '&size=' + ysize + 'x' + xsize + '&format=png';
        
        System.debug('### [generateAndStoreQRCode] QR API URL: ' + qrApiUrl);
        System.debug('### [generateAndStoreQRCode] Record ID: ' + recordId);
        System.debug('### [generateAndStoreQRCode] Raw Data: ' + data);
        
        try {
            WorkOrder WorkOrdRecord = [
                SELECT Id, WorkOrderNumber, Is_QR_Generated__c 
                FROM WorkOrder 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            System.debug('### [generateAndStoreQRCode] Retrieved WorkOrder: ' + WorkOrdRecord);
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(qrApiUrl);
            request.setMethod('GET');
            
            System.debug('### [generateAndStoreQRCode] Sending HTTP request to QR API...');
            HttpResponse response = http.send(request);
            System.debug('### [generateAndStoreQRCode] HTTP Status: ' + response.getStatus());
            System.debug('### [generateAndStoreQRCode] Status Code: ' + response.getStatusCode());
            
            if (response.getStatusCode() == 200) {
                Blob qrCodeBlob = response.getBodyAsBlob();
                
                Attachment attachment = new Attachment();
                attachment.ParentId = recordId; 
                attachment.Name = 'EInvoice_QRCode_' + WorkOrdRecord.WorkOrderNumber + '_' + System.now().format('h:mm a') + '.png';
                attachment.Body = qrCodeBlob;
                attachment.ContentType = 'image/png'; 
                
                insert attachment;
                System.debug('### [generateAndStoreQRCode] QR Code Attachment inserted: ' + attachment);
                
                WorkOrdRecord.Is_QR_Generated__c = true;
                update WorkOrdRecord;
                
                System.debug('### [generateAndStoreQRCode] WorkOrder updated with QR generated flag.');
            } else {
                System.debug('### [generateAndStoreQRCode] Failed to generate QR code. Response Body: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('### [generateAndStoreQRCode] Exception: ' + e.getMessage());
            ExceptionHelper.createExceptionLog(e);
        }
    }
    
}