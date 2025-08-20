public class GEN3_Wrapper {
    public class AccountCreation{
        public string Name {get;set;} 
        public String Email{get;set;}
        public String Phone{get;set;}
        public string pincode{get;set;}
        public string Address{get;set;}
    }   
    
    public class GEN3_BookOrder {
        public String userId {get;set;}
        public String opportunityId {get;set;}
        public String paymentStatus {get;set;}
        public String transactionId {get;set;}
        public String paymentMode {get;set;}
        public String paymentGateway {get;set;}
        public Decimal orderAmount {get;set;}
        public String vehicleColor {get;set;}
        public DateTime timestamp {get;set;}
        public String gatewayResponseMessage {get;set;}
        public CustomerDetails customerDetails {get;set;}
        public String signature {get;set;}
    }
    
    public class CustomerDetails {
        public String name {get;set;}
        public String email {get;set;}
        public String phone {get;set;}
    }
    
    public class getOrder {
        public String phone {get;set;} 
    }
    
    public class CheckExtendedWarrantyOrRSAFromPhoneNumber{
        public String phone {get; set;}
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
    
    
}