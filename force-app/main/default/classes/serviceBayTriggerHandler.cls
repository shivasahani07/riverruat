public class serviceBayTriggerHandler {
    
    public static void handleBayCount(list<Service_Bay__c> servicebaylist){
        Set<Id> accountIds = new Set<Id>();
    for (Service_Bay__c sb : servicebaylist) {
        if (sb.Service_Center__c != null) {
            accountIds.add(sb.Service_Center__c);
        }
    }

    if (!accountIds.isEmpty()) {
        // Query existing Service Bays grouped by Account
        Map<Id, Integer> accountToBayCount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Service_Center__c accId, COUNT(Id) cnt
            FROM Service_Bay__c
            WHERE Service_Center__c IN :accountIds
            GROUP BY Service_Center__c
        ]) {
            accountToBayCount.put((Id)ar.get('accId'), (Integer)ar.get('cnt'));
        }

        // Loop through new Service Bay records
        for (Service_Bay__c sb : servicebaylist) {
            if (sb.Service_Center__c != null) {
                Integer existingCount = accountToBayCount.containsKey(sb.Service_Center__c) 
                                        ? accountToBayCount.get(sb.Service_Center__c) 
                                        : 0;

                // If it's an insert → count includes existing + new ones in Trigger
                Integer newCount = existingCount;

                // Add trigger new records count for same Account
                for (Service_Bay__c innerSb : servicebaylist) {
                    if (innerSb.Service_Center__c == sb.Service_Center__c && innerSb != sb) {
                        newCount++;
                    }
                }

                // If record is Insert (not update of same record)
                if (Trigger.isInsert) {
                    newCount++;
                }

                if (newCount > 4) {
                    sb.addError('You cannot create more than 4 Service Bays for the same Account.');
                }
            }
        }
    }
    }
   
}