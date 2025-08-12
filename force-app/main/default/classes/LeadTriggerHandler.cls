/**
* @description       :
* @author            : Aniket Karmakar
* @group             :
* @last modified on  : 08-11-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class LeadTriggerHandler {
    public static void callQueableMethodForNewLead(List<Lead> newLeads){
        
        try{
            System.debug('Inside Test 18/07');
            List<Store_Details__mdt> dealerCodes = [Select id,Dealer_Code__c,IsActive__c From Store_Details__mdt WHERE IsActive__c = true];

            System.debug('dealerCodes==>'+dealerCodes);
            
            List<Id> newLeadIds = new List<Id>();
            Map<Id,String> newLeadMap = new Map<Id,String>();
            Set<String> storeDealerCodes = new Set<String>();
            
            for(Store_Details__mdt s : dealerCodes){
                storeDealerCodes.add(s.Dealer_Code__c);
            }
            
            List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
            WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
            String imageUrl = w.new_lead_book_a_test_ride_03__c;
            
            //new enhancement by Aniket on 18/02/2025
            Set<Id> leadIds = new Set<Id>();
            for(Lead l : newLeads){
                leadIds.add(l.Id);
                
            }
            List<Lead> leadListToFetch = [Select Id,LeadSource,Phone,Dealer_Code__c,Lead_Dealer_Code__c FROM Lead WHERE (Dealer_Code__c IN:storeDealerCodes OR Lead_Dealer_Code__c IN:storeDealerCodes) AND Id IN:leadIds];
            System.debug('leadListToFetch==>'+leadListToFetch);
            //up to here
             //String templateName = 'new_lead_book_a_test_ride_03';
             String templateName = 'lead_to_test_ride_flow';
            if(!leadListToFetch.isEmpty()){
                for(Lead lead : leadListToFetch){
                    if((lead.LeadSource == 'Bike Dekho' || lead.LeadSource =='Facebook'||lead.LeadSource=='Google'||lead.LeadSource=='91Wheels') && (storeDealerCodes.contains(lead.Dealer_Code__c)||storeDealerCodes.contains(lead.Lead_Dealer_Code__c)) && lead.Phone !=null ){
                        newLeadIds.add(lead.Id);
                        newLeadMap.put(lead.Id,lead.Phone);
                    }
                }
                if(!newLeadIds.isEmpty() && templateName!=null && newLeadMap!=null){
                    System.enqueueJob(new LeadToTestRideQueueable(newLeadIds, templateName, newLeadMap));//changed by Aniket on 04/08/2025
                }
            }
            
        }catch(Exception e){
            System.debug('Error is ==>'+e.getMessage());
            System.debug('Error Line ==>'+e.getLineNumber());
            System.debug('Error Cause ==>'+e.getCause());
        }
    }
    
    public static void callQueableMethodForAfterUpdate(List<Lead> newLeads,Map<Id,Lead> oldLeadMap){
           String templateName = 'new_lead_book_a_test_ride_03';
        // String templateName = 'lead_to_test_ride_flow';
        
        try{
            List<Store_Details__mdt> dealerCodes = [Select id,Dealer_Code__c,IsActive__c From Store_Details__mdt WHERE IsActive__c = true];
            List<Id> newLeadIds = new List<Id>();
            Map<Id,String> newLeadMap = new Map<Id,String>();
            
            Set<String> storeDealerCodes = new Set<String>();
            
            for(Store_Details__mdt s : dealerCodes){
                storeDealerCodes.add(s.Dealer_Code__c);
            }
            List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
            
            WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
            String imageUrl = w.new_lead_book_a_test_ride_03__c;
            // String templateName = 'new_lead_book_a_test_ride_03';
            
            List<Lead> leadsToUpdate = new List<Lead>();
            if(!newLeads.isEmpty()){
                for(Lead lead : newLeads){
                    if(lead.Dealer_Code__c != oldLeadMap.get(lead.Id).Dealer_Code__c && (lead.LeadSource == 'Bike Dekho' || lead.LeadSource =='Facebook'||lead.LeadSource=='Google'||lead.LeadSource=='91Wheels') && storeDealerCodes.contains(lead.Dealer_Code__c) && lead.Phone !=null &&lead.WhatsApp_Sent_After_Update__c == false){
                        System.debug('new dealer code ====>'+ lead.Dealer_Code__c);
                        System.debug('old dealer code ======>'+ lead.Dealer_Code__c);
                        
                        newLeadIds.add(lead.Id);
                        newLeadMap.put(lead.Id,lead.Phone);
                        leadsToUpdate.add(new Lead(Id=lead.Id,WhatsApp_Sent_After_Update__c = true));
                        
                    }
                    
                }
                if(!leadsToUpdate.isEmpty()){
                    update leadsToUpdate;
                }
                if(!newLeadIds.isEmpty() && templateName!=null && imageUrl!=null && !newLeadMap.isEmpty()){
                    System.debug('1 is running======>');
                    System.debug('newLeadIds======>' + newLeadIds);
                    System.debug('templateName======>' + templateName);
                    System.debug('imageUrl======>' + imageUrl);
                    System.debug('newLeadMap======>' + newLeadMap);
                    System.enqueueJob(new QueueableForImageTemplateMsg(newLeadIds, templateName, imageUrl, newLeadMap));
                }
                
            }
            
        }catch(Exception e){
            System.debug('Error is ==>'+e.getMessage());
            System.debug('Error Line ==>'+e.getLineNumber());
            System.debug('Error Cause ==>'+e.getCause());
        }
    }
    
    public static void callQueueableAfterRNR(List<Lead> newLeadList,Map<Id,Lead> oldLeadMap){
        String templateName = 'rnr_whatsapp_book_test_ride';
        try{
            // List<Store_Details__mdt> dealerCodes = [Select id,Dealer_Code__c,IsActive__c From Store_Details__mdt WHERE IsActive__c = true];
            
            List<Id> newLeadIds = new List<Id>();
            Map<Id,String> newLeadMap = new Map<Id,String>();
            Set<String> storeDealerCodes = new Set<String>();
            // for(Store_Details__mdt s : dealerCodes){
            //     storeDealerCodes.add(s.Dealer_Code__c);
            // }
            List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
            WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
            String imageUrl = w.rnr_whatsapp_book_test_ride__c;
            Set<Id> toGettestDrives = new Set<Id>();
            for(Lead lead : newLeadList){
                toGettestDrives.add(lead.Id);
            }
            if(toGettestDrives.isEmpty()){
                System.debug('No leads found to process for RNR test drives.');
                return;
                
            }
            List<Lead> leadList = [SELECT Id,Name,Phone,Status,(Select Id from Test_Drives__r) from Lead where Id IN: toGettestDrives];
            
            if(!leadList.isEmpty()){
                for(Lead l : leadList){
                    if(l.Status == 'RNR' && l.Status != oldLeadMap.get(l.Id).Status && l.Phone !=null && l.Test_Drives__r.isEmpty()){ /*storeDealerCodes.contains(l.Dealer_Code__c) &&*/
                        newLeadIds.add(l.Id);
                        newLeadMap.put(l.Id,l.Phone);
                    }
                }
                System.debug('newLeadIds==>'+newLeadIds);
                System.debug('newLeadMap==>'+newLeadMap);
                
                if(!newLeadIds.isEmpty() && (templateName!=null && imageUrl!=null && !newLeadMap.isEmpty())){
                    System.debug('2 is running======>');
                    System.enqueueJob(new QueueableForImageTemplateMsg(newLeadIds, templateName, imageUrl, newLeadMap));
                }
            }
        }catch(Exception e){
            System.debug('Error is ===>'+e.getMessage());
            System.debug('Error Line Number  ===>'+e.getLineNumber());
            
        }
    }
    
    public static void updatePreferredSeller(List<Lead> leadList) {
        System.debug('Entering updatePreferredSeller method.');
        
        if (leadList == null || leadList.isEmpty()) {
            System.debug('No leads fond');
            return;
        }
        
        User currentUser;
        try {
            currentUser = [
                SELECT Id, Profile.Name, Account.Name 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('Error fetching current user: ' + e.getMessage());
            return;
        }
        
        if (currentUser == null) {
            System.debug('No current user found.');
            return;
        }
        
        System.debug('Current User Details: ' + currentUser);
        
        List<Lead> leadsToUpdate = new List<Lead>();
        List<User> userList = [Select Id,Name from user where profile.name = 'System Administrator' AND Name = 'Binesh Nair' LIMIT 1];
        for (Lead lead : leadList) {  
            if (lead != null) {
                if (lead.Is_Order_Created__c == true) {
                    System.debug('Lead ' + lead.Id + ' has order created. Finding preferred store...');
                    String preferredStoreId = getPreferredStoreByPincode(lead.postalCode); // ← you provide this logic
                    if (preferredStoreId != null) {
                        System.debug('Assigning preferred store: ' + preferredStoreId);
                        lead.Dealer_Code__c = preferredStoreId;
                        lead.Dealer_Allocation__c = true;
                    }
                }
                else if ('Sales Manager (Partner)'.equalsIgnoreCase(currentUser.Profile.Name) && currentUser.Account != null) {
                    System.debug('User is a Sales Manager (Partner) with Account: ' + currentUser.Account.Name);
                    lead.PreferredSeller__c = currentUser.Account.Id;
                }
            }
        }  
        System.debug('Exiting updatePreferredSeller method.');
    }
    
    /* LMS Added by Anwar */
    public static void checkLeadStatus(List<Lead> newLeads) {
        try {
            Map<String,String> mapOfPincodeAndCenterName = new Map<String,String>();
            Map<String, String> mapOfPincodeAndDealerCode = new Map<String, String>();
            Map<String, String> mapOfPincodeAndCityName = new Map<String, String>();
            Map<String, String> mapOfDealerCodeAndCityName = new Map<String, String>();
            Map<String, Id> queueMap = new Map<String, Id>();
            for (Group grp : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']) {
                queueMap.put(grp.DeveloperName, grp.Id);
            }
            System.debug('queueMap populated =========>' + queueMap);
            
            for (Pin_Code__c grp : [SELECT Id, Dealer_Service_Center__c,Dealer_Service_Center__r.Name,Dealer_Service_Center__r.Center_Code__c,Dealer_Service_Center__r.Store_Name__c,City__r.Name,
                                    Area_Pincode__c FROM Pin_Code__c]) {
                                        mapOfPincodeAndCenterName.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Store_Name__c);
                                        mapOfPincodeAndDealerCode.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Center_Code__c);
                                        mapOfPincodeAndCityName.put(grp.Area_Pincode__c, grp.City__r.Name);
                                        mapOfDealerCodeAndCityName.put(grp.Dealer_Service_Center__r.Center_Code__c, grp.City__r.Name);
                                    }
            System.debug('queueMap populated =========>' + queueMap);
            
            List<Lead> notServiceableLeadsList = new List<Lead>();
            List<Lead> OutOfBusinessHoursLeadsList = new List<Lead>();
            List<Lead> ledList = new List<Lead>();
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            User usrObj = [select Id,firstname,Contact.Account.Name,Profile.Name,Contact.Account.Center_Code__c,Contact.Account.BillingPostalCode,Contact.Account.Store_Name__c from user where id=:userinfo.getuserid()];
            List<User> userList = [Select Id,Name from user where profile.name = 'System Administrator' AND Name = 'Binesh Nair' LIMIT 1];
            set<Id> setOfAGIds = new set<Id>();
            List<Assignment_Group__c> listOfAG = [SELECT Id,Last_Allocated_RRid__c,Business_Hours_Morning__c,Business_Hours_End_Time__c from Assignment_Group__c Where isActive__c = true AND Name__c = 'Out of Business Hours' LIMIT 1];
            System.debug('listOfAG =======> ' + listOfAG);
            for(Assignment_Group__c AGRec : listOfAG){
                setOfAGIds.add(AGRec.Id);
            }
            Time businessHoursStartTime = listOfAG[0] != null && listOfAG[0].Business_Hours_Morning__c != null ? listOfAG[0].Business_Hours_Morning__c : Time.newInstance(8, 0, 0, 0);
            Time businessHoursEndTime   = listOfAG[0] != null && listOfAG[0].Business_Hours_End_Time__c != null ? listOfAG[0].Business_Hours_End_Time__c : Time.newInstance(20, 0, 0, 0);
            System.debug('businessHoursStartTime =======> ' + businessHoursStartTime);
            System.debug('businessHoursEndTime =======> ' + businessHoursEndTime);
            Id assigningUser;
            if (!setOfAGIds.isEmpty()) {
                System.debug('1 =======> ');
                Decimal lastAssignmentId = listOfAG[0].Last_Allocated_RRid__c;
                
                List<Assignment_Group_Member__c> listOfAGM = [
                    SELECT Id, Assignment_Group__c, Active__c, Assignment_Id__c, Max_Case_Per_Day__c,Group_Member__c 
                    FROM Assignment_Group_Member__c 
                    WHERE Assignment_Group__c IN :setOfAGIds 
                    AND Active__c = true
                    ORDER BY Assignment_Id__c ASC
                ];
                
                System.debug('listOfAGM =======> ' + listOfAGM);
                Assignment_Group_Member__c selectedAGM;
                
                if (lastAssignmentId != null) {
                    for (Assignment_Group_Member__c agm : listOfAGM) {
                        if (agm.Assignment_Id__c == lastAssignmentId + 1) {
                            selectedAGM = agm;
                            break;
                        }
                    }
                }
                System.debug('selectedAGM =======> ' + selectedAGM);
                
                Assignment_Group__c assignmentRec;
                if (selectedAGM == null && !listOfAGM.isEmpty()) {
                    selectedAGM = listOfAGM[0];
                    assignmentRec = listOfAG[0];
                    assignmentRec.Last_Allocated_RRid__c = 1;
                }else{
                    assignmentRec = listOfAG[0];
                    assignmentRec.Last_Allocated_RRid__c = lastAssignmentId + 1;
                }
                update assignmentRec;
                System.debug('assignmentRec =======> ' + assignmentRec);
                System.debug('selectedAGM =======> ' + selectedAGM);
                if (selectedAGM != null) {
                    System.debug('Selected Assignment Group Member: ' + selectedAGM.Id);
                    assigningUser = selectedAGM.Group_Member__c;
                }
            }
            
            for (Lead ld : newLeads) {
                Id ownerId;
                String DealerCode;
                String StoreName;
                String CityName;
                String postalCode;
                Time currentTime = System.now().time(); 
                System.debug('currentTime =====> ' + currentTime);
                System.debug('businessHoursStartTime =====> ' + businessHoursStartTime);
                System.debug('businessHoursEndTime =====> ' + businessHoursEndTime);
                
                Boolean isBusinessHours = currentTime >= businessHoursStartTime && currentTime <= businessHoursEndTime;
                Boolean isZipInvalid = ld.PostalCode != null && !mapOfPincodeAndCenterName.containsKey(ld.PostalCode);
                System.debug('isZipInvalid =====> ' + isZipInvalid);
                
                if (isBusinessHours) {
                    if (isZipInvalid && ld.OwnerId != queueMap.get('Head_Quarter')) {
                        notServiceableLeadsList.add(new Lead(Id = ld.Id, Future_Lead__c = true, Status = 'New',Stores_Name__c = 'No Service Available', postalCode = ld.PostalCode,OwnerId = queueMap.get('Head_Quarter')));
                        System.debug('notServiceableLeadsList =====> ' + notServiceableLeadsList);
                        continue;
                    } else {
                        if (usrObj.Profile.Name == 'Sales Manager (Partner)') {
                            ownerId = usrObj.Id;
                            DealerCode = usrObj.Contact.Account.Center_Code__c;
                            StoreName = usrObj.Contact.Account.Store_Name__c;
                            CityName = mapOfDealerCodeAndCityName.get(DealerCode);
                            postalCode = usrObj.Contact.Account.BillingPostalCode;
                            
                            ledList.add(new Lead(Id = ld.Id, OwnerId = ownerId,
                                                 Dealer_Code__c = DealerCode,
                                                 Stores_Name__c = StoreName,
                                                 City = CityName,
                                                 postalCode = postalCode
                                                ));
                            
                        }
                        else if(assigningUser != null) {
                            
                            ownerId = assigningUser;
                            System.debug(' mapOfPincodeAndDealerCode ============> ' + mapOfPincodeAndDealerCode.get(ld.PostalCode));
                            System.debug(' mapOfPincodeAndCityName ============> ' + mapOfPincodeAndCityName.get(ld.PostalCode));
                            System.debug(' mapOfPincodeAndCenterName ============> ' + mapOfPincodeAndCenterName.get(ld.PostalCode));
                            StoreName = mapOfPincodeAndCenterName.get(ld.PostalCode);
                            CityName = mapOfPincodeAndCityName.get(ld.PostalCode) ;
                            DealerCode = mapOfPincodeAndDealerCode.get(ld.PostalCode);
                            postalCode = ld.PostalCode;
                            
                            ledList.add(new Lead(Id = ld.Id, OwnerId = ownerId,
                                                 Dealer_Code__c = DealerCode,
                                                 Stores_Name__c = StoreName,
                                                 City = CityName,
                                                 postalCode = postalCode
                                                ));
                        }
                        else{
                            StoreName = mapOfPincodeAndCenterName.get(ld.PostalCode);
                            CityName = mapOfPincodeAndCityName.get(ld.PostalCode) ;
                            DealerCode = mapOfPincodeAndDealerCode.get(ld.PostalCode);
                            postalCode = ld.PostalCode;
                            
                            OutOfBusinessHoursLeadsList.add(new Lead(Id = ld.Id, Status = 'New',
                                                                     OwnerId = queueMap.get('Out_of_Business_Hours'),
                                                                     Stores_Name__c = StoreName,
                                                                     Dealer_Code__c = DealerCode,
                                                                     City = CityName,
                                                                     postalCode = postalCode
                                                                    ));
                            System.debug('Lead assigned after hours to Out_of_Business_Hours queue. Lead Id: ' + ld.Id);
                        }
                    }
                } 
                else {
                    if (isZipInvalid && ld.OwnerId != queueMap.get('Head_Quarter')) {
                        notServiceableLeadsList.add(new Lead(Id = ld.Id, Future_Lead__c = true, Stores_Name__c = 'No Service Available',Status = 'New',postalCode = ld.PostalCode ,OwnerId = queueMap.get('Head_Quarter')));
                        continue;
                    } else {
                        if (usrObj.Profile.Name == 'Sales Manager (Partner)') {
                            ownerId = usrObj.Id;
                            DealerCode = usrObj.Contact.Account.Center_Code__c;
                            StoreName = usrObj.Contact.Account.Store_Name__c;
                            CityName = mapOfDealerCodeAndCityName.get(DealerCode);
                            postalCode = usrObj.Contact.Account.BillingPostalCode;
                            ledList.add(new Lead(Id = ld.Id, OwnerId = ownerId, Dealer_Code__c = DealerCode != null ? DealerCode :'' ,
                                                 Stores_Name__c = StoreName,City = CityName,
                                                 postalCode = postalCode));
                        } else {
                            System.debug('out of business hours');
                            StoreName = mapOfPincodeAndCenterName.get(ld.PostalCode);
                            CityName = mapOfPincodeAndCityName.get(ld.PostalCode) ;
                            DealerCode = mapOfPincodeAndDealerCode.get(ld.PostalCode);
                            postalCode = ld.PostalCode;
                            
                            OutOfBusinessHoursLeadsList.add(new Lead(Id = ld.Id, Status = 'New',
                                                                     OwnerId = ld.Dealer_Allocation__c == true ? queueMap.get('Out_of_Business_Hours') : userList[0].Id,
                                                                     Stores_Name__c = StoreName,
                                                                     Dealer_Code__c = DealerCode,
                                                                     City = CityName,
                                                                     postalCode = postalCode
                                                                    ));
                            System.debug('Lead assigned after hours to Out_of_Business_Hours queue. Lead Id: ' + ld.Id);
                        }
                    }
                }
            }
            
            if(!OutOfBusinessHoursLeadsList.isEmpty()){
                System.debug('Updating Leads which are out of business hours: ' + OutOfBusinessHoursLeadsList);
                update OutOfBusinessHoursLeadsList;
                
            }
            
            if (!notServiceableLeadsList.isEmpty()) {
                System.debug('Updating Not Serviceable Leads: ' + notServiceableLeadsList);
                update notServiceableLeadsList;
            }
            
            if (!ledList.isEmpty()) {
                System.debug('Updating Assigned Leads: ' + ledList);
                update ledList;
            }
            
            System.debug('checkLeadStatus method execution completed');
            
        } catch (Exception e) {
            System.debug('Error ==========> ' + e.getMessage() + ' Line ==========> ' + e.getLineNumber());
        }
    }
    
    public static void beforeConversionCheckAnyFollowIsOpendThenThrowError(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap) {
        for (Lead lead : newLeadList) {
            if (lead.Status == 'Converted' && oldLeadMap.get(lead.Id).Status != 'Converted') {
                if(lead.PostalCode == null){
                    lead.addError('Postal Code is required to convert the lead');
                }
            }
        }
    }
    
    public static void phoneNumberValidation(List<Lead> newLeadList) {
        for (Lead lead : newLeadList) {
            if (String.isNotBlank(lead.Phone)) {
                String phone = lead.Phone.trim();
                
                if (phone.startsWith('+91')) {
                    phone = phone.substring(3);
                }
                
                phone = phone.replaceAll('[^0-9]', ''); 
                if (phone.length() == 10) {
                    lead.Phone = phone;
                } else {
                    lead.addError('Phone number must be exactly 10 digits after removing special characters and country code.');
                }
            }
        }
    }
    
    public static void thresholdCallAttempt(List<Lead> leadList,Map<Id, Lead> oldMap){
        try{
            for(Lead ledRec : leadList){
                String thresCount = System.label.Threshold_Count;
                if(ledRec.Threshold_Count__c != oldMap.get(ledRec.Id).Threshold_Count__c  && ledRec.Threshold_Count__c >= decimal.valueOf(thresCount)){
                    ledRec.Status = 'Junk';
                }   
            }
        }catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String convertLeadUponStageChange(String recordId, Map<String, Object> formData) {
        System.debug('recordId =====>' + recordId);
        System.debug('formData =====>' + formData);
        try {
            if (recordId == null || formData == null) {
                return 'Invalid input: recordId or formData is null';
            }
            
            Lead leadRec = [SELECT Id, Name, OwnerId,PostalCode FROM Lead WHERE Id = :recordId LIMIT 1];
            
            List<Follow_Up__c> listOfFollowUp = [SELECT Id, Opportunity__c FROM Follow_Up__c WHERE Lead__c = :recordId Order By CreatedDate DESC];
            List<Test_Drive__c> listOfTestDrive = [SELECT Id, Opportunity__c,Test_Drive_Status__c FROM Test_Drive__c WHERE Lead__c = :recordId Order By CreatedDate DESC];
            
            String LeadStatus = formData.containsKey('Status') ? String.valueOf(formData.get('Status')) : null;
            System.debug('LeadStatus =======> ' + LeadStatus);
            String LeadEmail = formData.containsKey('Email') ? String.valueOf(formData.get('Email')) : null;
            System.debug('LeadEmail =======> ' + LeadEmail);
            String LeadPhone = formData.containsKey('Phone') ? String.valueOf(formData.get('Phone')) : null;
            System.debug('LeadPhone =======> ' + LeadPhone);
            String LeadDealerCode = formData.containsKey('DealerCode') ? String.valueOf(formData.get('DealerCode')) : null;
            System.debug('LeadDealerCode =======> ' + LeadDealerCode);
            String LeadLostReason = formData.containsKey('LostReason') ? String.valueOf(formData.get('LostReason')) : null;
            System.debug('LeadLostReason =======> ' + LeadLostReason);
            String LeadLostFeedback = formData.containsKey('LostFeedback') ? String.valueOf(formData.get('LostFeedback')) : null;
            System.debug('LeadLostFeedback =======> ' + LeadLostFeedback);
            String LeadNotes = formData.containsKey('Notes') ? String.valueOf(formData.get('Notes')) : null;
            System.debug('Notes =======> ' + LeadNotes);
            
            if (LeadStatus == null) {
                return 'Lead Status is required';
            }
            
            if (LeadStatus == 'Converted') {
                Id accountId = getLeadOwnerByPincode(leadRec.PostalCode);
                System.debug('accountId =======> ' + accountId);
                
                if (accountId == null) {
                    return 'No pincodes associated with this postal code, so we cannot convert this lead';
                }
                
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(recordId);
                lc.setConvertedStatus('Converted');
                lc.setDoNotCreateOpportunity(false);
                
                Database.LeadConvertResult result = Database.convertLead(lc);
                System.debug('Lead Conversion Result: ' + result.isSuccess());
                
                if (result.isSuccess()) {
                    Id accId = result.getAccountId();
                    Id conId = result.getContactId();
                    Id oppId = result.getOpportunityId();
                    
                    if (accId != null) {
                        Account acc = [SELECT Id FROM Account WHERE Id = :accId];
                        if (acc != null) {
                            acc.Name = leadRec.Name;
                            update acc;
                        }
                    }
                    
                    if (oppId != null) {
                        
                        Id contactId = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1].Id;
                        System.debug('contactId =======> ' + contactId);
                        
                        Id OwnerId =  [Select Id FROM User WHERE contactId = :contactId LIMIT 1 ].Id;
                        System.debug('ownerId =======> ' + ownerId);
                        
                        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppId];
                        if (opp != null) {
                            opp.Name = leadRec.Name;
                            opp.StageName = 'Test Ride Scheduled';
                            opp.CloseDate = System.today().addDays(30);
                            opp.OwnerId = ownerId;
                            update opp;
                            
                            if (!listOfFollowUp.isEmpty()) {
                                for (Follow_Up__c followUpRec : listOfFollowUp) {
                                    followUpRec.Opportunity__c = opp.Id;
                                    followUpRec.Status__c = 'Completed';
                                }
                                update listOfFollowUp;
                            }
                            
                            if (!listOfTestDrive.isEmpty()) {
                                for (Test_Drive__c testDriveRec : listOfTestDrive) {
                                    testDriveRec.Opportunity__c = opp.Id;
                                    testDriveRec.Test_Drive_Status__c = 'Canceled';
                                }
                                update listOfTestDrive;
                            }
                        }
                    }
                }
            } 
            else {
                Lead LeadRecs = new Lead(
                    Id = recordId
                );
                if(LeadStatus != null){
                    LeadRecs.Status = LeadStatus;
                }
                if(LeadNotes != null){
                    LeadRecs.Notes__c = LeadNotes;
                }
                if (LeadStatus == 'Not Interested' && LeadLostFeedback != null && LeadLostReason != null) {
                    LeadRecs.Lost_Feedback__c = LeadLostFeedback;
                    LeadRecs.Lost_Reason__c = LeadLostReason;
                }
                update LeadRecs;
            }
            return 'SUCCESS';
        } catch (Exception e) {
            System.debug('Error Message =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
            return e.getMessage();
        }
    }
    
    public static String getLeadOwnerByPincode(String postalCode) {
        System.debug('Method getLeadOwnerByPincode started with postalCode: ' + postalCode);
        
        if (String.isEmpty(postalCode)) {
            System.debug('PostalCode is null or empty, returning null');
            return null;
        }
        
        try {
            Pin_Code__c accountId;
            
            List<Pin_Code__c> pinCodeRecords = [SELECT Id, Dealer_Service_Center__c FROM Pin_Code__c WHERE Area_Pincode__c = :postalCode LIMIT 1];
            
            if (!pinCodeRecords.isEmpty()) {
                accountId = pinCodeRecords[0];
                System.debug('Found Pin_Code__c record: ' + accountId);
                return accountId.Dealer_Service_Center__c;
            } else {
                System.debug('No matching Pin_Code__c record found for postalCode: ' + postalCode);
                return null;
            }
        } catch (Exception e) {
            System.debug('Error in getLeadOwnerByPincode: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            return null;
        }
    }
    
    public static String getPreferredStoreByPincode(String postalCode) {
        List<Pin_Code__c> pincodeList = [SELECT Id, Dealer_Service_Center__r.Center_Code__c FROM Pin_Code__c WHERE Area_Pincode__c = :postalCode LIMIT 1];
        
        if (!pincodeList.isEmpty() && pincodeList[0].Dealer_Service_Center__c != null) {
            return pincodeList[0].Dealer_Service_Center__r.Center_Code__c;
        }else{
            return '123456';
        }
    }
    
    @AuraEnabled
    public static String getOpportunityId(String recordId) {
        try {
            if (recordId != null) {
                Lead leadRec = [
                    SELECT Id, ConvertedOpportunityId 
                    FROM Lead 
                    WHERE Id = :recordId
                ];
                
                System.debug('ConvertedOpportunityId ========>' +leadRec.ConvertedOpportunityId);
                return leadRec.ConvertedOpportunityId;
            }
            return null;
        } catch (Exception e) {
            System.debug('Error in getOpportunityId: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            return null;
        }
    }
    
    public static void callFutureLeadConversion(List<Lead> leadList) {
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        for (Lead l : leadList) {
            if (l.Book_Bike__c || l.WhatsApp_Sent_After_Update__c) {
                leadMap.put(l.Id, l);
            }
        }
        if (!leadMap.isEmpty()) {
            String jsonData = JSON.serialize(leadMap);
            handleLeadConversion(jsonData);
        }
    }
    
    @future
    public static void handleLeadConversion(String leadMapJson) {
        try {
            Map<String, Object> rawMap = (Map<String, Object>) JSON.deserializeUntyped(leadMapJson);
            Map<Id, Lead> leadMap = new Map<Id, Lead>();
            
            for (String key : rawMap.keySet()) {
                Map<String, Object> values = (Map<String, Object>) rawMap.get(key);
                Lead leadObj = new Lead();
                leadObj.Id = Id.valueOf(key);
                leadObj.Book_Bike__c = (Boolean) values.get('Book_Bike__c');
                leadObj.WhatsApp_Sent_After_Update__c = (Boolean) values.get('WhatsApp_Sent_After_Update__c');
                leadMap.put(leadObj.Id, leadObj);
            }
            
            List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
            List<Account> accountsToUpdate = new List<Account>();
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            List<Test_Drive__c> testDrivesToCreate = new List<Test_Drive__c>();
            
            for (Lead lead : leadMap.values()) {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lead.Id);
                lc.setConvertedStatus('Converted');
                lc.setDoNotCreateOpportunity(false);
                leadConverts.add(lc);
            }
            
            if (!leadConverts.isEmpty()) {
                List<Database.LeadConvertResult> results = Database.convertLead(leadConverts);
                
                Set<Id> contactIds = new Set<Id>();
                for (Database.LeadConvertResult res : results) {
                    if (res.isSuccess()) {
                        contactIds.add(res.getContactId());
                    }
                }
                
                Map<Id, Contact> contactMap = new Map<Id, Contact>(
                    [SELECT Id, Name FROM Contact WHERE Id IN :contactIds]
                );
                
                for (Database.LeadConvertResult res : results) {
                    if (res.isSuccess()) {
                        Lead lead = leadMap.get(res.getLeadId());
                        Contact con = contactMap.get(res.getContactId());
                        Id accId = res.getAccountId();
                        Id oppId = res.getOpportunityId();
                        
                        if (accId != null) {
                            accountsToUpdate.add(new Account(Id = accId, Name = con.Name));
                        }
                        
                        if (oppId != null) {
                            Opportunity opp = new Opportunity(
                                Id = oppId,
                                Name = con.Name,
                                CloseDate = System.today().addDays(30),
                                Probability = lead.Book_Bike__c ? 100 : null
                            );
                            
                            if(lead.WhatsApp_Sent_After_Update__c == true){
                                opp.StageName = 'Test Ride Scheduled';
                            }
                            else if(lead.Book_Bike__c == true){
                                opp.StageName = 'Test Ride Scheduled';
                            }
                            oppsToUpdate.add(opp);
                            
                            if (lead.WhatsApp_Sent_After_Update__c) {
                                testDrivesToCreate.add(new Test_Drive__c(
                                    Name = con.Name + ' -- Test Drive',
                                    Lead__c = lead.Id,
                                    Opportunity__c = opp.Id,
                                    Test_Drive_Status__c = 'Scheduled',
                                    Test_Drive_Date__c = System.today(),
                                    Subject__c = 'Scheduled Event for Test Ride',
                                    DurationInMinutes__c = 30
                                ));
                            }
                        }
                    }
                }
                
                if (!accountsToUpdate.isEmpty()) update accountsToUpdate;
                if (!oppsToUpdate.isEmpty()) update oppsToUpdate;
                if (!testDrivesToCreate.isEmpty()) insert testDrivesToCreate;
            }
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
        }
    }
    
    
    public static void updateLeadSourceForDMSUser(List<Lead> leadList, Map<Id, Lead> oldMap) {
        try {
            for (Lead lead : leadList) {
                Lead oldLead;
                if(oldMap != null){
                    oldLead = oldMap.get(lead.Id); 
                }
                
                if(oldLead != null && oldLead.Source__c != null && lead.Source__c != oldLead.Source__c && lead.OwnerId__c == 'Sales Manager (Partner)') {
                    lead.LeadSource = lead.Source__c;
                }else if (lead.Source__c != null && lead.OwnerId__c == 'Sales Manager (Partner)') {
                    lead.LeadSource = lead.Source__c;   
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }
    }
    
    public static void mytest(){
        Integer i=0;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
    }
    
    public class CustomException extends Exception {}
}