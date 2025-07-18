public class CouponCodeEmailHandler {
    public static void sendCouponEmails(List<Coupon_Code__c> newCoupons) {
        try {
            OrgWideEmailAddress owea = getOrgWideEmailAddress();

            Set<Id> caseIds = new Set<Id>();
            for (Coupon_Code__c cc : newCoupons) {
                if (cc.Case__c != null) {
                    caseIds.add(cc.Case__c);
                }
            }

            Map<Id, Case> caseMap = new Map<Id, Case>(
                [SELECT Id, Account.Name, Account.Email__c FROM Case WHERE Id IN :caseIds]
            );

            EmailTemplate template = [
                SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Coupon_Code_Generated' LIMIT 1
            ];

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (Coupon_Code__c cc : newCoupons) {
                Case caseObj = caseMap.get(cc.Case__c);
                if (caseObj == null || caseObj.Account == null || String.isBlank(caseObj.Account.Email__c)) {
                    continue;
                }

                String htmlBody = template.HtmlValue;

                htmlBody = htmlBody.replace('{!Coupon_Code__c.Coupon__c}', cc.Coupon__c);
                htmlBody = htmlBody.replace('{!Coupon_Code__c.Value__c}', String.valueOf(cc.Value__c));
                htmlBody = htmlBody.replace('{!TEXT(Coupon_Code__c.Expiry_Date_Time__c)}', cc.Expiry_Date_Time__c.format());
                htmlBody = htmlBody.replace('{!Coupon_Code__c.Case__r.Account.Name}', caseObj.Account.Name);

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ caseObj.Account.Email__c });
                email.setHtmlBody(htmlBody);
                email.setSubject('Your Coupon Code from River Mobility');
                email.setOrgWideEmailAddressId(owea.Id);
                email.setSaveAsActivity(true);

                emails.add(email);
            }

            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }

        } catch (Exception ex) {
            System.debug('Error sending coupon emails: ' + ex.getMessage());
        }
    }

    private static OrgWideEmailAddress getOrgWideEmailAddress() {
        return [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'River Mobility' LIMIT 1];
    }
}