/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 05-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ScheduleOrderCreationOnWebsite implements Schedulable{
    private List<Id> orderIds;

    public ScheduleOrderCreationOnWebsite(List<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new QueueableForCreateOrderOnWebsite(orderIds));
    }
}