/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-07-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class AccessTokenSimActivation {
    public static String getAccessToken(){
       
        List<SIM_Activation_API_Details__c> sim = SIM_Activation_API_Details__c.getAll().values();
        SIM_Activation_API_Details__c s = SIM_Activation_API_Details__c.getInstance('SIM Activation API Details');
        String userName = s.UserName__c != null ? s.UserName__c : 'could not find User Name';
        String password = s.Password__c != null ? s.Password__c : 'could not find Password';
        String BASE_URL = s.Basu_URL__c != null ? s.Basu_URL__c : 'could not find Base Url';

        try{
            String creds = userName + ':' + password;
            String encodedAuth = EncodingUtil.base64Encode(Blob.valueOf(creds));


            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(BASE_URL+'/token/');
            req.setHeader('Authorization','Basic '+encodedAuth);

            String body = 'grant_type=client_credentials' + '&Username=' + EncodingUtil.urlEncode(userName, 'UTF-8')+ '&Password=' + EncodingUtil.urlEncode(password, 'UTF-8');
            req.setBody(body);

            HttpResponse res = http.send(req);
            if(res.getStatusCode()== 200){
                System.debug('Response Body ==>'+res.getBody());
                Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                String accessToken = responseMap.containsKey('access_token') ? (String)responseMap.get('access_token') : 'Error Parsing Access Token';
                String refreshToken = responseMap.containsKey('refresh_token') ? (String)responseMap.get('refresh_token') : 'Error Parsing Refresh Token';

                return accessToken;
            }else{
                System.debug('Response Body ==>'+res.getBody());
                return 'Error In Getting Access and Refresh Token';
            }
            
        


        }catch(Exception e){
            System.debug('Error In Getting Access Token==>'+e.getMessage());
            System.debug('Error Line Number Is ===>'+e.getLineNumber());
            return 'Error';
        }
    }
}