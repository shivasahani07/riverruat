@isTest
public class LeadTriggerHandlerTest {
    @testSetup static void setup() {
        
        Profile pro = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        
        User userInstant = new User(Alias = 'standt', Email='sossfdc1@cirrologix.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                                    IsActive=true,Division='Rainmakers',
                                    LocaleSidKey='en_US', ProfileId = pro.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='standardVarsha1@testorg.com');
        insert userInstant;
        
        User userInstant1 = new User(Alias = 'standt', Email='sossfdc@cirrologix.com', 
                                     EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                     IsActive=true,Division='Rainmakers',
                                     LocaleSidKey='en_US', ProfileId = pro.Id,
                                     TimeZoneSidKey='America/Los_Angeles', UserName='standardVarsha@testorg.com');
        insert userInstant1;
        
        WhatsappIntegration__c mockIntegration = new WhatsappIntegration__c(
            Name = 'WhatsApp API',
            API_Endpoint__c = 'https://api.whatsapp.com/send',
            API_Key__c = 'mock-api-key'
        );
        insert mockIntegration;
        
        Store_Details__mdt dealerCodes1 = new Store_Details__mdt(Name__c='test',Dealer_Code__c='291008',IsActive__c=true);
        Store_Details__mdt dealerCodes2 = new Store_Details__mdt(Name__c='test2',Dealer_Code__c='291008',IsActive__c=true);  
        
        List<Store_Details__mdt> storeDetails = [SELECT Name__c, Dealer_Code__c, IsActive__c FROM Store_Details__mdt WHERE IsActive__c = true];
        
        Account acc = new Account();
        acc.Name = 'River Testing';
        acc.Center_Code__c = '291008';
        acc.Store_Type__c = 'COCO';
        acc.Type = 'Dealer';
        Insert acc;
        
        City__c cityRec = new City__c();
        cityRec.Name = 'Bengaluru';
        cityRec.State__c = 'Karnataka';
        Insert cityRec;
        
        Pin_Code__c pinRec = new Pin_Code__c();
        pinRec.City__c = cityRec.Id;
        pinRec.Name = 'JP Nagar';
        pinRec.Area_Pincode__c = '510068';
        pinRec.Dealer_Service_Center__c = acc.Id; 
        Insert pinRec;
        
        Assignment_Group__c AGRec = new Assignment_Group__c();
        AGRec.Name__c = 'Out of Business Hours';
        AGRec.Business_Hours_Morning__c = Time.newInstance(6, 45, 10, 10);
        AGRec.Business_Hours_End_Time__c = Time.newInstance(18, 45, 10, 10);
        AGRec.Last_Allocated_RRid__c = 1;
        AGRec.isActive__c = true;
        Insert AGRec;
        
        Assignment_Group__c AGRec1 = new Assignment_Group__c();
        AGRec1.Name__c = 'Out of Business Hours';
        AGRec1.Business_Hours_End_Time__c = Time.newInstance(6, 45, 10, 10);
        AGRec1.Business_Hours_Morning__c = Time.newInstance(18, 45, 10, 10);
        AGRec1.Last_Allocated_RRid__c = 1;
        AGRec1.isActive__c = true;
        Insert AGRec1;
        
        Assignment_Group_Member__c AGMRec = new Assignment_Group_Member__c();
        AGMRec.Assignment_Group__c = AGRec1.Id;
        AGMRec.Active__c = true;
        AGMRec.Assignment_Id__c = 1;
        AGMRec.Max_Case_Per_Day__c = 50;
        AGMRec.Group_Member__c = userInstant1.Id;
        Insert AGMRec;
        
        Assignment_Group_Member__c AGMRec1 = new Assignment_Group_Member__c();
        AGMRec1.Assignment_Group__c = AGRec1.Id;
        AGMRec1.Active__c = true;
        AGMRec1.Assignment_Id__c = 2;
        AGMRec1.Max_Case_Per_Day__c = 50;
        AGMRec1.Group_Member__c = userInstant.Id;
        Insert AGMRec1;
        
        Assignment_Group_Member__c AGMRec2 = new Assignment_Group_Member__c();
        AGMRec2.Assignment_Group__c = AGRec.Id;
        AGMRec2.Active__c = true;
        AGMRec2.Assignment_Id__c = 1;
        AGMRec2.Max_Case_Per_Day__c = 50;
        AGMRec2.Group_Member__c = userInstant1.Id;
        Insert AGMRec2;
        
        Assignment_Group_Member__c AGMRec3 = new Assignment_Group_Member__c();
        AGMRec3.Assignment_Group__c = AGRec.Id;
        AGMRec3.Active__c = true;
        AGMRec3.Assignment_Id__c = 2;
        AGMRec3.Max_Case_Per_Day__c = 50;
        AGMRec3.Group_Member__c = userInstant.Id;
        Insert AGMRec3;
        
    }
    
    @isTest
    public static void testClass(){
        
        List<Pin_Code__c>  pinRec = [Select Id,Area_Pincode__c from Pin_Code__c where Name = 'JP Nagar'];
        
        List<Lead> leadList = new List<Lead>();
        Map<Id, Lead> mapOfLead = new Map<Id, Lead>();  
        
        Lead ledRec1 = new Lead();
        ledRec1.LastName = 'Anwar Chikle';
        ledRec1.Company = 'Test NA';
        ledRec1.PostalCode = pinRec[0].Area_Pincode__c;
        ledRec1.Status = 'New';
        ledRec1.Threshold_Count__c = 6;
        ledRec1.Phone = '9035244424';
        ledRec1.Is_Order_Created__c = true;
        insert ledRec1;        
        leadList.add(ledRec1);
        mapOfLead.put(ledRec1.Id, ledRec1);
        
        ledRec1.Threshold_Count__c = 8;
        update ledRec1;
        mapOfLead.put(ledRec1.Id, ledRec1);
        
        Test_Drive__c testRide1 = new Test_Drive__c();
        testRide1.Name = ledRec1.LastName + ' Test Drive';
        testRide1.Lead__c = ledRec1.Id;
        testRide1.Test_Drive_Status__c = 'New';
        testRide1.Start_Date__c = system.now();
        testRide1.End_Date__c = system.now();
        testRide1.Test_Drive_Date__c = system.now();
        Insert testRide1;
        
        Map<String,Object> mapOfObject = new Map<String,Object>();
        mapOfObject.put('Status','Converted');
        mapOfObject.put('Email','anwar.chikle@utilitarianlabs.com');
        mapOfObject.put('Phone','9135244424');
        mapOfObject.put('DealerCode','291001');
        mapOfObject.put('LostReason','Out of Delivery Area');
        mapOfObject.put('LostFeedback','Testing');
        mapOfObject.put('Notes','Testing');
        
        Map<String,Object> mapOfObject1 = new Map<String,Object>();
        mapOfObject1.put('Status','Not Interested');
        mapOfObject1.put('Email','anwar.chikle@utilitarianlabs.com');
        mapOfObject1.put('Phone','9135244424');
        mapOfObject1.put('DealerCode','291001');
        mapOfObject1.put('LostReason','Out of Delivery Area');
        mapOfObject1.put('LostFeedback','Testing');
        mapOfObject1.put('Notes','Testing');
        
        
        LeadTriggerHandler.thresholdCallAttempt(leadList, mapOfLead);
        LeadTriggerHandler.getPreferredStoreByPincode(ledRec1.PostalCode);
        LeadTriggerHandler.getOpportunityId(ledRec1.Id);
        LeadTriggerHandler.getLeadOwnerByPincode(ledRec1.PostalCode);
        LeadTriggerHandler.beforeConversionCheckAnyFollowIsOpendThenThrowError(leadList, mapOfLead);
        LeadTriggerHandler.callQueableMethodForAfterUpdate(leadList, mapOfLead);
        LeadTriggerHandler.checkLeadStatus(leadList);
        LeadTriggerHandler.createTestRideIftheCreateTestRideCheckboxIsTicked(leadList);   
    }
    
    
    @isTest
    public static void testClass2(){
        
        List<Pin_Code__c>  pinRec = [Select Id,Area_Pincode__c from Pin_Code__c where Name = 'JP Nagar'];
        
        List<Lead> leadList = new List<Lead>();
        Map<Id, Lead> mapOfLead = new Map<Id, Lead>();  
        
        Lead ledRec1 = new Lead();
        ledRec1.LastName = 'Anwar Chikle';
        ledRec1.Company = 'Test NA';
        ledRec1.PostalCode = pinRec[0].Area_Pincode__c;
        ledRec1.Status = 'New';
        ledRec1.Threshold_Count__c = 6;
        ledRec1.Phone = '9035244424';
        insert ledRec1;        
        leadList.add(ledRec1);
        mapOfLead.put(ledRec1.Id, ledRec1);
        
        ledRec1.Threshold_Count__c = 8;
        update ledRec1;
        mapOfLead.put(ledRec1.Id, ledRec1);
        
        Map<String,Object> mapOfObject = new Map<String,Object>();
        mapOfObject.put('Status','Converted');
        mapOfObject.put('Email','anwar.chikle@utilitarianlabs.com');
        mapOfObject.put('Phone','9135244424');
        mapOfObject.put('DealerCode','291001');
        mapOfObject.put('LostReason','Out of Delivery Area');
        mapOfObject.put('LostFeedback','Testing');
        mapOfObject.put('Notes','Testing');
        
        Map<String,Object> mapOfObject1 = new Map<String,Object>();
        mapOfObject1.put('Status','Not Interested');
        mapOfObject1.put('Email','anwar.chikle@utilitarianlabs.com');
        mapOfObject1.put('Phone','9135244424');
        mapOfObject1.put('DealerCode','291001');
        mapOfObject1.put('LostReason','Out of Delivery Area');
        mapOfObject1.put('LostFeedback','Testing');
        mapOfObject1.put('Notes','Testing');
        
        Test_Drive__c testRide1 = new Test_Drive__c();
        testRide1.Name = ledRec1.LastName + ' Test Drive';
        testRide1.Lead__c = ledRec1.Id;
        testRide1.Test_Drive_Status__c = 'New';
        testRide1.Start_Date__c = system.now();
        testRide1.End_Date__c = system.now();
        testRide1.Test_Drive_Date__c = system.now();
        Insert testRide1;
        
        LeadTriggerHandler.convertLeadUponStageChange(ledRec1.Id,mapOfObject);
        LeadTriggerHandler.convertLeadUponStageChange(ledRec1.Id,mapOfObject1);
    }
    
    @isTest
    public static void testClass1(){
        
        List<Pin_Code__c>  pinRec = [Select Id,Area_Pincode__c from Pin_Code__c where Name = 'JP Nagar'];
        
        List<Lead> newLeadList = new List<Lead>();
        Lead ledRec = new Lead();
        ledRec.LastName = 'Anwar Chikle';
        ledRec.Company = 'Test NA';
        ledRec.Phone = '9035244424';
        ledRec.PostalCode = pinRec[0].Area_Pincode__c;
        ledRec.LeadSource = 'Bike Dekho';
        ledRec.Status = 'Converted';
        ledRec.Book_Bike__c = true;
        ledRec.WhatsApp_Sent_After_Update__c = true;
        Insert ledRec;
        newLeadList.add(ledRec);
        
        Test_Drive__c testRide = new Test_Drive__c();
        testRide.Name = ledRec.LastName + ' Test Drive';
        testRide.Lead__c = ledRec.Id;
        testRide.Test_Drive_Status__c = 'New';
        testRide.Start_Date__c = system.now();
        testRide.End_Date__c = system.now();
        testRide.Test_Drive_Date__c = system.now();
        Insert testRide;
        
        LeadTriggerHandler.createTestRideIftheCreateTestRideCheckboxIsTicked(newLeadList);
        LeadTriggerHandler.checkLeadStatus(newLeadList);
        LeadTriggerHandler.callQueableMethodForNewLead(newLeadList);
        LeadTriggerHandler.mytest();
    } 
    
}