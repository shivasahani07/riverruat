@RestResource(urlMapping='/RegisterAccount')
global with sharing class AccountRegistrationAPI {
    @HttpPost
    global static void createAccountContact(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        res.addHeader('Content-Type', 'application/json');
        String requestBody = req.requestBody.toString();
        
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
        Map<String, Object> billing_address = (Map<String, Object>)requestMap.get('billing_address') != null? (Map<String, Object>)requestMap.get('billing_address'):null;
        Map<String, Object> shipping_address = (Map<String, Object>)requestMap.get('shipping_address') != null? (Map<String, Object>)requestMap.get('shipping_address'):null;
        
        String leadEmail = (String)requestMap.get('email_address') != null? (String)requestMap.get('email_address'): '';
        String phone = (String)requestMap.get('phone_number') != null?(String)requestMap.get('phone_number'):'';
        String Company = (String)requestMap.get('full_name');
        String accountId = null;
        List<lead> existingLead = new List<lead>();
        List<Account> existingAccount = new List<Account>();
        String postalcode = (String)billing_address.get('pin_code') != null ? (String)billing_address.get('pin_code') : '';
        try{
            if(phone != null || phone != ''){
                existingAccount = [SELECT Id,Name,Phone FROM Account WHERE Phone = :phone  LIMIT 1];
                
                
                if(!existingAccount.isEmpty()){
                    
                    createOpportunityForAccount(existingAccount[0],postalcode);
                    
                    accountId = existingAccount[0].Id;
                    
                    Account newAccount = new Account(
                        id = accountId,
                        Name = (String)requestMap.get('full_name'),
                        Type = 'Customer',
                        Email__c = (String)requestMap.get('email_address') != null ? (String)requestMap.get('email_address') : '',
                        BillingCountry = (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India',
                        Phone = (String)requestMap.get('phone_number') != null ? (String)requestMap.get('phone_number') : '',
                        BillingStreet = ((String)billing_address.get('address_1') != null ? (String)billing_address.get('address_1') : '') +' '+((String)billing_address.get('address_2') != null ? (String)billing_address.get('address_2') : ''),
                        BillingCity = (String)billing_address.get('city') != null ? (String)billing_address.get('city') : '',
                        BillingState = (String)billing_address.get('state') != null ? (String)billing_address.get('state') : '',
                        BillingPostalCode = (String)billing_address.get('pin_code') != null ? (String)billing_address.get('pin_code') : '',
                        ShippingCountry = (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India',
                        ShippingStreet = ((String)shipping_address.get('address_1') != null ? (String)shipping_address.get('address_1') : '') +' '+ ((String)shipping_address.get('address_2') != null ? (String)shipping_address.get('address_2') : ''),
                        ShippingCity = (String)shipping_address.get('city') != null ? (String)shipping_address.get('city') : '',
                        ShippingState = (String)shipping_address.get('state') != null ? (String)shipping_address.get('state') : '',
                        ShippingPostalCode = (String)shipping_address.get('pin_code') != null ? (String)shipping_address.get('pin_code') : ''
                    );
                    Update newAccount;
                }
                else {
                    
                    existingLead = [SELECT Id,Owner.Type,Is_Order_Created__c,ConvertedAccount.Phone FROM Lead 
                                    WHERE (Email = :leadEmail OR Phone = :phone) AND isConverted = false LIMIT 1];
                    
                    if (!existingLead.isEmpty()) {
                        system.debug('existing lead found>>'+existingLead[0]);
                        if (existingLead[0].Owner.Type == 'Queue') {
                            User targetUser = [SELECT Id,LastName FROM User WHERE Name LIKE '%Binesh%' LIMIT 1];
                            
                            if (targetUser != null) {
                                existingLead[0].OwnerId = targetUser.Id;
                                existingLead[0].Is_Order_Created__c = true;
                                update existingLead[0];
                            }
                        }
                        Database.LeadConvert lc = new Database.LeadConvert();
                        lc.setLeadId(existingLead[0].Id);
                        lc.setConvertedStatus('Converted');
                        
                        Database.LeadConvertResult lcr = Database.convertLead(lc);
                        
                        if (lcr.isSuccess()) {
                            system.debug('Lead converted to Account and Contact' + lcr.getAccountId() + ' contact is >> ' + lcr.getContactId());
                            Id accId = lcr.getAccountId();
                            Id oppId = lcr.getOpportunityId();
                            
                            Account newAccount = new Account(Id = accId,
                                                             Type = 'Customer',
                                                             Name = (String)requestMap.get('full_name'),
                                                             Phone = (String)requestMap.get('phone_number') != null ? (String)requestMap.get('phone_number') : '',
                                                             Email__c = (String)requestMap.get('email_address') != null ? (String)requestMap.get('email_address') : '',
                                                             BillingCountry = (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India',
                                                             BillingStreet = ((String)billing_address.get('address_1') != null ? (String)billing_address.get('address_1') : '') +' '+ ((String)billing_address.get('address_2') != null ? (String)billing_address.get('address_2') : ''),
                                                             BillingCity = (String)billing_address.get('city') != null ? (String)billing_address.get('city') : '',
                                                             BillingState = (String)billing_address.get('state') != null ? (String)billing_address.get('state') : '',
                                                             BillingPostalCode = (String)billing_address.get('pin_code') != null ? (String)billing_address.get('pin_code') : '',
                                                             ShippingCountry = (String)shipping_address.get('country') != null ? (String)shipping_address.get('country') : 'India',
                                                             ShippingStreet = ((String)shipping_address.get('address_1') != null ? (String)shipping_address.get('address_1') : '')+ ' '+((String)shipping_address.get('address_2') != null ? (String)shipping_address.get('address_2') : ''),
                                                             ShippingCity = (String)shipping_address.get('city') != null ? (String)shipping_address.get('city') : '',
                                                             ShippingState = (String)shipping_address.get('state') != null ? (String)shipping_address.get('state') : '',
                                                             ShippingPostalCode = (String)shipping_address.get('pin_code') != null ? (String)shipping_address.get('pin_code') : ''
                                                            );
                            update newAccount;
                            
                            accountId = accId;
                            createOpportunityForAccount(newAccount,postalcode);
                            System.debug('Done ============>');
                        }
                    }     
                    else {
                        
                        Lead newLead = new Lead(
                            LastName = (String)requestMap.get('full_name'),
                            Company =(String)requestMap.get('full_name'),
                            Email = (String)requestMap.get('email_address') != null ? (String)requestMap.get('email_address') : '',
                            Phone = (String)requestMap.get('phone_number') != null ? (String)requestMap.get('phone_number') : '',
                            LeadSource = 'Online',
                            Secondary_Sources__c = 'River Website',
                            Is_Order_Created__c = true,
                            verified__c = true,
                            Status = 'Converted',
                            Street = (billing_address.containsKey('address_1') ? (String)billing_address.get('address_1') : '') + ' ' +(billing_address.containsKey('address_2') ? (String)billing_address.get('address_2') : ''),
                            City = billing_address.containsKey('city') ? (String)billing_address.get('city') : '',
                            State = billing_address.containsKey('state') ? (String)billing_address.get('state') : '',
                            PostalCode = billing_address.containsKey('pin_code') ? (String)billing_address.get('pin_code') : '',
                            Country = billing_address.containsKey('country') ? (String)billing_address.get('country') : 'India'
                        );
                        insert newLead;
                        
                        if (newLead.Owner.Type == 'Queue') {
                            User targetUser = [SELECT Id,LastName FROM User WHERE LastName LIKE '%Binesh%' LIMIT 1];
                            if (targetUser != null) {
                                newLead.OwnerId = targetUser.Id;
                                update newLead; 
                            }
                        }
                        
                        Database.LeadConvert lc = new Database.LeadConvert();
                        lc.setLeadId(newLead.Id);
                        lc.setConvertedStatus('Converted');
                        
                        Database.LeadConvertResult lcr = Database.convertLead(lc);
                        system.debug('New Lead is created >> ' + newLead);                    
                        system.debug('creating new account and contact1');
                        
                        Account newAccount = new Account(
                            Id = lcr.getAccountId(),
                            Name = (String)requestMap.get('full_name'),
                            AccountSource = 'River Website',
                            Type = 'Customer',
                            Email__c = (String)requestMap.get('email_address') != null ? (String)requestMap.get('email_address') : '',
                            BillingCountry = (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India',
                            Phone = (String)requestMap.get('phone_number') != null ? (String)requestMap.get('phone_number') : '',
                            BillingStreet = ((String)billing_address.get('address_1') != null ? (String)billing_address.get('address_1') : '') +' '+((String)billing_address.get('address_2') != null ? (String)billing_address.get('address_2') : ''),
                            BillingCity = (String)billing_address.get('city') != null ? (String)billing_address.get('city') : '',
                            BillingState = (String)billing_address.get('state') != null ? (String)billing_address.get('state') : '',
                            BillingPostalCode = (String)billing_address.get('pin_code') != null ? (String)billing_address.get('pin_code') : '',
                            ShippingCountry = (String)shipping_address.get('country') != null ? (String)shipping_address.get('country') : 'India',
                            ShippingStreet = ((String)shipping_address.get('address_1') != null ? (String)shipping_address.get('address_1') : '') +' '+ ((String)shipping_address.get('address_2') != null ? (String)shipping_address.get('address_2') : ''),
                            ShippingCity = (String)shipping_address.get('city') != null ? (String)shipping_address.get('city') : '',
                            ShippingState = (String)shipping_address.get('state') != null ? (String)shipping_address.get('state') : '',
                            ShippingPostalCode = (String)shipping_address.get('pin_code') != null ? (String)shipping_address.get('pin_code') : ''
                        );
                        update newAccount;
                        
                        accountId = newAccount.Id;
                        
                        
                        createOpportunityForAccount(newAccount,postalcode);
                    }
                }
            }
            
            Map<String, Object> response = new Map<String, Object>();
            response.put('status', 'Success');
            response.put('accountId', accountId);
            res.statusCode = 200; 
            res.responseBody = Blob.valueOf(JSON.serialize(response));
            
            insertIntegrationLog('Account Registration',JSON.seriaLizePretty(requestMap),JSON.seriaLizePretty(response),'','Success');
            
        }catch(Exception e){
            system.debug('Exception occured: '+e);
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            Map<String, Object> response = new Map<String, Object>();
            response.put('status', 'Failed');
            res.statusCode = 500; 
            res.responseBody = Blob.valueOf('Exception: '+e.getMessage());
            
            insertIntegrationLog('Account Registration',JSON.seriaLizePretty(requestMap),JSON.seriaLizePretty(response),'Exception: '+e.getMessage(),'Failed');
            
        }
    }
    
    
    private static void createOpportunityForAccount(Account acc, String postalcode) {
        List<Opportunity> oppList = [SELECT Id,StageName FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        System.debug('oppList ======>'+ oppList);
        List<Opportunity> oppToBeInserted = new List<Opportunity>();
        List<Opportunity> oppToBeUpdated = new List<Opportunity>();
        Opportunity o = new Opportunity();
        
        if (!oppList.isEmpty()) {
            if (oppList[0].StageName == 'Closed Won') {
                o.Name = acc.Name;
                o.CloseDate = System.Today();
                o.AccountId = acc.Id;
                o.ForecastCategoryName = 'Pipeline';
                o.StageName = 'New';
                o.Phone__c = acc.Phone;
                oppToBeInserted.add(o);
            }else{
                o.Id   = oppList[0].Id;
                o.Name = acc.Name;
                o.CloseDate = System.Today();
                o.AccountId = acc.Id;
                o.ForecastCategoryName = 'Pipeline';
                o.StageName = 'New';
                o.Phone__c = acc.Phone;
                oppToBeUpdated.add(o);
            }
        } else {
            o.Name = acc.Name;
            o.CloseDate = System.Today();
            o.AccountId = acc.Id;
            o.ForecastCategoryName = 'Pipeline';
            o.StageName = 'New';
            o.Phone__c = acc.Phone;
            oppToBeInserted.add(o);
        }
        if (!oppToBeInserted.isEmpty()) {
            System.debug('oppToBeInserted ======>'+ oppToBeInserted);
            insert OpportunityTriggerHandler.getOwnerFromPincodeAndAssignToOpp(oppToBeInserted,postalcode);
        }if(!oppToBeUpdated.isEmpty()){
            System.debug('oppToBeUpdated ======>'+ oppToBeInserted);
            update OpportunityTriggerHandler.getOwnerFromPincodeAndAssignToOpp(oppToBeUpdated,postalcode);
        }
        
    }
    
    private static void insertIntegrationLog(String type,String reqPayload,String resPayload,String errorMessage,String status){
        try{
            Integration_Log__c  logObj = new Integration_Log__c(
                Integration_Type__c = type,
                Request_Payload__c = reqPayload,
                Response_Payload__c = resPayload,
                Error_Message__c = errorMessage,
                Status__c = status
            );
            Insert logObj;
            System.debug('Inserted Log Object==>'+logObj);
            
        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
}