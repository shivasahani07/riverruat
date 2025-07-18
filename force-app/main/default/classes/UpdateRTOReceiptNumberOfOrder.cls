public class UpdateRTOReceiptNumberOfOrder {
    
    
    public static void updateRTOReceiptNumbers(Map<Id, String> orderIdToInvoiceMap) {
        try {
            
            List<Order> ordersToUpdate = [SELECT Id, RTO_Receipt_Number__c FROM Order WHERE Id IN :orderIdToInvoiceMap.keySet()];
            
            
            for (Order ord : ordersToUpdate) {
                ord.RTO_Receipt_Number__c = orderIdToInvoiceMap.get(ord.Id);
            }
            
            
            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
            }
            
        } catch (Exception e) {
            System.debug('Error updating RTO Receipt Numbers: ' + e.getMessage());
        }
    }
    
}