/**
 * @description       : 
 * @author            : Aniket Karmakar 
 * @group             : 
 * @last modified on  : 05-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ScheduleDeleteOrderItemOnWebsite implements Schedulable{
    public List<OrderItemTriggerHandler.OrderItemDeleteDTO> dtoList;

    public ScheduleDeleteOrderItemOnWebsite(List<OrderItemTriggerHandler.OrderItemDeleteDTO> dtoList) {
        this.dtoList = dtoList;
    }

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new QueueableForDeleteOrderItemOnWebsite(dtoList));
    }
}