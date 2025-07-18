/**
 * @description       :
 * @author            : Aniket Karmakar
 * @group             :
 * @last modified on  : 07-02-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class QueueableForCreateOrderOnWebsite implements Queueable, Database.allowsCallouts{
    private List<Id> orderIdsToProcess;
    
    public QueueableForCreateOrderOnWebsite(List<Id> orderIdsToProcess) {
        this.orderIdsToProcess = orderIdsToProcess;
    }
    public void execute(QueueableContext qc){
        System.debug('Create Order API is called 1');
        if(!orderIdsToProcess.isEmpty()){
            Id currentOrderId = orderIdsToProcess.remove(0);
            System.debug('currentOrderId===>'+currentOrderId);
            if(currentOrderId != null){
                callTheRiverCreateOrderAPI(currentOrderId);
            }
            if(!orderIdsToProcess.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableForCreateOrderOnWebsite(orderIdsToProcess));
            }
        }
        
    }
    public static void callTheRiverCreateOrderAPI(Id orderId){

        List<Website_Creds__c> rwd = Website_Creds__c.getAll().values();
        Website_Creds__c r = Website_Creds__c.getInstance('Website Creds');
        
        String BASE_URL_FOR_WEBSITE=r.BaseURL__c != null ? r.BaseURL__c : 'could not find base url';
        
        try{
            if(orderId != null){
                System.debug('Create Order API is called 2');

                List<Order> orderList = [Select Id,Website_Order_Id__c,AccountId,Account.Phone,Account.Name,Account.Email__c,Account.Center_Code__c,Notify_By_SMS__c,Notify_By_Email__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,
                Account.BillingState,OrderNumber,TotalAmount,Status,Description,BillingStreet,BillingCity,BillingPostalCode,BillingState,Offers_Amount__c,Offer_description__c,Pricebook2Id,Payment_Status__c,Grand_Total__c,Booking_Form_File_URL__c,Remaining_Amount__c
                FROM Order Where Id=:orderId];

                if(!orderList.isEmpty()){
                    Order o = orderList[0];
                    System.debug('Order ==>'+o);
                    System.debug('Order Account Email==>'+o.Account.Email__c);

                    List<OrderItem> orderProductList = [Select Id,OrderId,Product2.StockKeepingUnit,UnitPrice,Quantity,Type__c,Offer_Amount__c,Offer_Description__c,Product2.Name,Product_Total_Amount__c FROM Orderitem WHERE OrderId =:o.Id];
                    System.debug('List of Order Product==>'+orderProductList);

                    List<Order_Payment__c> orderPaymentList = [Select id,Name,Payments__r.Transaction_Id__c,Payments__r.Amount__c,Payments__r.Payment_Status__c,Payments__r.Bank_Reference_Number__c,Payments__r.Tracking_Id__c,
                                   Order__c,Payments__r.Mode_Of_Payment__c,Payments__r.Card_Name__c,Type__c,CreatedDate FROM Order_Payment__c WHERE Order__c=:o.Id ];

                  if(!orderPaymentList.isEmpty()){
                    Order_Payment__c op = orderPaymentList[0];
                    System.debug('Payment Details ==>'+op);

                Map<String,Id> nameProductMap = new  Map<String,Id>();
                for(OrderItem item : orderProductList){
                    nameProductMap.put(item.Product2.StockKeepingUnit,item.Id);
                }
                //upto here
                
                Map<String,Object> payLoad = new Map<String,Object>();
                
                //Payment Section
                Map<String,Object> payment = new Map<String,Object>();
                Map<String,Object> payment_gateway = new Map<String,Object>();
                payment_gateway.put('status',op.Payments__r.Payment_Status__c != null ? String.valueof(op.Payments__r.Payment_Status__c) : 'Blank');
                payment_gateway.put('card_name',op.Payments__r.Card_Name__c != null ? String.valueof(op.Payments__r.Card_Name__c) : 'Blank');
                payment_gateway.put('payment_mode',op.Payments__r.Mode_Of_Payment__c != null ? String.valueof(op.Payments__r.Mode_Of_Payment__c) : 'Blank');
                payment_gateway.put('order_id',op.Order__c != null ? String.valueof(op.Order__c) : 'Blank');
                payment_gateway.put('tracking_id',op.Payments__r.Tracking_Id__c != null ? String.valueof(op.Payments__r.Tracking_Id__c) : 'Blank');
                payment_gateway.put('bank_ref_no',op.Payments__r.Bank_Reference_Number__c != null ? String.valueof(op.Payments__r.Bank_Reference_Number__c) : 'Blank');
                payment_gateway.put('payment_provider',op.Payments__r.Mode_Of_Payment__c == 'Cash' ? 'cash' : 'pinelabs');
                
                payment.put('payment_gateway',payment_gateway);
                //payment.put('order_payment_type','booking');//added on 16/05/2025
                payment.put('payment_receipt_id',o.Booking_Form_File_URL__c != null ? String.valueof(o.Booking_Form_File_URL__c) : 'Blank');
                payment.put('payment_status','paid');//hardcoded for now
                payment.put('payment_amount',op.Payments__r.Amount__c != null ? op.Payments__r.Amount__c : 0);
                payment.put('payment_transaction_id',op.Payments__r.Transaction_Id__c != null ? String.valueof(op.Payments__r.Transaction_Id__c) : 'Blank');
                payment.put('crm_payment_id',op.Id != null ? String.valueof(op.Id) : 'Blank');
                //payment section done
                payLoad.put('payment',payment);
                
                //order item section
                List<Map<String, Object>> orderItems = new List<Map<String, Object>>();
                
                for (OrderItem oi : orderProductList) {
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
                    orderItem.put('product_unit_price', oi.Product_Total_Amount__c != null ? String.valueof(oi.Product_Total_Amount__c):'Blank');
                    orderItem.put('crm_pricebook_id', o.Pricebook2Id != null ? String.valueof(o.Pricebook2Id) : 'Blank');
                    orderItem.put('crm_product_sku', oi.Product2.StockKeepingUnit != null ? String.valueof(oi.Product2.StockKeepingUnit) : 'Blank');
                    orderItems.add(orderItem);
                }
                //upto here
                //order Section
                Map<String,Object> order = new Map<String,Object>();
                Map<String,Object> offer_info = new Map<String,Object>();
                Map<String,Object> billing_address_for_Order = new Map<String,Object>();
                
                
                billing_address_for_Order.put('state',o.BillingState != null ? String.valueof(o.BillingState) : 'Not Found');
                billing_address_for_Order.put('pin_code',o.BillingPostalCode != null ?String.valueof(o.BillingPostalCode): 'No Postal Code Found');
                billing_address_for_Order.put('city',o.BillingCity != null ? String.valueof(o.BillingCity) : 'Not Found');
                billing_address_for_Order.put('address_2',o.BillingStreet != null ? String.valueof(o.BillingStreet) : 'Not Found');
                billing_address_for_Order.put('address_1',o.BillingStreet != null ? String.valueof(o.BillingStreet) : 'Not Found');
                
                order.put('order_items',orderItems);
                
                //if(o.Offers_Amount__c != null){
                    offer_info.put('offer_amount',o.Offers_Amount__c != null ? o.Offers_Amount__c : 0);
                    offer_info.put('offer_description',o.Offer_description__c != null ? String.valueof(o.Offer_description__c) : 'No Description Found');
                //}
                // else{
                //     order.put('offer_info',null);
                // }
                
                order.put('offer_info',offer_info);
                order.put('billing_address',billing_address_for_Order);
                order.put('delivery_timeline_description',o.Description != null ? String.valueof(o.Description) : 'No Description was found');
                order.put('order_status',o.Status);
                order.put('remaining_amount',o.Remaining_Amount__c != null ? o.Remaining_Amount__c : 0);
                order.put('order_amount',o.Grand_Total__c);
                order.put('seller_code',o.Account.Center_Code__c != null ? String.valueof(o.Account.Center_Code__c) : 'No Seller Code');
                order.put('display_order_id',o.Website_Order_Id__c != null ? String.valueof(o.Website_Order_Id__c) : 'No Order Number Found');
                order.put('crm_order_id',o.Id);
                
                payLoad.put('order',order);
                
                
                //upto here
                
                //user section
                Map<String,Object> user = new Map<String,Object>();
                Map<String,Object> billing_address = new Map<String,Object>();
                billing_address.put('state',o.Account.BillingState != null ? String.valueof(o.Account.BillingState): 'Not Found');
                billing_address.put('pin_code',o.Account.BillingPostalCode != null ? String.valueof(o.Account.BillingPostalCode)  : 'Not Found');
                billing_address.put('city',o.Account.BillingCity != null ? String.valueof(o.Account.BillingCity) : 'Not Found');
                billing_address.put('address_2',o.Account.BillingStreet != null ? String.valueof(o.Account.BillingStreet) : 'Not Found');
                billing_address.put('address_1',o.Account.BillingStreet != null ? String.valueof(o.Account.BillingStreet) : 'Not Found');
                
                user.put('billing_address',billing_address);
                user.put('open_to_email',true);
                user.put('open_to_sms',true);
                user.put('phone_number',o.Account.Phone != null ? String.valueof(o.Account.Phone): 'No Phone Found');
                user.put('email_address',o.Account.Email__c != null ? String.valueof(o.Account.Email__c) : 'No Email Found');
                user.put('full_name',o.Account.Name != null ? String.valueof(o.Account.Name) : 'No Name Found');
                user.put('crm_account_id',o.Account.Id);
                
                payLoad.put('user', user);
                
                
                //upto here
                String serializedRequestBody = JSON.serializePretty(payLoad);
                System.debug('Payload==>'+JSON.serializePretty(payLoad));
                
                String accessToken = reverseIntegrationUtility.gererateAccessToken() ;//!= null ? reverseIntegrationUtility.gererateAccessToken() : 'Access Token Was Not Found';
                System.debug('accessToken==>'+accessToken);
                
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(BASE_URL_FOR_WEBSITE+'/api/v1/order');
                req.setBody(serializedRequestBody);
                req.setHeader('Authorization','Bearer '+accessToken);
                req.setHeader('Content-Type','application/json');
                system.debug('req ===>' + req);
                //System.debug('Endpoint',req.setEndpoint);
                
                HttpResponse res = http.send(req);
                
                System.debug('Response is==>'+res.getBody());
                if(res.getStatusCode() == 200){
                    System.debug('Response From Website Server is ==>' + res.getBody());
                    
                    
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    
                    if(responseMap.containsKey('data')){
                        Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
                        
                        if(dataMap.containsKey('order_item')){
                            List<Object> orderItemResponseList = (List<Object>) dataMap.get('order_item');
                            
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
                        if(dataMap.containsKey('order_id')){

                            String orderWebId = (String) dataMap.get('order_id');
                            o.Website_Response_Id__c = orderWebId;
                            update o;
                        }
                    }
                  }
                
                }
        
                }
                
            }
            
        }
        catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
        
        
        
        
    }
    
    
}