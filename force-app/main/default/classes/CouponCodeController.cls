public with sharing class CouponCodeController {
    @AuraEnabled(cacheable=true)
    public static List<String> getValidCouponCodes() {
        try {
            System.debug('Fetching all valid coupon codes...');
            List<Coupon_Code__c> coupons = [
                SELECT Coupon__c 
                FROM Coupon_Code__c 
                WHERE Status__c = 'Valid'
            ];

            List<String> codes = new List<String>();
            for (Coupon_Code__c c : coupons) {
                codes.add(c.Coupon__c);
            }
            System.debug('Found ' + codes.size() + ' valid coupon codes.');
            return codes;
        } catch(Exception ex) {
            System.debug('Error in getValidCouponCodes: ' + ex.getMessage());
            throw new AuraHandledException('Failed to fetch valid coupon codes: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void createCouponCode(Id caseId, String couponCode) {
        try {
            System.debug('Creating Coupon_Code__c record for CaseId: ' + caseId + ', CouponCode: ' + couponCode);
            
            List<Case> caseList = [SELECT Id, Coupon_Value__c, Case_Sub_Category__c,Coupon_For__c, Case.accountId FROM Case WHERE Id = :caseId LIMIT 1];
            
            if (caseList.isEmpty()) {
                throw new AuraHandledException('Case record not found with Id: ' + caseId);
            }
            
            Case caseRecord = caseList[0]; 
            
            Coupon_Code__c newCoupon = new Coupon_Code__c(
                Coupon__c = couponCode,
                Value__c = caseRecord.Coupon_Value__c,
                Case__c = caseId,
                Status__c = 'Valid',
                Generated_For__c = caseRecord.Case_Sub_Category__c,
                Coupon_For__c = caseRecord.Coupon_For__c,
                Account__c = caseRecord.AccountId,
                Expiry_Date_Time__c = System.now().addMonths(3)
            );

            insert newCoupon;
            System.debug('Coupon_Code__c record inserted successfully with Id: ' + newCoupon.Id);
        } catch(Exception ex) {
            System.debug('Error in createCouponCode: ' + ex.getMessage());
            throw new AuraHandledException('Failed to create coupon code record: ' + ex.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCaseInfo(Id caseId) {
        try {
            Case c = [
                SELECT Id, Coupon_For__c, Coupon_Value__c, Account.AccountSource
                FROM Case WHERE Id = :caseId
                LIMIT 1
            ];

            Map<String, Object> result = new Map<String, Object>();
            result.put('accountSource', c.Account.AccountSource);
            result.put('couponFor', c.Coupon_For__c);
            result.put('couponValue', c.Coupon_Value__c);

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to fetch case info: ' + e.getMessage());
        }
    }
}