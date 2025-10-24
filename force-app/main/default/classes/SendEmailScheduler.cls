/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 10-10-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class SendEmailScheduler implements Schedulable {
    
    //private String orderPaymentId;
    private String OrderpaymentId;
    private List<Attachment> attachmentsToInsert;
    
    // Constructor to pass parameters
    public SendEmailScheduler(String OrderpaymentId,List<Attachment> attachmentsToInsert){
        this.OrderpaymentId=OrderpaymentId;
        this.attachmentsToInsert=attachmentsToInsert;
        //this.emailList=emailList;
    }
    
    public void execute(SchedulableContext sc) {
        set<Id>setAccountId=new set<Id>();
        list<Order_Payment__c>lstOrderPayment=[SELECT Id,name,Order__c,order__r.AccountId,Order__r.OrderNumber,Amount__c,Order__r.Website_Order_Id__c FROM Order_Payment__c  WHERE Id=:OrderpaymentId];
        system.debug('lstOrderPayment==>'+lstOrderPayment);
        system.debug('OrderPayment==>'+lstOrderPayment);
        
        //fetch Org wide email address
        OrgWideEmailAddress orgWideEmailAddresses = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address='support@rideriver.com'];
        string senderEmail = orgWideEmailAddresses.Address; 
        
        for(Order_Payment__c objOrderPayment :lstOrderPayment){
            if(objOrderPayment.order__r.AccountId!=null){
                setAccountId.add(objOrderPayment.order__r.AccountId); 
            }
        } 
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        list<Contact>lstContact=[select Id, Name,Email,AccountId from contact where AccountId In:setAccountId];
        system.debug('lstContact==>'+lstContact);
        
        //Add attchaments.
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        
        // Add the attachments to the list
        for (Attachment attachment : attachmentsToInsert) {
            Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
            emailAttachment.setFileName(attachment.Name);
            emailAttachment.setBody(attachment.Body);
            emailAttachments.add(emailAttachment);
        }
        
        //Send the Email.
        for(contact ObjContact:lstContact){
            if(ObjContact.Email!=null){
                // Create and send the email
                Messaging.SingleEmailMessage sEmail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {objContact.Email}; // Use the appropriate email field
                    sEmail.setToAddresses(toAddresses);
                sEmail.setSubject('Payment Receipt');
                String body = 'Hi ' + objContact.Name + ',<br/><br/>' ;
                body += 'Thank you for making the payment of ' + lstOrderPayment[0].Amount__c + ' for Order ' + lstOrderPayment[0].Order__r.Website_Order_Id__c + '.<br/><br/>' ;
                body += 'Please find your receipts attached with this email.<br/><br/>' ;
                body += 'Warm Regards,<br/>';
                body += 'Team River';
                sEmail.setHtmlBody(body);  
                sEmail.setReplyTo(senderEmail);  
                sEmail.setOrgWideEmailAddressId(orgWideEmailAddresses.Id);
                
                // Attach the list of attachments to the email
                sEmail.setFileAttachments(emailAttachments);
                emailMessages.add(sEmail);
            }
        }
        
        if (!emailMessages.isEmpty()){
            try {
                Messaging.sendEmail(emailMessages);
            } catch(Exception e) {
                System.debug('Exception>>' + e);
            }
        }
    }  
}