public class MobileApp_Wrapper {
    // payload wrapper (User Input)
    public class MobileApp_LeadTotalLeadsWrapper{
        public string UserId {get; set;} 
        public String FilterDate{get; set;}
        public String FilterEndRange{get; set;}
    }
    
    // error Method
    public class MobileApp_ResponseLeadsWrapper{
        public string StatusCode {get; set;}
        public string StatusMessage {get; set;}
    }
    
    // payload wrapper (User Input for creation of Lead)
    public class MobileApp_CreateLead{
        public string UserId {get; set;}
        public String FirstName{get; set;}
        public String LastName{get; set;}
        public String Phone{get; set;}
        public String Email{get; set;}
        public String LeadSource{get; set;}
        public String LeadSecondarySource{get; set;}
        public String LeadSecondarySourceOthers{get; set;}
        
        // public boolean bookATestRide{get; set;}
        // public String TestDriveDate{get; set;}
        // public String TestDriveTime{get; set;}
        // public String RideType{get; set;}
        // public String HomeTestDriveAddress{get; set;}
    }

    public class MobileApp_TransferEnquiry{
        public string UserId {get; set;}
        public String Phone{get; set;}
    }
    
    // payload wrapper (User Input for creation of test drive)
    public class MobileApp_CreateTestDrive{
        public string UserId {get; set;}
        public String LeadId{get; set;}
        public String TestDriveDate{get; set;}
        public String TestDriveTime{get; set;}
        public boolean homeTestDrive{get; set;}
        public String HomeTestDriveAddress{get; set;}
        public boolean storeTestDrive{get; set;}
        public String pincode{get; set;}
    }
    
    public class MobileApp_UpdateTestDrive{
        public string UserId {get; set;}
        public String TestDriveId{get; set;}
        
        public String TestDriveStatus{get; set;}
        public String TestDriveDate{get; set;}
        public String TestDriveTime{get; set;}
        public string rideType{get; set;}
        public string homeTestDriveAddress{get; set;}
        public string pincode{get; set;}
        public boolean StartTestDrive{get; set;}
        public boolean CompleteTestDrive{get; set;}
        
    }
    
    public class MobileApp_UpdateLead{
        public string UserId {get; set;}
        public String LeadId{get; set;}
        public String LeadStatus{get; set;}

    }

    public class MobileApp_DropLead{
        public string UserId {get; set;}
        public String LeadId{get; set;}
        public String DropOutReason{get; set;}
        public String DropOutSubReason{get; set;}
        public String Others{get; set;}
    }
    
    // payload wrapper (User Input for creation of followup)
    public class MobileApp_CreateFollowUp{
        public string UserId {get; set;} 
        public String LeadId{get; set;}
        public String FollowUpDate{get; set;}
        public String FollowUpTime{get; set;}
        public String FollowUpFeedback{get; set;}
        public String followUpType{get; set;}
        public String followUpReason{get; set;}
        public String followUpSubReason{get; set;}
        public String followUpOther{get; set;}
        
    }

    public class MobileApp_CreateTicket{
        public string UserId {get; set;} 
        public String description{get; set;}
        public String SS1{get; set;}
        public String SS2{get; set;}
        public String SS3{get; set;}
        public String SS4{get; set;}
        public String SS5{get; set;}
    }
    
    // payload wrapper (User Input for updation of followup)
    public class MobileApp_UpdateFollowUp{
        public string UserId {get; set;}
        public String FollowUpId{get; set;}
        public boolean FollowUpStatusCompleted{get; set;}
        public String followUprating{get; set;}
        public String followUpfeedBack{get; set;}
    }
    
    //Book Order
    public class MobileApp_BookOrder {
        public String userId { get; set; }
        public String opportunityId { get; set; }
        public String paymentStatus { get; set; }
        public String transactionId { get; set; }
        public String paymentMode { get; set; }
        public String paymentGateway { get; set; }
        public Decimal orderAmount { get; set; }
        public String vehicleColor { get; set; }
        public DateTime timestamp { get; set; }
        public String gatewayResponseMessage { get; set; }
        public CustomerDetails customerDetails { get; set; }
        public String signature { get; set; }
    }

    public class CustomerDetails {
        public String name { get; set; }
        public String email { get; set; }
        public String phone { get; set; }
    }

    public class MobileApp_Comments {
        public String userId { get; set; }
        public String OrderId { get; set; }
        public String Comments { get; set; }
    }

    //Response Wrapper
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