/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 07-02-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ScheduleCreateOrderOnWebsite {
    public List<Id> orderIds;
 
    public ScheduleCreateOrderOnWebsite(List<Id> paymentIds) {
        this.orderIds = orderIds;
    }
 
    public void execute(SchedulableContext sc) {
        //System.enqueueJob(new QueueableForCreatePaymentOnWebsite(orderIds));
    }
}