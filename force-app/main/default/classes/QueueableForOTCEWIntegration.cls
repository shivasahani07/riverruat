/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class QueueableForOTCEWIntegration implements Queueable, Database.allowsCallouts{
    private List<Id> orderIdsToProcess;
    private Map<Id,OrderInvoiceGenerationOTCController.wrapperForEWIntegration> wrapperValues;
    public QueueableForOTCEWIntegration(List<Id> orderIdsToProcess, Map<Id,OrderInvoiceGenerationOTCController.wrapperForEWIntegration> wrapperValues){
        this.orderIdsToProcess=orderIdsToProcess;
        this.wrapperValues=wrapperValues;

    }
    public void execute(QueueableContext qc){
        if(!orderIdsToProcess.isEmpty()){
            Id currentOrderId = orderIdsToProcess.remove(0);
            
            
            if(currentOrderId != null && wrapperValues!=null){
                calloutToEWAPI(currentOrderId,wrapperValues);
            }
            if(!orderIdsToProcess.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableForOTCEWIntegration(orderIdsToProcess,wrapperValues));
            }
            
    }
}
public static void calloutToEWAPI(Id currentOrderId,Map<Id,OrderInvoiceGenerationOTCController.wrapperForEWIntegration> c){
    try{
            List<EW_API_Details__c> ewDetails= EW_API_Details__c.getAll().values();
            EW_API_Details__c apiDetails = EW_API_Details__c.getInstance('EW Integration');
            String endPoint = apiDetails.API_Endpoint__c != null ? apiDetails.API_Endpoint__c : '';
            String token = apiDetails.Token__c != null ? apiDetails.Token__c : '';
            String apiKey =  apiDetails.API_Key__c != null ? apiDetails.API_Key__c : '';
            String cookie = apiDetails.Cookie__c != null ? apiDetails.Cookie__c : '';
            
            String vpDate = String.valueof(c.get(currentOrderId).purchaseDate);
            System.debug('Date ==>'+vpDate);
            List<String> datePart = vpDate.split('-');
            String dateForReqBody = datePart[2]+'-'+datePart[1]+'-'+datePart[0];
            System.debug('dateForReqBody==>'+dateForReqBody);
            
            String dealerCodeFor = c.get(currentOrderId).dealerCode;
            
            OrderItem orderProd;
            List<OrderItem> orderProductList = [SELECT Id,OrderId,Product2Id,Product2.Name,Product2.ProductCode,Order.Account.Name,Order.Account.Email__c,Order.Account.Phone,Order.Assigned_Vehicle__r.CurrentOwner.Name,Order.Assigned_Vehicle__r.CurrentOwner.Email__c,Order.Assigned_Vehicle__r.CurrentOwner.Phone FROM OrderItem WHERE OrderId=:currentOrderId AND Product2.ProductCode LIKE '%RV-EW%' LIMIT 1];
            if(!orderProductList.isEmpty()){
                orderProd = orderProductList[0];
            }

            String ewPlan;
            if(orderProd.Product2.ProductCode == 'RV-EW-1' || orderProd.Product2.ProductCode == 'RV-EW-2' || orderProd.Product2.ProductCode == 'RV-EW-3'){
                ewPlan = '5 Years or 50,000Kms';
            }
            if(orderProd.Product2.ProductCode == 'RV-EW-4' || orderProd.Product2.ProductCode == 'RV-EW-5' || orderProd.Product2.ProductCode == 'RV-EW-6' ||orderProd.Product2.ProductCode == 'RV-EW-7'){
                ewPlan = '8 Years or 80,000Kms';
            }
            

            Account a = [SELECT Id,Center_Code__c,Type FROM Account WHERE Center_Code__c=:dealerCodeFor LIMIT 1];
            Map<String,Object> payLoad = new Map<String,Object>();
            payLoad.put('username',c.get(currentOrderId).dealerCode);
            payLoad.put('VehicleSaleDate',dateForReqBody);
            payLoad.put('ChassisNo',c.get(currentOrderId).chassisNumber);
            payLoad.put('Model',c.get(currentOrderId).model);
            payLoad.put('BatteryNo',c.get(currentOrderId).battery);
            payLoad.put('Motor',c.get(currentOrderId).engineNumber);
            payLoad.put('Charger',c.get(currentOrderId).charger);
            payLoad.put('WarrantyType','Extended Warranty');
            payLoad.put('SoldFrom',a.Type == 'Dealer' ? 'Showroom' : a.Type == 'Service Center' ? 'Workshop' : 'Nothing' );
            payLoad.put('EWPlan',ewPlan);
            payLoad.put('CustomerEmail',orderProd.Order.Assigned_Vehicle__r.CurrentOwner.Email__c != null ? orderProd.Order.Assigned_Vehicle__r.CurrentOwner.Email__c : 'Blank');
            payLoad.put('CustomerName',orderProd.Order.Assigned_Vehicle__r.CurrentOwner.Name != null ? orderProd.Order.Assigned_Vehicle__r.CurrentOwner.Name : 'Blank');
            payLoad.put('CustomerMobile',orderProd.Order.Assigned_Vehicle__r.CurrentOwner.Phone != null ? orderProd.Order.Assigned_Vehicle__r.CurrentOwner.Phone : 'Blank');

            String reqBody = JSON.serialize(payLoad);
            System.debug('Request body=>'+JSON.serializePretty(payLoad));

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Cookie',cookie);
            req.setHeader('Authorization','Token '+token);
            req.setHeader('X-API-Key',apiKey);
            req.setBody(reqBody);
            
            HttpResponse res = http.send(req);
            try{
                if(res.getStatusCode() == 200 || res.getStatusCode() == 201){

                    
                    Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                    System.debug('Response Map==>'+responseMap);

                    if(responseMap.containsKey('status') && responseMap.get('status') == 'success'){

                        if(!responseMap.containsKey('EW Start Date') || !responseMap.containsKey('EW Expire Date')){
                            handleEWError(reqBody, res.getBody(), 'Either Start Date or Expiry Date Missing', c.get(currentOrderId).chassisNumber,currentOrderId);
                            return;
                        }


                        String inputDateForStartDate = String.valueOf(responseMap.get('EW Start Date')); 
                    String inputDateForExpireDate = String.valueOf(responseMap.get('EW Expire Date')); 
                    
                    Date ewStartDate;
                    if (inputDateForStartDate != null && inputDateForStartDate.contains('-')) {
                        List<String> dateParts = inputDateForStartDate.split('-');
                        if (dateParts.size() == 3) {
                            String formattedDateForEWSTART = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0];
                            ewStartDate = Date.valueOf(formattedDateForEWSTART); 
                            System.debug('Formatted Date for Start: ' + ewStartDate);
                        }
                    }
        
                    Date ewExpireDate;
                    if (inputDateForExpireDate != null && inputDateForExpireDate.contains('-')) {
                        List<String> datePartsForExpire = inputDateForExpireDate.split('-');
                        if (datePartsForExpire.size() == 3) {
                            String formattedDateForEWExpire = datePartsForExpire[2] + '-' + datePartsForExpire[1] + '-' + datePartsForExpire[0];
                            ewExpireDate = Date.valueOf(formattedDateForEWExpire); 
                            System.debug('Formatted Date For Expire: ' + ewExpireDate);
                        }
                    }
                    //for conversion of Currency Field
                    
                        String dealerAmountStr = String.valueOf(responseMap.get('Dealer Amount'));

                        
                        String customerAmountStr = String.valueOf(responseMap.get('Customer Amount'));

                        
                        Decimal dealerAmount = 0;
                        Decimal customerAmount = 0;

                       
                        if (String.isNotBlank(dealerAmountStr)) {
                        try {
                            dealerAmount = Decimal.valueOf(dealerAmountStr);
                            dealerAmount = dealerAmount.setScale(2); 
                        } catch (Exception e) {
                            System.debug('Error converting Dealer Amount to Decimal: ' + e.getMessage());
                        }
                        }

                        
                        if (String.isNotBlank(customerAmountStr)) {
                        try {
                            customerAmount = Decimal.valueOf(customerAmountStr);
                            customerAmount = customerAmount.setScale(2); 
                        } catch (Exception e) {
                            System.debug('Error converting Customer Amount to Decimal: ' + e.getMessage());
                        }
                        }

                    Vehicle v = [Select Id,Policy_Number__c,EW_Start_Date__c,EW_Expire_Date__c,Dealer_Amount__c,Customer_Amount__c,EW_Submitted__c from Vehicle WHERE Id =:c.get(currentOrderId).vehicleId LIMIT 1];
                    v.EW_Policy_Number__c = (String) responseMap.get('Policy No');
                    v.EW_Start_Date__c= ewStartDate;
                    v.EW_Expire_Date__c = ewExpireDate;
                    v.Dealer_Amount__c = dealerAmount;
                    v.Customer_Amount__c = customerAmount;
                    v.EW_Submitted__c=true;  
                    v.EW_Plan__c=(String) responseMap.get('EWPlan'); 
                    v.Certificate_For_EW__c = (String) responseMap.get('Certificate URL'); 
                    update v;
                    System.debug('Updated Vehicle==>'+v);
                
                    Integration_Log__c logObj = new Integration_Log__c(
                        Integration_Type__c = 'Extended Warranty',
                        Request_Payload__c = reqBody,
                        Response_Payload__c = res.getBody(),
                        //Error_Message__c = msg,
                        Status__c = 'Success',
                        Order__c=currentOrderId
                    );
                    insert logObj;

                    }else if(responseMap.containsKey('status') && responseMap.get('status') == 'error'){
                        String errorMessage = '';
                        if (responseMap.containsKey('message')) {
                            errorMessage = (String) responseMap.get('message');
                        }
                        handleEWError(reqBody, res.getBody(), errorMessage, c.get(currentOrderId).chassisNumber,currentOrderId);
                    }
                                            
                    
                }else if(res.getStatusCode() != 200 || res.getStatusCode() != 201){
                    Map<String,Object> responseMapForError = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                    String errorMessage = (String) responseMapForError.get('message');
                    handleEWError(reqBody, res.getBody(), errorMessage, c.get(currentOrderId).chassisNumber,currentOrderId);
                
                    
                }
            }
            catch(Exception err){
                
                System.debug('Error is ==>'+err.getMessage());
                System.debug('Error Line Is ==>'+err.getLineNumber());
            }

            }
            catch(Exception e){
                System.debug('Error Occured ==>'+e.getMessage());
                System.debug('Error Line Number Is===>'+e.getLineNumber());
            }

    }
    private static void handleEWError(
    String reqBody,
    String resBody,
    String errorMessage,
    String chassisNumber,
    Id orderId
) {
    try {
        
        Integration_Log__c logObj = new Integration_Log__c(
            Integration_Type__c = 'Extended Warranty',
            Request_Payload__c = reqBody,
            Response_Payload__c = resBody,
            Error_Message__c = errorMessage,
            Status__c = 'Failed',
            Order__c=orderId
        );
        insert logObj;

        // 2. Fetch EW group
        Group g;
        List<Group> sapGroup = [SELECT Id FROM Group WHERE DeveloperName = 'EW_Group' LIMIT 1];
        if (!sapGroup.isEmpty()) {
            g = sapGroup[0];
        }

        // 3. Fetch group members
        List<GroupMember> members = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :g.Id];
        Set<Id> userIds = new Set<Id>();
        for (GroupMember gm : members) {
            if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
                userIds.add(gm.UserOrGroupId);
            }
        }

        // 4. Fetch user emails
        List<User> users = [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];
        List<String> emailList = new List<String>();
        for (User u : users) {
            emailList.add(u.Email);
        }

        // 5. Prepare and send the email
        if (!emailList.isEmpty()) {
            List<OrgWideEmailAddress> oweaList = [
                SELECT Id FROM OrgWideEmailAddress WHERE Address = 'support@rideriver.com' LIMIT 1
            ];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(emailList);
            mail.setSubject('SAP Sync Failure');
            mail.setOrgWideEmailAddressId(oweaList.isEmpty() ? null : oweaList[0].Id);

            String htmlBody = 
                '<html>' +
                '<head>' +
                '<style>' +
                'body { font-family: Arial, sans-serif; color: #333; }' +
                '.container { padding: 20px; border: 1px solid #ccc; border-radius: 8px; background-color: #f9f9f9; }' +
                'h2 { color: #d9534f; }' +
                '.po-details { margin-top: 20px; padding: 15px; background-color: #fff3cd; border-left: 5px solid #ffeeba; }' +
                '.footer { margin-top: 30px; font-size: 12px; color: #888; }' +
                '</style>' +
                '</head>' +
                '<body>' +
                '<div class="container">' +
                '<h2>🚨 EW Sync Failure</h2>' +
                '<p>Dear EW Group Users,</p>' +
                '<p>The following Vehicle failed to sync with EW Portal. Please review the details below and take appropriate action.</p>' +
                '<div class="po-details">' +
                '<p><strong>VIN No.:</strong> ' + chassisNumber + '</p>' +
                '<p><strong>Failure Reason:</strong> ' + errorMessage + '</p>' +
                '</div>' +
                '<p>Kindly address this issue at the earliest.</p>' +
                '<div class="footer">' +
                '<p>--<br/>This is an automated message from Salesforce.</p>' +
                '</div>' +
                '</div>' +
                '</body>' +
                '</html>';

            mail.setHtmlBody(htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    } catch (Exception e) {
        System.debug('Error in handleEWError: ' + e.getMessage());
    }
}

       

}