/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 05-21-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ScheduleDeletePaymentOnWebsite implements Schedulable{
    private List<OrderPaymentTriggerHandler.wrapperForDeletePayment> deleteList;
    public ScheduleDeletePaymentOnWebsite(List<OrderPaymentTriggerHandler.wrapperForDeletePayment> deleteList){
        this.deleteList=deleteList;
    }
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new QueueableForDeletePaymentOnWebsite(deleteList));
    }
}