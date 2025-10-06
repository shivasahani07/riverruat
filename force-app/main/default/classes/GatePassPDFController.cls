public without sharing class GatePassPDFController {
    public Order ord { get; private set; }
    public List<Attachment> QRAtt {get;set;}
    public Boolean hasError { get; private set; }
    public String errorMessage { get; private set; }

    public GatePassPDFController() {
        hasError = false;
        errorMessage = '';
        try {
            String orderIdParam = ApexPages.currentPage().getParameters().get('id');
            String qrAttachmentId = ApexPages.currentPage().getParameters().get('qrAttachmentId');
            if (String.isBlank(orderIdParam)) {
                throw new IllegalArgumentException('Order ID parameter is missing');
            }
            Id orderId = Id.valueOf(orderIdParam);
            ord = getOrderDetails(orderId);
            if (ord == null) {
                throw new IllegalArgumentException('Order not found with ID: ' + orderId);
            }
            QRAtt = [SELECT Id, Body, Name FROM Attachment WHERE Id = :qrAttachmentId];
        } catch (Exception e) {
            hasError = true;
            errorMessage = 'Error generating gate pass: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Exception in GatePassPDFController: ' + e.getMessage());
        }
    }

    private Order getOrderDetails(Id orderId) {
        try {
            return [SELECT Id, OrderNumber, Assigned_Vehicle__r.VehicleIdentificationNumber, Assigned_Vehicle__r.VehicleRegistrationNumber, Account.Name, Delivery_Date__c, Dealer__r.Name, Gate_Pass_Issuer__c, Gate_Pass_Generated_Date_Time__c FROM Order WHERE Id = :orderId LIMIT 1];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception fetching order details: ' + e.getMessage());
            return null;
        }
    }
}