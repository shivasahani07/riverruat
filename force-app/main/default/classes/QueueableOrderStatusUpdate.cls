public class QueueableOrderStatusUpdate implements Queueable, Database.AllowsCallouts {
    Set<Id> orderIds;
    public static final Id vehicleRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
    public QueueableOrderStatusUpdate(Set<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(QueueableContext context) {
        List<Order> ordersToUpdate = new List<Order>();

        for (Order ord : [
            SELECT Id, Remaining_Amount__c, Assigned_Vehicle__c,Payment_status__c, Status, RecordType.DeveloperName
            FROM Order
            WHERE Id IN :orderIds
        ]) {
            if (ord.RecordTypeId == vehicleRecordTypeId) {
                if (ord.Remaining_Amount__c == 0 && ord.Assigned_Vehicle__c != null) {
                    ord.Status = 'Pre Invoice';
                    ord.Payment_status__c = 'Completed';
                }
                ordersToUpdate.add(ord);
            }
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
}