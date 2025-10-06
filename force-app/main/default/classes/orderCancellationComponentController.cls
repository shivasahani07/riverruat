/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 09-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class orderCancellationComponentController {
    @AuraEnabled(cacheable = true)
    public static Order getOrderDetail(Id recordId){
        try{
            System.debug('RecordId==>'+recordId);
            Order o;
            List<Order> orderList = [SELECT Id,Status,Remaining_Amount__c,OrderNumber FROM Order WHERE Id=:recordId LIMIT 1];
            if(!orderList.isEmpty()){
              o = orderList[0];
            }
            return o;
        }catch(Exception e){
            System.debug('Error Fetching Order Details==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            return null;
        }
        
    }
    @AuraEnabled
    public static String updateOrder(String reason,String additionalDetails,String accName,String accNumber,String iFSC,String recordId){
        System.debug('RecordId==>'+recordId);
        try {
            Order o;
            List<Order> orderList = [SELECT Id,Total_Amount_paid__c,Account_Name_Bank__c,Cancellation_Reason__c,Cancellation_Additional_Reason__c,Account_Number__c,IFSC__c,Dealer__c,OrderNumber FROM Order WHERE Id=:recordId LIMIT 1];
            System.debug('Order==>'+orderList);
            if(!orderList.isEmpty()){
                o=orderList[0];
                o.Cancellation_Reason__c=reason;
                o.Cancellation_Additional_Reason__c=additionalDetails;
                o.Account_Name_Bank__c=accName;
                o.Account_Number__c=accNumber;
                o.Assigned_Vehicle__c = null;
                o.Cancel_Order__c = true;
                o.IFSC__c=iFSC;
                o.Refund_Status__c = 'Requested';
                o.Status='Cancellation Requested';
                o.Refund_Amount__c  = o.Total_Amount_paid__c;
                update o;
            }
             
            sendToFinance(o);
            return 'Success';
            
            
        } catch (Exception e) {
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            return 'Error';
        }
    }

    public static void sendToFinance(Order o){
    System.debug('Order Record ==>' + o);

    List<OrgWideEmailAddress> oweaList = [
        SELECT Id FROM OrgWideEmailAddress WHERE Address = 'support@rideriver.com' LIMIT 1
    ];
    System.debug('OrgWideEmailAddress List In Salesforce==>' + oweaList);

    try {
        Account a;
        List<Account> accList = [
            SELECT Id, Email__c, Store_Type__c 
            FROM Account 
            WHERE Id = :o.Dealer__c 
            LIMIT 1
        ];
        if(!accList.isEmpty()){
            a = accList[0];
        }

        String orderNumber = o.OrderNumber; 
        String orderLink = 'https://rivermobilityprivatelimited2--riverlms.sandbox.lightning.force.com' + '/lightning/r/Order/' + o.Id + '/view';
        System.debug('Full Order Link==>' + orderLink);

        // If Store type Is COCO == Comment Added by Aniket
        if(a != null && a.Store_Type__c == 'COCO'){
            User u;
            List<User> userList = [
                SELECT Id, Profile.Name, ProfileId, Email 
                FROM User 
                WHERE Id = '0055j00000BS3XcAAL' 
                LIMIT 1
            ];
            if(!userList.isEmpty()){
                u = userList[0];
            }

            if(u != null){
                Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
                mail2.setToAddresses(new String[]{u.Email});
                mail2.setSubject('Refund Details Required');
                mail2.setOrgWideEmailAddressId(oweaList[0].Id);

                String htmlBody =
                    '<html>' +
                    '<head>' +
                    '<style>' +
                    '  body { font-family: Arial, sans-serif; color: #333; background-color: #f9f9f9; }' +
                    '  .container { padding: 20px; border: 1px solid #ddd; border-radius: 10px; background-color: #ffffff; max-width: 600px; margin: auto; }' +
                    '  h2 { color: #0070d2; text-align: center; }' +
                    '  p { font-size: 14px; line-height: 1.6; }' +
                    '  .details { margin: 20px 0; padding: 15px; background-color: #f4f9ff; border-left: 5px solid #0070d2; }' +
                    '  .details p { margin: 6px 0; font-size: 15px; }' +
                    '  .btn { display: inline-block; padding: 12px 20px; margin-top: 20px; background-color: #0070d2; color: #fff; text-decoration: none; border-radius: 5px; font-weight: bold; }' +
                    '  .btn:hover { background-color: #005bb5; }' +
                    '  .footer { margin-top: 30px; font-size: 12px; color: #888; text-align: center; }' +
                    '</style>' +
                    '</head>' +
                    '<body>' +
                    '  <div class="container">' +
                    '    <h2>💰 Refund Details Required</h2>' +
                    '    <p>Dear Finance Team,</p>' +
                    '    <p>Please provide the <strong>Refund Amount</strong> and <strong>Payment Reference Details</strong> for the below order at the earliest.</p>' +
                    '    <div class="details">' +
                    '      <p><strong>Order Number:</strong> ' + orderNumber + '</p>' +
                    '    </div>' +
                    '    <p>You can update the details by navigating to the order record:</p>' +
                    '    <a class="btn" href="' + orderLink + '">🔗 View Order</a>' +
                    '    <div class="footer">' +
                    '      <p>--<br/>This is an automated message from Salesforce.</p>' +
                    '    </div>' +
                    '  </div>' +
                    '</body>' +
                    '</html>';

                mail2.setHtmlBody(htmlBody);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail2 });
                System.debug('Send Email Result (Finance User): ' + results[0].isSuccess());
            }
        }

        // If Store type Is Not COCO === Comment Added By Aniket
        if(a != null && a.Store_Type__c != 'COCO'){
            Contact c;
            List<Contact> contactList = [
                SELECT Id, Designation__c, AccountId, Email 
                FROM Contact 
                WHERE Designation__c = 'WM' AND AccountId = :a.Id 
                LIMIT 1
            ];
            System.debug('Contact List ==>' + contactList);
            if(!contactList.isEmpty()){
                c = contactList[0];
            }

            if(c != null){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{c.Email});
                mail.setSubject('Refund Details Required');
                mail.setOrgWideEmailAddressId(oweaList[0].Id);

                String htmlBody2 =
                    '<html>' +
                    '<head>' +
                    '<style>' +
                    '  body { font-family: Arial, sans-serif; color: #333; background-color: #f9f9f9; }' +
                    '  .container { padding: 20px; border: 1px solid #ddd; border-radius: 10px; background-color: #ffffff; max-width: 600px; margin: auto; }' +
                    '  h2 { color: #0070d2; text-align: center; }' +
                    '  p { font-size: 14px; line-height: 1.6; }' +
                    '  .details { margin: 20px 0; padding: 15px; background-color: #f4f9ff; border-left: 5px solid #0070d2; }' +
                    '  .details p { margin: 6px 0; font-size: 15px; }' +
                    '  .btn { display: inline-block; padding: 12px 20px; margin-top: 20px; background-color: #0070d2; color: #fff; text-decoration: none; border-radius: 5px; font-weight: bold; }' +
                    '  .btn:hover { background-color: #005bb5; }' +
                    '  .footer { margin-top: 30px; font-size: 12px; color: #888; text-align: center; }' +
                    '</style>' +
                    '</head>' +
                    '<body>' +
                    '  <div class="container">' +
                    '    <h2>💰 Refund Details Required</h2>' +
                    '    <p>Dear Store Manager,</p>' +
                    '    <p>Please provide the <strong>Refund Amount</strong> and <strong>Payment Reference Details</strong> for the below order at the earliest.</p>' +
                    '    <div class="details">' +
                    '      <p><strong>Order Number:</strong> ' + orderNumber + '</p>' +
                    '    </div>' +
                    '    <p>You can update the details by navigating to the order record:</p>' +
                    '    <a class="btn" href="' + orderLink + '">🔗 View Order</a>' +
                    '    <div class="footer">' +
                    '      <p>--<br/>This is an automated message from Salesforce.</p>' +
                    '    </div>' +
                    '  </div>' +
                    '</body>' +
                    '</html>';

                mail.setHtmlBody(htmlBody2);
                Messaging.SendEmailResult[] results2 = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                System.debug('Send Email Result (Store Manager): ' + results2[0].isSuccess());
            }
        }
    } catch (Exception e) {
        System.debug('Error Occured==>' + e.getMessage());
        System.debug('Error Line Number Is==>' + e.getLineNumber());
    }
}

}