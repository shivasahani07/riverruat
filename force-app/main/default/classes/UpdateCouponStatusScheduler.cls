global class UpdateCouponStatusScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        
        List<Coupon_Code__c> allCoupons = [
            SELECT Id, CreatedDate, Expiry_Date_Time__c, Status__c
            FROM Coupon_Code__c
            WHERE Status__c != 'Expired' AND Expiry_Date_Time__c != null
        ];
        System.debug('Number of coupons to expire: ' + allCoupons);
        
        List<Coupon_Code__c> couponsToExpire = new List<Coupon_Code__c>();
        for (Coupon_Code__c coupon : allCoupons) {
            if (coupon.CreatedDate > coupon.Expiry_Date_Time__c) {
                coupon.Status__c = 'Expired';
                couponsToExpire.add(coupon);
            }
        }
         System.debug('Number of coupons to expire: ' + couponsToExpire);
        if (!couponsToExpire.isEmpty()) {
            update couponsToExpire;
        }
    }
}