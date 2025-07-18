/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 05-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ScheduleCreatePaymentOnWebsite implements Schedulable {

    public List<Id> paymentIds;

    public ScheduleCreatePaymentOnWebsite(List<Id> paymentIds) {
        this.paymentIds = paymentIds;
    }

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new QueueableForCreatePaymentOnWebsite(paymentIds));
    }
}