/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 04-09-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QueueableForUpdateUserOnWebsite implements Queueable, Database.allowsCallouts{
    List<Id> accountIdsToProcess;
    public QueueableForUpdateUserOnWebsite(List<Id> accountIdsToProcess){
           this.accountIdsToProcess = accountIdsToProcess;
    }
    public void execute(QueueableContext qc){
        if(!accountIdsToProcess.isEmpty()){
            Id currentAccountId = accountIdsToProcess.remove(0);
              
            System.debug('currentAccountId==>'+currentAccountId);
            if(currentAccountId != null){
                callUpdateUserAPI(currentAccountId);
            }
            if(!accountIdsToProcess.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new QueueableForUpdateUserOnWebsite(accountIdsToProcess));
            }
        }
    
    }
    public static void callUpdateUserAPI(Id accountId){
        List<Website_Creds__c> rwd = Website_Creds__c.getAll().values();
        Website_Creds__c r = Website_Creds__c.getInstance('Website Creds');
        
        String BASE_URL_FOR_WEBSITE=r.BaseURL__c != null ? r.BaseURL__c : 'could not find base url';
        try{
            if(accountId != null){
                List<Account> accountList = [Select id,Name,Phone,Email__c,BillingStreet,BillingCity,BillingState,BillingPostalCode FROM Account Where Id =:accountId];
                if(!accountList.isEmpty()){
                    Account a = accountList[0];

                    System.debug('Fetched Account Is ==>'+a);

            Map<String,Object> payLoad = new Map<String,Object>();
            Map<String,Object> billing_address = new Map<String,Object>();

            billing_address.put('state', a.BillingState != null ? String.valueof(a.BillingState) : 'No State Is Mentioned');
            billing_address.put('pin_code', a.BillingPostalCode != null ? String.valueof(a.BillingPostalCode) : '');
            billing_address.put('city', a.BillingCity != null ? String.valueof(a.BillingCity) : '');
            billing_address.put('address_2', a.BillingStreet != null ? String.valueof(a.BillingStreet): '');
            billing_address.put('address_1', a.BillingStreet != null ? String.valueof(a.BillingStreet): '');

            payLoad.put('billing_address',billing_address);
            payLoad.put('email_address', a.Email__c != null ? a.Email__c : '');
            payLoad.put('phone_number', a.Phone != null ? a.Phone : '');
            payLoad.put('full_name',a.Name != null ? a.Name : '');
            payLoad.put('crm_account_id',a.Id);

            String reqBody = JSON.serialize(payLoad);
            System.debug('Payload ==>'+ JSON.serializePretty(payLoad));

            String accessToken = reverseIntegrationUtility.gererateAccessToken() /*!= null ? reverseIntegrationUtility.gererateAccessToken() : 'Access Token Was Not Found'*/;
            System.debug('accessToken==>'+accessToken);

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('PATCH');
            req.setEndpoint(BASE_URL_FOR_WEBSITE+'/api/v1/user');
            req.setBody(reqBody);
            req.setHeader('Authorization','Bearer '+accessToken);
            req.setHeader('Content-Type','application/json');

            HttpResponse res = http.send(req);
            if(res.getStatusCode() == 200){
                System.debug('Response from Server is ==>'+res.getBody());
                System.debug('The User Has Been Successfullly Updated in the River Website Database');
            }else{
                System.debug('Some Error Occurred==>'+res.getBody());
            }

                }
            
            }
            




        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number is ==>'+e.getLineNumber());
        }

    }
}