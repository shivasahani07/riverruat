/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 05-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QueueableForDeleteOrderItemOnWebsite implements Queueable, Database.allowsCallouts{
   private List<OrderItemTriggerHandler.OrderItemDeleteDTO> dtoList;

    public QueueableForDeleteOrderItemOnWebsite(List<OrderItemTriggerHandler.OrderItemDeleteDTO> dtoList) {
        this.dtoList = dtoList;
    }

    public void execute(QueueableContext qc) {
        if (!dtoList.isEmpty()) {
            OrderItemTriggerHandler.OrderItemDeleteDTO current = dtoList.remove(0);
            callTheRiverDeleteOrderProductAPI(current);

            if (!dtoList.isEmpty() && !Test.isRunningTest()) {
                System.enqueueJob(new QueueableForDeleteOrderItemOnWebsite(dtoList));
            }
        }
    }

    public static void callTheRiverDeleteOrderProductAPI(OrderItemTriggerHandler.OrderItemDeleteDTO dto) {
        try {
            Website_Creds__c r = Website_Creds__c.getInstance('Website Creds');
            String BASE_URL_FOR_WEBSITE = r.BaseURL__c != null ? r.BaseURL__c : 'could not find base url';
 
            Order o = [Select id,Grand_Total__c,Remaining_Amount__c,AccountId from Order WHERE Id =:dto.orderId LIMIT 1];
            Map<String, Object> payload = new Map<String, Object>{
                'remaining_amount' => o.Remaining_Amount__c != null ? o.Remaining_Amount__c : 0,
                'order_amount'     => o.Grand_Total__c != null ? o.Grand_Total__c : 0,
                'order_item_id'    => String.isNotBlank(dto.websiteResponseId) ? dto.websiteResponseId : 'Not Found',
                'crm_account_id'   => String.isNotBlank(o.AccountId) ? o.AccountId : 'Not Found',
                'crm_order_id'     => String.isNotBlank(dto.orderId) ? dto.orderId : 'Not Found'
            };

            System.debug('payload==>'+JSON.serializePretty(payload));

            String accessToken = reverseIntegrationUtility.gererateAccessToken();
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('DELETE');
            req.setEndpoint(BASE_URL_FOR_WEBSITE + '/api/v1/order/order-item');
            req.setBody(JSON.serialize(payload));
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');

            HttpResponse res = http.send(req);
            System.debug('API Response: ' + res.getBody());

            if (res.getStatusCode() == 200) {
                System.debug('Order Product deleted successfully on website.');
            }

        } catch (Exception e) {
            System.debug('API Error: ' + e.getMessage());
            System.debug('Line: ' + e.getLineNumber());
        }
    }
}