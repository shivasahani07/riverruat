/**
* @description       : 
* @author            : Aniket Karmakar
* @group             : 
* @last modified on  : 10-22-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QueueableForCreatePaymentOnWebsite implements Queueable, Database.allowsCallouts{
    private List<Id> paymentIdToProcess;
    public QueueableForCreatePaymentOnWebsite(List<Id> paymentIdToProcess) {
        this.paymentIdToProcess = paymentIdToProcess;
    }
    public void execute(QueueableContext qc){
        if(!paymentIdToProcess.isEmpty()){
            Id currentPaymentId = paymentIdToProcess.remove(0);
            
            System.debug('currentPaymentId===>'+currentPaymentId);
            if(currentPaymentId != null){
                callCreatePaymentAPI(currentPaymentId);
            }
            if(!paymentIdToProcess.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableForCreatePaymentOnWebsite(paymentIdToProcess));
            }
        }
    }
    public static void callCreatePaymentAPI(Id paymentId){
        List<Website_Creds__c> rwd = Website_Creds__c.getAll().values();
        Website_Creds__c r = Website_Creds__c.getInstance('Website Creds');
        system.debug('r == >'+r);  
        String BASE_URL_FOR_WEBSITE;
        if(r != null){
         BASE_URL_FOR_WEBSITE=r.BaseURL__c != null ? r.BaseURL__c : 'could not find base url';   
        }
        try{
            if(paymentId != null){
                List<Order_Payment__c> orderPaymentList = [Select id,Name,Order__c,Order__r.AccountId,Payments__c,Payments__r.Transaction_Id__c,Payments__r.Amount__c, Payments__r.Payment_Status__c,Payments__r.Bank_Reference_Number__c,Payments__r.Tracking_Id__c,Payments__r.Mode_Of_Payment__c, Payments__r.Card_Name__c,Order__r.Remaining_Amount__c,Order__r.Booking_Form_File_URL__c,Order__r.Payment_Receipt_PDF_URL__c,Type__c,Order__r.EffectiveDate,Order__r.Website_Order_Id__c from Order_Payment__c Where Id=:paymentId LIMIT 1];
                if(!orderPaymentList.isEmpty()){
                    Order_Payment__c o = orderPaymentList[0];
                    System.debug('Order Payment ==>'+o);
                    
                    Map<String,Object> order = new Map<String,Object>();
                    Map<String,Object> payLoad = new Map<String,Object>();
                    Map<String,Object> payment_gateway = new Map<String,Object>();
                    payment_gateway.put('status',o.Payments__r.Payment_Status__c != null ? o.Payments__r.Payment_Status__c : '');
                    payment_gateway.put('card_name',o.Payments__r.Card_Name__c != null ? o.Payments__r.Card_Name__c :'');
                    payment_gateway.put('payment_mode',o.Payments__r.Mode_Of_Payment__c != null ? o.Payments__r.Mode_Of_Payment__c : '');
                    payment_gateway.put('order_id',o.Order__c != null ? o.Order__c : '');
                    payment_gateway.put('tracking_id',o.Payments__r.Tracking_Id__c != null ? o.Payments__r.Tracking_Id__c : '');
                    payment_gateway.put('bank_ref_no',o.Payments__r.Bank_Reference_Number__c != null ? o.Payments__r.Bank_Reference_Number__c : '');
                    payment_gateway.put('payment_provider',o.Payments__r.Mode_Of_Payment__c == 'Cash' ? 'cash' : 'pinelabs');
                    
                    order.put('remaining_amount',o.Order__r.Remaining_Amount__c != null ? o.Order__r.Remaining_Amount__c : 0.0);

                    payLoad.put('payment_gateway',payment_gateway);
                    payLoad.put('order',order);
                    payLoad.put(
                                'order_payment_type',
                                o.Type__c == 'Down Payment' ? 'downpayment' :
                                o.Type__c == 'Full Payment' ? 'fullpayment' :
                                o.Type__c == 'Refund' ? 'refund' :
                                o.Type__c == 'Others' ? 'others' :
                                o.Type__c== 'Warranty Payment' ? 'warrantypayment':
                                o.Type__c == 'Accessories Payment' ? 'accessoriespayment':
                                o.Type__c == 'RSA Payment' ? 'roadsideassistancepayment':
                                'Not Defined '
                            );
//hardcoded for now
                    payLoad.put('payment_receipt_id',o.Order__r.Payment_Receipt_PDF_URL__c != null ? String.valueof(o.Order__r.Payment_Receipt_PDF_URL__c) : 'Blank');
                    payLoad.put('payment_status','paid'/*o.Payments__r.Payment_Status__c != null ? o.Payments__r.Payment_Status__c : ''*/);
                    payLoad.put('payment_amount',o.Payments__r.Amount__c != null ? o.Payments__r.Amount__c : null);
                    payLoad.put('payment_transaction_id',o.Payments__r.Transaction_Id__c != null ? o.Payments__r.Transaction_Id__c : '');
                    payLoad.put('crm_payment_id',o.Id != null ? o.Id : '');
                    payLoad.put('crm_order_id',o.Order__c != null ? o.Order__c : '');
                    payLoad.put('crm_account_id',o.Order__r.AccountId);
                    
                    String reqBody = JSON.serialize(payLoad);
                    System.debug('Payload ==>'+JSON.serializePretty(payLoad));
                    
                    String accessToken = reverseIntegrationUtility.gererateAccessToken() /*!= null ? reverseIntegrationUtility.gererateAccessToken() : 'Access Token Was Not Found'*/;
                    System.debug('accessToken==>'+accessToken);
                    
                    Http http = new Http();
                    HttpRequest req = new HttpRequest();
                    req.setMethod('POST');
                    req.setEndpoint(BASE_URL_FOR_WEBSITE+'/api/v1/payment');
                    req.setBody(reqBody);
                    req.setHeader('Authorization','Bearer '+accessToken);
                    req.setHeader('Content-Type','application/json');
                    
                    HttpResponse res = http.send(req);
                    if(res.getStatusCode() == 200){
                        System.debug('Payment Information has been successfully updated in River Website Database');

                         Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Reverse Integration Create Payment',
                        Request_Payload__c = reqBody,
                        Response_Payload__c = res.getBody(),
                        Error_Message__c = '',
                        Status__c = 'Success',
                        Order__c=o.Order__c     
                    );
                    insert logObj;
                    }else{
                        System.debug('Some Error Occurred==>'+res.getBody());
                        Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Reverse Integration Create Payment',
                        Request_Payload__c = reqBody,
                        Response_Payload__c = res.getBody(),
                        Error_Message__c = '',
                        Status__c = 'Failed',
                        Order__c=o.Order__c  
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
                        '      <p><strong>Order No.:</strong> ' + o.Order__r.Website_Order_Id__c + '</p>' +
                        '      <p><strong>Failure Reason:</strong> ' + res.getBody() + '</p>' +
                         '      <p><strong>Order Date:</strong> ' + o.Order__r.EffectiveDate+ '</p>' +
                        '      <p><strong>Integration Type:</strong> ' + 'Reverse Integration Create Payment' + '</p>' +
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
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    } 
    
}