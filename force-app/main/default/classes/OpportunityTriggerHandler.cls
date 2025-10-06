/**
* @File Name : OpportunityTriggerHandler.cls
* @Description :
* @Author : Anwar Chikle
* @Last Modified By :
* @Last Modified On : April 18, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 18, 2025 |   | Initial Version
**/

public without sharing class OpportunityTriggerHandler {   
    
    // public static void pincodeIsMandatory(List<Opportunity> newLeads){
    //     try{
    //         for(Opportunity oppRec : newLeads){
    //             if (oppRec.postalCode == null || oppRec.postalCode.length() < 6) {
    //                 oppRec.postalCode.addError('Enter Proper Pincode');
    //             }
    //         }
    //     }catch(Exception e){
    //         System.debug('error message =====> '+ e.getMessage() + ' at line number =====>'+ e.getLineNumber());
    //     }
    // }
    
    public static void assignOpportunityToSM(List<Opportunity> oppList){
        try {
            Set<Id> setOfUserIds = new Set<Id>();
            for(Opportunity opp : oppList){
                setOfUserIds.add(opp.OwnerId);
            }

            Map<Id, User> mapUserIdToUser = new Map<Id, User>([
                SELECT Id, IsActive, ContactId, Contact.AccountId 
                FROM User 
                WHERE Id IN :setOfUserIds
            ]);

            Set<Id> accountIds = new Set<Id>();
            for(User usr : mapUserIdToUser.values()){
                if(usr.ContactId != null && usr.Contact.AccountId != null){
                    accountIds.add(usr.Contact.AccountId);
                }
            }

            Map<Id, Id> mapAccountIdToSMUserId = new Map<Id, Id>();
            if(!accountIds.isEmpty()){
                List<Contact> smContacts = [
                    SELECT Id, AccountId, Designation__c, 
                           (SELECT Id, IsActive FROM Users WHERE IsActive = true) 
                    FROM Contact 
                    WHERE AccountId IN :accountIds 
                      AND Designation__c = 'SM'
                ];

                for(Contact con : smContacts){
                    if(con.Users != null && !con.Users.isEmpty()){
                        for(User smUser : con.Users){
                            if(smUser.IsActive){
                                mapAccountIdToSMUserId.put(con.AccountId, smUser.Id);
                                break;
                            }
                        }
                    }
                }
            }

            List<Opportunity> oppToUpdate = new List<Opportunity>();
            for(Opportunity opp : oppList){
                User currentOwner = mapUserIdToUser.get(opp.OwnerId);
                if(currentOwner != null && currentOwner.ContactId != null && currentOwner.Contact.AccountId != null){
                    Id smUserId = mapAccountIdToSMUserId.get(currentOwner.Contact.AccountId);
                    if(smUserId != null && smUserId != opp.OwnerId){
                        oppToUpdate.add(new Opportunity(Id = opp.Id, OwnerId = smUserId));
                    }
                }
            }

            if(!oppToUpdate.isEmpty()){
                update oppToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error in assignOpportunityToSM =====> ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }

    public static void tagPricebookToOwner(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        try {
            Set<Id> ownerIds = new Set<Id>();
            for (Opportunity opp : newList) {
                if(oldMap != null){
                    if(oldMap.size() > 0 && opp.OwnerId != oldMap.get(opp.Id).OwnerId){
                        ownerIds.add(opp.OwnerId);
                    }
                }else{
                    ownerIds.add(opp.OwnerId);
                }
            }

            if (ownerIds.isEmpty()) return;

            Map<Id, User> ownerToUserMap = new Map<Id, User>([SELECT Id, ContactId, Contact.Location__c, Contact.Location__r.Price_Book__c FROM User WHERE Id IN :ownerIds AND ContactId != null]);

            Pricebook2 defaultPB = [SELECT Id FROM Pricebook2 WHERE IsActive = true AND IsStandard = true LIMIT 1];

            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            Set<Id> oppsNeedingReset = new Set<Id>();
            System.debug('1 ======>');
            for (Opportunity opp : newList) {
                if (ownerToUserMap.containsKey(opp.OwnerId)) {
                    User owner = ownerToUserMap.get(opp.OwnerId);

                    Id targetPBId = owner.Contact != null && owner.Contact.Location__r != null && owner.Contact.Location__r.Price_Book__c != null
                                    ? owner.Contact.Location__r.Price_Book__c : defaultPB.Id;

                    if (opp.Pricebook2Id != targetPBId) {
                        Opportunity oppToUpdate = new Opportunity(Id = opp.Id, Pricebook2Id = targetPBId);
                        oppsToUpdate.add(oppToUpdate);
                        oppsNeedingReset.add(opp.Id);
                    }
                }
            }

            if (!oppsToUpdate.isEmpty()) {
                System.debug('2 ======>');
                
                List<OpportunityLineItem> oliToDelete = [SELECT Id, OpportunityId, SortOrder, PricebookEntryId, Product2Id, ProductCode, Name, Quantity, TotalPrice, UnitPrice, ListPrice, ServiceDate, Description, 
                                                        CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, IsDeleted, LastViewedDate, LastReferencedDate, AssetIdentificationNumber, Payment_Method__c
                                                        FROM OpportunityLineItem WHERE OpportunityId IN :oppsNeedingReset];

                List<Opportunity_Line_Item__c> oliHistoryList = new List<Opportunity_Line_Item__c>();
                System.debug('oliToDelete ======>' + oliToDelete);
                for(OpportunityLineItem oliRec : oliToDelete){
                    Opportunity_Line_Item__c oliHistory = new Opportunity_Line_Item__c();
                    oliHistory.ServiceDate__c      = oliRec.ServiceDate;
                    oliHistory.Discount__c         = oliRec.Discount;
                    oliHistory.OpportunityId__c    = oliRec.OpportunityId;
                    oliHistory.Description__c      = oliRec.Description;
                    oliHistory.ListPrice__c        = oliRec.ListPrice;
                    oliHistory.Payment_Method__c   = oliRec.Payment_Method__c;
                    oliHistory.Product__c          = oliRec.Product2Id;
                    oliHistory.ProductCode__c      = oliRec.ProductCode;
                    oliHistory.Quantity__c         = oliRec.Quantity;
                    oliHistory.Unit_Price__c       = oliRec.UnitPrice;
                    oliHistory.Sub_total__c        = oliRec.UnitPrice * oliRec.Quantity;
                    oliHistory.Total_Price__c      = oliRec.TotalPrice;
                    oliHistoryList.add(oliHistory);
                }

                if(!oliHistoryList.isEmpty()){
                    insert oliHistoryList;
                }

                if (!oliToDelete.isEmpty()) {
                    delete oliToDelete;
                }
                update oppsToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error =======>' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
    }
    
    public static void createOrderIfOppIsClosedWon(List<Opportunity> listOfOpp, Map<Id, Opportunity> oldMap) { 
        try{
            Map<Id, Opportunity> oppsToCreateOrders = new Map<Id, Opportunity>();
            List<Order> listOfOrder = new List<Order>();
            
            for (Opportunity opp : listOfOpp) {
                if (opp.StageName == 'Closed Won' && oldMap.containsKey(opp.Id) && opp.StageName != oldMap.get(opp.Id).StageName && opp.Order__c == null) {
                    oppsToCreateOrders.put(opp.Id, opp);
                }
            }
            
            if (!oppsToCreateOrders.isEmpty()) {
                for (Opportunity opp : oppsToCreateOrders.values()) {
                    Order newOrd = new Order();
                    newOrd.AccountId = opp.AccountId;
                    newOrd.OpportunityId = opp.Id;
                    newOrd.EffectiveDate = System.today();
                    newOrd.Status = 'Draft';
                    listOfOrder.add(newOrd);
                }
                
                if (!listOfOrder.isEmpty()) {
                    insert listOfOrder;
                }
            }
        }catch(Exception e){
            System.debug('Error message ======> ' + e.getMessage() + ' at line number =====> ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String createEvent(Map<String, Object> dateObj) {
        try {
            System.debug('Received dateObj: ' + JSON.serialize(dateObj));
            
            Datetime startDateTime = null;
            Datetime endDateTime = null;
            String whatId = null;
            String Status = null;
            String rideType = null;
            String street = '';
            String city = '';
            String country = '';
            String province = '';
            String postalCode = '';
            
            if (dateObj != null) {
                if (dateObj.containsKey('StartDate') && dateObj.get('StartDate') != null) {
                    String startDateString = String.valueOf(dateObj.get('StartDate'));
                    startDateString = startDateString.replace('T', ' ').replace('Z', '');
                    startDateTime = Datetime.valueOf(startDateString);
                    System.debug('startDateTime =======>' +startDateTime);
                }
                
                if (dateObj.containsKey('EndDate') && dateObj.get('EndDate') != null) {
                    String endDateString = String.valueOf(dateObj.get('EndDate'));
                    endDateString = endDateString.replace('T', ' ').replace('Z', '');
                    endDateTime = Datetime.valueOf(endDateString);
                    System.debug('endDateTime =======>' +endDateTime );
                }
                
                if (dateObj.containsKey('Status') && dateObj.get('Status') != null) {
                    Status = String.valueOf(dateObj.get('Status'));
                }
                
                if (dateObj.containsKey('rideType') && dateObj.get('rideType') != null) {
                    rideType = String.valueOf(dateObj.get('rideType'));
                }
                
                if (dateObj.containsKey('recordId') && dateObj.get('recordId') != null) {
                    whatId = String.valueOf(dateObj.get('recordId'));
                }
            }
            
            if (dateObj.containsKey('street'))     street = String.valueOf(dateObj.get('street'));
            if (dateObj.containsKey('city'))       city = String.valueOf(dateObj.get('city'));
            if (dateObj.containsKey('country'))    country = String.valueOf(dateObj.get('country'));
            if (dateObj.containsKey('province'))   province = String.valueOf(dateObj.get('province'));
            if (dateObj.containsKey('postalCode')) postalCode = String.valueOf(dateObj.get('postalCode'));
            
            Lead leadrec = new Lead();
            Opportunity opprec = new Opportunity();
            
            String Query = 'SELECT Id, Opportunity__c, Test_Drive_Status__c FROM Test_Drive__c';
            List<Test_Drive__c> listOfTestDrive = new List<Test_Drive__c>();
            System.debug( '1==== ======>' + whatId);
            if (whatId != null && whatId.startsWithIgnoreCase('00Q')) {
                leadrec = [SELECT Id, Name FROM Lead WHERE Id = :whatId LIMIT 1];
                Query += ' WHERE Lead__c = \'' + String.escapeSingleQuotes(whatId) + '\'';
                Query += ' AND Test_Drive_Status__c NOT IN (\'Completed\', \'Canceled\',\'Reschedule\') ORDER BY CreatedDate DESC';
                listOfTestDrive = Database.query(Query);
                
            } else if (whatId != null && whatId.startsWithIgnoreCase('006')) {
                opprec = [SELECT Id, Name FROM Opportunity WHERE Id = :whatId LIMIT 1];
                Query += ' WHERE Opportunity__c = \'' + String.escapeSingleQuotes(whatId) + '\'';
                Query += ' AND Test_Drive_Status__c NOT IN (\'Completed\', \'Canceled\',\'Reschedule\') ORDER BY CreatedDate DESC';
                listOfTestDrive = Database.query(Query);
            }
            
            if(listOfTestDrive.size() > 0){
                return 'Please Complete or Cancel the previous Test Drive before creating a new one.';
            }
            
            if (startDateTime != null && endDateTime != null && Status == 'Scheduled') {
                Test_Drive__c newEvent = new Test_Drive__c(
                    Test_Drive_Date__c = startDateTime,
                    End_Date__c = endDateTime,
                    Ride_Type__c = rideType,
                    Subject__c = 'Scheduled Event for Test Ride',
                    DurationInMinutes__c = 45,
                    Test_Drive_Status__c = Status
                );
                
                if (rideType == 'HTR') {
                    newEvent.Address__Street__s        = street;
                    newEvent.Address__City__s          = city;
                    newEvent.Address__CountryCode__s   = country;
                    newEvent.Address__StateCode__s     = province;
                    newEvent.Address__PostalCode__s    = postalCode;
                }
                
                if (String.isNotBlank(whatId)) {
                    if (whatId.startsWithIgnoreCase('006')) {
                        newEvent.Opportunity__c = whatId;
                    } else if (whatId.startsWithIgnoreCase('00Q')) {
                        newEvent.Lead__c = whatId;
                    }
                }
                if(leadrec.Name != null){
                    newEvent.Name = leadrec.Name +'- Test Drive';
                }else if(opprec.Name != null){
                    newEvent.Name = opprec.Name +'- Test Drive';
                }else{
                    newEvent.Name = 'Test Drive';
                }
                insert newEvent;
                System.debug('Event successfully created =====> ' + newEvent.Id);
                
                return 'Event Scheduled Successfully';
            } else {
                Test_Drive__c newEvent = new Test_Drive__c(
                    Subject__c = 'Scheduled Event for Test Ride',
                    DurationInMinutes__c = 45,
                    Test_Drive_Status__c = Status,
                    Ride_Type__c = rideType
                );
                
                if (rideType == 'HTR') {
                    newEvent.Address__Street__s        = street;
                    newEvent.Address__City__s          = city;
                    newEvent.Address__CountryCode__s   = country;
                    newEvent.Address__StateCode__s     = province;
                    newEvent.Address__PostalCode__s    = postalCode;
                }
                
                if(startDateTime != null) {
                    newEvent.Test_Drive_Date__c = startDateTime;
                } if(endDateTime != null) {
                    newEvent.End_Date__c = endDateTime;
                }
                
                if (String.isNotBlank(whatId)) {
                    if (whatId.startsWithIgnoreCase('006')) {
                        newEvent.Opportunity__c = whatId;
                    } else if (whatId.startsWithIgnoreCase('00Q')) {
                        newEvent.Lead__c = whatId;
                    }
                }
                
                if(leadrec.Name != null){
                    newEvent.Name = leadrec.Name +'- Test Drive';
                }else if(opprec.Name != null){
                    newEvent.Name = opprec.Name +'- Test Drive';
                }else{
                    newEvent.Name = 'Test Drive';
                }
                insert newEvent;
                System.debug('Event successfully created without dates =====> ' + newEvent.Id);
                
                if (whatId.startsWithIgnoreCase('006')) {
                    Opportunity opp = new Opportunity();
                    opp.StageName = 'Test Ride Scheduled';
                    opp.Id = whatId;
                    update opp;
                } else if (whatId.startsWithIgnoreCase('00Q')) {
                    Lead led = new lead();
                    led.Id = whatId;
                    led.Status = 'Test Ride';
                    update led;
                }
                
                return 'Event Created Successfully';
            }
        } catch (Exception e) {
            System.debug('Error ============> ' + e.getMessage() + ' at line numnber ============> ' + e.getLineNumber());
            return e.getMessage();
        }
    }   
    
    @AuraEnabled
    public static string ConvertLeadAndShowTheOpportunity(String phoneNumber){
        try {
            system.debug('phoneNumber =====>'+ phoneNumber);
            String cleanedPhone = phoneNumber != null ? phoneNumber.replaceAll('[^0-9]', '') : '';
            
            List<Account> accList = [SELECT Id, Name, Center_Code__c, Store_Name__c,OwnerId FROM Account WHERE Phone = :cleanedPhone LIMIT 1];
            if (!accList.isEmpty()) {
                System.debug('Account found with phone number: ' + phoneNumber);
                List<Opportunity> oppList = [SELECT Id, Name, Phone__c,OwnerId FROM Opportunity WHERE AccountId = :accList[0].Id AND StageName != 'Closed Won' Order By CreatedDate DESC LIMIT 1];
                if (!oppList.isEmpty()) {
                    System.debug(' 1=============>');
                    
                    Opportunity opp = oppList[0];
                    if(opp.OwnerId != UserInfo.getuserId()){
                        opp.OwnerId = UserInfo.getUserId();
                    }
                    opp.Phone__c = phoneNumber;
                    opp.Secondary_Source__c = 'Walk-In';
                    update opp;
                    
                    List<Test_Drive__c> testDriveList = [Select Id,Name,Lead__c,Opportunity__c,Test_Drive_Status__c,Start_Date__c,Subject__c,DurationInMinutes__c from Test_Drive__c where Opportunity__c =: opp.Id AND Test_Drive_Status__c != 'Completed'];
                    if(!testDriveList.isEmpty()){
                        Follow_Up__c followUpRec = new Follow_Up__c();
                        followUpRec.Phone__c = opp.Phone__c;
                        followUpRec.Name = opp.Name + ' - follow-up';
                        followUpRec.Subject__c = 'call ';
                        followUpRec.Status__c = 'New';
                        followUpRec.Priority__c = 'High';
                        followUpRec.Due_Date__c = System.today() + 1;
                        followUpRec.Follow_Up_Date__c = System.today();
                        followUpRec.Opportunity__c = opp.Id;
                        Insert followUpRec;
                    }else{
                        Test_Drive__c testDriverec = new Test_Drive__c();
                        testDriverec.Name = opp.Name + ' -- Test Drive';
                        testDriverec.Opportunity__c = opp.Id;
                        testDriverec.Test_Drive_Status__c = 'New';
                        testDriverec.Test_Drive_Date__c = system.today();
                        testDriverec.Subject__c = 'Scheduled Event for Test Ride';
                        testDriverec.DurationInMinutes__c = 45;
                        insert testDriverec;
                        
                        Follow_Up__c followUpRec = new Follow_Up__c();
                        followUpRec.Phone__c = opp.Phone__c;
                        followUpRec.Name = opp.Name + ' - follow-up';
                        followUpRec.Subject__c = 'call ';
                        followUpRec.Status__c = 'New';
                        followUpRec.Priority__c = 'High';
                        followUpRec.Due_Date__c = System.today() + 1;
                        followUpRec.Follow_Up_Date__c = System.today();
                        followUpRec.Opportunity__c = opp.Id;
                        Insert followUpRec;
                    }
                    return 'Opportunity already exists for this phone number: ' + opp.Id;
                } else {
                    System.debug(' 2=============>');
                    return 'No Lead found';
                }
            }else{
                System.debug(' 3 =============>');
                List<Lead> leadList = [SELECT Id, Name, Phone,isConverted,Stores_Name__c,Future_Lead__c,OwnerId FROM Lead WHERE Phone = :cleanedPhone LIMIT 1];
                System.debug('leadList.size() ====>' + leadList.size());
                System.debug('leadList.size() ====>' + leadList.isEmpty());
                if(leadList.size() > 0){
                    Lead lead = leadList[0];
                    if(lead.isConverted == true){
                        System.debug(' 4 =============>');
                        return 'Lead is already converted';
                    }else{
                        if(lead.Stores_Name__c == 'Out of Coverage' && lead.Future_Lead__c == true){
                            user usrRec = [Select Id from User where profile.Name = 'System Administrator' AND IsActive = true limit 1];
                            lead.OwnerId = usrRec.Id;
                            update lead;
                        }
                        System.debug(' 5 =============>');
                        Database.LeadConvert leadConvert = new Database.LeadConvert();
                        leadConvert.setLeadId(lead.Id);
                        leadConvert.setDoNotCreateOpportunity(false);
                        leadConvert.setConvertedStatus('Converted');
                        
                        Database.LeadConvertResult convertResult = Database.convertLead(leadConvert);
                        
                        if(convertResult.isSuccess()){
                            System.debug(' 6 =============>');
                            Opportunity opp = [SELECT Id, Name,Phone__c FROM Opportunity WHERE Id = :convertResult.getOpportunityId() LIMIT 1];
                            Opp.Phone__c = lead.Phone;
                            opp.OwnerId = UserInfo.getUserId();
                            update opp;
                            return 'Lead converted successfully. Opportunity created: ' + opp.Id;
                        } else {
                            System.debug(' 7=============>');
                            return 'Lead conversion failed: ' + convertResult.getErrors()[0].getMessage();
                        }
                    }
                } else {
                    System.debug(' 8=============>');
                    return 'No Lead found';
                }
            }
            
        } catch (Exception e) {
            System.debug('Error ============> ' + e.getMessage() + ' at line numnber ============> ' + e.getLineNumber());
            return e.getMessage();
        }
    }
    
    @AuraEnabled
    public static String createOpportunity(Map<String, Object> objName) {
        System.debug('Received objName: ' + objName);
        try {
            if (objName == null || objName.isEmpty()) {
                return 'Please provide a valid object';
            }
            
            Map<String,String> mapOfPincodeAndCenterName = new Map<String,String>();
            Map<String, String> mapOfPincodeAndDealerCode = new Map<String, String>();
            Map<String, String> mapOfPincodeAndCityName = new Map<String, String>();
            Map<String, String> mapOfDealerCodeAndCityName = new Map<String, String>();
            
            for (Pin_Code__c grp : [SELECT Id, Dealer_Service_Center__c,Dealer_Service_Center__r.Name,Dealer_Service_Center__r.Center_Code__c,
                                    Dealer_Service_Center__r.Store_Name__c,City__r.Name,Area_Pincode__c FROM Pin_Code__c]) {
                                        mapOfPincodeAndCenterName.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Store_Name__c);
                                        mapOfPincodeAndDealerCode.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Center_Code__c);
                                        mapOfPincodeAndCityName.put(grp.Area_Pincode__c, grp.City__r.Name);
                                        mapOfDealerCodeAndCityName.put(grp.Dealer_Service_Center__r.Center_Code__c, grp.City__r.Name);
                                    }
            
            User usrObj = [select Id,firstname,Contact.Account.Name,Profile.Name,Contact.Account.Center_Code__c,Contact.Account.BillingPostalCode,Contact.Account.Store_Name__c from user where id=:userinfo.getuserid()];
            
            String DealerCode = usrObj.Contact.Account.Center_Code__c;
            String StoreName = usrObj.Contact.Account.Store_Name__c;
            String CityName = mapOfDealerCodeAndCityName.get(DealerCode);
            String postalCode = usrObj.Contact.Account.BillingPostalCode;
            
            String fName = (String)objName.get('fName');
            String lName = (String)objName.get('lName');
            String phone = (String)objName.get('phone');
            String pincode = (String)objName.get('pincode');
            String primSource = (String)objName.get('primSorceValue');
            String seconSource = (String)objName.get('secSourceValue');
            
            Account acc = new Account();
            acc.Name = fName + ' ' + lName;
            acc.Phone = phone;
            acc.BillingPostalCode = postalCode;
            acc.ownerId = UserInfo.getUserId();
            acc.Center_Code__c = DealerCode;
            acc.Store_Name__c = StoreName;
            acc.BillingCity = CityName;
            insert acc;
            
            Contact con = new Contact();
            con.FirstName = fName;
            con.LastName = lName;
            con.Phone = phone;
            con.AccountId = acc.Id;
            con.ownerId = UserInfo.getUserId();
            insert con;
            
            Opportunity newOpp = new Opportunity(); 
            newOpp.Name = fName + ' ' + lName;
            newOpp.AccountId = acc.Id;
            newOpp.StageName = 'New';
            newOpp.Enquiry_Primary_Source__c = primSource;
            newOpp.Secondary_Sources__c = seconSource;
            newOpp.CloseDate = System.today().addDays(30);
            newOpp.ownerId = UserInfo.getUserId();
            newOpp.Phone__c = phone;
            insert newOpp;
            
            OpportunityContactRole ocr = new OpportunityContactRole();
            ocr.OpportunityId = newOpp.Id;
            ocr.ContactId = con.Id;
            ocr.Role = 'Decision Maker';
            ocr.IsPrimary = true;
            insert ocr;
            
            return 'Opportunity created with Id: ' + newOpp.Id;
        } catch (Exception e) {
            System.debug('Error ============> ' + e.getMessage() + ' at line number ============> ' + e.getLineNumber());
            return e.getMessage();
        }
    }
    
    public static void onClosedWonShowErrorIfOppLineItemsAreNotThere(List<Opportunity> newListOfOpp,Map<Id, Opportunity> oldMap){
        try{
            Set<Id> setOfOppIdWhichAreClosedWon = new Set<Id>();
            Map<Id, List<OpportunityLineItem>> mapOfOppAndLineItems = new Map<Id, List<OpportunityLineItem>>();
            for (Opportunity opp : newListOfOpp) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                    setOfOppIdWhichAreClosedWon.add(opp.Id);
                    mapOfOppAndLineItems.put(opp.Id, new List<OpportunityLineItem>());
                }
            }
            List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
            if(!oppLineItems.isEmpty()){
                oppLineItems = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId IN :setOfOppIdWhichAreClosedWon];
                
                for (OpportunityLineItem oli : oppLineItems) {
                    if (!mapOfOppAndLineItems.containsKey(oli.OpportunityId)) {
                        mapOfOppAndLineItems.put(oli.OpportunityId, new List<OpportunityLineItem>());
                    }
                    mapOfOppAndLineItems.get(oli.OpportunityId).add(oli);
                }
                
                for (Opportunity opp : newListOfOpp) {
                    if (setOfOppIdWhichAreClosedWon.contains(opp.Id)) {
                        List<OpportunityLineItem> oppLineItemList = mapOfOppAndLineItems.get(opp.Id);
                        if (oppLineItemList == null || oppLineItemList.isEmpty()) {
                            opp.addError('Please Add the Enquiry Products First');
                        }
                    }
                }
            }            
        } catch (Exception e) {
            System.debug('Error ============> ' + e.getMessage() + ' at line numnber ============> ' + e.getLineNumber());
        }
    }
    
    public static void onClosedWonShowErrorIfBookingAmountIsNull(List<Opportunity> newListOfOpp, Map<Id, Opportunity> oldMap) {
        try{
            for(Opportunity newOpp : newListOfOpp) {
                Opportunity oldOpp = oldMap.get(newOpp.Id);
                
                if (newOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                    if (newOpp.Booking_Amount__c == null) {
                        newOpp.addError('Please Add the Products And Then Create Payment');   
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error ============> ' + e.getMessage() + ' at line numnber ============> ' + e.getLineNumber());
        }
    }
    
    public static void createFollowUpOnOppCreated(List<Opportunity> newListOfOpp){
        try{
            List<Follow_Up__c> followUpListToBeInserted = new List<Follow_Up__c>();
            for (Opportunity opp : newListOfOpp) {
                Follow_Up__c newFollowUp = new Follow_Up__c();
                newFollowUp.Follow_Up_Date__c = system.today().addDays(1);
                newFollowUp.Opportunity__c = opp.Id;
                newFollowUp.Name = opp.Name + ' - Follow Up';
                newFollowUp.FollowUpType__c = 'Schedule TR Call';
                followUpListToBeInserted.add(newFollowUp);
            }
            if(!followUpListToBeInserted.isEmpty()){
                insert followUpListToBeInserted;
            }
        } catch (Exception e) {
            System.debug('Error ============> ' + e.getMessage() + ' at line numnber ============> ' + e.getLineNumber());
        }
    }

    public static void getThePreferredSellerOfAccount(List<Opportunity> newListOfOpp, Map<Id, Opportunity> oldMap) {
        try {
            Set<Id> setOfOwnerId = new Set<Id>();

            for (Opportunity opp : newListOfOpp) {
                Opportunity oldOppo = oldMap.get(opp.Id);

                if (oldOppo == null) {
                    setOfOwnerId.add(opp.OwnerId);
                } else if (oldOppo.OwnerId != opp.OwnerId) {
                    setOfOwnerId.add(opp.OwnerId);
                }
            }

            if (!setOfOwnerId.isEmpty()) {
                Map<Id, User> mapOfUsers = new Map<Id, User>([SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id IN :setOfOwnerId AND ContactId != null AND Contact.AccountId != null]);
                List<Opportunity> oppsToUpdate = new List<Opportunity>();

                for (Opportunity opp : newListOfOpp) {
                    User usr = mapOfUsers.get(opp.OwnerId);
                    if (usr != null && usr.ContactId != null && usr.Contact.AccountId != null) {
                        Opportunity oppRecToUpdate = new Opportunity();
                        oppRecToUpdate.PreferredSeller__c = usr.Contact.AccountId;
                        oppRecToUpdate.Id = opp.Id;
                        oppsToUpdate.add(oppRecToUpdate);
                    }
                }

                if (!oppsToUpdate.isEmpty()) {
                    update oppsToUpdate;
                }
            }
        } catch (Exception e) {
            System.debug('Error message ====>' + e.getMessage() + ' at line number ======> ' + e.getLineNumber());
        }
    }

    
    public static void changeOwnerOfTestDriveAndFollowUpIsOppOwnerIsChanged(List<Opportunity> newListOfOpp, Map<Id, Opportunity> oldMap){
        try{
            set<Id> setOfOppId = new Set<Id>();
            List<Test_Drive__c> testDriveToBeUpdated = new List<Test_Drive__c>();
            List<Follow_Up__c> followUpToBeUpdated = new List<Follow_Up__c>();
            for(Opportunity opp : newListOfOpp){
                if(opp.OwnerId != oldMap.get(opp.Id).OwnerId ){
                    setOfOppId.add(opp.Id);
                }
            }
            
            if(!setOfOppId.isEmpty()){
                Map<Id,Opportunity> mapOfOpp = new Map<Id,Opportunity>([Select Id,OwnerId from Opportunity where Id IN : setOfOppId]);
                List<Test_Drive__c> testDriveList = [Select Id,Opportunity__c,OwnerId from Test_Drive__c where Opportunity__c IN : setOfOppId];
                if(!testDriveList.isEmpty()){
                    for(Test_Drive__c testDrive : testDriveList){
                        testDrive.OwnerId = mapOfOpp.get(testDrive.Opportunity__c).OwnerId;
                        testDriveToBeUpdated.add(testDrive);
                    }
                }
                List<Follow_Up__c> followUpList = [Select Id,Opportunity__c,OwnerId from Follow_Up__c where Opportunity__c IN : setOfOppId];
                
                if(!followUpList.isEmpty()){
                    for(Follow_Up__c followUp : followUpList){
                        followUp.OwnerId = mapOfOpp.get(followUp.Opportunity__c).OwnerId;
                        followUpToBeUpdated.add(followUp);
                    }
                }
                
                if(!testDriveToBeUpdated.isEmpty()){
                    update testDriveToBeUpdated;
                }
                if(!followUpToBeUpdated.isEmpty()){
                    update followUpToBeUpdated;
                }
            }
        } catch (Exception e) {
            System.debug('Error ============> ' + e.getMessage() + ' at line numnber ============> ' + e.getLineNumber());
        }
    }

    public static void lockTheRecordAfterClosedWon(List<Opportunity> newListOfOpp, Map<Id, Opportunity> oldMap){
        try {
           
            // String currentProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
            // if (currentProfileName == 'System Administrator') {
            //     return;
            // }
            
            for (Opportunity opp : newListOfOpp) {
                Opportunity oldRec = oldMap.get(opp.Id);

                if (oldRec == null) {
                    System.debug('Skipping record due to null oldRec for ID: ' + opp.Id);
                    continue;
                }
                

                System.debug('Checking Job Card: ' + opp.Id);
                System.debug('Old Status: ' + oldRec.StageName);
                System.debug('New Status: ' + opp.StageName);

                if (oldRec.StageName == 'Closed Won') {
                    opp.addError('You cannot update Closed Won Enquiry');
                }
            }
        } catch (Exception ex) {
            System.debug('Exception in validateJobCardStatus: ' + ex.getMessage() + 'Line Number : ' + ex.getLineNumber());
        }
    }

    public static List<Opportunity> getOwnerFromPincodeAndAssignToOpp(List<Opportunity> oppToBeInserted,String postalcode){
        try{
            List<Pin_Code__c> listOfPinCode=[SELECT Id,Dealer_Service_Center__c FROM Pin_Code__c WHERE Area_Pincode__c=:postalcode AND Dealer_Service_Center__c!=null LIMIT 1];
            System.debug('listOfPinCode==>'+listOfPinCode);
            if(!listOfPinCode.isEmpty()){
                Set<Id> setOfAccountId=new Set<Id>();
                for(Pin_Code__c pinRec:listOfPinCode){
                    if(pinRec.Dealer_Service_Center__c!=null){
                        setOfAccountId.add(pinRec.Dealer_Service_Center__c);
                    }
                }
                if(!setOfAccountId.isEmpty()){
                    List<Contact> listOfContact=[SELECT Id,Designation__c,User__c FROM Contact WHERE AccountId IN:setOfAccountId];
                    System.debug('listOfContact==>'+listOfContact);
                    if(!listOfContact.isEmpty()){
                        Id selectedUserId;
                        for(Contact con:listOfContact){
                            if(con.Designation__c=='SM'){
                                selectedUserId=con.Id;
                                break;
                            }
                        }
                        if(selectedUserId==null){
                            selectedUserId=listOfContact[0].Id;
                        }
                        System.debug('selectedUserId ======> '+selectedUserId);
                        if(selectedUserId!=null){
                            List<User> userList=[SELECT Id,Name,Contact.AccountId FROM User WHERE ContactId=:selectedUserId LIMIT 1];
                            if(!userList.isEmpty()){
                                for(Opportunity opp:oppToBeInserted){
                                    opp.OwnerId=userList[0].Id;
                                    opp.PreferredSeller__c=userList[0].Contact.AccountId;
                                }
                                return oppToBeInserted;
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
            System.debug('Error ============> '+e.getMessage()+' at line number ============> '+e.getLineNumber());
        }
        return oppToBeInserted;
    }


}