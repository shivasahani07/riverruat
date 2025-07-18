public without sharing class CouponCodeService {

    public static void cancelCouponsIfOrderCancelled(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        if (newOrders == null || newOrders.isEmpty()) {
            System.debug('No new Order records provided. Exiting.');
            return;
        }

        try {
            Set<Id> ordersToProcess = new Set<Id>();
            for (Order newOrder : newOrders) {
                Order oldOrder = oldOrderMap.get(newOrder.Id);
                if (newOrder.Status == 'Order Cancelled' && (oldOrder == null || oldOrder.Status != 'Order Cancelled')) {
                    ordersToProcess.add(newOrder.Id);
                }
            }

            if (ordersToProcess.isEmpty()) {
                System.debug('No Orders transitioned to Cancelled status. Exiting.');
                return;
            }

            System.debug('Processing coupon cancellations for Order IDs: ' + ordersToProcess);

            List<Coupon_Code__c> couponsToCancel = [
                SELECT Id, Status__c, Order__c, Coupon__c
                FROM Coupon_Code__c
                WHERE Order__c IN :ordersToProcess
                AND Status__c != 'Cancelled'
            ];

            System.debug('Found ' + couponsToCancel.size() + ' coupon(s) to check for cancellation.');

            List<Coupon_Code__c> couponsToUpdate = new List<Coupon_Code__c>();
            for (Coupon_Code__c coupon : couponsToCancel) {
                if (coupon.Coupon__c != null && coupon.Coupon__c.toUpperCase().startsWith('RVAC')) {
                    coupon.Status__c = 'Cancelled';
                    couponsToUpdate.add(coupon);
                }
            }

            if (!couponsToUpdate.isEmpty()) {
                update couponsToUpdate;
                System.debug('Updated ' + couponsToUpdate.size() + ' coupon(s) to status Cancelled.');
            } else {
                System.debug('No coupons with prefix "RVAC" found to cancel.');
            }
        } catch (Exception e) {
            System.debug('Error while cancelling coupons: ' + e.getMessage());
        }
    }
}