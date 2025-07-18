/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 06-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class WorkOrderWhatsAppHandler {
    public static void sendWhatsAppMsgMethod(List<WorkOrder> jobCardList,Map<Id,WorkOrder> oldWorkOrderMap){
        System.debug('jobCardList==>'+jobCardList);
        System.debug('oldWorkOrderMap==>'+oldWorkOrderMap);
        try{
            Set<Id> serviceCentreId = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> serviceAdvisorId = new Set<Id>();

            Map<Id,String> accountPhoneMap = new Map<Id,String>();

            List<Id> jobCardIds = new List<Id>();
            Map<Id,String> jobCardNumberMap = new Map<Id,String>();

            Map<Id,String> scAdvisorNameMap = new Map<Id,String>();
            Map<Id,String> scAdvisorPhoneMap = new Map<Id,String>();

            Map<Id,String> wmNameMap = new Map<Id,String>();
            Map<Id,String> wmPhoneMap = new Map<Id,String>();

            Map<Id,String> wmNameMapForMap = new Map<Id,String>();
            Map<Id,String> wmPhoneMapForMap = new Map<Id,String>();

            Map<Id,String> asmNameMap = new Map<Id,String>();
            Map<Id,String> asmEmailMap = new Map<Id,String>();

            Map<Id,String> phoneMap = new Map<Id,String>();

            if(!jobCardList.isEmpty()){
                for(WorkOrder w : jobCardList){
                    if(w.Status == 'Completed' && oldWorkOrderMap.get(w.Id).Status != 'Completed'){
                          serviceCentreId.add(w.Service_Center__c);
                          accountIds.add(w.AccountId);
                          serviceAdvisorId.add(w.RR_Service_Advisor__c);
                    }
                }
            }
            ServiceResource serviceAdvisor = [Select id,RelatedRecord.Phone,RelatedRecord.Name from ServiceResource WHERE Id =:serviceAdvisorId LIMIT 1];

            List<Contact> contactList = [SELECT Id, AccountId, Phone, Primary_Contact__c FROM Contact WHERE AccountId IN :accountIds AND Primary_Contact__c = true];
            if(!contactList.isEmpty()){
                  for(Contact cc : contactList){
                      accountPhoneMap.put(cc.AccountId,cc.Phone);
                  }
                  
            }
            List<Contact> relatedContactList = [Select Id,Phone,Designation__c,AccountId,LastName from Contact WHERE AccountId IN:serviceCentreId];
            if(!relatedContactList.isEmpty()){
                for(Contact c : relatedContactList){
                    if(c.Designation__c == 'WM'){
                        wmNameMap.put(c.AccountId,c.LastName);
                        wmPhoneMap.put(c.AccountId,c.Phone);
                    }
                }
            }
            Id loggedInUserId = UserInfo.getUserId();
            User u;
            if(loggedInUserId!=null){
               u = [Select Id,ManagerId,Manager.Email,Manager.Name,Manager.Phone from User WHERE Id =:loggedInUserId LIMIT 1];
            }

            for(WorkOrder ww : jobCardList){
                String wmName = wmNameMap.get(ww.Service_Center__c);
                String wmPhone = wmPhoneMap.get(ww.Service_Center__c);

                String contactPhone = accountPhoneMap.get(ww.AccountId);
                
                jobCardIds.add(ww.Id);
                /*jobCardNumberMap.put(ww.Id,ww.WorkOrderNumber);

                scAdvisorNameMap.put(ww.Id,serviceAdvisor.RelatedRecord.Name);
                scAdvisorPhoneMap.put(ww.Id,serviceAdvisor.RelatedRecord.Phone);

                wmNameMapForMap.put(ww.Id,wmName);
                wmPhoneMapForMap.put(ww.Id,wmPhone);

                asmNameMap.put(ww.Id,u.Manager.Name);
                asmEmailMap.put(ww.Id,u.Manager.Email);
  
                phoneMap.put(ww.Id,contactPhone);*/
                
                jobCardNumberMap.put(ww.Id, ww.WorkOrderNumber != null ? ww.WorkOrderNumber : 'Not Found');

                    scAdvisorNameMap.put(ww.Id, serviceAdvisor != null && serviceAdvisor.RelatedRecord != null && serviceAdvisor.RelatedRecord.Name != null ? serviceAdvisor.RelatedRecord.Name : 'Not Found');
                    scAdvisorPhoneMap.put(ww.Id, serviceAdvisor != null && serviceAdvisor.RelatedRecord != null && serviceAdvisor.RelatedRecord.Phone != null ? serviceAdvisor.RelatedRecord.Phone : 'Not Found');
                
                    wmNameMapForMap.put(ww.Id, wmName != null ? wmName : 'Not Found');
                    wmPhoneMapForMap.put(ww.Id, wmPhone != null ? wmPhone : 'Not Found');
                
                    asmNameMap.put(ww.Id, u != null && u.Manager != null && u.Manager.Name != null ? u.Manager.Name : 'Not Found');
                    asmEmailMap.put(ww.Id, u != null && u.Manager != null && u.Manager.Email != null ? u.Manager.Email : 'Not Found');
                
                    phoneMap.put(ww.Id, contactPhone != null ? contactPhone : 'Not Found');


            }
            if(!jobCardIds.isEmpty()){
                System.enqueueJob(new QueueableForServiceClosureImmediateMsg(jobCardIds,jobCardNumberMap,scAdvisorNameMap,scAdvisorPhoneMap,wmNameMapForMap,wmPhoneMapForMap,asmNameMap,asmEmailMap,phoneMap));
            }




        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
}