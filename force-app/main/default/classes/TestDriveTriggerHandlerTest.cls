/**
* @description       : 
* @author            : Aniket Karmakar
* @group             : 
* @last modified on  : 02-05-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class TestDriveTriggerHandlerTest {
    @IsTest
    public static void afterInsert(){
        
        WhatsappIntegration__c mockIntegration = new WhatsappIntegration__c(
            Name = 'WhatsApp API',
            API_Endpoint__c = 'https://api.whatsapp.com/send',
            API_Key__c = 'mock-api-key'
            //test_ride_done__c='anything.jpg'
        );
        insert mockIntegration;
        
        Store_Details__mdt dealerCodes1 = new Store_Details__mdt(Name__c='test',Dealer_Code__c='292001',IsActive__c=true);
        Store_Details__mdt dealerCodes2 = new Store_Details__mdt(Name__c='test2',Dealer_Code__c='292002',IsActive__c=true);  
        
        List<Store_Details__mdt> storeDetails = [SELECT Name__c, Dealer_Code__c, IsActive__c FROM Store_Details__mdt WHERE IsActive__c = true];
        
        
        Lead testLead1 = new Lead(FirstName = 'Test', LastName = 'Ride', Company = 'Test Company 1', LeadSource = 'Google', PostalCode='560078',Dealer_Code__c='292002', Phone = '1234567890');
        insert testLead1; 
        Lead testLead2 = new Lead(FirstName = 'Test2', LastName = 'Ride2', Company = 'Test Company 2', LeadSource = 'Bike Dekho', PostalCode='560078',Dealer_Code__c='292002', Phone = '0987654321');
        insert testLead2;         
        
        Test_Drive__c testDrive1 = new Test_Drive__c(Name='Drive 1', Lead__c = testLead1.Id, Ride_Type__c= 'HTR',Test_Ride_Date__c=System.Now());
        Test_Drive__c testDrive2 = new Test_Drive__c(Name='Drive 2', Lead__c = testLead2.Id, Ride_Type__c= 'STR',Test_Ride_Date__c=System.Now().addDays(+3));
        
        Test.startTest();
        
        insert testDrive1;
        insert testDrive2;
        
        TestDriveTriggerHandler.mytest();
        
        Test.stopTest();
        
    }
  
}