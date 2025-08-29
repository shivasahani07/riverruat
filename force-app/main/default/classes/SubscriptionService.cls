public with sharing class SubscriptionService {

    public static Subscription__c createSubscription(Id customerId, Id productId, Id invoiceId) {
        Subscription_Product__c product = [
            SELECT Id, Name, Default_Instances__c, Default_Duration__c
            FROM Subscription_Product__c
            WHERE Id = :productId
            LIMIT 1
        ];
        
        Date startDate = Date.today();
        String TimePeriod=product.Default_Duration__c;// Year/month/days
        Date endDate   = startDate.addMonths(1);
        
        Subscription__c subscription = new Subscription__c();
        subscription.Account__c       = customerId;
        subscription.Subscription_Product__c = product.Id;
        subscription.Start_Date__c     = startDate;
        subscription.End_Date__c       = endDate;
        subscription.Total_Instances__c   = product.Default_Instances__c;
        subscription.Remaining_Instances__c = product.Default_Instances__c;
        subscription.Availed_Instances__c = 0;
        subscription.External_Id__c='External_Id__c';
        //subscription.
        //subscription.Invoice__c        = 'www.url.com';
        subscription.Status__c         = 'Active';
        
        insert subscription;
        return subscription;
    }
    
    /*
* Consume an instance from the oldest active subscription
*/
    public static Subscription_Instance__c consumeInstance(Id customerId, String productName, Id jobCardId) {
        List<Subscription__c> activeSubs = [
            SELECT Id, Name, Remaining_Instances__c, Availed_Instances__c,
            Start_Date__c, End_Date__c, Status__c, Subscription_Product__r.Name
            FROM Subscription__c
            WHERE Account__c = :customerId
            AND Subscription_Product__r.Name = :productName
            AND Status__c = 'Active'
            AND End_Date__c >= :Date.today()
            ORDER BY Start_Date__c ASC
        ];
        
        if (activeSubs.isEmpty()) {
            throw new AuraHandledException('No active subscription found for ' + productName);
        }
        
        Subscription__c sub = activeSubs[0]; // oldest active subscription
        
        if (sub.Remaining_Instances__c <= 0) {
            throw new AuraHandledException('No instances remaining in ' + productName + ' subscription.');
        }
        
        // Deduct instance
        sub.Remaining_Instances__c--;
        sub.Availed_Instances__c++;
        
        Subscription_Instance__c instance = new Subscription_Instance__c();
        instance.Subscription__c = sub.Id;
        instance.Service_Date__c = Date.today();
        instance.Job_Card__c = jobCardId;
        instance.Status__c = 'Availed';
        
        update sub;
        insert instance;
        
        return instance;
    }
    
    /*
* Check alerts and return messages
*/
    public static List<String> checkAlerts(Id customerId, String productName) {
        List<String> alerts = new List<String>();
        
        List<Subscription__c> activeSubs = [
            SELECT Id, Remaining_Instances__c, End_Date__c, Status__c
            FROM Subscription__c
            WHERE Account__c = :customerId
            AND Subscription_Product__r.Name = :productName
            AND Status__c = 'Active'
            ORDER BY End_Date__c ASC
        ];
        
        if (activeSubs.isEmpty()) {
            alerts.add('No subscription is present.');
            return alerts;
        }
        
        Subscription__c current = activeSubs[0];
        
        // 1. Expiry check
        if (current.End_Date__c <= Date.today().addDays(30)) {
            alerts.add('Subscription is expiring within 30 days.');
        }
        
        // 2. No instances left
        if (current.Remaining_Instances__c == 0) {
            alerts.add('All subscription instances have been availed.');
        }
        
        // 3. One instance left
        if (current.Remaining_Instances__c == 1) {
            alerts.add('Only one subscription instance remains.');
        }
        
        return alerts;
    }
}