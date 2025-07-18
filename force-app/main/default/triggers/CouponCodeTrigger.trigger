trigger CouponCodeTrigger on Coupon_Code__c (after insert) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
            CouponCodeEmailHandler.sendCouponEmails(Trigger.new);
    }
}