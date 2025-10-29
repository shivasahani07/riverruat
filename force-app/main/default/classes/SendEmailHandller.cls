/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-10-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class SendEmailHandller {        
    
    public static void SendEmailHandller(list<order> lstOrder, map<id,List<Attachment>> mapOrderIdToAttachments) {
        Set<Id> setAccount = new Set<Id>();
        Set<Id> eligibleOrderIds = new Set<Id>();
        for (Order objOrder : [SELECT Id, AccountId, RecordType.Name FROM Order WHERE Id IN :lstOrder]) {
            if (objOrder.AccountId != null && objOrder.RecordType.Name == 'Vehicle') {
                setAccount.add(objOrder.AccountId);                
            }
        }
        List<OrderItem> lstOrderItems = [ SELECT Id, OrderId, Type__c FROM OrderItem WHERE OrderId IN :lstOrder AND Type__c = 'Vehicle' ];
        for (OrderItem oi : lstOrderItems) {
            eligibleOrderIds.add(oi.OrderId);
        }
        
        System.debug('setAccount==>'+setAccount + ' && eligibleOrderIds==>'+eligibleOrderIds);
        if(setAccount.size()>0 && eligibleOrderIds.size()>0){
            OrgWideEmailAddress orgWideEmailAddresses = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address='support@rideriver.com'];
            string senderEmail = orgWideEmailAddresses.Address; 
            System.debug('orgWideEmailAddresses==>'+orgWideEmailAddresses); 
            Map<string, List<Contact>> mapAccIdToConEmails = New Map<string,List<contact>>();
            List<Contact> lstContact = [SELECT Id, Name, Email, AccountId FROM Contact WHERE AccountId IN :setAccount];
            system.debug('lstContact #1==>'+lstContact);
            if(lstContact.size()>0){
                for(Contact con : lstContact) {
                    if(con.Email != null && con.Email != '') {
                        if(!mapAccIdToConEmails.containsKey(con.AccountId)) {
                            mapAccIdToConEmails.put(con.AccountId, new List<contact>{con});
                        } else {
                            mapAccIdToConEmails.get(con.AccountId).add(con);
                        }
                    }
                }
            }else{
                System.debug('No Contact Found for the Account Id');
            }
            
            system.debug('mapAccIdToConEmails==>'+mapAccIdToConEmails);
            List<Messaging.SingleEmailMessage> Emails = new List<Messaging.SingleEmailMessage>();
            For(order order:lstOrder){
                if (mapAccIdToConEmails.get(order.AccountId) != null && mapAccIdToConEmails.get(order.AccountId).size()>0) {
                    For(Contact objContact : mapAccIdToConEmails.get(order.AccountId)){
                        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                        for (Attachment attachment : mapOrderIdToAttachments.get(order.Id)) {
                            Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                            emailAttachment.setFileName(attachment.Name.replace(' ', '_').replace('-', '_'));
                            emailAttachment.setBody(attachment.Body);
                            emailAttachments.add(emailAttachment);
                        }
                        Messaging.SingleEmailMessage sEmail = new Messaging.SingleEmailMessage();
                        String[] toAddresses = new String[] {objContact.Email}; 
                            System.debug('toAddresses==>'+toAddresses);
                        sEmail.setSubject('Exciting News! Your Order is Ready for Registration');
                        String body = 'Hi ' + objContact.Name + ',<br/><br/>';
                        body += 'We are excited to inform you that your Indie with order number ' ;
                        
                        If(order.Website_Order_Id__c != null && order.Website_Order_Id__c != ''){
                            body += order.Website_Order_Id__c;
                        }else{
                            body += order.OrderNumber;
                        }
                        body +=  ' is now ready for registration!<br/>' ;  
                        body += 'Please find your Invoices/Receipts attached with this email.<br/><br/>' ;
                        body += 'Welcome to the River family!<br/><br/>' ;
                        body += 'Warm Regards,<br/>';
                        body += 'Team River';
                        sEmail.setToAddresses(new String[] { objContact.Email });
                        sEmail.setHtmlBody(body);
                        sEmail.setReplyTo(senderEmail);  
                        sEmail.setOrgWideEmailAddressId(orgWideEmailAddresses.Id);
                        sEmail.setFileAttachments(emailAttachments);
                        Emails.add(sEmail);
                    }
                }   
            }
            
            try {
                Messaging.sendEmail(Emails);
                System.debug('Email sent successfully # SendEmailHandller');
            } catch(Exception e) {
                System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
            }
        }else{
            System.debug('Order is Not Vehicle Type');
        }
    }
    
    //====================================================================================================================================================================
    
    public static void SendEmailHandller2(list<order>lstOrder, List<Attachment> attachmentsToInsert) {
        Set<Id> setAccount = new Set<Id>();
        for (Order objOrder : lstOrder) {
            if (objOrder.AccountId != null) {
                setAccount.add(objOrder.AccountId);                
            }
        }
        
        OrgWideEmailAddress orgWideEmailAddresses = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address='support@rideriver.com'];
        string senderEmail = orgWideEmailAddresses.Address; 
        List<Contact> lstContact = [SELECT Id, Name, Email, AccountId FROM Contact WHERE AccountId IN :setAccount];
        system.debug('lstContact==>'+lstContact);
        List<Messaging.SingleEmailMessage> Emails = new List<Messaging.SingleEmailMessage>();
        for (Contact objContact : lstContact) {
            if (objContact.Email != null) {
                List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                for (Attachment attachment : attachmentsToInsert) {
                    Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                    emailAttachment.setFileName(attachment.Name);
                    emailAttachment.setBody(attachment.Body);
                    emailAttachments.add(emailAttachment);
                }
                Messaging.SingleEmailMessage sEmail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {objContact.Email}; // Use the appropriate email field
                    sEmail.setToAddresses(toAddresses);
                sEmail.setSubject('Pre-Order Receipt');
                String body = 'Hi ' + objContact.Name + ',<br/><br/>' ;
                body += '  <strong>We are glad to confirm your River Indie is booking.</strong><br/><br/>';  
                body += ' Your order booking number is  <strong>' + lstOrder[0].Booking_Payment_Id__c + '</strong>.<br/><br/>';  
                body += ' We will notify you on the progress of your order and keep you updated via the mode of communication chosen by you.(We send all our communication via Email, SMS, and Whatsapp).<br/><br/>' ;
                body += 'For any queries you can contact us at - 9731158443 <br/><br/>';
                body += 'Welcome to the River community!<br/><br/>';    
                body += 'Warm Regards,<br/>';
                body += 'Team River';
                sEmail.setHtmlBody(body);
                sEmail.setReplyTo(senderEmail);  
                sEmail.setOrgWideEmailAddressId(orgWideEmailAddresses.Id);
                sEmail.setFileAttachments(emailAttachments);
                Emails.add(sEmail); 
            }   
        }
        try {
            Messaging.sendEmail(Emails);
            System.debug('Email sent successfully # SendEmailHandller2');
        } catch(Exception e) {
            System.debug('Exception>>' + e);
        }
    }
    
    // ==============================================================================================================================================================================   
    // Send the Pre_payments Attchamnetnts.
    public static void sendPreAttchamnets(string OrderpaymentId, List<Attachment> attachmentsToInsert){
       System.debug('Scheduler For EMail Debug has been called');
        Order_Payment__c op = [
        SELECT Id, Order__c, Order__r.RecordType.Name
        FROM Order_Payment__c
        WHERE Id = :orderPaymentId
        LIMIT 1
    ];

    
    if (op.Order__r.RecordType.Name == 'Vehicle') {
        Datetime dt = Datetime.now().addSeconds(15);

        String cron = String.format('{0} {1} {2} {3} {4} ? {5}',
            new String[]{
                String.valueOf(dt.second()),
                String.valueOf(dt.minute()),
                String.valueOf(dt.hour()),
                String.valueOf(dt.day()),
                String.valueOf(dt.month()),
                String.valueOf(dt.year())
            }
        );

        
        SendEmailScheduler job = new SendEmailScheduler(orderPaymentId, attachmentsToInsert);
        System.schedule('Schedule_SendEmailPDF_' + Datetime.now().getTime(), cron, job);

        System.debug('Scheduled SendEmailScheduler for Vehicle order.');
    } else {
        System.debug('Skipped scheduling — Order Record Type is not Vehicle.');
    }



    //     set<Id>setAccountId=new set<Id>();
    //     list<Order_Payment__c>lstOrderPayment=[SELECT Id,name,Order__c,order__r.AccountId,Order__r.OrderNumber,Amount__c,Order__r.Website_Order_Id__c FROM Order_Payment__c  WHERE Id=:OrderpaymentId];
    //     system.debug('lstOrderPayment==>'+lstOrderPayment);
    //     system.debug('OrderPayment==>'+lstOrderPayment);
        
    //     //fetch Org wide email address
    //     OrgWideEmailAddress orgWideEmailAddresses = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address='support@rideriver.com'];
    //     string senderEmail = orgWideEmailAddresses.Address; 
        
    //     for(Order_Payment__c objOrderPayment :lstOrderPayment){
    //         if(objOrderPayment.order__r.AccountId!=null){
    //             setAccountId.add(objOrderPayment.order__r.AccountId); 
    //         }
    //     } 
    //     List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
    //     list<Contact>lstContact=[select Id, Name,Email,AccountId from contact where AccountId In:setAccountId];
    //     system.debug('lstContact==>'+lstContact);
        
    //     //Add attchaments.
    //     List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        
    //     // Add the attachments to the list
    //     for (Attachment attachment : attachmentsToInsert) {
    //         Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
    //         emailAttachment.setFileName(attachment.Name);
    //         emailAttachment.setBody(attachment.Body);
    //         emailAttachments.add(emailAttachment);
    //     }
        
    //     //Send the Email.
    //     for(contact ObjContact:lstContact){
    //         if(ObjContact.Email!=null){
    //             // Create and send the email
    //             Messaging.SingleEmailMessage sEmail = new Messaging.SingleEmailMessage();
    //             String[] toAddresses = new String[] {objContact.Email}; // Use the appropriate email field
    //                 sEmail.setToAddresses(toAddresses);
    //             sEmail.setSubject('Payment Receipt');
    //             String body = 'Hi ' + objContact.Name + ',<br/><br/>' ;
    //             body += 'Thank you for making the payment of ' + lstOrderPayment[0].Amount__c + ' for Order ' + lstOrderPayment[0].Order__r.Website_Order_Id__c + '.<br/><br/>' ;
    //             body += 'Please find your receipts attached with this email.<br/><br/>' ;
    //             body += 'Warm Regards,<br/>';
    //             body += 'Team River';
    //             sEmail.setHtmlBody(body);  
    //             sEmail.setReplyTo(senderEmail);  
    //             sEmail.setOrgWideEmailAddressId(orgWideEmailAddresses.Id);
                
    //             // Attach the list of attachments to the email
    //             sEmail.setFileAttachments(emailAttachments);
    //             emailMessages.add(sEmail);
    //         }
    //     }
        
    //     if (!emailMessages.isEmpty()){
    //         try {
    //              Messaging.sendEmail(emailMessages);
    //         } catch(Exception e) {
    //             System.debug('Exception>>' + e);
    //         }
    //     }
    //  
            }
    
   
    
}