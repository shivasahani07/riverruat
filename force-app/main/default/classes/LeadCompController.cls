/**
* @File Name : LeadCompController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 21, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 21, 2024 |   | Initial Version
**/

public with sharing class LeadCompController {
    
    public class leadWrapper{
        @AuraEnabled
        public list<Follow_Up__c> lstFollowUp{get;set;}
        @AuraEnabled
        public List<Lead> lstLead{get;set;}
        @AuraEnabled
        public list<Test_Drive__c> lstTestRide{get;set;}
        @AuraEnabled
        public  Map<Id,Follow_Up__History> oldValue{get;set;}
        @AuraEnabled
        public  Map<Id,Follow_Up__History> previousComment{get;set;}
        
    }
    
    public class summarrywrapper{
        @AuraEnabled
        public integer todayfolloups{get;set;}
        @AuraEnabled
        public integer notattenedfolloups{get;set;}
        @AuraEnabled
        public integer Newleads{get;set;}
        @AuraEnabled
        public  integer Notattendedleads{get;set;}
        @AuraEnabled
        public integer newstatusleads{get;set;}
        @AuraEnabled
        public integer testrideleads{get;set;}
        @AuraEnabled
        public integer followupLead{get;set;}
        @AuraEnabled
        public integer readyforbbokingleads{get;set;}
        @AuraEnabled
        public integer convertleads{get;set;}
        @AuraEnabled
        public integer clostlostleads{get;set;}
        @AuraEnabled
        public integer todayTestRide{get;set;}
        @AuraEnabled
        public integer notattendedTestRide{get;set;}   
    }
    
    public class LeadWrapper1 {
        @AuraEnabled public String id; 
        @AuraEnabled public String name;
        @AuraEnabled public Decimal age;
        @AuraEnabled public String phone;
        @AuraEnabled public String status;
        @AuraEnabled public Date createdDate;
        
        public LeadWrapper1(Lead lead) {
            this.id = lead.Id; 
            this.name = lead.Name;
            this.age = lead.Lead_Age__c	; 
            this.phone = lead.Phone;
            this.status = lead.Status;
            this.createdDate = lead.CreatedDate.date();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<LeadWrapper1> getLeadsDetailsByDateRange(Date fromDate, Date toDate) {
        List<LeadWrapper1> leadList = new List<LeadWrapper1>();
        
        User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Boolean isSysAdmin = (currentUser.Profile.Name == 'System Administrator');
        String currentUserId = UserInfo.getUserId();
        
        Datetime startDatetime = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDatetime = Datetime.newInstance(toDate, Time.newInstance(23, 59, 59, 999));
        
        System.debug('### Current User Profile: ' + currentUser.Profile.Name);
        
        List<Lead> leads;
        
        if (isSysAdmin) {
            leads = [SELECT Id, Name, Lead_Age__c, Phone,Status, CreatedDate, OwnerId 
                     FROM Lead 
                     WHERE CreatedDate >= :startDatetime AND CreatedDate <= :endDatetime
                     AND Status = 'New' ORDER BY CreatedDate DESC];
        } else {
            leads = [SELECT Id, Name, Lead_Age__c, Phone,Status, CreatedDate, OwnerId 
                     FROM Lead 
                     WHERE CreatedDate >= :startDatetime AND CreatedDate <= :endDatetime 
                     AND OwnerId = :currentUserId
                     AND Status = 'New' ORDER BY CreatedDate DESC];
        }
        
        System.debug('### Total Leads Retrieved: ' + leads.size());
        
        for (Lead l : leads) {
            System.debug('### Lead Name: ' + l.Name + ', Age: ' + l.Lead_Age__c + ', Phone: ' + l.Phone + ', CreatedDate: ' + l.CreatedDate);
            leadList.add(new LeadWrapper1(l));
        }
        
        return leadList;
    }

    @AuraEnabled
    public static leadWrapper TodaysFollowUp(Date fromDate, Date toDate) {
        System.debug('### Inside TodaysFollowUp Method ###');
        System.debug('Received fromDate: ' + fromDate + ', toDate: ' + toDate);
        
        User currentUser = [SELECT Id ,Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.debug('Current User Id: ' + currentUser.Id);
        Boolean isSysAdmin = (currentUser.Profile.Name == 'System Administrator');
        
        Datetime startDatetime = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDatetime = Datetime.newInstance(toDate, Time.newInstance(23, 59, 59, 999));
        
        List<Follow_Up__c> followUps;
        
        if (isSysAdmin) {
            followUps = [
                SELECT Id, Due_Date__c, Lead__c, Lead__r.Name, Lead__r.Phone, Status__c, 
                Subject__c, Lead__r.Lead_Age__c, Follow_Up_Date__c, 
                Previous_Followup_date__c, Previous_Feedback__c, Feedback__c 
                FROM Follow_Up__c 
                WHERE Lead__r.IsConverted = false
                AND Lead__r.Status IN ('RNR', 'Follow Up', 'Ready For booking')
                AND Follow_Up_Date__c >= :startDatetime 
                AND Follow_Up_Date__c <= :endDatetime 
                AND Status__c != 'Completed' 
                ORDER BY Follow_Up_Date__c ASC
            ];
        } else {
            followUps = [
                SELECT Id, Due_Date__c, Lead__c, Lead__r.Name, Lead__r.Phone, Status__c, 
                Subject__c, Lead__r.Lead_Age__c, Follow_Up_Date__c, 
                Previous_Followup_date__c, Previous_Feedback__c, Feedback__c 
                FROM Follow_Up__c 
                WHERE Lead__r.IsConverted = false
                AND Lead__r.Status IN ('RNR', 'Follow Up', 'Ready For booking')
                AND Follow_Up_Date__c >= :startDatetime 
                AND Follow_Up_Date__c <= :endDatetime 
                AND Status__c != 'Completed' 
                AND Lead__r.OwnerId = :currentUser.Id
                ORDER BY Follow_Up_Date__c ASC
            ];
        }
        
        System.debug('Fetched Follow-Ups: ' + followUps.size());
        System.debug('Follow-Up Records: ' + JSON.serialize(followUps));
        
        Set<Id> leadIds = new Set<Id>();
        for (Follow_Up__c fup : followUps) {
            leadIds.add(fup.Lead__c);
        }
        
        List<Lead> leads = [
            SELECT Id, OwnerId, Name, Phone, LeadSource, Lead_Age__c 
            FROM Lead 
            WHERE Id IN :leadIds
            AND Status != 'Close Lost'
        ];
        
        Map<Id, Follow_Up__History> mapHistory = new Map<Id, Follow_Up__History>();
        List<Follow_Up__History> lstHistory = [
            SELECT OldValue, NewValue, Field, CreatedDate, ParentId 
            FROM Follow_Up__History  
            WHERE Field = 'Due_Date__c' 
            AND ParentId IN :leadIds 
            ORDER BY CreatedDate ASC
        ];
        
        for (Follow_Up__History objHis : lstHistory) {
            if (!mapHistory.containsKey(objHis.ParentId)) {
                mapHistory.put(objHis.ParentId, objHis);
            }
        }
        
        System.debug('Follow-Up History Map Size: ' + mapHistory.size());
        leadWrapper objWrapper = new leadWrapper();
        objWrapper.lstFollowUp = followUps;
        objWrapper.lstLead = leads;
        objWrapper.oldValue = mapHistory;
        
        System.debug('Final leadWrapper Response: ' + JSON.serialize(objWrapper));
        
        return objWrapper;
    }

    @AuraEnabled
    public static List<Lead> getLeadsList(String searchKeyword){
        String key = '%' + searchKeyword + '%';
        List<Lead> SearchLeads = [Select id,Name, LeadSource,Status,MobilePhone, Customer_Age__c, Lead_Age__c from Lead WHERE Status ='New' AND IsConverted=false AND Status !='close lost' AND Status !='Test Ride'AND Status !='Follow Up'/* AND Lead_Age__c <= 21 */AND Status LIKE :key] ;
        
        return SearchLeads;
    }
    
    @AuraEnabled
    public static List<Lead> getLeads(Integer pageSize, Integer pageNumber){
        Integer offsetValue = (pageNumber - 1) * pageSize;
        
        List<Lead> LeadsList = [Select id,Name, Phone, CreatedDate ,Lead_Age__c,Status from Lead WHERE IsConverted=false  AND Status !='close lost' AND Status !='Test Ride' AND Status !='Follow Up'/* AND Lead_Age__c <= 21 */AND CreatedDate<=TODAY  ORDER BY CreatedDate DESC LIMIT :pageSize OFFSET :offsetValue ];
        system.debug(LeadsList);
        return LeadsList;
        
    }
    
    @AuraEnabled
    public static List<Lead> newgetLeads(){
        List<Lead> LeadsList = [Select id,Name, Phone, CreatedDate ,Lead_Age__c,Status from Lead WHERE IsConverted=false  AND Status !='close lost' AND Status !='Test Ride' AND Status !='Follow Up'/* AND Lead_Age__c <= 21 */AND CreatedDate=TODAY ORDER BY CreatedDate DESC limit 50 ];
        system.debug('kkk'+LeadsList);
        
        return LeadsList;
        
    }
    
    @AuraEnabled
    public static Lead getLeaddeatails(Id leadid){
        Lead getLead = new Lead(); 
        try{
            getLead = [Select id,Name, LeadSource,Lost_Reason__c, Phone, Customer_Age__c, Lead_Age__c, city,country,postalCode,state,street,Status,Owner.Name,Email,PS_Name__c from Lead WHERE Id=:leadid AND IsConverted=false ];
        }catch(Exception e){
            getLead= null; 
        }
        return getLead;
    }

    @AuraEnabled
    public static List<Lead> getLeadsListBySearchKeyWord(String searchKeyword){
        String key = '%' + searchKeyword + '%';
        // List<Lead> SearchLeads = [Select id,Name, LeadSource, Phone, Customer_Age__c, Lead_Age__c from Lead WHERE (Name LIKE:key OR Phone LIKE:key) and isConverted = false AND Status !='close lost'AND Status!='Test Ride'AND Status !='Follow Up' AND CreatedDate<=TODAY] ;
        List<Lead> SearchLeads = [Select id,Name, LeadSource, Phone, Customer_Age__c, Lead_Age__c ,CreatedDate from Lead WHERE (Name LIKE:key OR Phone LIKE:key) and isConverted = false AND Status !='close lost' AND CreatedDate<=TODAY ORDER BY CreatedDate DESC] ;
        system.debug('hhhh='+SearchLeads);
        return SearchLeads;
    }
    
    @auraenabled
    public static void updatelead(string id, string lead_source, string phone, Decimal Age,string email ,string city,string Country,string PostalCode,string State,string Street, string Status,string psname){
        system.debug('gggg='+Country);
        lead ul = new lead();
        ul.Id = id;
        ul.LeadSource = lead_source;
        ul.Phone = phone;
        ul.Customer_Age__c = age;
        ul.City=city;
        ul.Country=Country;
        ul.PostalCode=PostalCode;
        ul.State=State;
        ul.Street=Street;
        ul.Email=email;
        ul.Status=Status;
        ul.PS_Name__c=psname;
        
        update ul;
    }
    @AuraEnabled
    public static Follow_Up__c followupfeedback(Id followupId,String Feedback){
        Follow_Up__c fllist= new Follow_Up__c();
        fllist.Id = followupId;
        fllist.Feedback__c=Feedback;
        fllist.isAcctionCompleted__c=true;
        fllist.Status__c='Completed';
        update fllist;
        return fllist;
    }
    
    @AuraEnabled
    public static leadWrapper getTestDriveRecords(Date fromDate, Date toDate) {
        System.debug('### Inside getTestDriveRecords Method ###');
        System.debug('Received fromDate: ' + fromDate + ', toDate: ' + toDate);
        
        Datetime startDatetime = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDatetime = Datetime.newInstance(toDate, Time.newInstance(23, 59, 59, 999));
        
        System.debug('Converted startDatetime: ' + startDatetime);
        System.debug('Converted endDatetime: ' + endDatetime);
        
        User currentUser = [SELECT Id ,Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Boolean isSysAdmin = (currentUser.Profile.Name == 'System Administrator');
        
        
        List<Test_Drive__c> newList;
        if(isSysAdmin){
            newList = [
                SELECT Id, Name, MobilePhone__c, Lead__c, Lead__r.Name, Test_Drive_Date__c, Is_Reschedule__c, 
                Ride_Type__c, Phone__c, Reschedule_Date__c, Test_Ride_Date__c, Test_Drive_Status__c, 
                Start_Date__c, End_Date__c, Lead__r.Lead_Age__c, Drivers_License_Number__c, Indemnity__c
                FROM Test_Drive__c 
                WHERE Lead__r.isConverted = false 
                AND Lead__r.Status != 'close lost'
                AND Lead__r.Status = 'Test Ride' 
                AND Test_Ride_Date__c >= :startDatetime 
                AND Test_Ride_Date__c <= :endDatetime 
                ORDER BY Test_Ride_Date__c ASC
            ];
        }else{
            newList = [
                SELECT Id, Name, MobilePhone__c, Lead__c, Lead__r.Name, Test_Drive_Date__c, Is_Reschedule__c, 
                Ride_Type__c, Phone__c, Reschedule_Date__c, Test_Ride_Date__c, Test_Drive_Status__c, 
                Start_Date__c, End_Date__c, Lead__r.Lead_Age__c, Drivers_License_Number__c, Indemnity__c
                FROM Test_Drive__c 
                WHERE Lead__r.OwnerId = :currentUser.Id
                AND Lead__r.isConverted = false 
                AND Lead__r.Status != 'close lost'
                AND Lead__r.Status = 'Test Ride' 
                AND Test_Ride_Date__c >= :startDatetime 
                AND Test_Ride_Date__c <= :endDatetime 
                ORDER BY Test_Ride_Date__c ASC
            ];
            
        }
        
        Set<Id> leadIds = new Set<Id>();
        for (Test_Drive__c fup : newList) {
            leadIds.add(fup.Lead__c);
        }
        
        List<Lead> leads = [
            SELECT Id, OwnerId, Name, Phone, LeadSource, Lead_Age__c 
            FROM Lead 
            WHERE Id IN :leadIds
            AND Status != 'Close Lost'
        ];
        
        if (newList.isEmpty()) {
            System.debug('No records found in first query, running fallback query...');
            newList = [
                SELECT Id, Name, MobilePhone__c, Lead__c, Lead__r.Name, Test_Drive_Date__c, Is_Reschedule__c, 
                Ride_Type__c, Phone__c, Reschedule_Date__c, Test_Drive_Status__c, Start_Date__c, 
                End_Date__c, Lead__r.Lead_Age__c, Drivers_License_Number__c, Indemnity__c, Test_Ride_Date__c
                FROM Test_Drive__c 
                WHERE Lead__c IN :leadIds
                AND Lead__r.isConverted = false 
                AND Lead__r.Status != 'close lost' 
                AND Test_Ride_Date__c >= :startDatetime 
                AND Test_Ride_Date__c <= :endDatetime 
                ORDER BY Test_Ride_Date__c ASC
            ];
            System.debug('Total newList records (fallback query): ' + newList.size());
        }
        
        leadWrapper objWrapper = new leadWrapper();
        objWrapper.lstTestRide = newList;
        objWrapper.lstLead = leads;
        System.debug('### Returning leadWrapper object ###');
        return objWrapper;
    }
    
    @Auraenabled
    public static void rescheduledate(DateTime rescheduledate,Id testdriverid,String rideType){
        Test_Drive__c objtestDrive = new Test_Drive__c();
        objtestDrive.Id = testdriverid;
        objtestDrive.Reschedule_Date__c=rescheduledate;
        objtestDrive.Test_Ride_Date__c=rescheduledate;
        objtestDrive.Ride_Type__c = rideType;
        objtestDrive.Test_Drive_Status__c='Reschedule';
        
        update objtestDrive;
    }
    
    @Auraenabled
    public static void updateLeadStatusToClosedLost(Id testDriveId,string reason,string reasonfeedback){
        System.debug('lead Id'+testDriveId);
        Test_Drive__c testDrive = [SELECT Lead__c FROM Test_Drive__c WHERE Id = :testDriveId LIMIT 1];
        System.debug('lead Id'+testDrive);
        Lead leadToUpdate = [SELECT Id, Status,Lost_Reason__c,Lost_Feedback__c FROM Lead WHERE Id = :testDrive.Lead__c LIMIT 1];
        leadToUpdate.Lost_Reason__c=reason;
        leadToUpdate.Lost_Feedback__c=reasonfeedback;
        System.debug('lead Id'+leadToUpdate);
        leadToUpdate.Status = 'close lost';
        update leadToUpdate;
    }
    
    @Auraenabled
    public static void updateLeadStatus(Id leadId){
        Lead objLead = new Lead();
        objLead.Id = leadId;
        objLead.Status = 'close lost';
        update objLead;
    }
    
    @Auraenabled
    public static void leadstatuscancel(Id testrideId,string cancelreason){
        Test_Drive__c objtestDrive = new Test_Drive__c();
        objtestDrive.Id = testrideId;
        objtestDrive.Test_Drive_Status__c='Canceled';
        objtestDrive.Reason_For_Cancellation__c=cancelreason;
        update objtestDrive;
    }
    
    @auraenabled
    public static  Test_Drive__c leadstatuscomplete(Id testrideId,string feedback){
        Test_Drive__c testrideLeadId = [SELECT Id,Lead__c FROM Test_Drive__c WHERE Id = : testrideId];
        
        Test_Drive__c objtestDrive = new Test_Drive__c();
        objtestDrive.Id = testrideId;
        objtestDrive.Test_Drive_Status__c='Completed';
        objtestDrive.isAcctionCompleted__c= true;
        objtestDrive.Feedback__c=feedback;
        update objtestDrive;
        
        Lead  updatelead = new Lead();
        updatelead.Id = testrideLeadId.Lead__c;
        updatelead.Status ='Follow Up';
        
        update updatelead;
        return objtestDrive;
    }
    
    @auraenabled
    public static Follow_Up__c getPreviousfollowUp(String currentFollowUpId) {
        Follow_Up__c currentFollowUp = [SELECT Id, CreatedDate,Lead__c FROM Follow_Up__c WHERE Id = :currentFollowUpId];
        return currentFollowUp; 
    }
    
    @auraenabled
    public static Id createnewfollowup(String testrideId, id leadid,datetime followupdate, string feedbackvalue){
        system.debug('enter'+leadid+followupdate+feedbackvalue);
        //  Follow_Up__c followUpObj =[SELECT Id, Name,Lead__c,Status__c FROM Follow_Up__c WHERE Lead__c = :leadid  AND Status__c != 'Completed' ORDER BY CreatedDate DESC LIMIT 1];
        Lead objlead = new Lead();
        objlead.Id = leadid;
        objlead.Status ='Follow Up';
        update objlead;
        
        if(testrideId != null){
            Test_Drive__c objTes = new Test_Drive__c();
            objTes.Id = testrideId;
            objTes.Feedback__c = feedbackvalue;
            objTes.isAcctionCompleted__c = true;
            objTes.Test_Drive_Status__c = 'Completed';
            update objTes;
        }
        else{
            System.debug('testrideId');
        }
        
        Follow_Up__c crfollowup=new Follow_Up__c();
        if(followupdate!=null&&feedbackvalue!=null){
            system.debug('enter'+leadid+followupdate+feedbackvalue);
            
            crfollowup.Lead__c=leadid;
            crfollowup.Follow_Up_Date__c=followupdate;
            crfollowup.Feedback__c =feedbackvalue;
            
        }
        insert crfollowup;
        return crfollowup.Id;
    }
    
    @auraenabled
    public static Id createnewfollowupFromFollowup(String followUpId, id leadid,datetime followupdate, string feedbackvalue){
        Lead objlead = new Lead();
        objlead.Id = leadid;
        objlead.Status ='Follow Up';
        update objlead;
        
        if(followUpId != null){
            Follow_Up__c objFollow = new Follow_Up__c();
            objFollow.Id = followUpId;
            objFollow.Feedback__c = feedbackvalue;
            objFollow.isAcctionCompleted__c=true;
            update objFollow;
        }
        else{
            System.debug('testrideId');
        }
        Follow_Up__c objprefollowUp =[SELECT Id,Name,CreatedDate FROM Follow_Up__c WHERE Id =: followUpId];
        Follow_Up__c crfollowup=new Follow_Up__c();
        if(followupdate!=null&&feedbackvalue!=null){
            system.debug('enter'+leadid+followupdate+feedbackvalue);
            
            crfollowup.Lead__c=leadid;
            crfollowup.Previous_Feedback__c = feedbackvalue;
            crfollowup.Follow_Up_Date__c=followupdate;
            crfollowup.Previous_Followup_date__c =objprefollowUp.CreatedDate;
        }
        insert crfollowup;        
        return crfollowup.Id;
    }
    
    @auraenabled
    public static list<Follow_Up__c>  NotAttendedfllowups(){
        list<Follow_Up__c> NotAttendedfllowupslist=[select Id,Due_Date__c,Lead__c,Lead__r.Name,Lead__r.Phone__c,Status__c,Subject__c,Lead__r.Lead_Age__c,Follow_Up__c,Previous_Followup_date__c,Previous_Feedback__c,Feedback__c,Lead__r.City,Lead__r.State,Lead__r.Country,Lead__r.PostalCode,Lead__r.Street from Follow_Up__c where  Follow_Up_Date__c < TODAY AND Status__c!='Completed' and Lead__r.isConverted = false AND Lead__r.Status !='close lost' AND Lead__r.Status !='Test Ride'  ORDER BY CreatedDate DESC];
        return NotAttendedfllowupslist;
    }
    
    @auraenabled
    public static list<Test_Drive__c>  NotAttendedtestdrives(){
        list<Test_Drive__c> NotAttendedtestdriveslist= [select Id,Name,MobilePhone__c,Lead__c,Lead__r.Name,Test_Drive_Date__c ,Is_Reschedule__c,Ride_Type__c, Phone__c, Reschedule_Date__c,Test_Ride_Date__c, Test_Drive_Status__c,Start_Date__c,End_Date__c,Lead__r.Lead_Age__c,Drivers_License_Number__c,Indemnity__c from Test_Drive__c where  Lead__r.isConverted = false and Lead__r.Status !='close lost'AND Lead__r.Status ='Test Ride' AND Lead__r.Lead_Age__c <= 21 and ((Test_Ride_Date__c < TODAY AND  Test_Drive_Status__c='Scheduled') OR(Reschedule_Date__c < TODAY AND Test_Drive_Status__c='Reschedule')) ORDER BY Lead__r.Lead_Age__c DESC];
        return NotAttendedtestdriveslist;
    }
    
    @auraenabled
    public static summarrywrapper summarrywrappersetcount(){
        System.debug('count');
        
        List<Lead> LeadsList = [Select id,Name, Phone, CreatedDate ,Lead_Age__c,Status from Lead WHERE IsConverted=false  AND Status !='close lost' AND Status !='Test Ride' AND Status !='Follow Up'/* AND Lead_Age__c <= 21 */AND CreatedDate<TODAY  ORDER BY CreatedDate DESC limit 50 ];
        List<Lead> newLeadsList = [Select id,Name, Phone, CreatedDate ,Lead_Age__c,Status from Lead WHERE IsConverted=false  AND Status !='close lost' AND Status !='Test Ride' AND Status !='Follow Up'/* AND Lead_Age__c <= 21 */AND CreatedDate=TODAY ORDER BY CreatedDate DESC limit 50 ];
        List<Follow_Up__c> Flist = [select Id,Due_Date__c,Lead__c,Lead__r.Name,Lead__r.Phone__c,Status__c,Subject__c,Lead__r.Lead_Age__c,Follow_Up__c,Previous_Followup_date__c,Previous_Feedback__c,Feedback__c,Lead__r.City,Lead__r.State,Lead__r.Country,Lead__r.PostalCode,Lead__r.Street from Follow_Up__c where  Follow_Up_Date__c = TODAY AND Status__c!='Completed' and Lead__r.isConverted = false AND Lead__r.Status !='close lost' AND Lead__r.Status !='Test Ride'  ORDER BY CreatedDate DESC];
        List<Test_Drive__c> newList = [select Id,Name,MobilePhone__c,Lead__c,Lead__r.Name,Test_Drive_Date__c ,Is_Reschedule__c,Ride_Type__c, Phone__c, Reschedule_Date__c,Test_Ride_Date__c, Test_Drive_Status__c,Start_Date__c,End_Date__c,Lead__r.Lead_Age__c,Drivers_License_Number__c,Indemnity__c from Test_Drive__c where  Lead__r.isConverted = false and Lead__r.Status !='close lost'AND Lead__r.Status ='Test Ride' AND  ((Test_Ride_Date__c = TODAY AND  Test_Drive_Status__c='Scheduled') OR(Reschedule_Date__c = TODAY AND Test_Drive_Status__c='Reschedule')) ORDER BY Test_Ride_Date__c ASC];
        list<Follow_Up__c> NotAttendedfllowupslist=[select Id,Due_Date__c,Lead__c,Lead__r.Name,Lead__r.Phone__c,Status__c,Subject__c,Lead__r.Lead_Age__c,Follow_Up__c,Previous_Followup_date__c,Previous_Feedback__c,Feedback__c,Lead__r.City,Lead__r.State,Lead__r.Country,Lead__r.PostalCode,Lead__r.Street from Follow_Up__c where  Follow_Up_Date__c < TODAY AND Status__c!='Completed' and Lead__r.isConverted = false AND Lead__r.Status !='close lost' AND Lead__r.Status !='Test Ride'  ORDER BY CreatedDate DESC];
        list<Test_Drive__c> NotAttendedtestdriveslist= [select Id,Name,MobilePhone__c,Lead__c,Lead__r.Name,Test_Drive_Date__c ,Is_Reschedule__c,Ride_Type__c, Phone__c, Reschedule_Date__c,Test_Ride_Date__c, Test_Drive_Status__c,Start_Date__c,End_Date__c,Lead__r.Lead_Age__c,Drivers_License_Number__c,Indemnity__c from Test_Drive__c where  Lead__r.isConverted = false and Lead__r.Status !='close lost'AND Lead__r.Status ='Test Ride' AND  ((Test_Ride_Date__c < TODAY AND  Test_Drive_Status__c='Scheduled') OR(Reschedule_Date__c < TODAY AND Test_Drive_Status__c='Reschedule')) ORDER BY Test_Ride_Date__c ASC];
        list<lead> newstatusleads=[select Id,Status  from lead  where Status ='New' ];
        list<lead> testrideleads=[select Id,Status  from lead  where Status ='Test Ride' ];
        list<lead> followupleads=[select Id,Status  from lead  where Status ='Follow Up' ];
        list<lead> readyforbbokingleads=[select Id,Status  from lead  where Status ='Ready For booking' ];
        list<lead> convertleads=[select Id,Status  from lead  where Status ='Converted' ];
        list<lead> closelostleads=[select Id,Status  from lead  where Status ='Close lost' ];
        integer LeadsListcount=LeadsList.size();
        integer newLeadsListcount=newLeadsList.size();
        integer  Flistcount=Flist.size();
        integer  newListcount=newList.size();
        integer integerNotAttendedfllowupslistcount=NotAttendedfllowupslist.size();
        integer NotAttendedtestdriveslistcount=NotAttendedtestdriveslist.size();
        integer newstatusleadscount=newstatusleads.size();
        integer testrideleadscount=testrideleads.size();
        integer followupleadscount=followupleads.size();
        integer readyforbbokingleadscount=readyforbbokingleads.size();
        integer convertleadscount=convertleads.size();
        integer closelostleadscount=closelostleads.size();
        
        summarrywrapper summarrywrapperobject=new summarrywrapper();
        summarrywrapperobject.todayfolloups=Flistcount;
        summarrywrapperobject.notattenedfolloups=integerNotAttendedfllowupslistcount;
        summarrywrapperobject.Newleads=newLeadsListcount;
        summarrywrapperobject.Notattendedleads=LeadsListcount;
        summarrywrapperobject.newstatusleads=newstatusleadscount;
        summarrywrapperobject.testrideleads=testrideleadscount;
        summarrywrapperobject.followupLead=followupleadscount;
        summarrywrapperobject.readyforbbokingleads=readyforbbokingleadscount;
        summarrywrapperobject.convertleads=convertleadscount;
        summarrywrapperobject.clostlostleads=closelostleadscount;
        summarrywrapperobject.todayTestRide=newListcount;
        summarrywrapperobject.notattendedTestRide=NotAttendedtestdriveslistcount;
        System.debug('count'+summarrywrapperobject);
        return summarrywrapperobject;
    }
    
}