/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-22-2025
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

            Order order = [Select id,AccountId,Remaining_Amount__c,Website_Response_Id__c,EffectiveDate,Website_Order_Id__c from Order WHERE Id =:current.orderId LIMIT 1];
            // if(order.Website_Response_Id__c == null || order.Website_Response_Id__c == ''){
            //     System.debug('Delete Payment API is not eligible to be called');
            //     return ;
            // }
            Payment__c p = [Select id,Transaction_Id__c from Payment__c WHERE Id =: current.paymentId LIMIT 1];

            Map<String,Object> payload = new Map<String,Object>();
            payload.put('remaining_amount',order.Remaining_Amount__c != null ? order.Remaining_Amount__c : 0);
            payload.put('payment_transaction_id',p.Transaction_Id__c != null ? String.valueof(p.Transaction_Id__c) : 'Not Found');
            payload.put('crm_account_id',order.AccountId != null ? String.valueof(order.AccountId) : 'Not Found');
            payload.put('crm_order_id',order.Id !=null ? String.valueof(order.Id) : 'Not Found');

            System.debug('payload==>'+JSON.serializePretty(payload));

            String accessToken = reverseIntegrationUtility.gererateAccessToken();

            String reqBody = JSON.serialize(payload);
            
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

                
                         Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Reverse Integration Delete Order Payment',
                        Request_Payload__c = reqBody,
                        Response_Payload__c = res.getBody(),
                        Error_Message__c = '',
                        Status__c = 'Success',
                        Order__c=order.Id     
                    );
                    insert logObj;
            } else{
                 Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Reverse Integration Delete Order Payment',
                        Request_Payload__c = reqBody,
                        Response_Payload__c = res.getBody(),
                        Error_Message__c = '',
                        Status__c = 'Failed',
                        Order__c=order.Id 
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
                        '      <p><strong>Order No.:</strong> ' + order.Website_Order_Id__c + '</p>' +
                        '      <p><strong>Failure Reason:</strong> ' + res.getBody() + '</p>' +
                         '      <p><strong>Order Date:</strong> ' + order.EffectiveDate+ '</p>' +
                        '      <p><strong>Integration Type:</strong> ' + 'Reverse Integration Delete Order Payment' + '</p>' +
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
            

        }catch(Exception e){
            System.debug('Error Occured=>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
}