public class NewCreateReceiptOChargesController {
    
    Public Date currentDate {get;set;}
    Public Order order{get;set;}
    Public string inWords{get;set;}
    Public string invoiceId{get;set;}
    Public string height{get;set;}
    Public string height2{get;set;}
    Public string height3{get;set;}
    Public string DealerName{get;set;}
    public Integer rowCount { get; set; }
    Public Decimal Gst{get;set;}
    Public Decimal taxableAmount{get;set;}
    Public Decimal TotalAmount{get;set;}
    
    Public Decimal HcgstPercent{get;set;}
    Public Decimal WcgstPercent{get;set;}
    Public Decimal HsgstPercent{get;set;}
    Public Decimal WsgstPercent{get;set;}
    Public Decimal HigstPercent{get;set;}
    Public Decimal WigstPercent{get;set;}
    
    Public Decimal cgst{get;set;}
    Public Decimal sgst{get;set;}
    Public Decimal igst{get;set;}
    
    Public Decimal Htax{get;set;}
    Public Decimal WTax{get;set;}
    Public Contact contact{get;set;}
    public Company_Details__mdt compDetails{get;set;}
    public DeliveryChallanPDF__mdt dcPdf { get; set; }
    Public string state{get;set;}
    public string AccState{get;set;}
    public boolean sameState{get;set;} 
    public string dodoAccName { get; set; }
    public string dodoBillCityName { get; set; }
    public string dodoBillStateName { get; set; }
    public string dodoBillPostalCode { get; set; }
    public string dodoBillEmail { get; set; }
    public String dodoPhone { get; set; }
    public string cocoBillEmail { get; set; }
    public String cocoPhone { get; set; }
    public String cocoCIN { get; set; }
    public String storeType { get; set; }
    
    public String getFormattedBillingStreet() {
        return order.Dealer__r.BillingStreet != null ? order.Dealer__r.BillingStreet.replace('\n', '<br/>') : '';
    }
    public String getFormattedAccountBillingStreet() {
        return order.Account.BillingStreet != null ? order.Account.BillingStreet.replace('\n', '<br/>') : '';
    }
    
    Public NewCreateReceiptOChargesController(ApexPages.StandardController controller){
        try{
            Id orderId = controller.getId();
            compDetails = [SELECT Id, DeveloperName, Account_Number__c, Bank_Name__c, Beneficiary_Name__c, CIN__c, Contact__c, Email__c, GST__c, IFSC__c, PAN__c, Swift_Code__c  FROM Company_Details__mdt  WHERE DeveloperName='River_Mobility_Private_Limited' LIMIT 1];
            
            order = [SELECT Id,AccountId, OrderNumber, BillingCity, Dealer__c, BillingCountry, BillingPostalCode, BillingState, BillingStreet, ShippingCity,Website_Order_Id__c,Approval_Status__c,
                     ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet, RTO_Charges__c, Handling_Charges__c, Insurance_Amount__c, Warranty_Amount__c,Transportation_Charges__c,
                     Account.Name,Dealer__r.Store_Type__c, Finance__r.Name,Account.GSTIN_Number__c, Account.Phone,Account.Secondary_Phone_Number__c,Account.Email__c, Account.BillingCity,Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet,                
                     Extended_Warranty__c,Dealer__r.Center_Code__c, Dealer__r.Name, Dealer__r.BillingCity,Dealer__r.BillingCountry, Dealer__r.BillingPostalCode, Dealer__r.BillingState, Dealer__r.BillingStreet, Internal_Purchase__c,
                     Dealer__r.CIN__c, Dealer__r.RR_Customer_Care_Email__c, Dealer__r.RR_Customer_HelpLine_Number__c, Dealer__r.Email__c,  Dealer__r.GSTIN_Number__c,  Dealer__r.Phone,
                     Dealer__r.Beneficiary_Name__c, Dealer__r.Account_Number__c, Dealer__r.Bank_Name__c, Dealer__r.Swift_Code__c, Dealer__r.IFSC__c, Dealer__r.PAN_Number__c  FROM Order  WHERE Id=:orderId ]; 
            
            dcPdf = [SELECT Id, CIN__c, Company_Email__c, Company_Phone__c, Company_Website__c, CompanyName__c, Factory_Address__c, Former_Address__c, GST__c, Registered_Office__c,  Bill_From__c, Bill_To__c, PartA__c, Small_CName__c   FROM DeliveryChallanPDF__mdt] ;
            
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
                    dodoBillEmail = order.Dealer__r.Email__c;
                    dodoPhone = order.Dealer__r.Phone;
                    cocoBillEmail = system.Label.COCOEmail;
                    cocoPhone = System.label.COCOPhone;
                    cocoCIN = System.label.COCOCIN;
                }
            }
            
            
            DealerName = order.Dealer__r.Name.toUpperCase();
            
            List<Contact> contacts = [SELECT Id, Name, Email, Phone, MailingCity, MailingCountry, MailingPostalCode, MailingState, MailingStreet    FROM Contact  WHERE AccountId = :order.AccountId AND Primary_Contact__c = true  LIMIT 1];
            
            If(contacts.size()>0){
                contact = contacts[0];
            }
            
            sameState = true;
            
            If(order.Dealer__c != null && order.Dealer__r.BillingState != null){
                state = order.Dealer__r.BillingState.toLowerCase();
            }else If(order.BillingState != null){
                state = order.BillingState.toLowerCase();
            }else If(order.Account.BillingState != null){
                state = order.Account.BillingState.toLowerCase();
            }else{
                state = 'ka';
            }
            
            If(order.Account.BillingState != null){
                AccState = order.Account.BillingState.toLowerCase();
            }else If(contact != null && contact.MailingState != null && Contact.MailingState != ''){
                AccState = contact.MailingState.toLowerCase();
            }else{
                AccState = state;
            }
            
            If(AccState != state){
                sameState = GenericClass.checkStatePicklistvalue(AccState, state);
            }
            
            //InvoiceId generation
            string invoicesequence = System.currentPageReference().getParameters().get('sequence');
            If(invoicesequence != null && invoicesequence != ''){
                invoiceId = invoicesequence;
            }else{
                invoiceId = 'RV_PREINVOICE_OC';
            }
            System.debug('invoiceId>>'+invoiceId);
            
            currentDate = Date.today();
            
            //Page Height calulation
            if (order.Extended_Warranty__c != false) {
                // Extended Warranty is true
                if (order.Handling_Charges__c != null && order.Handling_Charges__c != 0) {
                    height = 'auto;';
                    height2 = '150px;';
                } else {
                    // Handling Charges is empty
                    height = 'auto;';
                    height2 = '180px;';
                }
            } else {
                // Extended Warranty is false
                if (order.Handling_Charges__c != null && order.Handling_Charges__c != 0) {
                    // Handling Charges is not empty
                    height = '180px;';
                    height2 = '150px;';
                } else {
                    // Handling Charges is empty
                    height = '180px;';
                    height2 = ''; 
                }
            }
            
            WcgstPercent = 9;
            WsgstPercent = 9;
            WigstPercent = 18;
            HcgstPercent = 9;
            HsgstPercent = 9;
            HigstPercent = 18;
            cgst = 0;
            sgst = 0;
            igst = 0;
            
            List<Tax_Detail__mdt> taxMetadata = [SELECT Id, DeveloperName, CGST__c, SGST__c, IGST__c FROM Tax_Detail__mdt WHERE DeveloperName IN ('Handling_Charges_Tax','Extended_Warranty_Tax')];
            
            For(Tax_Detail__mdt taxdata: taxMetadata){
                If(taxdata.DeveloperName == 'Handling_Charges_Tax'){
                    HcgstPercent = taxdata.CGST__c;
                    HsgstPercent = taxdata.SGST__c;
                    HigstPercent = taxdata.IGST__c;
                }else If(taxdata.DeveloperName == 'Extended_Warranty_Tax'){
                    WcgstPercent = taxdata.CGST__c;
                    WsgstPercent = taxdata.SGST__c;
                    WigstPercent = taxdata.IGST__c;
                }
            }
            
            TotalAmount = 0;
            taxableAmount = 0;
            Htax = 0;
            Wtax=0;
            
            TotalAmount = order.Handling_Charges__c != null?order.Handling_Charges__c:0;
            TotalAmount = TotalAmount.setscale(2);
            If(!order.Internal_Purchase__c){
                Decimal handlingCharge = (order.Handling_Charges__c != null?order.Handling_Charges__c:0);
                Decimal warrantyAmount = (order.Warranty_Amount__c != null?order.Warranty_Amount__c:0);
                
                system.debug('sameState>>'+sameState);
                
                if(sameState){
                    
                    Decimal unitPriceH = handlingCharge / (1+(HsgstPercent/100) + (HcgstPercent/100));
                    Decimal unitPriceW = warrantyAmount / (1+(WcgstPercent/100) + (WsgstPercent/100));
                    
                    cgst = unitPriceH * (HcgstPercent/100);
                    sgst = unitPriceH * (HsgstPercent/100);
                    
                    
                    system.debug('unitPriceH>>'+unitPriceH);
                    system.debug('HigstPercent>>'+HigstPercent);
                    system.debug('unitPriceW>>'+unitPriceW);
                    system.debug('WigstPercent>>'+WigstPercent);
                    system.debug('igst>>'+igst);
                    system.debug('cgst>>'+cgst);
                    system.debug('sgst>>'+sgst);
                    
                    Htax = (handlingCharge - unitPriceH);
                    Wtax = (warrantyAmount - unitPriceW);
                    
                }else{
                    Decimal unitPriceH = handlingCharge / (1+(HigstPercent/100));
                    Decimal unitPriceW = warrantyAmount / (1+(WigstPercent/100));
                    
                    igst = unitPriceH * (HigstPercent/100) + unitPriceW *(WigstPercent/100);
                    
                    Htax = (handlingCharge - unitPriceH);
                    Wtax = (warrantyAmount - unitPriceW);
                }
                
                taxableAmount = TotalAmount - Htax;
                taxableAmount= taxableAmount;
            }else{
                Htax=0;
                Wtax=0;
                taxableAmount = TotalAmount;
                taxableAmount= taxableAmount;
                Gst = 0;
                Gst= Gst;
            }
            
            if(taxableAmount < 0){
                taxableAmount = 0;
            }
            system.debug('taxableAmount === >'+taxableAmount);
            Integer roundedValue = (Integer) Math.Round(TotalAmount);

            system.debug('roundedValue === >'+roundedValue);
            inWords = CurrencyToWordsInRupees.convertToWords(Decimal.valueOf(roundedValue));
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
}