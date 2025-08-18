public class SalesforceTicketController {
    
    @AuraEnabled(cacheable=true)
    public static List<Salesforce_Support__c> getSalesforceSupportRecords(){

        try{
            System.debug('---------------- Inside getSalesforceSupportRecords() ----------------');
            return [
                SELECT Id, Name, Status__c, Subject__c, Description__c, Internal_Team_Remarks__c, Team_Analysis__c, Additional_Details__c, CreatedById,
                Ticket_Age__c, Closing_Date__c, location__c, CreatedDate
                FROM Salesforce_Support__c
                WHERE Status__c != 'Closed'
                OR CreatedDate = TODAY
            ];
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ContactUserWrapper> getContactAndUserOptions(){
        try {
            System.debug('---------------- Inside getContactAndUserOptions() ----------------');

            List<ContactUserWrapper> lstContactUserWrapper = new List<ContactUserWrapper>();

            for(Contact c : [
                SELECT Id, FirstName, LastName, Name
                FROM Contact
                WHERE Designation__c = 'Technical Support'
            ]){
                lstContactUserWrapper.add(new ContactUserWrapper(c.Name, c.Id, 'Contact'));
            }

            for(User u : [
                SELECT Id, Name, Email 
                FROM User
                WHERE IsActive = true
                LIMIT 5
            ]){
                lstContactUserWrapper.add(new ContactUserWrapper(u.Name, u.Id, 'User'));
            }

            return lstContactUserWrapper;
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String createTicketAssignment(Id ticketId, Id userId, Id contactId, String remarks, String priority) {
        
        System.debug('ticketId : ' + ticketId + '   &&   userId : ' + userId + '   &&   remarks : ' + remarks + '   &&   priority : ' + priority);

        try{
            System.debug('---------------- Inside createTicketAssignment() ----------------');

            Ticket_Assignment__c ta = new Ticket_Assignment__c();
            ta.Ticket__c = ticketId;
            ta.Assigned_To__c = userId != null ? userId : null;
            ta.Contact__c = contactId != null ? contactId : null;
            ta.Assigned_By__c = UserInfo.getUserId();
            ta.Assignment_Date__c = System.now();
            ta.Remarks__c = remarks;
            ta.Priority__c = priority;

            insert ta;

            return 'Ticket Assigned Successfully !!';
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }


    // Wrapper Class
    public class ContactUserWrapper{

        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String type;

        public ContactUserWrapper(String label, String value, String type){
            this.label = label;
            this.value = value;
            this.type  = type;
        }
    }
}