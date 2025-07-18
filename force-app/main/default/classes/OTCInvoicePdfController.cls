public class OTCInvoicePdfController {
    public List<OrderItem> orderItemList { get; set; }
    public Date currentDate { get; set; }
    public Order order { get; set; }
    public String inWords { get; set; }
    public String invoiceId { get; set; }
    public Contact contact { get; set; }
    public String DealerName { get; set; }
    public Company_Details__mdt compDetails { get; set; }
    public String state { get; set; }
    public Decimal calcValue { get; set; }
    public Decimal tValueAftGST { get; set; }
    public Decimal offerAmount { get; set; }
    public Decimal NetAmount { get; set; }
    public String AccState { get; set; }
    public Boolean sameState { get; set; }
    public Decimal cgstPercentage { get; set; }
    public Decimal sgstPercentage { get; set; }
    public Decimal igstPercentage { get; set; }
    public Decimal trcgstPercentage { get; set; }
    public Decimal trsgstPercentage { get; set; }
    public Decimal trigstPercentage { get; set; }
    public DeliveryChallanPDF__mdt dcPdf { get; set; }

    public String dodoAccName { get; set; }
    public String dodoBillCityName { get; set; }
    public String dodoBillStateName { get; set; }
    public String dodoBillPostalCode { get; set; }
    public String dodoBillEmail { get; set; }
    public String dodoPhone { get; set; }
    public string cocoBillEmail { get; set; }
    public String cocoPhone { get; set; }
    public String cocoCIN { get; set; }

    public Decimal totalValueAfterGST { get; set; }
    public String storeType { get; set; }
    public Decimal totalValueAfterAllTaxes { get; set; }
    public Decimal AccessoriesDiscountAmountOnOrder { get; set; }

    public String getFormattedBillingStreet() {
        return order.Dealer__r.BillingStreet != null ? order.Dealer__r.BillingStreet.replace('\n', '<br/>') : '';
    }

    public String getFormattedAccountBillingStreet() {
        return order.Account.BillingStreet != null ? order.Account.BillingStreet.replace('\n', '<br/>') : '';
    }

    public OTCInvoicePdfController(ApexPages.StandardController controller) {
        try {
            dcPdf = [SELECT Id, CIN__c, Company_Email__c, Company_Phone__c, Company_Website__c, CompanyName__c, Factory_Address__c, Former_Address__c, GST__c, Registered_Office__c, Bill_From__c, Bill_To__c, PartA__c, Small_CName__c FROM DeliveryChallanPDF__mdt];
            cgstPercentage = 2.5;
            sgstPercentage = 2.5;
            igstPercentage = 5;
            totalValueAfterGST = 0;
            totalValueAfterAllTaxes = 0;
            AccessoriesDiscountAmountOnOrder = 0;

            Id orderId = controller.getId();
            compDetails = [SELECT Id, DeveloperName, Account_Number__c, Bank_Name__c, Beneficiary_Name__c, CIN__c, Contact__c, Email__c, GST__c, IFSC__c, PAN__c, Swift_Code__c FROM Company_Details__mdt WHERE DeveloperName='River_Mobility_Private_Limited' LIMIT 1];

            order = [SELECT Id, AccountId, OrderNumber, BillingCity, BillingCountry, Dealer__c, BillingPostalCode, BillingState, BillingStreet, ShippingCity, Website_Order_Id__c, Approval_Status__c,
                        ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet, RTO_Charges__c, Handling_Charges__c, Insurance_Amount__c, Warranty_Amount__c,
                        Account.Name, Account.Phone, Account.Email__c, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet,
                        Assigned_Vehicle__r.VehicleIdentificationNumber, Assigned_Vehicle__r.VehicleDefinition.ModelCode, Assigned_Vehicle__r.EngineNumber, Assigned_Vehicle__r.Colour__c,
                        Assigned_Vehicle__r.VehicleDefinition.Battery_Name__c, Assigned_Vehicle__r.VehicleDefinition.Battery_Quantity__c, Assigned_Vehicle__r.VehicleDefinition.BatteryCapacity,
                        Assigned_Vehicle__r.Name, Finance__r.Name, Assigned_Vehicle__r.VehicleDefinition.Battery_Capacity__c, Assigned_Vehicle__r.Vehicle_Details__c, Dealer__r.Name, Dealer__r.Center_Code__c,
                        Dealer__r.BillingCity, Dealer__r.BillingCountry, Dealer__r.BillingPostalCode, Dealer__r.BillingState, Dealer__r.BillingStreet, Transportation_Charges__c, Internal_Purchase__c,
                        Discount_on_Ex_Showroom_Price__c, Subsidy_Amount__c, State_Govt_Subsidy__c, Offers_Amount__c, Accessories_Discount_Amount__c,
                        Dealer__r.CIN__c, Dealer__r.RR_Customer_Care_Email__c, Dealer__r.RR_Customer_HelpLine_Number__c, Dealer__r.Email__c, Dealer__r.GSTIN_Number__c, Dealer__r.Phone,
                        Dealer__r.Beneficiary_Name__c, Dealer__r.Account_Number__c, Dealer__r.Bank_Name__c, Dealer__r.Swift_Code__c, Dealer__r.IFSC__c, Dealer__r.PAN_Number__c,
                        IRN_No__c, Account.GSTIN_Number__c, Dealer__r.Store_Type__c, OTC_Total_Product_Discount_Amount__c, OTC_Additional_Discount_Amount__c FROM Order WHERE Id = :orderId];

            if (order.Dealer__r.Store_Type__c != null) {
                if (order.Dealer__r.Store_Type__c == 'DODO') {
                    storeType = 'DODO';
                    dodoAccName = order.Dealer__r.Name;
                    dodoBillCityName = order.Dealer__r.BillingCity != null ? order.Dealer__r.BillingCity : '';
                    dodoBillStateName = order.Dealer__r.BillingState;
                    dodoBillPostalCode = order.Dealer__r.BillingPostalCode;
                    dodoBillEmail = order.Dealer__r.Email__c;
                    dodoPhone = order.Dealer__r.Phone;
                } else if (order.Dealer__r.Store_Type__c == 'COCO') {
                    dodoAccName = 'RIVER MOBILITY PRIVATE LIMITED';
                    storeType = 'COCO';
                    dodoBillCityName = order.Dealer__r.BillingCity;
                    dodoBillStateName = order.Dealer__r.BillingState;
                    dodoBillPostalCode = order.Dealer__r.BillingPostalCode;
                    cocoBillEmail = system.Label.COCOEmail;
                    cocoPhone = System.label.COCOPhone;
                    cocoCIN = System.label.COCOCIN;
                }
            }

            DealerName = order.Dealer__r.Name != null ? order.Dealer__r.Name.toUpperCase() : '';

            List<Contact> contacts = [SELECT Id, Name, Email, Phone, MailingCity, MailingCountry, MailingPostalCode, MailingState, MailingStreet FROM Contact WHERE AccountId = :order.AccountId AND Primary_Contact__c = true LIMIT 1];
            if (contacts.size() > 0) {
                contact = contacts[0];
            }

            sameState = true;

            if (order.Dealer__c != null && order.Dealer__r.BillingState != null) {
                state = order.Dealer__r.BillingState.toLowerCase();
            } else if (order.BillingState != null) {
                state = order.BillingState.toLowerCase();
            } else if (order.Account.BillingState != null) {
                state = order.Account.BillingState.toLowerCase();
            } else {
                state = 'ka';
            }

            if (order.Account.BillingState != null) {
                AccState = order.Account.BillingState.toLowerCase();
            } else if (contact != null && contact.MailingState != null && contact.MailingState != '') {
                AccState = contact.MailingState.toLowerCase();
            } else {
                AccState = state;
            }

            if (AccState != state) {
                sameState = GenericClass.checkStatePicklistvalue(AccState, state);
            }

            currentDate = Date.today();
            AccessoriesDiscountAmountOnOrder = order.OTC_Additional_Discount_Amount__c != null ? order.OTC_Additional_Discount_Amount__c : 0;

            orderItemList = [SELECT Id, HSN_Code__c, Quantity, UnitPrice, TotalPrice, Description, Order.Invoice_No__c, Charger_Included__c, Product2.CGST_Percentage__c, Product2.IGST_Percentage__c, Product2.SGST_Percentage__c, OrderItemNumber, Product2.Name,
                             Taxable_Amount__c, Product_IGST__c, Product_IGST_Amount__c, Product_CGST__c, Product_CGST_Amount__c, Product_SGST__c, Product_SGST_Amount__c, Product_Total_Amount__c, Order.Accessories_Discount_Amount__c, Product_Accessories_Taxable_Amount__c,
                             Product2.Merchandise_discount_price__c, Discounted_Amount_on_Merchandise__c, Type__c FROM OrderItem WHERE OrderId = :orderId AND Type__c IN ('Accessories', 'Merchandise', 'Extended Warranty', 'Road side assistance', 'Parts')];

            for (OrderItem oi : orderItemList) {
                if (oi.Product2 != null) {
                    totalValueAfterAllTaxes += oi.Product_Total_Amount__c;
                    Decimal igstMultiplier = 1 + (oi.Product2.IGST_Percentage__c / 100);
                    Decimal igstAmount = (oi.UnitPrice * oi.Quantity * igstMultiplier);
                    totalValueAfterGST += igstAmount;
                }
            }

            String invoicesequence = System.currentPageReference().getParameters().get('sequence');
            invoiceId = (invoicesequence != null && invoicesequence != '') ? invoicesequence : 'RV_INVOICE_VH';

            NetAmount = Math.round(totalValueAfterAllTaxes - AccessoriesDiscountAmountOnOrder);
            inWords = CurrencyToWordsInRupees.convertToWords(NetAmount);
        } catch (Exception e) {
            System.debug('Error Occured===>>' + e.getMessage() + ' And Error occured in Line Number====>' + e.getLineNumber());
        }
    }
}