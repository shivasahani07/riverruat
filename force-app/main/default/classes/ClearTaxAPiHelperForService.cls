/**
* @author Ram Kumar
* @email ram.k@utilitarianlabs.com
* @create date 28-08-2025
* @modify date 28-08-2025
* @desc [ClearTax All API Method whihc using for the API]
*/

public without sharing class ClearTaxAPiHelperForService {
private static ClearTax_Api_Details__c clearTaxDetails;
static {
    clearTaxDetails = ClearTax_Api_Details__c.getInstance('ClearTax Api');
    if (clearTaxDetails == null) {
        System.debug('Custom setting "ClearTax Api" is not found.');
    }
}

// Method to get Access Token
public static String getAccessToken() {
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(clearTaxDetails.BaseURL_AccessToken__c);
    request.setMethod('GET');
    request.setHeader('x-clear-client-secret', clearTaxDetails.Client_Secret__c);
    System.debug('Acess token Endpoint ==>'+clearTaxDetails.BaseURL_AccessToken__c);
    System.debug('client Secret ==>'+clearTaxDetails.Client_Secret__c);
    try {
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            System.debug('Response #1 == > ' + response.getBody());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (responseMap.containsKey('access_token')) {
                String accessToken = (String) responseMap.get('access_token');
                System.debug('Access Token == > ' + accessToken);
                return accessToken;
            } else {
                System.debug('access_token not found in the response');
                return null;
            }
        } else {
            System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getBody());
            return null;
        }
    } catch (Exception e) {
        ExceptionHelper.createExceptionLog(e);
        System.debug('Exception Message # == > ' + e.getMessage()+' && Line  === >'+e.getLineNumber());
        return null;
    }
}

// =============================================================================================================================================================================================================
// Method to Generate IRN & SignedQRCode  ##1
@AuraEnabled
public static String generateEInvoice(String recordId) {

WorkOrder WorkOrdRecord = [ 
    SELECT Id, CreatedDate, EndDate, Service_Center__r.Name, Service_Center__r.Company_GSTIN_name__c, Service_Center__r.GSTIN_Number__c, Service_Center__r.ShippingStreet, Service_Center__r.ShippingCity,
            Service_Center__r.ShippingState, Service_Center__r.ShippingCountry, Service_Center__r.ShippingPostalCode, Company__c, Invoice_No__c, WorkOrderNumber, Invoice_Date__c,
            Account.ShippingState, Account.Name, Status, Service_Center__r.Center_Code__c, Same_State__c,
            Vehicle__r.Insurance__r.Name, Vehicle__r.Policy_Number__c, Vehicle__r.EngineNumber, Invoice_Type__c, Vehicle__r.isCustomerStateSame__c, City__r.State__c,
            Vehicle_Registration_Number__c, Vehicle__r.VehicleIdentificationNumber, Vehicle__r.Name, Vehicle__r.VehicleRegistrationNumber, Vehicle__r.LastOdometerReading, toLabel(RR_Job_Type__c),
            Vehicle__r.CurrentOwner.Name, Vehicle__r.CurrentOwner.GSTIN_Number__c, Vehicle__r.CurrentOwner.ShippingStreet, Service_Center__r.BillingCity, Service_Center__r.BillingCountry,
            Service_Center__r.BillingState, Service_Center__r.BillingStreet, Service_Center__r.CIN__c, Service_Center__r.BillingPostalCode,
            Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.Email__c, Account.Phone, Account.Secondary_Phone_Number__c, Account.GSTIN_Number__c,
            Service_Center__r.Store_Type__c, Service_Center__r.Email__c, Service_Center__r.Phone, Vehicle__r.CurrentOwner.ShippingCity, Vehicle__r.CurrentOwner.ShippingState,
            Vehicle__r.CurrentOwner.ShippingCountry, Vehicle__r.CurrentOwner.ShippingPostalCode, Service_Center__r.Secondary_Phone_Number__c, RR_Service_Advisor__r.Name,
            Odometer_Reading__c, toLabel(RR_Service_Advisor__r.ResourceType)
    FROM WorkOrder WHERE Id = :recordId 
];

try {
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(clearTaxDetails.E_Invoice_Base_URL__c);
    request.setMethod('PUT');
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('X-Cleartax-Auth-Token', getAccessToken());
    request.setHeader('gstin', WorkOrdRecord.Service_Center__r.GSTIN_Number__c); // Seller GSTIN
    System.debug('E Inovice Base URL ==>' + clearTaxDetails.E_Invoice_Base_URL__c);
    System.debug('request' + request);

    String payload = generatePayloadForIRN(recordId);
    System.debug('payload === >' + payload);
    request.setBody(payload);
    request.setTimeout(120000);

    HttpResponse response = http.send(request);
    ExceptionHelper.createAPICalloutLog(request, response, 'IRN');

    if (response.getStatusCode() == 200) {
        System.debug('Response == > ' + response.getBody());

        List<Object> jsonResponseList = (List<Object>) JSON.deserializeUntyped(response.getBody());

        if (!jsonResponseList.isEmpty()) {
            Map<String, Object> firstItem = (Map<String, Object>) jsonResponseList[0];
            String documentStatus = (String) firstItem.get('document_status');

            if (documentStatus == 'IRN_CANCELLED') {
                return 'IRN for this invoice is cancelled. Please use a new invoice number to generate a fresh IRN.';
            }
        }
        

        List<Object> responseList = (List<Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> payloadList = (List<Object>) JSON.deserializeUntyped(payload);

        if (!responseList.isEmpty()) {
            String irnNumber = ''; 
            List<String> errorMessages = new List<String>();

            for (Integer i = 0; i < responseList.size(); i++) {
                Map<String, Object> item = (Map<String, Object>) responseList[i];
                Map<String, Object> payloadItem = (Map<String, Object>) payloadList[i];

                String productType = payloadItem.containsKey('productType') ? (String) payloadItem.get('productType') : 'Vehicle';

                if (item.containsKey('govt_response')) {
                    Map<String, Object> govtResponse = (Map<String, Object>) item.get('govt_response');

                    if (govtResponse.containsKey('Irn') && (String) govtResponse.get('Success') == 'Y') {
                        irnNumber = (String) govtResponse.get('Irn'); 

                        String signedQRCode = (String) govtResponse.get('SignedQRCode');
                        ClearTaxTagIrnNumberForService.generateAndStoreQRCode(signedQRCode, recordId);
                    } else if (govtResponse.containsKey('ErrorDetails')) {
                        List<Object> errorDetails = (List<Object>) govtResponse.get('ErrorDetails');
                        if (!errorDetails.isEmpty()) {
                            Map<String, Object> firstError = (Map<String, Object>) errorDetails[0];
                            String errorMessage = (String) firstError.get('error_message');
                            errorMessages.add(errorMessage);
                        }
                    }
                }
            }

            if (!String.isBlank(irnNumber)) {
                //System.enqueueJob(new IRNUpdateQueueableForService(WorkOrdRecord.Id, irnNumber, 1));
                WorkOrder updateWorkOrd = new WorkOrder(Id = recordId);
                updateWorkOrd.IRN_Generated_DateTime__c = System.now();
                updateWorkOrd.IRN_No__c = irnNumber;
                updateWorkOrd.Can_Cancel_IRN__c = true;
            
                try{
                    update updateWorkOrd;
                System.debug('WorkOrder update successful ==> ' + updateWorkOrd);
                }catch(exception e){
                    System.debug('WorkOrder update successful ==> ' + e.getMessage()+ ' '+ e.getLineNumber());
                    ExceptionHelper.createExceptionLog(e);
                }
            }

                if (!String.isBlank(irnNumber) && errorMessages.isEmpty()) {
                    return 'SUCCESS: IRN generated - ' + irnNumber;
                } else if (!errorMessages.isEmpty()) {
                    return 'ERRORS: ' + String.join(errorMessages, ', ');
                } else {
                    return 'No IRN generated and no errors returned.';
                }
            } else {
                return 'Empty response received from e-invoice API.';
            }
        } else {
            System.debug('HTTP Error Code = > ' + response.getStatusCode() + ' && Response Body ==>' + response.getBody());
            return 'Error: HTTP ' + response.getStatusCode();
        }
    } catch (Exception e) {
        ExceptionHelper.createExceptionLog(e);
        System.debug('Exception Message ==>' + e.getMessage() + ' && Line == >' + e.getLineNumber());
        return 'Exception: ' + e.getMessage();
    }
    }




@AuraEnabled
public static String generatePayloadForIRN(Id workOrderId) {
System.debug('=== generatePayloadForIRN STARTED for WorkOrderId: ' + workOrderId);

// Build state code map
Map<String, String> stateCodeMap = new Map<String, String>();
for (State_Code_Mapping__mdt m : [SELECT MasterLabel, State_Code__c FROM State_Code_Mapping__mdt]) {
    stateCodeMap.put(m.MasterLabel, m.State_Code__c);
}
System.debug('StateCodeMap => ' + stateCodeMap);

// Work Order
WorkOrder wo = [
    SELECT Id, AccountId, Service_Center__c, Service_Center__r.Name,
            Service_Center__r.GSTIN_Number__c, Service_Center__r.BillingStreet,
            Service_Center__r.BillingCity, Service_Center__r.BillingState,
            Service_Center__r.BillingCountry, Service_Center__r.BillingPostalCode,
            Service_Center__r.Center_Code__c,
            Account.BillingStreet, Account.BillingCity, Account.BillingState,
            Account.BillingCountry, Account.BillingPostalCode, Account.GSTIN_Number__c, Account.Name,
            Invoice_No__c, Same_State__c, CreatedDate
    FROM WorkOrder
    WHERE Id = :workOrderId
    LIMIT 1
];
System.debug('Fetched WorkOrder => ' + wo);

// Buyer (Customer)
Account buyer = [
    SELECT BillingStreet, BillingCity, BillingPostalCode, BillingState, BillingCountry,
            GSTIN_Number__c, Name
    FROM Account
    WHERE Id = :wo.AccountId
    LIMIT 1
];
System.debug('Buyer Account => ' + buyer);

// Seller (Service Center)
Account seller = [
    SELECT BillingStreet, BillingCity, BillingPostalCode, BillingState, BillingCountry,
            GSTIN_Number__c, Name, Center_Code__c
    FROM Account
    WHERE Id = :wo.Service_Center__c
    LIMIT 1
];
System.debug('Seller Account => ' + seller);

// Parts (Paid)
List<WorkOrderLineItem> wolis = [
    SELECT Id, Quantity, UnitPrice, Discount, Subtotal, TotalPrice,
            RR_Product__r.Name, RR_Product__r.HSN_Code__c,
            IGST_Percentage_formula__c, CGST_Percentage_Formula__c, SGST_Percentage_Formula__c,
            IGST_Amount__c, CGST_Amount__c, SGST_Amount__c,
            RR_Parts_Category__c
    FROM WorkOrderLineItem
    WHERE WorkOrderId = :wo.Id
        AND RR_Parts_Category__c IN ('Paid')
];
System.debug('Paid WOLIs size => ' + wolis.size());

// Labour (Paid)
List<WorkPlan> wps = [
    SELECT Id, Name, RR_Labour_Category__c, RR_Labour_Code__r.HSN_Code__c,
            Labour_Charge__c, Discount__c, Subtotal__c,
            IGST_Amount__c, CGST_Amount__c, SGST_Amount__c,
            RR_Labour_Code__r.IGST_Percentage__c,
            RR_Labour_Code__r.CGST_Percentage__c,
            RR_Labour_Code__r.SGST_Percentage__c,
            RR_Labour_Code__r.Code
    FROM WorkPlan
    WHERE WorkOrderId = :wo.Id
        AND RR_Labour_Category__c IN ('Paid')
];
System.debug('Paid WorkPlans size => ' + wps.size());

// Determine buyer state code and inter/intra
Boolean isInternational = (buyer.BillingCountry != null && buyer.BillingCountry != 'India');
String buyerStateCode = isInternational ? '96' : stateCodeMap.get(buyer.BillingState);
String sellerStateCode = (seller.Center_Code__c != null && seller.Center_Code__c.length() >= 2)
    ? seller.Center_Code__c.substring(0, 2) : stateCodeMap.get(seller.BillingState);
Boolean isIntrastate = (!isInternational && buyerStateCode != null && buyerStateCode == sellerStateCode);

System.debug('isInternational => ' + isInternational);
System.debug('buyerStateCode => ' + buyerStateCode + ', sellerStateCode => ' + sellerStateCode);
System.debug('isIntrastate => ' + isIntrastate + ' (branch: ' + (isIntrastate ? 'INTRA (CGST+SGST)' : 'INTER (IGST)') + ')');

// Header blocks
Datetime now = Datetime.now();
Map<String, Object> tranDtls = new Map<String, Object>{
    'TaxSch' => 'GST',
    'SupTyp' => 'B2B',
    'RegRev' => 'N'
};
Map<String, Object> docDtls = new Map<String, Object>{
    'Typ' => 'INV',
    'No' => 'tvv'+ wo.Invoice_No__c,
    'Dt' => now.format('dd/MM/yyyy')
};

// Seller & buyer maps (use instance isNumeric)
Map<String, Object> sellerDtls = new Map<String, Object>{
    'Gstin' => seller.GSTIN_Number__c,
    'LglNm' => seller.Name,
    'Addr1' => seller.BillingStreet,
    'Loc' => seller.BillingCity,
    'Pin' => (seller.BillingPostalCode != null && seller.BillingPostalCode.isNumeric()) ? Integer.valueOf(seller.BillingPostalCode) : null,
    'Stcd' => sellerStateCode
};
Map<String, Object> buyerDtls = new Map<String, Object>{
    'Gstin' => buyer.GSTIN_Number__c,
    'LglNm' => buyer.Name,
    'Pos' => buyerStateCode,
    'Addr1' => buyer.BillingStreet,
    'Loc' => buyer.BillingCity,
    'Pin' => (buyer.BillingPostalCode != null && buyer.BillingPostalCode.isNumeric()) ? Integer.valueOf(buyer.BillingPostalCode) : null,
    'Stcd' => buyerStateCode
};
System.debug('SellerDtls => ' + JSON.serializePretty(sellerDtls));
System.debug('BuyerDtls => ' + JSON.serializePretty(buyerDtls));

// Items and totals
List<Map<String, Object>> itemList = new List<Map<String, Object>>();
Integer sl = 1;
Decimal totalAssVal = 0, totalCgst = 0, totalSgst = 0, totalIgst = 0;

// Helper to round to 2 decimals (assuming round2 exists in class; if not, inline)
// Decimal round2(Decimal d) => d == null ? null : d.setScale(2);

// Parts lines
for (WorkOrderLineItem li : wolis) {
    Decimal qty = (li.Quantity == null) ? 0 : li.Quantity;
    Decimal unitPrice = (li.UnitPrice == null) ? 0 : li.UnitPrice;
    Decimal base = qty * unitPrice;
    Decimal discPct = (li.Discount == null) ? 0 : li.Discount;
    Decimal discountAmt = base * discPct / 100;
    if (discountAmt > base) discountAmt = base;
    Decimal assAmt = base - discountAmt;
    Decimal cgstRate = (li.CGST_Percentage_Formula__c == null) ? 0 : li.CGST_Percentage_Formula__c;
    Decimal sgstRate = (li.SGST_Percentage_Formula__c == null) ? 0 : li.SGST_Percentage_Formula__c;
    Decimal igstRate = (li.IGST_Percentage_formula__c == null) ? 0 : li.IGST_Percentage_formula__c;

    Decimal cgstAmt = 0, sgstAmt = 0, igstAmt = 0, gstRt = 0;
    if (isIntrastate) {
        cgstAmt = assAmt * cgstRate / 100;
        sgstAmt = assAmt * sgstRate / 100;
        gstRt = cgstRate + sgstRate;
    } else {
        igstAmt = assAmt * igstRate / 100;
        gstRt = igstRate;
    }
    Decimal totItemVal = assAmt + cgstAmt + sgstAmt + igstAmt;

    totalAssVal += assAmt;
    totalCgst += cgstAmt;
    totalSgst += sgstAmt;
    totalIgst += igstAmt;

    System.debug(
        'Part Item => ' +
        (li.RR_Product__r != null ? li.RR_Product__r.Name : 'Unnamed') +
        ' | HSN=' + (li.RR_Product__r != null ? li.RR_Product__r.HSN_Code__c : null) +
        ' | Qty=' + qty +
        ' | UnitPrice=' + unitPrice +
        ' | Base=' + base +
        ' | Disc%=' + discPct +
        ' | Discount=' + discountAmt +
        ' | AssAmt=' + assAmt +
        ' | Rates (CGST/SGST/IGST)=' + cgstRate + '/' + sgstRate + '/' + igstRate +
        ' | Amts (CGST/SGST/IGST)=' + cgstAmt + '/' + sgstAmt + '/' + igstAmt +
        ' | GstRt=' + gstRt +
        ' | TotVal=' + totItemVal +
        ' | TaxBranch=' + (isIntrastate ? 'INTRA' : 'INTER')
    );

    itemList.add(new Map<String, Object>{
        'SlNo' => String.valueOf(sl++),
        'IsServc' => 'N',
        'PrdDesc' => (li.RR_Product__r != null ? li.RR_Product__r.Name : null),
        'HsnCd' => (li.RR_Product__r != null ? li.RR_Product__r.HSN_Code__c : null),
        'Qty' => qty,
        'Unit' => 'NOS',
        'UnitPrice' => round2(unitPrice),
        'TotAmt' => round2(base),
        'Discount' => round2(discountAmt),
        'AssAmt' => round2(assAmt),
        'GstRt' => gstRt,
        'CgstAmt' => round2(cgstAmt),
        'SgstAmt' => round2(sgstAmt),
        'IgstAmt' => round2(igstAmt),
        'TotItemVal' => round2(totItemVal)
    });
}

// Labour lines
for (WorkPlan lp : wps) {
    Decimal qty = 1;
    Decimal unitPrice = (lp.Labour_Charge__c == null) ? 0 : lp.Labour_Charge__c;
    Decimal base = qty * unitPrice;
    Decimal discPct = (lp.Discount__c == null) ? 0 : lp.Discount__c;
    Decimal discountAmt = base * discPct / 100;
    if (discountAmt > base) discountAmt = base;
    Decimal assAmt = base - discountAmt;

    Decimal cgstRate = (lp.RR_Labour_Code__r != null && lp.RR_Labour_Code__r.CGST_Percentage__c != null) ? lp.RR_Labour_Code__r.CGST_Percentage__c : 0;
    Decimal sgstRate = (lp.RR_Labour_Code__r != null && lp.RR_Labour_Code__r.SGST_Percentage__c != null) ? lp.RR_Labour_Code__r.SGST_Percentage__c : 0;
    Decimal igstRate = (lp.RR_Labour_Code__r != null && lp.RR_Labour_Code__r.IGST_Percentage__c != null) ? lp.RR_Labour_Code__r.IGST_Percentage__c : 0;

    Decimal cgstAmt = 0, sgstAmt = 0, igstAmt = 0, gstRt = 0;
    if (isIntrastate) {
        cgstAmt = assAmt * cgstRate / 100;
        sgstAmt = assAmt * sgstRate / 100;
        gstRt = cgstRate + sgstRate;
    } else {
        igstAmt = assAmt * igstRate / 100;
        gstRt = igstRate;
    }
    Decimal totItemVal = assAmt + cgstAmt + sgstAmt + igstAmt;

    totalAssVal += assAmt;
    totalCgst += cgstAmt;
    totalSgst += sgstAmt;
    totalIgst += igstAmt;

    System.debug(
        'Labour Item => ' + lp.Name +
        ' | HSN=' + lp.RR_Labour_Code__r.HSN_Code__c +
        ' | Base=' + base +
        ' | Disc%=' + discPct +
        ' | Discount=' + discountAmt +
        ' | AssAmt=' + assAmt +
        ' | Rates (CGST/SGST/IGST)=' + cgstRate + '/' + sgstRate + '/' + igstRate +
        ' | Amts (CGST/SGST/IGST)=' + cgstAmt + '/' + sgstAmt + '/' + igstAmt +
        ' | GstRt=' + gstRt +
        ' | TotVal=' + totItemVal +
        ' | TaxBranch=' + (isIntrastate ? 'INTRA' : 'INTER')
    );

    itemList.add(new Map<String, Object>{
        'SlNo' => String.valueOf(sl++),
        'IsServc' => 'Y',
        'PrdDesc' => lp.Name,
        'HsnCd' => (lp.RR_Labour_Code__r.HSN_Code__c != null ? lp.RR_Labour_Code__r.HSN_Code__c : null),
        'Qty' => qty,
        'Unit' => 'OTH',
        'UnitPrice' => round2(unitPrice),
        'TotAmt' => round2(base),
        'Discount' => round2(discountAmt),
        'AssAmt' => round2(assAmt),
        'GstRt' => gstRt,
        'CgstAmt' => round2(cgstAmt),
        'SgstAmt' => round2(sgstAmt),
        'IgstAmt' => round2(igstAmt),
        'TotItemVal' => round2(totItemVal)
    });
}
System.debug('ItemList built (count=' + itemList.size() + ') => ' + JSON.serializePretty(itemList));

Map<String, Object> valDtls = new Map<String, Object>{
    'AssVal' => round2(totalAssVal),
    'CgstVal' => round2(totalCgst),
    'SgstVal' => round2(totalSgst),
    'IgstVal' => round2(totalIgst),
    'Discount' => 0,
    'TotInvVal' => Math.round(totalAssVal + totalCgst + totalSgst + totalIgst)
};
System.debug('ValDtls => ' + JSON.serializePretty(valDtls));

Map<String, Object> txn = new Map<String, Object>{
    'Version' => '1.1',
    'TranDtls' => tranDtls,
    'DocDtls' => docDtls,
    'SellerDtls' => sellerDtls,
    'BuyerDtls' => buyerDtls,
    'ItemList' => itemList,
    'ValDtls' => valDtls
};
System.debug('Transaction object (txn) => ' + JSON.serializePretty(txn));

List<Map<String, Object>> payloadList = new List<Map<String, Object>>();
payloadList.add(new Map<String, Object>{
    'transaction' => txn, 
    'productType' => 'WorkOrder'
});
System.debug('Final Payload (list) => ' + JSON.serializePretty(payloadList));

System.debug('=== generatePayloadForIRN FINISHED for WorkOrderId: ' + workOrderId);
return JSON.serialize(payloadList);
}

private static Decimal round2(Decimal d) {
return d == null ? null : d.setScale(2);
}


// =============================================================================================================================================================================================================

@AuraEnabled
public static String genereteE_invoicePDF(String recordId) {
    String response;
    try {
        if (recordId == null) return 'No WorkOrder Id';
        
        WorkOrder WorkOrdRecord = [
            SELECT Id, WorkOrderNumber, Is_QR_Generated__c, IRN_No__c
            FROM WorkOrder 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        System.debug('Fetched WorkOrdRecord => ' + WorkOrdRecord);
        
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        
        System.debug('Generating E-Invoice PDF...');
        PageReference vfPagepdf = Page.CustomerE_Invoice;
        vfPagepdf.getParameters().put('id', recordId);
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test') : vfPagepdf.getContentAsPDF();

        Attachment attachment = new Attachment();
        attachment.ParentId = recordId;
        attachment.Name = 'Customer E-Invoice-' + WorkOrdRecord.WorkOrderNumber + '-' + Date.Today().format() + ' ' + System.now().format('h:mm a') + '.pdf';
        attachment.Body = pdfBlob;
        attachment.ContentType = 'application/pdf';
        attachmentsToInsert.add(attachment);
        System.debug('Prepared Main E-Invoice Attachment');
        
        if (!attachmentsToInsert.isEmpty()) {
            insert attachmentsToInsert;
            WorkOrdRecord.Is_E_invoice_Generated__c = true;
            update WorkOrdRecord;
            response = 'success';
            System.debug('Inserted Attachments count: ' + attachmentsToInsert.size());
        } else {
            response = 'No Attachments to insert';
        }

        
            ClearTaxTagIrnNumberForService.deleteOrderQRcode(WorkOrdRecord.Id);
        
    } catch(Exception e) {
        ExceptionHelper.createExceptionLog(e);
        response = e.getMessage();
        System.debug('Error Message => ' + e.getMessage() + ' | Error Line => ' + e.getLineNumber());
    }
    System.debug('Final Response => ' + response);
    return response;
}

// Method to Validate Data for IRN Generation
@AuraEnabled
public static string checkValidateDataforIRNGeneration(string recordId){
    try{
        if(recordId != null){
            WorkOrder WorkOrdRecord = [SELECT Id, WorkOrderNumber, AccountId, Service_Center__c FROM WorkOrder WHERE Id = :recordId];
            Account buyer = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingState, BillingCountry, GSTIN_Number__c, Phone, Email__c FROM Account WHERE Id = :WorkOrdRecord.AccountId];
            System.debug('buyer == >' + buyer);
            if(buyer != null){
                if(buyer.BillingStreet == null || buyer.BillingStreet == ''){
                    return 'Attention: Buyer Address is required.';
                }
                if(buyer.BillingCity == null || buyer.BillingCity == ''){
                    return 'Attention: Buyer City is required.';
                }
                if(buyer.BillingPostalCode == null || buyer.BillingPostalCode == ''){
                    return 'Attention: Buyer Postal Code is required.';
                }
                if(buyer.BillingState == null || buyer.BillingState == ''){
                    return 'Attention: Buyer State is required.';
                }
                if(buyer.GSTIN_Number__c == null || buyer.GSTIN_Number__c == ''){
                    return 'Attention: Buyer GSTIN is required.';
                }
            }
            
            Account seller = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, BillingState, GSTIN_Number__c, Phone, Email__c, Center_Code__c,Store_Type__c FROM Account WHERE Id = :WorkOrdRecord.Service_Center__c];
            System.debug('seller == >' + seller);
            if(seller != null){
                if(seller.BillingStreet == null || seller.BillingStreet == ''){
                    return 'Attention: Seller Address is required.';
                }
                if(seller.BillingCity == null || seller.BillingCity == ''){
                    return 'Attention: Seller City is required.';
                }
                if(seller.BillingPostalCode == null || seller.BillingPostalCode == ''){
                    return 'Attention: Seller Postal Code is required.';
                }
                if(seller.BillingState == null || seller.BillingState == ''){
                    return 'Attention: Seller State is required.';
                }
                if(seller.GSTIN_Number__c == null || seller.GSTIN_Number__c == ''){
                    return 'Attention: Seller GSTIN is required.';
                }
                if(seller.Center_Code__c == null || seller.Center_Code__c == ''){
                    return 'Attention: Seller Dealer Code is required.';
                }
                if(seller.Store_Type__c == null || seller.Store_Type__c == ''){
                    return 'Attention: Please Provide Store Type.';
                }
                System.debug('success');
                return 'success';
            }
        }
    }catch(Exception e){
        System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
    }
    return null;
}


// =============================================================================================================================================================================================================

// Method to Cancel IRN (before 24 hours)
@AuraEnabled
public static String cancelIRN_EInvoice(String cancellationReason, String cancellationRemark, String WorkOrderId) {
    System.debug('==> cancellationReason: ' + cancellationReason + ', cancellationRemark: ' + cancellationRemark + ', workOrderId: ' + WorkOrderId);
    
    WorkOrder WorkOrdRecord = new WorkOrder();
    if (WorkOrderId != null) {
        WorkOrdRecord = [SELECT Id, WorkOrderNumber, Service_Center__r.GSTIN_Number__c, IRN_No__c 
                    FROM WorkOrder 
                    WHERE Id = :WorkOrderId 
                    LIMIT 1];
        System.debug('==> Order Record: ' + WorkOrdRecord);
    } else {
        return 'Attention: WorkOrder ID is required.';
    }
    
    try {
        if (String.isBlank(cancellationReason)) {
            return 'Attention: Cancellation reason is required.';
        }
        
        if (String.isBlank(WorkOrdRecord.Service_Center__r.GSTIN_Number__c)) {
            return 'Attention: Seller GSTIN is required.';
        }
        
        List<CancelRequest> requestBody = new List<CancelRequest>();
        Map<String, String> result = new Map<String, String>();
        
        if (!String.isBlank(WorkOrdRecord.IRN_No__c)) {
            CancelRequest mainIRN = new CancelRequest();
            mainIRN.irn = WorkOrdRecord.IRN_No__c;
            mainIRN.CnlRsn = cancellationReason;
            mainIRN.CnlRem = cancellationRemark != null ? cancellationRemark : '';
            requestBody.add(mainIRN);
        }
        
        if (requestBody.isEmpty()) {
            return 'Attention: No IRNs available to cancel.';
        }
        
        String jsonBody = JSON.serialize(requestBody);
        System.debug('==> JSON Request Body: ' + jsonBody);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(clearTaxDetails.Cancel_IRN_Base_URL__c);
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Cleartax-Auth-Token', getAccessToken());
        req.setHeader('gstin', WorkOrdRecord.Service_Center__r.GSTIN_Number__c);
        req.setBody(jsonBody);
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('==> Response Status: ' + res.getStatusCode());
        System.debug('==> Response Body: ' + res.getBody());
        
        if (res.getStatusCode() == 200) {
            Object responseObj = JSON.deserializeUntyped(res.getBody());
            if (responseObj instanceof List<Object>) {
                List<Object> responseList = (List<Object>) responseObj;
                if (!responseList.isEmpty() && responseList[0] instanceof Map<String, Object>) {
                    Map<String, Object> firstResponse = (Map<String, Object>) responseList[0];
                    System.debug('==> First Response: ' + firstResponse);
                    result.put('document_status', (String) firstResponse.get('document_status'));
                    Map<String, Object> govtResponse = (Map<String, Object>) firstResponse.get('govt_response');
                    System.debug('==> Govt Response: ' + govtResponse);
                    if (govtResponse != null) {
                        result.put('Success', (String) govtResponse.get('Success'));
                        result.put('AckNo', String.valueOf(govtResponse.get('AckNo')));
                        result.put('AckDt', (String) govtResponse.get('AckDt'));
                        if ('Y' == (String) govtResponse.get('Success')) {
                            ClearTaxTagIrnNumberForService.updateOrderIRNCancel(WorkOrdRecord);
                            return 'success';
                        }
                    }
                    System.debug('==> Final Result Map: ' + result);
                }
            }
        } else {
            System.debug('HTTP Error: Status Code = ' + res.getStatusCode() + ', Status = ' + res.getStatus());
        }
    } catch (Exception e) {
        ExceptionHelper.createExceptionLog(e);
        System.debug('==> Error Message: ' + e.getMessage() + ', Line: ' + e.getLineNumber());
    }
    
    return null;
}

public class CancelRequest {
    public String irn { get; set; }
    public String CnlRsn { get; set; }
    public String CnlRem { get; set; }
} 
}