/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 08-13-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class PostService7DaysScheduler implements Schedulable{
   global void execute(SchedulableContext sc) {
    Date targetDate = Date.today().addDays(-07);
    List<WorkOrder> orders = [SELECT Id, AccountId, Status, Completed_Date__c,Service_Center__c,RR_Job_Type__c FROM WorkOrder WHERE DAY_ONLY(Completed_Date__c) = :targetDate AND RR_Job_Type__c='Periodic maintenance'];
    System.debug('Last 30 Days old ==>'+orders);
    if (orders.isEmpty()) {
            System.debug('No Job Cards found with Delivery Date = ' + targetDate);
            return;
        }

        // Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>();
        // for (WorkOrder o : orders) {
        //     WorkOrder oldOrder = new WorkOrder(Id = o.Id, Status = 'Ready for Delivery');
        //     oldMap.put(o.Id, oldOrder);
        // }

        PSFController.generateFeedbackUrl(orders, null);
        PSFController.sendWhatsAppMessageWithFeedbackUrl(orders, null);


   }
}