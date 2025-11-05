/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 11-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/changeCustomerDetails/*')
global without sharing class ChangeUserDetailsAPI {
    
     @HttpPatch
     global static void changeDetails(){
           RestRequest req = RestContext.request;
           RestResponse response = RestContext.response;
           String phoneNumber;
        try{

            System.debug('Req==>'+req.toString());

            Account a;
            
            if(!req.params.containsKey('existing_phone')){
                response.statusCode=404;
                response.responseBody=responseCommonMethod('failure','Please Provide Existing Phone','404');

                createLogRecords(req.toString(),response.responseBody.toString(),'Failed');

                return;

                
            }
            phoneNumber = req.params.get('existing_phone');
            List<Account> accList = [SELECT Id,Name,Email__c,Phone FROM Account WHERE Phone=:phoneNumber LIMIT 1];
            if(accList.isEmpty()){
                response.statusCode=404;
                response.responseBody=responseCommonMethod('failure','No Account Was Found with Phone Number '+phoneNumber,'404');

                createLogRecords(req.toString(),response.responseBody.toString(),'Failed');

                return;
            }
            a = accList[0];

            if(req.params.containsKey('new_phone')){
                a.Phone = req.params.get('new_phone');
            }
            if(req.params.containsKey('new_email')){
                a.Email__c = req.params.get('new_email');
            }
            if(req.params.containsKey('new_name')){
                a.Name = req.params.get('new_name');
            }
            update a;
            response.statusCode=200;
            response.responseBody=responseCommonMethod('success','','200');
            createLogRecords(req.toString(),response.responseBody.toString(),'Success');
            System.debug('Response Body ==>'+response.responseBody.toString());
            




        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is==>'+e.getLineNumber());
        }
     }
     private static Blob responseCommonMethod(String typeOfResponse,String errorMessage,String statusCode){
        try{
            Map<String,Object> responseBody = new Map<String,Object>();
            Map<String,Object> data = new Map<String,Object>();
            if(typeOfResponse == 'success'){
              data.put('success','true');
              data.put('message','Details are Updated successfully!!!');
            }else{
              data.put('success','false');
              data.put('message',errorMessage);
            }
            
            
            responseBody.put('data',data);
            responseBody.put('status',statusCode);

            Blob responseAsPayLoad = Blob.valueOf(JSON.serializePretty(responseBody));

            return responseAsPayLoad;

        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            return null;
        }
    }
    public static void createLogRecords(String reqBody,String resBody,String status){
        try{
            Integration_Log__c i = new Integration_Log__c();
            i.Request_Payload__c = reqBody;
            i.Response_Payload__c=resBody;
            i.Status__c=status;
            i.Integration_Type__c = 'Mobile App Account Detail Change';

            insert i;

        }catch(Exception e){
            System.debug('Error Occured in Creating Log Record==>'+e.getMessage() + ' And Error Line Number Is==>'+e.getLineNumber());
        }
    }
}