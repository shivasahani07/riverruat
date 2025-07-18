/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 07-10-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/getInvoice')
global with sharing class Gen3AppApiForServiceInvoice {
    @HttpGet
    global static void getInvoicePDF(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        try{
            String reqBody = request.requestBody != null ? request.requestBody.toString() : '';
            System.debug('Request Body ==> ' + reqBody);

            Map<String, Object> requestMap = (reqBody != '') ?  (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String,Object>();
            System.debug('Request Map ==>' + requestMap);

            String accountPhone = requestMap.containsKey('account_phone') ? (String)requestMap.get('account_phone') : 'Not Found';

            if(!Pattern.matches('^\\d{10}$', accountPhone)){
               response.statuscode=400;
               response.responsebody=responseUtility('Phone Number Must Be Exactly 10 Digits',false);
               return;
            }
            
            Account a ;
            List<Account> accountList = [SELECT Id,Phone FROM Account WHERE Phone =:accountPhone LIMIT 1];
            if(accountList.isEmpty()){
                response.statuscode=400;
                response.responsebody=responseUtility('No Account Was Found with this phone number '+accountPhone,false);
                return;
            }
            if(!accountList.isEmpty()){
                a = accountList[0];
            }

            WorkOrder w;
            
            List<WorkOrder> jobCardList = [SELECT Id,Invoice_PDF_Link__c,AccountId,CreatedDate FROM WorkOrder WHERE AccountId =: a.Id ORDER BY CreatedDate LIMIT 1];
            if(jobCardList.isEmpty()){
                response.statuscode=400;
                response.responsebody=responseUtility('No Service Record found in Salesforce ',false);
                return;
            }
            if(!jobCardList.isEmpty()){
                 w = jobCardList[0];

                 if(w.Invoice_PDF_Link__c == null || w.Invoice_PDF_Link__c == ''){
                response.statuscode=400;
                response.responsebody=responseUtility('Invoice is still not generated ',false);

                return;
                 }
            }
            
            Map<String,Object> responseMap = new Map<String,Object>();
            Map<String,Object> data = new Map<String,Object>();

            data.put('success',true);
            data.put('PDF_Link',String.valueof(w.Invoice_PDF_Link__c));

            responseMap.put('data',data);

            response.statuscode=200;
            response.responsebody = Blob.valueOf(JSON.serializePretty(responseMap));


        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
    public static Blob responseUtility(String Message,Boolean status){
        try{
            Map<String,Object> responseBody = new Map<String,Object>();
            responseBody.put('message',Message);
            responseBody.put('status',status);
            Blob serializedRes = Blob.valueOf(JSON.serializePretty(responseBody));
            return serializedRes;
        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            return null;
        }
    }
}