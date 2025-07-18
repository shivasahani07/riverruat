/**
 * @description       : 
 * @author            : Ram Kumar
 * @group             : 
 * @last modified on  : 
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class CouponCodeRedemptionhandler {

    @AuraEnabled(cacheable=true)
    public static List<Case> getAccountCasesWithCoupons(Id accountId) {
        System.debug('Entering getAccountCasesWithCoupons. AccountId: ' + accountId);
        try {
            List<Case> caseList = [
                SELECT Id,
                       Type,
                       RecordType.Name,
                       Account.AccountSource,
                       (SELECT Id, Coupon__c, Status__c, Value__c FROM Coupon_Codes__r)
                FROM Case
                WHERE AccountId = :accountId
                  AND RecordType.Name = 'General Query'
                  AND Case_Type__c = 'Coupon'
            ];
            System.debug('Number of cases retrieved: ' + caseList.size());
            System.debug('Case record: ' + caseList);
            return caseList;
        } catch (Exception ex) {
            System.debug('Exception in getAccountCasesWithCoupons: ' + ex.getMessage());
            throw new AuraHandledException('Error retrieving coupon-related cases.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderItems(Id orderId) {
        System.debug('Entering getOrderItems. OrderId: ' + orderId);
        try {
            List<OrderItem> orderItemList = [
                SELECT Id, Type__c
                FROM OrderItem
                WHERE OrderId = :orderId
            ];
            System.debug('Number of order items retrieved: ' + orderItemList.size());
            return orderItemList;
        } catch (Exception ex) {
            System.debug('Exception in getOrderItems: ' + ex.getMessage());
            throw new AuraHandledException('Error retrieving order items.');
        }
    }

  @AuraEnabled
    public static void applyCouponToOrder(Id orderId, Id couponId, String prefix, Decimal couponValue, String couponCode) {
        try {
            System.debug('applyCouponToOrder called with orderId=' + orderId + ', couponId=' + couponId + ', prefix=' + prefix + ', couponValue=' + couponValue + ', couponCode=' + couponCode);

            List<Redemption__c> previousRedemptions = [
                SELECT Value_Redeemed__c FROM Redemption__c WHERE Coupon_Code__c = :couponId
            ];
            Decimal totalPreviouslyRedeemed = 0;
            for (Redemption__c red : previousRedemptions) {
                totalPreviouslyRedeemed += red.Value_Redeemed__c != null ? red.Value_Redeemed__c : 0;
            }
            System.debug('Total previously redeemed amount: ' + totalPreviouslyRedeemed);

            Decimal remainingCouponValue = couponValue - totalPreviouslyRedeemed;
            if (remainingCouponValue <= 0) {
                throw new AuraHandledException('This coupon has already been fully redeemed.');
            }

            List<OrderItem> orderItems = [
                SELECT Id, Type__c, Taxable_Amount__c, UnitPrice
                FROM OrderItem
                WHERE OrderId = :orderId
            ];
            System.debug('Order items retrieved: ' + orderItems.size());

            Set<String> validTypes = new Set<String>();
            Boolean skipTypeFilter = false;

            switch on prefix {
                when 'CCGWAC' {
                    validTypes.addAll(new List<String>{'Accessories', 'Parts', 'Road side assistance', 'Extended Warrenty', 'Add-ons'});
                }
                when 'CCGWRG' {
                    validTypes.add('Merchandise');
                }
                when 'CCGWVH' {
                    validTypes.add('Vehicle');
                }
                when 'RVAC' {
                    validTypes.addAll(new List<String>{'Accessories', 'Parts'});
                }
                when 'CCGWGR' {
                    skipTypeFilter = true;
                }
                when else {
                    throw new AuraHandledException('Unsupported coupon');
                }
            }

            Decimal totalTaxableAmount = 0;
            for (OrderItem item : orderItems) {
                if (skipTypeFilter || validTypes.contains(item.Type__c)) {
                    totalTaxableAmount += item.UnitPrice != null ? item.UnitPrice : 0;
                }
            }
            System.debug('Total taxable amount calculated: ' + totalTaxableAmount);

            if (totalTaxableAmount == 0) {
                throw new AuraHandledException('No applicable order items for this coupon.');
            }

            Decimal redeemedAmount = Math.min(remainingCouponValue, totalTaxableAmount);
            System.debug('Redeemed amount to apply now: ' + redeemedAmount);

            Redemption__c redemption = new Redemption__c();
            redemption.Coupon_Code__c = couponId;
            redemption.Redeemed_On__c = System.Now();
            redemption.Value_Redeemed__c = redeemedAmount;
            redemption.Status__c = 'Success';
            insert redemption;
            System.debug('Redemption record inserted: ' + redemption.Id);

            Order orderUpdate = new Order(Id = orderId);
            orderUpdate.Coupon_Code__c = couponCode;
            orderUpdate.Coupon_Redeemed_Value__c = redeemedAmount;
            orderUpdate.Is_Coupon_Applied__c = true;
            update orderUpdate;
            System.debug('Order updated with redeemed coupon value.');

            Coupon_Code__c couponUpdate = new Coupon_Code__c(Id = couponId);
            couponUpdate.Order__c = orderId;

            if ((totalPreviouslyRedeemed + redeemedAmount) == couponValue) {
                couponUpdate.Status__c = 'Redeemed';
            }
            update couponUpdate;
            System.debug('Coupon status updated if fully redeemed.');

        } catch (Exception ex) {
            System.debug('Exception in applyCouponToOrder: ' + ex.getMessage() + ' line number :' + ex.getLineNumber());
            throw new AuraHandledException('Failed to apply coupon. Please contact support.');
        }
    }

    @AuraEnabled
    public static void markCustomerHasNoCoupon(Id orderId) {
        try {
            System.debug('markCustomerHasNoCoupon called with orderId=' + orderId);

            if (orderId == null) {
                System.debug('Order ID is null. Exiting method.');
                return;
            }

            Order orderToUpdate = new Order(Id = orderId);
            orderToUpdate.Customer_Has_No_Coupon__c = true;
            update orderToUpdate;

            System.debug('Order updated successfully with Customer_Has_No_Coupon__c = true');
        } catch (Exception ex) {
            System.debug('Exception in markCustomerHasNoCoupon: ' + ex.getMessage() + ', line: ' + ex.getLineNumber());
            throw new AuraHandledException('Failed to mark order as no coupon. Please contact support.');
        }
    }

}