public class NewCreateReceiptRtoInsuranceController {
    
    Public Date currentDate {get;set;}
    Public Order order{get;set;}
    Public string inWords{get;set;}
    Public string invoiceId{get;set;}
    Public string height{get;set;}
    Public string DealerName{get;set;}
    public Integer rowCount { get; set; }
    Public Decimal TotalAmount{get;set;}
    public DateTime currentTime { get; set; }
    Public Contact contact{get;set;}
    public DeliveryChallanPDF__mdt dcPdf { get; set; }
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
    public Company_Details__mdt compDetails{get;set;}
    list<Order> ordersToUpdate = new List<Order>();
    
    public String getFormattedBillingStreet() {
        return order.Dealer__r.BillingStreet != null ? order.Dealer__r.BillingStreet.replace('\n', '<br/>') : '';
    }
    public String getFormattedAccountBillingStreet() {
        return order.Account.BillingStreet != null ? order.Account.BillingStreet.replace('\n', '<br/>') : '';
    }
    Public NewCreateReceiptRtoInsuranceController(ApexPages.StandardController controller){
        try{
            Id orderId = controller.getId();
            compDetails = [SELECT Id, DeveloperName, Account_Number__c, Bank_Name__c, Beneficiary_Name__c, CIN__c, Contact__c,  Email__c, GST__c, IFSC__c, PAN__c, Swift_Code__c  FROM Company_Details__mdt  WHERE DeveloperName='River_Mobility_Private_Limited' LIMIT 1];
            
            order= [SELECT Id,AccountId,Account.Store_Type__c,Finance_Name__c, OrderNumber, Invoice_No__c, BillingCity, Dealer__c, BillingCountry, BillingPostalCode, BillingState, BillingStreet, ShippingCity,Website_Order_Id__c,Approval_Status__c,
                    ShippingCountry, ShippingPostalCode, ShippingState, ShippingStreet, RTO_Charges__c, Handling_Charges__c, Insurance_Amount__c, Warranty_Amount__c,
                    Account.Name,Account.GSTIN_Number__c ,Name,Account.Phone,Account.Secondary_Phone_Number__c,Account.Email__c, Account.BillingCity,Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet,                
                    Extended_Warranty__c, Grand_Total__c, Total_Amount_paid__c, Remaining_Amount__c,
                    Dealer__r.CIN__c, Dealer__r.RR_Customer_Care_Email__c, Dealer__r.RR_Customer_HelpLine_Number__c, Dealer__r.Email__c,  Dealer__r.GSTIN_Number__c,  Dealer__r.Phone, 
                    Dealer__r.BillingCity, Dealer__r.BillingCountry, Dealer__r.BillingPostalCode, Dealer__r.BillingState, Dealer__r.BillingStreet, Dealer__r.Name,Dealer__r.Store_Type__c  FROM Order  WHERE Id=:orderId ];
            
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
            
            List<Contact> contacts = [SELECT Id, Name, Email, Phone, MailingCity, MailingCountry, MailingPostalCode, MailingState, MailingStreet    FROM Contact   WHERE AccountId = :order.AccountId AND Primary_Contact__c = true  LIMIT 1];
            
            If(contacts.size()>0){
                contact = contacts[0];
            }
            
            currentDate = Date.today();
            
             System.debug('order # 1 === >'+order);
            //InvoiceId generation
            If(order.Website_Order_Id__c != null){
                Integer stringLength = order.Website_Order_Id__c.length();        
                invoiceId = 'RVRE'+ order.Website_Order_Id__c.substring(stringLength - 4, stringLength)+'RTO';
                System.debug('invoiceId ==>'+invoiceId);
            }
            else{
                invoiceId = order.OrderNumber;
                System.debug('invoiceId ==>'+invoiceId);
            }
            
            //Time calculation
            DateTime currentDateTime = System.now();
            
            // Set the time zone to Indian Standard Time (IST)
            TimeZone istTimeZone = TimeZone.getTimeZone('Asia/Kolkata');
            currentTime = currentDateTime.addSeconds(istTimeZone.getOffset(currentDateTime) / 1000);
            
            //height calculation
            
            If((order.Insurance_Amount__c != null && order.Insurance_Amount__c != 0 ) && (order.RTO_Charges__c != null && order.RTO_Charges__c != 0)){
                rowCount = 2;
            }else If((order.Insurance_Amount__c != null && order.Insurance_Amount__c != 0 ) || (order.RTO_Charges__c != null && order.RTO_Charges__c != 0)){
                rowCount = 1;
            }else{
                rowCount = 1;
            }
            
            height = string.valueOf(180 - (rowCount*20 - 1))+'px';
            
            TotalAmount = 0;        
            
            TotalAmount = (order.Insurance_Amount__c != null?order.Insurance_Amount__c:0) +(order.RTO_Charges__c != null?order.RTO_Charges__c:0) ;
            system.debug('TotalAmount==='+TotalAmount);
            TotalAmount = TotalAmount.setscale(2);
            
            if(TotalAmount < 0){
                TotalAmount = 0;
            }
            system.debug('TotalAmount === >'+TotalAmount);
            Integer roundedValue = TotalAmount.round().intValue();
            system.debug('roundedValue === >'+roundedValue);
            inWords = CurrencyToWordsInRupees.convertToWords(Decimal.valueOf(roundedValue));
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    } 
}