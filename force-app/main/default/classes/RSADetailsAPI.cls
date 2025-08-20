@RestResource(urlMapping='/RSADetailsAPI')
global class RSADetailsAPI {
    
    @HttpPOST
    global static void getRSADetails(){
        
        RestRequest req = RestContext.request;
        Blob body = req.requestBody;
        try{
            String requestString = req.requestBody != null ? req.requestBody.toString() : '';
            System.debug('requestString : ' + requestString);
            
            if(String.isBlank(requestString)){
                GEN3_Wrapper.setResponses(400, 'Empty Request Body', null);
                return;
            }
            
            GEN3_Wrapper.CheckExtendedWarrantyOrRSAFromPhoneNumber reqData = (GEN3_Wrapper.CheckExtendedWarrantyOrRSAFromPhoneNumber) JSON.deserialize(requestString, GEN3_Wrapper.CheckExtendedWarrantyOrRSAFromPhoneNumber.class); 
            
            System.debug('reqData : ' + reqData);
            
            if(reqData.Phone.length() != 10 || reqData.Phone.startsWith('+91')){
                GEN3_Wrapper.setResponses(401, 'Phone needs to be exact 10 digits and should not include +91', null);
                return;
            }
            
            String receivedPhoneNo = reqData.phone;
            System.debug('receivedPhoneNo : ' + receivedPhoneNo);
            
            Account acc = [
                SELECT Id, Name 
                FROM Account 
                WHERE Phone = :receivedPhoneNo 
                AND Type = 'Customer' 
                LIMIT 1
            ];
            System.debug('acc : ' + acc);
            
            if(acc == null){
                GEN3_Wrapper.setResponses(401, 'No account found with this Phone', null);
                return;
            }
            
            List<Vehicle> vehicles = [
                SELECT Id, Name, RSA_Activation__c, RSA_Subscription_ID__c, 
                RSA_Start_Date__c, RSA_End_Date__c, CurrentOwnerId
                FROM Vehicle
                WHERE CurrentOwnerId = :acc.Id
            ];
            
            System.debug('vehicles : ' + vehicles.size());
            
            if (vehicles.isEmpty()) {
                GEN3_Wrapper.setResponses(401, 'No vehicle registered with this Phone', null);
                return;
            }
            
            List<Map<String, Object>> responseData = new List<Map<String, Object>>();
            
            for(Vehicle vcl : vehicles){
                
                Map<String, Object> row = new Map<String, Object>();
                row.put('vehicleName', vcl.Name);
                row.put('rsaStartDate', vcl.RSA_Start_Date__c);
                row.put('rsaEndDate', vcl.RSA_End_Date__c);
                row.put('rsaActivation', vcl.RSA_Activation__c);
                row.put('rsaSubscriptionId', vcl.RSA_Subscription_ID__c);
                
                responseData.add(row);
                GEN3_Wrapper.setResponses(200, 'RSA Details Fetched Successfully !', responseData);
            }
            System.debug('Try Block Executed Successfully !!');
        }
        catch(Exception ex){
            System.debug('***** ERROR : Line Number : ' + ex.getLineNumber() + ' *****Error Message : ' + ex.getMessage() + ' *****Error StackTrace : ' + ex.getStackTraceString());
            GEN3_Wrapper.setResponses(500, 'Internal Server Error : ' + ex.getMessage(), null);
            
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = 'GEN 3',
                Request_Payload__c = JSON.serializePretty(body),
                Response_Payload__c = 'Error: ' + ex.getMessage(),
                Error_Message__c = 'Exception: ' + ex.getMessage(),
                Status__c = 'Failed'
            );
            insert logObj;
            
        }
    }
}