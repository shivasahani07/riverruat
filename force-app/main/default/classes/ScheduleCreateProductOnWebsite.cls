/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 05-16-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ScheduleCreateProductOnWebsite implements Schedulable{
    public List<Id> orderItemIds;
 
    public ScheduleCreateProductOnWebsite(List<Id> orderItemIds) {
        this.orderItemIds = orderItemIds;
    }
 
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new QueueableForCreateProductInOrder(orderItemIds));
    }
}