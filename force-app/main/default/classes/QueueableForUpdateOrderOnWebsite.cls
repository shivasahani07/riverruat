/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-22-2025
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
                List<Order> orderList = [Select id,AccountId,Status,Description,BillingStreet,BillingCity,BillingPostalCode,BillingState, TotalAmount,Pricebook2Id,Grand_Total__c,Assigned_Vehicle__c,Delivery_Date__c,Website_Response_Id__c,EffectiveDate,Website_Order_Id__c from Order Where id =:orderId];

                if(!orderList.isEmpty()){
                    Order o = orderList[0];
                    System.debug('Order ===>'+o);
                    // if(o.Website_Response_Id__c == '' || o.Website_Response_Id__c == null){
                    //     System.debug('Update Order API Should Not be called');
                    //     return;
                    // }
                     
                    Vehicle v;
                    List<Vehicle> vehicleList = [Select Id,VehicleIdentificationNumber,VehicleRegistrationNumber,Purchased_Date__c from Vehicle WHERE Id=:o.Assigned_Vehicle__c LIMIT 1];
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
                    
                    if (o.Assigned_Vehicle__c != null && v != null) {
                        
                        if(v.Purchased_Date__c != null){
                            payLoad.put('delivery_date', String.valueOf(v.Purchased_Date__c));
                        }
                        if(String.isNotBlank(v.VehicleIdentificationNumber)){
                            payLoad.put('vin_number',  String.valueOf(v.VehicleIdentificationNumber));
                        }
                        if(String.isNotBlank(v.VehicleRegistrationNumber)){
                            payLoad.put('vehicle_number', String.valueOf(v.VehicleRegistrationNumber));
                        }
                        
                        
                    }
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

                        Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Reverse Integration Update Order',
                        Request_Payload__c = serializedRequestBody,
                        Response_Payload__c = res.getBody(),
                        Error_Message__c = '',
                        Status__c = 'Success',
                        Order__c=o.Id    
                    );
                    insert logObj;
                    }else{
                        Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Reverse Integration Update Order',
                        Request_Payload__c = serializedRequestBody,
                        Response_Payload__c = res.getBody(),
                        Error_Message__c = '',
                        Status__c = 'Failed',
                        Order__c=o.Id    
                    );
                    insert logObj;

                       Group g;
                List<Group> sapGroup = [SELECT Id,Name,DeveloperName from Group WHERE DeveloperName = 'Integration_Group' LIMIT 1];
                System.debug('sapGroup=>'+sapGroup);
                if(!sapGroup.isEmpty()){
                    g=sapGroup[0];
                    System.debug('G==>'+g);
                }
                List<GroupMember> members = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :g.Id];
                System.debug('members==>'+members);
                Set<Id> userIds = new Set<Id>();
                for (GroupMember gm : members) {
                    if (gm.UserOrGroupId.getSObjectType() == Schema.User.SObjectType) {
                        userIds.add(gm.UserOrGroupId);
                    }
                }
                List<User> users = [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];
                System.debug('users==>'+users);
                List<String> emailList = new List<String>();
                for(User u : users){
                    emailList.add(u.Email);
                }
                System.debug('emailList==>'+emailList);


                                //upto here
               List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'support@rideriver.com' LIMIT 1];
               System.debug('OrgWideEmailAddress List In Salesforce==>'+oweaList);
                Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
                mail2.setToAddresses(emailList);
                mail2.setSubject('Reverse Integration Failure');
                mail2.setOrgWideEmailAddressId(oweaList[0].Id);
               
                                    String htmlBody = 
                        '<html>' +
                        '<head>' +
                        '<style>' +
                        '  body { font-family: Arial, sans-serif; color: #333; }' +
                        '  .container { padding: 20px; border: 1px solid #ccc; border-radius: 8px; background-color: #f9f9f9; }' +
                        '  h2 { color: #d9534f; }' +
                        '  .po-details { margin-top: 20px; padding: 15px; background-color: #fff3cd; border-left: 5px solid #ffeeba; }' +
                        '  .footer { margin-top: 30px; font-size: 12px; color: #888; }' +
                        '</style>' +
                        '</head>' +
                        '<body>' +
                        '  <div class="container">' +
                        '    <h2>🚨 Reverse Integration Failure</h2>' +
                        '    <p>Dear Integration Group Users,</p>' +
                        '    <p>The following Order failed to sync with Website. Please review the details below and take appropriate action.</p>' +
                        '    <div class="po-details">' +
                        '      <p><strong>Order No.:</strong> ' + o.Website_Order_Id__c + '</p>' +
                        '      <p><strong>Failure Reason:</strong> ' + res.getBody() + '</p>' +
                         '      <p><strong>Order Date:</strong> ' + o.EffectiveDate+ '</p>' +
                        '      <p><strong>Integration Type:</strong> ' + 'Reverse Integration Update Order' + '</p>' +
                        '    </div>' +
                        '    <p>Kindly address this issue at the earliest.</p>' +
                        '    <div class="footer">' +
                        '      <p>--<br/>This is an automated message from Salesforce.</p>' +
                        '    </div>' +
                        '  </div>' +
                        '</body>' +
                        '</html>';

                    mail2.setHtmlBody(htmlBody);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail2 });
                System.debug('Send Email Result: ' + results[0].isSuccess());


                    }
                }
                
            }

        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==='+e.getLineNumber());
        }

        

    }
}