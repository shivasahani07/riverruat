@isTest
public class TriggerOnTicketHelperTest {
    
    @isTest
    static void testAfterTicketUpdate() {
        // Step 1: Create initial test ticket with no resolution
        Ticket__c testTicket = new Ticket__c();
        insert testTicket;
        
        // Step 2: Update the ticket with a resolution
        testTicket.Resolution__c = 'Issue Resolved';
        update testTicket;
        
        // Step 3: Simulate trigger update logic by calling helper directly
        Ticket__c updatedTicket = [SELECT Id, Resolution__c, Resolution_History__c FROM Ticket__c WHERE Id = :testTicket.Id];
        
        // Simulate trigger.new context
        List<Ticket__c> newTickets = new List<Ticket__c>{
            new Ticket__c(
                Id = updatedTicket.Id,
                Resolution__c = updatedTicket.Resolution__c,
                Resolution_History__c = updatedTicket.Resolution_History__c // Should be null before update
            )
                };
                    
                    Test.startTest();
        TriggerOnTicketHelper.afterTicketUpdate(newTickets);
        Test.stopTest();
        
        // Step 4: Verify the Resolution_History__c field was updated
        Ticket__c finalTicket = [SELECT Id, Resolution_History__c FROM Ticket__c WHERE Id = :testTicket.Id];
        System.assertEquals('Issue Resolved', finalTicket.Resolution_History__c, 'Resolution_History__c should match updated Resolution__c');
    }
    
    @IsTest
    static void getUserTest() {
        
        Account portalAccount = new Account(Name = 'Test Portal Account', Type = 'Service Center', Center_Code__c = '948984');
        insert portalAccount;
        
        Contact portalContact = new Contact(
            LastName = 'Test Portal Contact',
            Role_Type__c = 'Sales',
            AccountId = portalAccount.Id,
            Phone = '9035244421',
            Designation__c = 'WM'
        );
        insert portalContact;
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Service_Center__c = portalContact.AccountId
        );
        insert wo;
        
        Id recordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Ticket__c' 
            AND DeveloperName = 'PSF_Ticket' 
            LIMIT 1
        ].Id;
        
        Ticket__c ticket = new Ticket__c(
            Status__c = 'Open',
            Job_Card__c = wo.Id,
            RecordTypeId = recordTypeId
        );
        insert ticket;
        
        ticket.Status__c = 'Pending';
        update ticket;
    }
}