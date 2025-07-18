/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 04-09-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AccountTriggerHandler {
    public static void sendDataToRiverWebsiteAfterUpdate(List<Account> updatedAccountList,Map<Id,Account> oldACcMap){
        try{
            List<Id> accountIds = new List<Id>();
            if(!updatedAccountList.isEmpty()){
                for(Account a : updatedAccountList){
                    if(a.Name != oldACcMap.get(a.Id).Name || a.Email__c != oldACcMap.get(a.Id).Email__c || a.Phone != oldACcMap.get(a.id).Phone || a.BillingCity != oldACcMap.get(a.id).BillingCity || a.BillingStreet != oldACcMap.get(a.id).BillingStreet || a.BillingPostalCode != oldACcMap.get(a.id).BillingPostalCode || a.BillingState != oldACcMap.get(a.id).BillingState){
                        accountIds.add(a.Id);
                    }
                    
                }
            }
            if(!accountIds.isEmpty()){
                System.enqueueJob(new QueueableForUpdateUserOnWebsite(accountIds));
            }

        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
}