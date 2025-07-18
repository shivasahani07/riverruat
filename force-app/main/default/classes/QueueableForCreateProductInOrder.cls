/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 07-01-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QueueableForCreateProductInOrder implements Queueable, Database.allowsCallouts{
    private List<Id> orderIdsToProcess;
    
    public QueueableForCreateProductInOrder(List<Id> orderIdsToProcess) {
        this.orderIdsToProcess = orderIdsToProcess;
    }
    public void execute(QueueableContext qc){
        System.debug('Update Order API is called 1');
        if(!orderIdsToProcess.isEmpty()){
            Id currentOrderId = orderIdsToProcess.remove(0);
            System.debug('currentOrderId===>'+currentOrderId);
            if(currentOrderId != null){
                callTheRiverCreateOrderAPI(currentOrderId);
            }
            if(!orderIdsToProcess.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableForCreateProductInOrder(orderIdsToProcess));
            }
        }
        
    }
    public static void callTheRiverCreateOrderAPI(Id orderId){
        List<Website_Creds__c> rwd = Website_Creds__c.getAll().values();
        Website_Creds__c r = Website_Creds__c.getInstance('Website Creds');
        
        String BASE_URL_FOR_WEBSITE=r.BaseURL__c != null ? r.BaseURL__c : 'could not find base url';
        try{
            Set<Id> orderIds = new Set<Id>();
            Order o;
            Map<String,Id> nameProductMap = new  Map<String,Id>();
               
           if(orderId != null){
            List<OrderItem> orderProducts = [Select Id,OrderId,Website_Response_Id__c,Product2.StockKeepingUnit,UnitPrice,Quantity,Type__c,Offer_Amount__c,Offer_Description__c,Product2.Name,Product_Total_Amount__c FROM Orderitem WHERE Id =:orderId];
            if(!orderProducts.isEmpty()){
                for(OrderItem item : orderProducts){
                     orderIds.add(item.OrderId);
                      nameProductMap.put(item.Product2.StockKeepingUnit,item.Id);
                }
            }
            List<Order> orderList = [Select id,AccountId,Pricebook2Id,Grand_Total__c,Remaining_Amount__c from Order WHERE Id=:orderIds LIMIT 1];
            if(!orderList.isEmpty()){
                o = orderList[0];
            }
            Map<String,Object> payload = new Map<String,Object>();
            List<Map<String,Object>> orderItems = new List<Map<String,Object>>();
                    for(OrderItem oi : orderProducts){
                        Map<String, Object> orderItem = new Map<String, Object>();
                        Map<String, Object> subsidyInfo = new Map<String, Object>();
                    orderItem.put('subsidy_info', null);
                   
                    if (oi.Offer_Amount__c != null && oi.Offer_Description__c != null) {
                        Map<String, Object> offerInfo = new Map<String, Object>();
                        offerInfo.put('offer_amount', oi.Offer_Amount__c != null ? oi.Offer_Amount__c : 0);
                        offerInfo.put('offer_description', oi.Offer_Description__c != null ? String.valueof(oi.Offer_Description__c) : 'Blank');
                        orderItem.put('offer_info', offerInfo);
                    } else {
                        orderItem.put('offer_info', null);
                    }
                    orderItem.put('product_type', oi.Type__c != null ?  String.valueof( oi.Type__c) : 'Blank');
                    orderItem.put('product_quantity', oi.Quantity != null ? oi.Quantity : null);
                    orderItem.put('product_unit_price', oi.Product_Total_Amount__c != null ? oi.Product_Total_Amount__c:0);
                    orderItem.put('crm_pricebook_id', o.Pricebook2Id != null ? String.valueof(o.Pricebook2Id) : 'Blank');
                    if(oi.Website_Response_Id__c != null){
                        orderItem.put('order_item_id', oi.Website_Response_Id__c);
                    }
                    orderItem.put('crm_product_sku', oi.Product2.StockKeepingUnit != null ? String.valueof(oi.Product2.StockKeepingUnit) : 'Blank');
                    orderItems.add(orderItem);
                    }
                    //prepare payload 

                    payload.put('order_items',orderItems);
                    payload.put('order_amount',o.Grand_Total__c);
                    payload.put('remaining_amount',o.Remaining_Amount__c);
                    payload.put('crm_account_id',o.AccountId);
                    payload.put('crm_order_id',o.Id);

                    String serializedRequestBody = JSON.serializePretty(payload);
                    System.debug('Payload ==>'+JSON.serializePretty(payload));

                    String accessToken = reverseIntegrationUtility.gererateAccessToken() /*!= null ? reverseIntegrationUtility.gererateAccessToken() : 'Access Token Was Not Found'*/;
                    System.debug('accessToken==>'+accessToken);
                    
                    Http http = new Http();
                    HttpRequest req = new HttpRequest();
                    req.setMethod('PATCH');
                    req.setEndpoint(BASE_URL_FOR_WEBSITE+'/api/v1/order');
                    req.setBody(serializedRequestBody);
                    req.setHeader('Authorization','Bearer '+accessToken);
                    req.setHeader('Content-Type','application/json');
                    system.debug('req ===>' + req);

                    HttpResponse res = http.send(req);
                    System.debug('Response is==>'+res.getBody());

                    if(res.getStatusCode() == 200){
                    System.debug('Response From Website Server is ==>' + res.getBody());
                    
                    
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    
                    if(responseMap.containsKey('data')){
                        Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
                        
                        if(dataMap.containsKey('order_items')){
                            List<Object> orderItemResponseList = (List<Object>) dataMap.get('order_items');
                            
                            List<OrderItem> orderItemToUpdate = new List<OrderItem>();

                            if(!orderItemResponseList.isEmpty()){
                                for(Object oo : orderItemResponseList){
                                    Map<String, Object> orderItemMap = (Map<String, Object>) oo;
                                    
                                    String productSku = (String) orderItemMap.get('sku');
                                    String responseId = (String) orderItemMap.get('id');
                                    
                                    if(nameProductMap.containsKey(productSku)) {
                                        String opId = nameProductMap.get(productSku);
                                        orderItemToUpdate.add(new OrderItem(Id = opId, Website_Response_Id__c = responseId));
                                    }
                                }
                            }
                            
                            if(!orderItemToUpdate.isEmpty()){
                                update orderItemToUpdate;
                                System.debug('Successfully updated Order Items with River Website API response Product SKUs.'+orderItemToUpdate);
                            }
                        }
                    }
                  }
        }
        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
}