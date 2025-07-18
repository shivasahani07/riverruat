/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 07-02-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QueueableForUpdateOrderOnWebsite implements Queueable, Database.allowsCallouts{
    private List<Id> orderIdsToProcess;
    
    public QueueableForUpdateOrderOnWebsite(List<Id> orderIdsToProcess) {
        this.orderIdsToProcess = orderIdsToProcess;
    }
    public void execute(QueueableContext qc){
        System.debug('Update Order API is called 1');
        if(!orderIdsToProcess.isEmpty()){
            Id currentOrderId = orderIdsToProcess.remove(0);
            System.debug('currentOrderId===>'+currentOrderId);
            if(currentOrderId != null){
                callUpdateOrderAPI(currentOrderId);
            }
            if(!orderIdsToProcess.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableForUpdateOrderOnWebsite(orderIdsToProcess));
            }
        }
    }
    public static void callUpdateOrderAPI(Id orderId){
        List<Website_Creds__c> rwd = Website_Creds__c.getAll().values();
        Website_Creds__c r = Website_Creds__c.getInstance('Website Creds');
        
        String BASE_URL_FOR_WEBSITE=r.BaseURL__c != null ? r.BaseURL__c : 'could not find base url';

        try{
            if(orderId!=null){
                List<Order> orderList = [Select id,AccountId,Status,Description,BillingStreet,BillingCity,BillingPostalCode,BillingState, TotalAmount,Pricebook2Id,Grand_Total__c,Assigned_Vehicle__c,Delivery_Date__c from Order Where id =:orderId];

                if(!orderList.isEmpty()){
                    Order o = orderList[0];
                    System.debug('Order ===>'+o);
                     
                    Vehicle v;
                    List<Vehicle> vehicleList = [Select Id,VehicleIdentificationNumber,VehicleRegistrationNumber from Vehicle WHERE Id=:o.Assigned_Vehicle__c LIMIT 1];
                    if(!vehicleList.isEmpty()){
                        v=vehicleList[0];
                    }

                    // List<OrderItem> orderProducts = [Select Id,OrderId,Website_Response_Id__c,Product2.StockKeepingUnit,UnitPrice,Quantity,Type__c,Offer_Amount__c,Offer_Description__c,Product2.Name,Product_Total_Amount__c FROM Orderitem WHERE OrderId =:o.Id];
                    // System.debug('List Of Order Products ==>'+orderProducts);

                    Map<String,Object> payLoad = new Map<String,Object>();

                    // List<Map<String,Object>> orderItems = new List<Map<String,Object>>();
                    // for(OrderItem oi : orderProducts){
                    //     Map<String, Object> orderItem = new Map<String, Object>();
                    //     Map<String, Object> subsidyInfo = new Map<String, Object>();
                    // orderItem.put('subsidy_info', null);
                    
                    // if (oi.Offer_Amount__c != null && oi.Offer_Description__c != null) {
                    //     Map<String, Object> offerInfo = new Map<String, Object>();
                    //     offerInfo.put('offer_amount', oi.Offer_Amount__c != null ? oi.Offer_Amount__c : 0);
                    //     offerInfo.put('offer_description', oi.Offer_Description__c != null ? String.valueof(oi.Offer_Description__c) : 'Blank');
                    //     orderItem.put('offer_info', offerInfo);
                    // } else {
                    //     orderItem.put('offer_info', null);
                    // }
                    // orderItem.put('product_type', oi.Type__c != null ?  String.valueof( oi.Type__c) : 'Blank');
                    // orderItem.put('product_quantity', oi.Quantity != null ? oi.Quantity : null);
                    // orderItem.put('product_unit_price', oi.Product_Total_Amount__c != null ? String.valueof(oi.Product_Total_Amount__c):'Blank');
                    // orderItem.put('crm_pricebook_id', o.Pricebook2Id != null ? String.valueof(o.Pricebook2Id) : 'Blank');
                    // if(oi.Website_Response_Id__c != null){
                    //     orderItem.put('order_item_id', oi.Website_Response_Id__c);
                    // }
                    // orderItem.put('crm_product_sku', oi.Product2.StockKeepingUnit != null ? String.valueof(oi.Product2.StockKeepingUnit) : 'Blank');
                    // orderItems.add(orderItem);
                    // }
                   

                    // Map<String,Object> billing_address = new Map<String,Object>();
                    // billing_address.put('state',o.BillingState != null ? String.valueof(o.BillingState): 'Not Found');
                    // billing_address.put('pin_code',o.BillingPostalCode != null ? String.valueof(o.BillingPostalCode)  : 'Not Found');
                    // billing_address.put('city',o.BillingCity != null ? String.valueof(o.BillingCity) : 'Not Found');
                    // billing_address.put('address_2',o.BillingStreet != null ? String.valueof(o.BillingStreet) : 'Not Found');
                    // billing_address.put('address_1',o.BillingStreet != null ? String.valueof(o.BillingStreet) : 'Not Found');

                    // payLoad.put('order_items',orderItems);
                    // payLoad.put('billing_address',billing_address);
                    // payLoad.put('delivery_timeline_description',o.Description); 

                    //payLoad.put('delivery_date',String.valueof(o.Delivery_Date__c));
                    //payLoad.put('vin_number',String.valueof(v.VehicleIdentificationNumber));
                    //payLoad.put('vehicle_number',String.valueof(v.VehicleRegistrationNumber));
                    
                    payLoad.put('order_status',o.Status);
                    // payLoad.put('order_amount',o.Grand_Total__c);
                    payLoad.put('crm_account_id',o.AccountId);
                    payLoad.put('crm_order_id',o.Id);

                    String serializedRequestBody = JSON.serializePretty(payLoad);
                    System.debug('Payload==>'+JSON.serializePretty(payLoad));
                    
                    String accessToken = reverseIntegrationUtility.gererateAccessToken() ;//!= null ? reverseIntegrationUtility.gererateAccessToken() : 'Access Token Was Not Found';
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
                        System.debug('Response is==>'+res.getBody());
                        System.debug('Order Is Successfully Updated In The River Website Database');
                    }
                }
                
            }

        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==='+e.getLineNumber());
        }

        

    }
}