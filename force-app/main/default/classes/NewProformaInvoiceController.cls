public class NewProformaInvoiceController {
    public List<OrderItem> orderItemList { get; set; }
    public Order order { get; set; }
    public String inWords { get; set; }
    public Decimal grandTotal { get; set; }
    public Decimal remainingAmount { get; set; }
    public String dodoBillEmail { get; set; }

    public NewProformaInvoiceController(ApexPages.StandardController controller) {
        try {
            Id orderId = controller.getId();

            order = [
                SELECT Id, OrderNumber, Website_Order_Id__c, Dealer__r.Name, Dealer__r.BillingCity, 
                       Dealer__r.BillingState, Dealer__r.BillingPostalCode, Dealer__r.Email__c,
                       Account.Name, Account.Phone, Account.Email__c, Account.BillingCity, 
                       Account.BillingState, Account.BillingPostalCode,Account.GSTIN_Number__c,Dealer__r.GSTIN_Number__c,
                       Total_Amount_paid__c
                FROM Order WHERE Id = :orderId
            ];

            dodoBillEmail = order.Dealer__r.Email__c;

            orderItemList = [
                SELECT Id, Product2.Name, Quantity, UnitPrice, Total_Price__c
                FROM OrderItem WHERE OrderId = :orderId
            ];

            grandTotal = 0;
            for (OrderItem oi : orderItemList) {
                grandTotal += (oi.Total_Price__c != null ? oi.Total_Price__c : 0);
            }

            remainingAmount = grandTotal - (order.Total_Amount_paid__c != null ? order.Total_Amount_paid__c : 0);

            Integer roundedValue = Math.round(remainingAmount);
            inWords = CurrencyToWordsInRupees.convertToWords(Decimal.valueOf(roundedValue));
        } catch (Exception e) {
            System.debug('Error Occurred ===> ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
}