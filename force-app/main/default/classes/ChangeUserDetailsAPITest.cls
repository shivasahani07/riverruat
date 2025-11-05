@IsTest
public class ChangeUserDetailsAPITest {
    @testSetup
    static void setupData() {
        Account a = new Account();
        a.Name = 'API Test';
        a.Phone='0987654321';
        a.Email__c='test@example.com';
        insert a;
        
         Website_Creds__c mockIntegrations = new Website_Creds__c(
                Name = 'Website Creds',
                BaseURL__c = 'https://river-crm-apis.dev.rideriver.com',
                ClientId__c = '7f2a1bk826eb5179ec8e357340408fd444ab3ssbb1d5fb40a06f6eac590f6b8d51bea40886bf80cd388813f296effa4269550ce98d4e4e5c7e582da19e9faff0',
                ClientSecret__c = 'a7ebb3r90eaa4eac1a356c351a0f7c5fdesa87c87010298fa84bc728d6db305638b68b6bce984110e8d70fd2e39eab0dbcdd2b5264570ae77e320acb6937afe32'
            );
            insert mockIntegrations;
    }
    @IsTest
     static void coverMethod() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
  
        req.params.put('new_phone','9051911077');
        req.params.put('existing_phone','0987654321');
        req.params.put('new_name','Aniket API Test PATCH Method');
        req.params.put('new_email','aniket@example.com123');
         
        RestContext.request = req;
        RestContext.response = res;

        ChangeUserDetailsAPI.changeDetails();
    }
    
    @IsTest
     static void coverErrorMethod1() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
  
        req.params.put('new_phone','9051911077');
        req.params.put('new_name','Aniket API Test PATCH Method');
        req.params.put('new_email','aniket@example.com123');
         
        RestContext.request = req;
        RestContext.response = res;

        ChangeUserDetailsAPI.changeDetails();
    }
    @IsTest
     static void coverErrorMethod2() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
  
        req.params.put('new_phone','9051911077');
        req.params.put('new_name','Aniket API Test PATCH Method');
        req.params.put('new_email','aniket@example.com123');
       req.params.put('existing_phone','0987654320');
         
        RestContext.request = req;
        RestContext.response = res;

        ChangeUserDetailsAPI.changeDetails();
    }

}