public with sharing class VorListViewDMSController {
    
    
    @AuraEnabled(cacheable=true)
    public static  List<VOR__c> GetDealerAssociatedVors(String userId ,String vorReason){
        List<VOR__c> vorList = new List<VOR__c>();
        System.debug('UserId' + UserId);
        User loginUser = [SELECT Id, Name, Dealer_Code__c, Profile.Name, IsPartner FROM User WHERE Id = :userId];
        
        if (loginUser.IsPartner) {
            List<User> relatedUsers = [
                SELECT Id, Name FROM User WHERE Dealer_Code__c = :loginUser.Dealer_Code__c
            ];
            List<WorkOrder> relatedJobs = [
                SELECT Id FROM WorkOrder WHERE OwnerId IN :relatedUsers AND Status != 'Canceled'
            ];
            if(vorReason=='without Reason'){
                vorList = [
                    SELECT Id, Name, VOR_Reason__c, Job_card__r.WorkOrderNumber, Job_card__c ,Ageing__c
                    FROM VOR__c 
                    WHERE VOR_Reason__c =null AND Job_Card__c IN :relatedJobs
                ];
            }else if(vorReason=='with Reason'){
                vorList = [
                    SELECT Id, Name, VOR_Reason__c, Job_card__r.WorkOrderNumber, Job_card__c ,Ageing__c
                    FROM VOR__c 
                    WHERE VOR_Reason__c !=null AND Job_Card__c IN :relatedJobs];
            }else if(vorReason=='All'){
                vorList = [
                    SELECT Id, Name, VOR_Reason__c, Job_card__r.WorkOrderNumber, Job_card__c ,Ageing__c
                    FROM VOR__c 
                    WHERE VOR_Reason__c !=null AND Job_Card__c IN :relatedJobs];
            }else{
                vorList = [
                    SELECT Id, Name, VOR_Reason__c, Job_card__r.WorkOrderNumber, Job_card__c ,Ageing__c
                    FROM VOR__c 
                    WHERE VOR_Reason__c =: vorReason AND Job_Card__c IN :relatedJobs];
            }
        }else{
            system.debug('this is not partner user ---'+userId);
        }
        
        return vorList;
    }
    
}