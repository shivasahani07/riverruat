public class TriggerOnTicketHelper {
    public static void afterTicketUpdate(List<Ticket__c> newTickets) {
        List<Ticket__c> ticketsToUpdate = new List<Ticket__c>();

        for (Ticket__c tikt : newTickets) {
            if (tikt.Resolution__c != null && tikt.Resolution__c != tikt.Resolution_History__c) {
                Ticket__c t = new Ticket__c(
                    Id = tikt.Id,
                    Resolution_History__c = tikt.Resolution__c
                );
                ticketsToUpdate.add(t);
            }
        }

        if (!ticketsToUpdate.isEmpty()) {
            update ticketsToUpdate;
        }
    }

    // Method to update the Ticket Owner as WM when the Status is updated to "Pending"
    public static void updateOwnerOnPending(List<Ticket__c> newList, Map<Id, Ticket__c> oldMap) {
        List<Ticket__c> toUpdate = new List<Ticket__c>();
        Set<Id> jobCardIds = new Set<Id>();

        for (Ticket__c t : newList) {
            if (t.Status__c == 'Pending' && oldMap.get(t.Id).Status__c != 'Pending') {
                if (t.Job_Card__c != null) jobCardIds.add(t.Job_Card__c);
            }
        }

        Map<Id, WorkOrder> jobCards = new Map<Id, WorkOrder>([
            SELECT Id, Service_Center__c FROM WorkOrder WHERE Id IN :jobCardIds
        ]);

        Map<Id, Id> serviceCenterToWmUserId = new Map<Id, Id>();

        // Step 1: Get all Service Centers
        Set<Id> serviceCenterIds = new Set<Id>();
        for (WorkOrder jc : jobCards.values()) {
            if (jc.Service_Center__c != null)
                serviceCenterIds.add(jc.Service_Center__c);
        }

        // Step 2: Get WM Contacts for Service Centers
        Map<Id, Contact> serviceCenterToWMContact = new Map<Id, Contact>();
        for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :serviceCenterIds AND Designation__c = 'WM']) {
            serviceCenterToWMContact.put(c.AccountId, c);
        }

        // Step 3: Get Users related to WM Contacts
        Map<Id, Id> contactToUserId = new Map<Id, Id>();

        // Extract Contact IDs from the WM Contact map
        Set<Id> wmContactIds = new Set<Id>();
        for (Contact c : serviceCenterToWMContact.values()) {
            wmContactIds.add(c.Id);
        }

        // Query Users whose ContactId is in this set
        for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :wmContactIds AND IsActive = true]) {
            contactToUserId.put(u.ContactId, u.Id);
        }

        for (Ticket__c t : newList) {
            if (t.Status__c == 'Pending' && oldMap.get(t.Id).Status__c != 'Pending') {
                Id newOwnerId;
                Id jcId = t.Job_Card__c;
                if (jobCards.containsKey(jcId)) {
                    Id scId = jobCards.get(jcId).Service_Center__c;
                    if (scId != null && serviceCenterToWMContact.containsKey(scId)) {
                        Contact wm = serviceCenterToWMContact.get(scId);
                        if (contactToUserId.containsKey(wm.Id)) {
                            newOwnerId = contactToUserId.get(wm.Id);
                        }
                    }
                }

                if (newOwnerId == null) {
                    newOwnerId = UserInfo.getUserId();
                }

                Ticket__c updatedTicket = new Ticket__c(Id = t.Id);
                updatedTicket.OwnerId = newOwnerId;
                toUpdate.add(updatedTicket);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}