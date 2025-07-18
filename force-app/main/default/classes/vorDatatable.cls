/**
* @File Name : vorDatatable.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 13, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 13, 2025 |   | Initial Version
**/

public class vorDatatable {
    
    @AuraEnabled
    public static List<VOR__c> getVorOfCurrentUser(String userId,String filter, Integer limitSize, Integer offsetSize) {
        try {
            String query = 'SELECT Id, Name, Ageing__c, Job_Card__c, Job_Card__r.WorkOrderNumber FROM VOR__c ' +
                           'WHERE OwnerId = :userId';


            if (filter == 'without Reason') {
                query += ' AND VOR_Reason__c = null';
            } else {
                query += ' AND VOR_Reason__c != null';
            }

            query += ' ORDER BY CreatedDate ASC';
            query += ' LIMIT ' + limitSize + ' OFFSET ' + offsetSize;

            System.debug('query ======> ' + query);

            return Database.query(query);
        } catch(Exception e) {
            System.debug('Error message ====> ' + e.getMessage() + ' at line number ======>' + e.getLineNumber());
            return null;
        }
    }


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
             vorList = [
                SELECT Id, Name, VOR_Reason__c, Job_card__r.WorkOrderNumber, Job_card__c ,Ageing__c
                FROM VOR__c 
                WHERE VOR_Reason__c =:vorReason AND Job_Card__c IN :relatedJobs
            ];
    }else{
        system.debug('this is not partner user ---'+userId);
    }

        return vorList;
    }
}