/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 05-21-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QueueableForDeletePaymentOnWebsite implements Queueable, Database.allowsCallouts{
    private List<OrderPaymentTriggerHandler.wrapperForDeletePayment> deleteList;
    public QueueableForDeletePaymentOnWebsite(List<OrderPaymentTriggerHandler.wrapperForDeletePayment> deleteList){
        this.deleteList=deleteList;
    }
    public void execute(QueueableContext qc){
        if(!deleteList.isEmpty()){
            OrderPaymentTriggerHandler.wrapperForDeletePayment current = deleteList.remove(0);
            callWebsiteDeletePaymentAPI(current);
            if(!deleteList.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableForDeletePaymentOnWebsite(deleteList));
            }
        }
    }
    public static void callWebsiteDeletePaymentAPI(OrderPaymentTriggerHandler.wrapperForDeletePayment current){
        try{
            Website_Creds__c r = Website_Creds__c.getInstance('Website Creds');
            String BASE_URL_FOR_WEBSITE = r.BaseURL__c != null ? r.BaseURL__c : 'could not find base url';

            Order order = [Select id,AccountId,Remaining_Amount__c from Order WHERE Id =:current.orderId LIMIT 1];
            Payment__c p = [Select id,Transaction_Id__c from Payment__c WHERE Id =: current.paymentId LIMIT 1];

            Map<String,Object> payload = new Map<String,Object>();
            payload.put('remaining_amount',order.Remaining_Amount__c != null ? order.Remaining_Amount__c : 0);
            payload.put('payment_transaction_id',p.Transaction_Id__c != null ? String.valueof(p.Transaction_Id__c) : 'Not Found');
            payload.put('crm_account_id',order.AccountId != null ? String.valueof(order.AccountId) : 'Not Found');
            payload.put('crm_order_id',order.Id !=null ? String.valueof(order.Id) : 'Not Found');

            System.debug('payload==>'+JSON.serializePretty(payload));

            String accessToken = reverseIntegrationUtility.gererateAccessToken();
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('DELETE');
            req.setEndpoint(BASE_URL_FOR_WEBSITE + '/api/v1/payment');
            req.setBody(JSON.serialize(payload));
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');

            HttpResponse res = http.send(req);
            System.debug('API Response: ' + res.getBody());

            if (res.getStatusCode() == 200) {
                System.debug('Order Payment deleted successfully on website.');
            } 
            

        }catch(Exception e){
            System.debug('Error Occured=>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
}