public without sharing class DiscrepancyLotController {
    @AuraEnabled(cacheable=true)
    public static List<Discrepancy_Line_Item__c> getLineItemsForShipment(Id shipmentId) {
        System.debug('Shipment ID: ' + shipmentId);
        if (shipmentId == null) {
            throw new AuraHandledException('Shipment ID is required.');
        }

        return [
            SELECT Id, Name,Product_Name__c,Quantity__c,Claimed_Amount__c,Shipment__c,Discrepancy__r.Name,Warehouse_Approval__c
            FROM Discrepancy_Line_Item__c
            WHERE Discrepancy__r.Shipment_Item__r.Parent_Shipment__c = :shipmentId
            AND Warehouse_Approval__c = 'Initiate Part Request'
        ];
    }

  @AuraEnabled
public static String createDiscrepancyLot(
    String handoverPerson,
    String requesterName,
    String phone,
    Date dispathcdate,
    String purpose,
    String addressOfConsignee,
    String modeOfTransport,
    List<Id> lineItemIds
) {
    try {
        if (lineItemIds == null || lineItemIds.isEmpty()) {
            throw new AuraHandledException('No line items selected.');
        }

        // 1. Create Discrepancy Lot
        Discrepancy_Lot__c newLot = new Discrepancy_Lot__c();
        newLot.Handover_Person_Store__c = handoverPerson;
        newLot.Requestor_Name__c = requesterName;
        newLot.Phone__c = phone;
        newLot.Purpose_of_Sending__c = purpose;
        newLot.Status__c = 'New';
        newlot.Date_of_Dispatch__c= dispathcdate;
        insert newLot;

        // 2. Update Line Items
        List<Discrepancy_Line_Item__c> toUpdate = [
            SELECT Id FROM Discrepancy_Line_Item__c WHERE Id IN :lineItemIds
        ];

        for (Discrepancy_Line_Item__c item : toUpdate) {
            item.Discrepancy_Lot__c = newLot.Id;
            item.Is_Dispatch__c = True;
        }
        update toUpdate;

        // 3. Send email to fixed email address
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { 'lokhandeshubham772@gmail.com' });
        mail.setSubject('New Discrepancy Lot Created');

        String body = 'Dear Warehouse Team,\n\n' +
            'A new Discrepancy Lot has been created.\n\n' +
            'Discrepancy Lot ID: ' + newLot.Id + '\n\n' +
            'Please take necessary action.\n\n' +
            'Regards,\nSalesforce System';

        mail.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        System.debug('Email sent to lokhandeshubham772@gmail.com');

        return newLot.Id;

    } catch (Exception e) {
        System.debug('Error: ' + e.getMessage());
        throw new AuraHandledException('Error creating Discrepancy Lot: ' + e.getMessage());
    }
}



}