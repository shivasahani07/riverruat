/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 06-02-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global with sharing class OverallExperienceScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        Date targetDate = Date.today().addDays(-30);
        
        List<Order> orders = [SELECT Id, AccountId, Status, Delivery_Date__c FROM Order WHERE Delivery_Date__c = :targetDate ];
        System.debug('Last 30 Days old ==>'+orders);

        if (orders.isEmpty()) {
            System.debug('No orders found with Delivery Date = ' + targetDate);
            return;
        }

        Map<Id, Order> oldMap = new Map<Id, Order>();
        for (Order o : orders) {
            Order oldOrder = new Order(Id = o.Id, Status = 'Ready For Delivery');
            oldMap.put(o.Id, oldOrder);
        }

        ProductReviewController.generateFeedbackUrl(orders, oldMap);
        ProductReviewController.sendWhatsAppMessageWithFeedbackUrl(orders, oldMap);

    }
}