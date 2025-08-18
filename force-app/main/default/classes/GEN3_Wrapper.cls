public class GEN3_Wrapper {
    public class AccountCreation{
        public string Name {get; set;} 
        public String Email{get; set;}
        public String Phone{get; set;}
        public string pincode{get; set;}
        public string Address{get; set;}
    }     
    
    public static void setResponse(Integer statusCode, String message, Map<String, Object> data) {
        RestResponse res = RestContext.response;
        res.statusCode = statusCode;
        res.addHeader('Content-Type', 'application/json');
        
        Map<String, Object> responseWrapper = new Map<String, Object>{
            'StatusCode' => statusCode,
                'StatusMessage' => message
                };
                    
                    if(data != null) {
                        responseWrapper.putAll(data);
                    }
        
        res.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
    }
    
    public static void setResponses(Integer statusCode, String message, List<Map<String, Object>> data) {
        RestResponse res = RestContext.response;
        res.statusCode = statusCode;
        res.addHeader('Content-Type', 'application/json');
        
        Map<String, Object> responseWrapper = new Map<String, Object>{
            'StatusCode' => statusCode,
                'StatusMessage' => message
                };
                    
                    if (data != null) {
                        responseWrapper.put('Data', data);
                    }
        
        res.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
    }

    public class CheckExtendedWarrantyOrRSAFromPhoneNumber{
        public String phone {get; set;}
    }

    public static void setExtendedWarrantyOrRSAResponse(Integer statusCode, String message, List<Map<String, Object>> data){
        RestResponse res = RestContext.response;
        res.statusCode = statusCode;
        res.addHeader('Content-Type', 'application/json');

        Map<String, Object> responseWrapper = new Map<String, Object>{
            'statusCode' => statusCode,
            'statusMessage' => message
        };

        if(data != null){
            responseWrapper.put('data', data);
        }
        System.debug('responseWrapper : ' + responseWrapper);
        
        res.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
    }
}