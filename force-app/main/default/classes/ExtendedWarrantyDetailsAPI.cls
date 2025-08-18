@RestResource(urlMapping='/ExtendedWarrantyDetailsAPI')
global class ExtendedWarrantyDetailsAPI {
    
    @HttpPOST
    global static void getWarrantyDetails() {
        
        RestRequest req = RestContext.request;

        try{
            String requestString = req.requestBody != null ? req.requestBody.toString() : '';
            System.debug('requestString : ' + requestString);

            if(String.isBlank(requestString)){
                GEN3_Wrapper.setExtendedWarrantyOrRSAResponse(400, 'Empty Request Body', null);
                return;
            }

            GEN3_Wrapper.CheckExtendedWarrantyOrRSAFromPhoneNumber reqData = (GEN3_Wrapper.CheckExtendedWarrantyOrRSAFromPhoneNumber) JSON.deserialize(requestString, GEN3_Wrapper.CheckExtendedWarrantyOrRSAFromPhoneNumber.class); 
            System.debug('reqData : ' + reqData);

            if(reqData.Phone.length() != 10 || reqData.Phone.startsWith('+91')){
                GEN3_Wrapper.setExtendedWarrantyOrRSAResponse(401, 'Phone needs to be exact 10 digits and should not include +91', null);
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
                GEN3_Wrapper.setExtendedWarrantyOrRSAResponse(401, 'No account found with this Phone', null);
                return;
            }

            List<Vehicle> vehicles = [
                SELECT Id, Name, EW_Start_Date__c, EW_Expire_Date__c, 
                Dealer_Amount__c, Customer_Amount__c, EW_Submitted__c, CurrentOwnerId 
                FROM Vehicle 
                WHERE CurrentOwnerId = :acc.Id
            ];
            System.debug('vehicles : ' + vehicles.size());

            if (vehicles.isEmpty()) {
                GEN3_Wrapper.setExtendedWarrantyOrRSAResponse(401, 'No vehicle registered with this Phone', null);
                return;
            }
            
            List<Map<String, Object>> responseData = new List<Map<String, Object>>();

            for(Vehicle vcl : vehicles){

                Map<String, Object> row = new Map<String, Object>();
                row.put('vehicleName', vcl.Name);
                row.put('ewStartDate', vcl.EW_Start_Date__c);
                row.put('ewExpiryDate', vcl.EW_Expire_Date__c);
                row.put('dealerAmount', vcl.Dealer_Amount__c);
                row.put('customerAmount', vcl.Customer_Amount__c);
                row.put('ewSubmitted', vcl.EW_Submitted__c);

                responseData.add(row);
                GEN3_Wrapper.setExtendedWarrantyOrRSAResponse(200, 'Warranty Details Fetched Successfully !', responseData);
            }
            System.debug('Try Block Executed Successfully !!');
        }
        catch(Exception ex){
            System.debug('***** ERROR  : Line Number : ' + ex.getLineNumber() + ' *****Error Message : ' + ex.getMessage() + ' *****Error StackTrace : ' + ex.getStackTraceString());
            GEN3_Wrapper.setExtendedWarrantyOrRSAResponse(500, 'Internal Server Error : ' + ex.getMessage(), null);

            /*
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = 'GEN 3',
                Request_Payload__c = JSON.serializePretty(body),
                Response_Payload__c = 'Error: ' + e.getMessage(),
                Error_Message__c = 'Exception: ' + e.getMessage(),
                Status__c = 'Failed'
            );
            insert logObj;
            */
        }
    }
}