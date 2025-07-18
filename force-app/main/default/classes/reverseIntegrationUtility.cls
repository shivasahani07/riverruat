/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 04-09-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class reverseIntegrationUtility {
    public static String gererateAccessToken(){
        // String BASE_URL='https://river-crm-apis.dev.rideriver.com';
        // String CLIENT_ID='7f2a1bk826eb5179ec8e357340408fd444ab346bb1d5fb40a06f6eac590f6b8d51bea40886bf80cd388813f296effa4269550ce98d4e4e5c7e582da19e9faff0';
        // String CLIENT_SECRET='a7ebb3r90eaa4eac1a356c351a0f7c5fdef87c87010298fa84bc728d6db305638b68b6bce984110e8d70fd2e39eab0dbcdd2b5264570ae77e320acb6937afe32';

        List<Website_Creds__c> rwd = Website_Creds__c.getAll().values();
        Website_Creds__c r = Website_Creds__c.getInstance('Website Creds');
        String CLIENT_ID = r.ClientId__c != null ? r.ClientId__c : 'could not find client id';
        String CLIENT_SECRET = r.ClientSecret__c != null ? r.ClientSecret__c : 'could not find client secret';
        String BASE_URL = r.BaseURL__c != null ? r.BaseURL__c : 'could not find base url';

       try{
           Http http = new Http();
           HttpRequest req = new HttpRequest();

           Map<String,Object> reqBody = new Map<String,Object>();
           reqBody.put('client_secret',CLIENT_SECRET);
           reqBody.put('client_id',CLIENT_ID);
           String payLoadForAccessToken = JSON.serialize(reqBody);

           req.setMethod('POST');
           req.setHeader('Content-Type','application/json');
           req.setBody(payLoadForAccessToken);
           req.setEndpoint(BASE_URL+'/api/v1/auth');

           HttpResponse response = http.send(req);
          if(response.getStatusCode() == 200){
           Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
           Map<String,Object> dataForToken = responseMap.containsKey('data')? (Map<String,Object>)responseMap.get('data') : null;
           String accessToken = dataForToken.containsKey('token')? (String)dataForToken.get('token') : null;
           System.debug('Access Token ==>'+accessToken);
           return accessToken;
          

       }
       return 'Access token Was not found';
   }
       catch(Exception e){
           System.debug('Error Occured==>'+e.getMessage());
           System.debug('Error Line Number Is ==>'+e.getLineNumber());
           return null;
       }
    }
}