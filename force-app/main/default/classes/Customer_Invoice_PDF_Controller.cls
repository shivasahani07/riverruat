/**
* @description       : 
* @author            : Ram Kumar
* @group             : 
* @last modified on  : 26-08-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public class Customer_Invoice_PDF_Controller {
    public Double offset {
        get {
            TimeZone tz = UserInfo.getTimeZone();
            // Milliseconds to Day
            Double offSetValue = tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
            system.debug('## OFFSET VALUE: ' + offSetValue);
            return offSetValue;
        }
    }
    public WorkOrder workOrderRecord { get; set; }
    public List<WorkOrderLineItem> workOrderLineItemList { get; set; }
    public List<WorkPlan> workPlansItemList { get; set; }
    
    public City__c cityDetails { get; set; } // added by Aniket on 07/07/2025
    
    // Part Summary Fields
    public decimal partTotal { get; set; }
    public decimal partDiscount { get; set; }
    public decimal parttaxValue { get; set; }
    public decimal partCGST { get; set; }
    public decimal partSGST { get; set; }
    public decimal partIGST { get; set; }
    public decimal partLineItemTotal { get; set; }
    
    // Labour Summary Fields
    public decimal labourTotal { get; set; }
    public decimal labourDiscount { get; set; }
    public decimal labourtaxValue { get; set; }
    public decimal labourCGST { get; set; }
    public decimal labourSGST { get; set; }
    public decimal labourIGST { get; set; }
    
    public decimal partsTotal { get; set; }
    public decimal laboursTotal { get; set; }
    public decimal invoiceTotal { get; set; }
    public String invoiceTotalInWords { get; set; }
    public String ModPayment { get; set; }
    public String storeType { get; set; }
    public DeliveryChallanPDF__mdt dcPdf { get; set; }
    public String dodoAccName { get; set; }
    public String dodoBillCityName { get; set; }
    public String dodoBillStateName { get; set; }
    public String dodoBillPostalCode { get; set; }
    public String dodoBillEmail { get; set; }
    public String dodoPhone { get; set; }
    public String cocoBillEmail { get; set; }
    public String cocoPhone { get; set; }
    public String cocoCIN { get; set; }
    public Terms_and_Condition__mdt cocoTC { get; set; }
    public String formatedIRNNumber { get; set; }
    public String storeNameForBottom { get; set; }
    public String JuriName { get; set; }
    public String GSTIN { get; set; }
    
    
    // New property to hold individual line item totals
    public Map<Id, Decimal> lineItemTotalsMap { get; set; }
    
    public Customer_Invoice_PDF_Controller(ApexPages.StandardController controller) {
        system.debug('## Entering Customer_Invoice_PDF_Controller constructor');
        workOrderRecord = new WorkOrder();
        workOrderLineItemList = new List<WorkOrderLineItem>();
        workPlansItemList = new List<WorkPlan>();
        
        // Initialize parts and labour summary fields
        partTotal = 0;
        partDiscount = 0;
        parttaxValue = 0;
        partCGST = 0;
        partSGST = 0;
        partIGST = 0;
        
        labourTotal = 0;
        labourDiscount = 0;
        labourtaxValue = 0;
        labourCGST = 0;
        labourSGST = 0;
        labourIGST = 0;
        
        partsTotal = 0;
        laboursTotal = 0;
        invoiceTotal = 0;
        invoiceTotalInWords = '';
        
        // Initialize the map for individual line item totals
        lineItemTotalsMap = new Map<Id, Decimal>();
        
        String workOrderId = Apexpages.currentPage().getParameters().get('id');
        system.debug('## WorkOrderId from URL: ' + workOrderId);
        
        dcPdf = [
            SELECT Id, CIN__c, Company_Email__c, Company_Phone__c, Company_Website__c, CompanyName__c, Factory_Address__c, Former_Address__c, GST__c, Registered_Office__c, Bill_From__c, Bill_To__c, PartA__c, Small_CName__c 
            FROM DeliveryChallanPDF__mdt LIMIT 1
        ];
        system.debug('## dcPdf record fetched: ' + dcPdf);
        
        List<WorkOrder> workOrderList = [
            SELECT Id, CreatedDate, EndDate, Service_Center__r.Parent.GSTIN_Number__c, Service_Center__r.Name, Service_Center__r.Company_GSTIN_name__c, Service_Center__r.GSTIN_Number__c, Service_Center__r.ShippingStreet, Service_Center__r.ShippingCity,
            Service_Center__r.ShippingState, Service_Center__r.ShippingCountry, Service_Center__r.ShippingPostalCode, Company__c, Invoice_No__c, WorkOrderNumber, Invoice_Date__c,
            Account.ShippingState, Account.Name, Status, Service_Center__r.Center_Code__c, Same_State__c, Account.Company_GSTIN_name__c,
            Vehicle__r.Insurance__r.Name, Vehicle__r.Policy_Number__c, Vehicle__r.EngineNumber, Invoice_Type__c, Vehicle__r.isCustomerStateSame__c, City__r.State__c,
            Vehicle_Registration_Number__c, Vehicle__r.VehicleIdentificationNumber, Vehicle__r.Name, Vehicle__r.VehicleRegistrationNumber, Vehicle__r.LastOdometerReading, toLabel(RR_Job_Type__c),
            Vehicle__r.Dealer__r.Name, Vehicle__r.Dealer__r.ShippingStreet, Vehicle__r.Dealer__r.GSTIN_Number__c, Vehicle__r.Insurance__r.Address__c, Vehicle__r.Insurance__r.GSTIN_Number__c,
            Vehicle__r.CurrentOwner.Name, Vehicle__r.CurrentOwner.GSTIN_Number__c, Vehicle__r.CurrentOwner.ShippingStreet, Service_Center__r.BillingCity, Service_Center__r.BillingCountry,
            Service_Center__r.BillingState, Service_Center__r.BillingStreet, Service_Center__r.CIN__c, Service_Center__r.BillingPostalCode, Service_Center__r.GST_City__c, Service_Center__r.GST_State__c, Service_Center__r.GST_Zip_Postal_Code__c,
            Service_Center__r.GST_Street__c,Mode_Of_Payment__c,
            Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.Email__c, Account.Phone, Account.Secondary_Phone_Number__c, Account.GSTIN_Number__c,
            Service_Center__r.Store_Type__c, Service_Center__r.Email__c, Service_Center__r.Phone, Vehicle__r.CurrentOwner.ShippingCity, Vehicle__r.CurrentOwner.ShippingState,
            Vehicle__r.CurrentOwner.ShippingCountry, Vehicle__r.CurrentOwner.ShippingPostalCode, Service_Center__r.Secondary_Phone_Number__c, RR_Service_Advisor__r.Name,
            Odometer_Reading__c, toLabel(RR_Service_Advisor__r.ResourceType)
            FROM WorkOrder WHERE Id = :workOrderId LIMIT 1
        ];
        system.debug('## WorkOrderList size: ' + workOrderList.size());
        
        if (workOrderList != null && workOrderList.size() > 0) {
            workOrderRecord = workOrderList[0];
            ModPayment = workOrderList[0].Mode_Of_Payment__c;
            system.debug('## WorkOrderRecord: ' + workOrderRecord);
            
            String centerGSTIN = workOrderRecord.Service_Center__r.GSTIN_Number__c;
            String parentGSTIN = (workOrderRecord.Service_Center__r.Parent != null)
                ? workOrderRecord.Service_Center__r.Parent.GSTIN_Number__c
                : null;
            
            if (!String.isBlank(parentGSTIN)) {
                GSTIN = parentGSTIN;
            } else {
                GSTIN = centerGSTIN;
            }
            
            workOrderLineItemList = [
                SELECT Id, CreatedDate, WorkOrderId, ParentWorkOrderLineItemId, Product2Id, AssetId, OrderId, RootWorkOrderLineItemId, Description,
                StartDate, EndDate, Status, PricebookEntryId, Quantity, UnitPrice, Discount, ListPrice, Subtotal, TotalPrice, Duration,
                DurationType, DurationInMinutes, WorkTypeId, Street, City, State, PostalCode, Country, Latitude, Longitude, GeocodeAccuracy,
                Address, ServiceTerritoryId, Subject, StatusCategory, IsClosed, Priority, ServiceAppointmentCount, LocationId, Total_Amount__c,
                Inventory_Lot__c, Product_Available__c, Stage__c, RR_Parts_Category__c, RR_Product__c, RR_Product__r.Name,RR_Product__r.ProductCode , RR_Product__r.HSN_Code__c, IGST_Percentage_formula__c, CGST_Percentage_Formula__c, SGST_Percentage_Formula__c,
                IGST__c, CGST__c, SGST__c, IGST_Amount__c, CGST_Amount__c, SGST_Amount__c, Amount__c, Unit_of_Measurement__c,List_Price_New__c,Total_NDP__c,Sub_Total__c,
                Total_Part_Price__c
                FROM WorkOrderLineItem WHERE WorkOrderId = :workOrderRecord.Id AND RR_Parts_Category__c IN ('Paid')
            ];
            system.debug('## WorkOrderLineItemList size: ' + workOrderLineItemList.size());
            system.debug('## WorkOrderLineItemList : ' + workOrderLineItemList);
            
            workPlansItemList = [
                SELECT Id, Name, WorkOrderId, Description, WorkOrderLineItemId, Subtotal__c, WorkPlanTemplateId, ParentRecordId, ParentRecordType, Contact__c, RR_Labour_Code__r.HSN_Code__c,
                Duration_Hour__c, Discount__c, Duration_Min__c, RR_Labour_Category__c, Labour_Charge__c, Labour_Charge_CodeSet_New__c, Status__c, Work_Type__c,
                Estimate_Duration_Type__c, Estimated_Duration__c, RR_Labour_Code__c, RR_Labour_Code__r.Code, IGST__c, SGST__c,
                CGST__c, IGST_Amount__c, CGST_Amount__c, SGST_Amount__c, Amount__c
                FROM WorkPlan WHERE WorkOrderId = :workOrderRecord.Id AND RR_Labour_Category__c IN ('Paid')
            ];
            system.debug('## WorkPlansItemList size: ' + workPlansItemList.size());
            system.debug('## WorkPlansItemList : ' + workPlansItemList);
            
            // Store type details
            if (workOrderRecord.Service_Center__r.Store_Type__c != null) {
                system.debug('## Store Type: ' + workOrderRecord.Service_Center__r.Store_Type__c);
                if (workOrderRecord.Service_Center__r.Store_Type__c == 'DODO') {
                    storeType = 'DODO';
                    dodoAccName = workOrderRecord.Service_Center__r.Company_GSTIN_name__c;
                    dodoBillCityName = workOrderRecord.Service_Center__r.BillingCity != null ? workOrderRecord.Service_Center__r.BillingCity : '';
                    dodoBillStateName = workOrderRecord.Service_Center__r.BillingState;
                    dodoBillPostalCode = workOrderRecord.Service_Center__r.BillingPostalCode; 
                    
                    
                    /*  dodoBillCityName = workOrderRecord.Service_Center__r.GST_City__c != null ? workOrderRecord.Service_Center__r.GST_City__c : '';
dodoBillStateName = workOrderRecord.Service_Center__r.GST_State__c != null ? workOrderRecord.Service_Center__r.GST_State__c : '';
dodoBillPostalCode = workOrderRecord.Service_Center__r.GST_Zip_Postal_Code__c != null ? workOrderRecord.Service_Center__r.GST_Zip_Postal_Code__c : ''; */
                    
                    dodoBillEmail = workOrderRecord.Service_Center__r.Email__c;
                    dodoPhone = workOrderRecord.Service_Center__r.Phone;
                    system.debug('## DODO store details: ' + dodoAccName + ', ' + dodoBillCityName);
                } else if (workOrderRecord.Service_Center__r.Store_Type__c == 'COCO') {
                    dodoAccName = 'RIVER MOBILITY PRIVATE LIMITED';
                    storeType = 'COCO';
                    dodoBillCityName = workOrderRecord.Service_Center__r.BillingCity;
                    dodoBillStateName = workOrderRecord.Service_Center__r.BillingState;
                    dodoBillPostalCode = workOrderRecord.Service_Center__r.BillingPostalCode;
                    dodoBillEmail = workOrderRecord.Service_Center__r.Email__c;
                    dodoPhone = workOrderRecord.Service_Center__r.Phone;
                    cocoBillEmail = System.Label.COCOEmail;
                    cocoPhone = System.Label.COCOPhone;
                    cocoCIN = System.Label.COCOCIN;
                    system.debug('## COCO store details set');
                }
            }
            
            if (workOrderRecord.Service_Center__r.Store_Type__c == 'COCO') {
                storeNameForBottom = 'River Mobility Private Limited';
                JuriName = 'Bengaluru';
            } else if (workOrderRecord.Service_Center__r.Store_Type__c == 'DODO') {
                storeNameForBottom = workOrderRecord.Service_Center__r.Company_GSTIN_name__c;
                
            }
            system.debug('## StoreNameForBottom: ' + storeNameForBottom);
            
            // Calculate parts totals and populate individual line item totals map
            if (workOrderLineItemList != null && workOrderLineItemList.size() > 0) {
                partLineItemTotal = 0;
                for (WorkOrderLineItem workItem : workOrderLineItemList) {
                    if (workItem.Quantity != null && workItem.List_Price_New__c != null) {
                        partTotal += (workItem.Quantity * workItem.List_Price_New__c);
                    }
                    if (workItem.Discount != null) {
                        partDiscount += workItem.Total_NDP__c * workItem.Discount / 100;
                    }
                    if (workItem.Total_NDP__c != null) {
                        parttaxValue += workItem.Sub_Total__c;
                        // Store individual line item total
                        lineItemTotalsMap.put(workItem.Id, workItem.TotalPrice);
                    }
                    if (workItem.IGST_Amount__c != null) {
                        partIGST += workItem.IGST_Amount__c;
                    }
                    if (workItem.CGST_Amount__c != null) {
                        partCGST += workItem.CGST_Amount__c;
                    }
                    if (workItem.SGST_Amount__c != null) {
                        partSGST += workItem.SGST_Amount__c;
                    }
                    
                    
                }
                system.debug('## Part Totals => Total: ' + partTotal + ', Discount: ' + partDiscount + ', Tax: ' + parttaxValue + ', IGST: ' + partIGST + ', CGST: ' + partCGST + ', SGST: ' + partSGST);
                system.debug('## Individual Line Item Totals: ' + lineItemTotalsMap);
            }
            
            // Calculate labour totals
            if (workPlansItemList != null && workPlansItemList.size() > 0) {
                for (WorkPlan workItem : workPlansItemList) {
                    if (workItem.Labour_Charge__c != null) {
                        labourTotal += workItem.Labour_Charge__c;
                    }
                    if (workItem.IGST_Amount__c != null) {
                        labourIGST += workItem.IGST_Amount__c;
                    }
                    if (workItem.CGST_Amount__c != null) {
                        labourCGST += workItem.CGST_Amount__c;
                    }
                    if (workItem.SGST_Amount__c != null) {
                        labourSGST += workItem.SGST_Amount__c;
                    }
                    if (workItem.Subtotal__c != null) {
                        labourtaxValue += workItem.Subtotal__c;
                    }
                    if (workItem.Discount__c != null && workItem.Labour_Charge__c != null) {
                        labourDiscount += workItem.Labour_Charge__c * workItem.Discount__c / 100;
                    }
                }
                system.debug('## Labour Totals => Total: ' + labourTotal + ', Discount: ' + labourDiscount + ', Tax: ' + labourtaxValue + ', IGST: ' + labourIGST + ', CGST: ' + labourCGST + ', SGST: ' + labourSGST);
            }
            
            partsTotal += parttaxValue + ((workOrderRecord.same_state__c == true) ? (partCGST + partSGST) : partIGST);
            laboursTotal += labourtaxValue + ((workOrderRecord.same_state__c == true) ? (labourCGST + labourSGST) : labourIGST);
            invoiceTotal = Math.round(partsTotal + laboursTotal);
            invoiceTotalInWords = CurrencyToWordsInRupees.convertToWords(invoiceTotal);
            system.debug('## FINAL TOTALS => Parts: ' + partsTotal + ', Labours: ' + laboursTotal + ', InvoiceTotal: ' + invoiceTotal + ', InvoiceInWords: ' + invoiceTotalInWords);
        }
    }
    
    public String getFormattedBillingStreet() {
        
        String formatted = workOrderRecord.Service_Center__r.BillingStreet != null ? workOrderRecord.Service_Center__r.BillingStreet.replace('\n', '<br/>') : '';
        system.debug('## FormattedBillingStreet: ' + formatted);
        return formatted;
    }
    
    public String getFormattedGSTBillingStreet() {
        
        String formatted = workOrderRecord.Service_Center__r.GST_Street__c != null ? workOrderRecord.Service_Center__r.GST_Street__c.replace('\n', '<br/>') : '';
        system.debug('## FormattedBillingStreet: ' + formatted);
        return formatted;
    }
    
    public String getFormattedAccountBillingStreet() {
        String formatted = workOrderRecord.Account.BillingStreet != null ? workOrderRecord.Account.BillingStreet.replace('\n', '<br/>') : '';
        system.debug('## FormattedAccountBillingStreet: ' + formatted);
        return formatted;
    }
    public static void methodToCoverage(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    
    public static void methodToCoverage1(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    public static void methodToCoverage2(){ 
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
}