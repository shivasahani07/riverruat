/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 07-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class POCreationInSAPQueueable implements Queueable,Database.allowsCallouts{
    private List<Id> poIds;
    public POCreationInSAPQueueable(List<Id> poIds) {
       this.poIds=poIds;
    }
    public void execute(QueueableContext qc){
        if(!poIds.isEmpty()){
            Id currentPOId = poIds.remove(0);
            if(currentPOId != null){
                callSAPApi(currentPOId);
            }
            if(!poIds.isEmpty() && !Test.isRunningTest()){
                System.enqueuejob(new POCreationInSAPQueueable(poIds));
            }

        }
    }
    public static void callSAPApi(Id currentPOId){
        System.debug('SAP API Method Called');
        System.debug('Current PO Id Is ==>'+currentPOId);
        try{
            ProductRequest p;
            List<ProductRequest> poRecordList = [SELECT Id,ProductRequestNumber,CreatedDate,ShipmentType,Contact__r.Dealer_Code__c,Synch_with_SAP__c,SAP_SO_Number__c,Contact__r.Account.Store_Type__c,Product_Type__c FROM ProductRequest WHERE Id=:currentPOId];
            System.debug('PO Records ==>'+poRecordList);
            if(!poRecordList.isEmpty()){
                p=poRecordList[0];
            } 
            if(p.Contact__r.Account.Store_Type__c != 'DODO') return;

            List<ProductRequestLineItem> poLineItems = [SELECT Id,ParentId,QuantityRequested,Product2.ProductCode From ProductRequestLineItem WHERE ParentId=:p.Id];
            if(poLineItems.isEmpty()){
                return;
            }
            Date createdDate = p.CreatedDate.date(); 
            String formattedDate = p.CreatedDate.formatGmt('yyyy-MM-dd') + 'T00:00:00';

            Map<String,Object> payload = new Map<String,Object>();
            List<Map<String,Object>> ItemList = new List<Map<String,Object>>();
            for(ProductRequestLineItem pr : poLineItems){
                Map<String,Object> item = new Map<String,Object>();
                item.put('Quantity',String.valueOf(pr.QuantityRequested.setScale(0)));
                item.put('ItemCode',String.valueof(pr.Product2.ProductCode));
                ItemList.add(item);
            }
            payload.put('ItemList',ItemList);
            payload.put('SalesForceId',String.valueof(p.Id));
            payload.put('OrderType',String.valueof(p.ShipmentType));
            payload.put('RequestedDeliveryDate',formattedDate);//Hardcoded for Now 
            payload.put('CustomerPurchaseOrderDate',formattedDate);
            payload.put('PurchaseOrderByCustomer',String.valueof(p.ProductRequestNumber));
            payload.put('OrganizationDivision',p.Product_Type__c == 'Vehicle' ? '01' : p.Product_Type__c == 'Service' ? '02' : p.Product_Type__c == 'Accessories' ? '03' : p.Product_Type__c == 'Merchandise' ? '04' : '02');//HardCoded For Now 
            payload.put('PartyCode',String.valueof(p.Contact__r.Dealer_Code__c));

            String serializedBody = JSON.serializePretty(payload);
            System.debug('Payload==>'+serializedBody);

            Http http = new Http();
            
            List<SAP_API_Creds__c> rwd = SAP_API_Creds__c.getAll().values();
            SAP_API_Creds__c r = SAP_API_Creds__c.getInstance('SAP API Creds');
            
            //String username = 'RiverSalesForce';
            //String password = 'River_SF_Devp';
            
            String username = r.User_Name__c;
            String password = r.Password__c;
            String endPoint = r.Endpoint__c;
            
            String credentials = username + ':' + password;
            String encodedCredentials = EncodingUtil.base64Encode(Blob.valueOf(credentials));

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Basic ' + encodedCredentials);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(serializedBody);

            HttpResponse res = Http.send(req);

             System.debug('Response Body==>'+res.getBody());
            if(res.getStatusCode() == 200){
                System.debug('Response Body==>'+res.getBody());
                Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                
                String message = responseMap.containsKey('message') ? (String)responseMap.get('message') : 'Not Found';
                String soNumber = responseMap.containsKey('sapDocumentDetails') ? (String)responseMap.get('sapDocumentDetails'):'Blank';
                if(message == 'Successfully Posted the Data to SAP!!'){
                    System.debug('Success Response Received');
                     p.SAP_SO_Number__c=soNumber;
                     p.Synch_with_SAP__c = true;
                     update p;
                     System.debug('Updated PO Is ==>'+p);
                }
            }else{
                Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                String msg = responseMap.containsKey('message') ? (String)responseMap.get('message') : 'Not Found';
                System.debug('Error Message Is ==>'+msg);

                Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'SAP',
                        Request_Payload__c = serializedBody,
                        Response_Payload__c = res.getBody(),
                        Error_Message__c = msg,
                        Status__c = 'Failed'
                    );
                    insert logObj;

                //added by Aniket on 11/07/2025
                Group g;
                List<Group> sapGroup = [SELECT Id,Name,DeveloperName from Group WHERE DeveloperName = 'SAP_Group' LIMIT 1];
                System.debug('sapGroup=>'+sapGroup);
                if(!sapGroup.isEmpty()){
                    g=sapGroup[0];
                    System.debug('G==>'+g);
                }
                List<GroupMember> members = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :g.Id];
                System.debug('members==>'+members);
                Set<Id> userIds = new Set<Id>();
                for (GroupMember gm : members) {
                    if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
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
                mail2.setSubject('SAP Sync Failure');
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
                        '    <h2>🚨 SAP Sync Failure</h2>' +
                        '    <p>Dear SAP Group Users,</p>' +
                        '    <p>The following Purchase Order failed to sync with SAP. Please review the details below and take appropriate action.</p>' +
                        '    <div class="po-details">' +
                        '      <p><strong>Purchase Order Number:</strong> ' + p.ProductRequestNumber + '</p>' +
                        '      <p><strong>Failure Reason:</strong> ' + msg + '</p>' +
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
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ===>'+e.getLineNumber());
        }
    }
}