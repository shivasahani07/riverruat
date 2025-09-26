/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 09-22-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/getCustomerDetails/*')
global without sharing class TelematicsAPI {
    @HttpGet
    global static void getCustomerDetails(){
       
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Vehicle v;
        String vehicleIdentificationNumber;

        try{
            
            vehicleIdentificationNumber = req.requestURI.subString(req.requestURI.lastIndexOf('/')+1);
            System.debug('Vehicle Identification Number Is ==>'+ vehicleIdentificationNumber);

            List<Vehicle> vehicleList = [SELECT Id,CurrentOwner.Phone,CurrentOwner.Name,VehicleIdentificationNumber,CurrentOwnerId FROM Vehicle WHERE VehicleIdentificationNumber=:vehicleIdentificationNumber LIMIT 1];
            if(vehicleList.isEmpty()){
                res.statusCode=404;
                res.responseBody = responseCommonMethod('','','404','','No Vehicle Was Found With The VIN '+vehicleIdentificationNumber,'failure');
                return;
            }

            v = vehicleList[0];
            if(String.isBlank(v.CurrentOwnerId)){
              res.statusCode = 404;
              res.responseBody = responseCommonMethod('','','404','','The Vehicle Does Not Have Any Owner','failure');
              return;
            }else{
              res.statusCode = 200;
              res.responseBody = responseCommonMethod(v.CurrentOwner.Name != ''? v.CurrentOwner.Name : 'Not Found',
                                                     v.CurrentOwner.Phone != ''? v.CurrentOwner.Phone : 'Not Found',
                                                    '200',
                                                    v.VehicleIdentificationNumber != '' ? v.VehicleIdentificationNumber : 'Not Found',
                                                    '','success');
            }
            
            
            
            

        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());

        }

    }
    private static Blob responseCommonMethod(String customerName,String phoneNumber,String statusCode,String VIN,String message,String typeOfResponse){
        try{
            Map<String,Object> responseBody = new Map<String,Object>();
            Map<String,Object> data = new Map<String,Object>();
            if(typeOfResponse == 'success'){
              data.put('phone_number',phoneNumber);
              data.put('customer_name',customerName);
              data.put('vin',VIN);
            }else{
              data.put('message',message);
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
}