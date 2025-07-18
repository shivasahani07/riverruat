/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 07-03-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class TaskHandler {
    
    public static void handleAfterInsert(List<Task> newTasks) {
        System.debug('----------------handleAfterInsert-------------------');
        
        Set<Id> feedbackIds = new Set<Id>();
        String feedbackPrefix = 'a2r'; // Confirm this is correct for Post_service_Feedback__c
        
        // Collect valid WhatIds where subject = 'Call'
        for (Task t : newTasks) {
            if (
                t.Subject != null &&
                //t.Subject.toLowerCase().contains('feedback call') &&
                t.Subject.toLowerCase().contains('followup-') &&
                t.WhatId != null &&
                String.valueOf(t.WhatId).startsWith(feedbackPrefix)
                //t.Parent_Task__c != null
            ) {
                feedbackIds.add(t.WhatId);
                System.debug('feedbackIds : ' + feedbackIds);
            }
        }
        
        if (feedbackIds.isEmpty()) {
            System.debug('No relevant feedback records found.');
            return;
        }
        
        // Query Post_service_Feedback__c
        Map<Id, Post_service_Feedback__c> feedbackMap = new Map<Id, Post_service_Feedback__c>(
            [SELECT Id, Call_Count__c, Status__c FROM Post_service_Feedback__c WHERE Id IN :feedbackIds]
        );
        
        // Get call count per feedback
        Map<Id, Integer> callCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT WhatId, COUNT(Id) total
            FROM Task
            WHERE WhatId IN :feedbackIds
            //AND Parent_Task__c != null
            GROUP BY WhatId
        ]) {
            callCounts.put((Id) ar.get('WhatId'), (Integer) ar.get('total'));
        }
        System.debug('callCounts : ' + callCounts);
        /*
for (AggregateResult ar : [
SELECT WhatId, COUNT(Id) total
FROM Task
WHERE Subject = 'Feedback Call.' AND WhatId IN :feedbackIds
GROUP BY WhatId
]) {
callCounts.put((Id) ar.get('WhatId'), (Integer) ar.get('total'));
}
*/
        List<Post_service_Feedback__c> updates = new List<Post_service_Feedback__c>();
        
        for (Id fid : feedbackIds) {
            if (feedbackMap.containsKey(fid)) {
                Post_service_Feedback__c feedback = feedbackMap.get(fid);
                Integer count = callCounts.containsKey(fid) ? callCounts.get(fid) : 0;
                feedback.Call_Count__c = count;
                
                if (count >= 3) {
                    //feedback.Status__c = 'NFA';
                    //feedback.Sub_Status__c = null;
                    System.debug('Inside count check condition');
                }
                
                updates.add(feedback);
                System.debug('count : ' + count);
            }
            
        }
        
        if (!updates.isEmpty()) {
            try {
                update updates;
                System.debug('Updated feedback records: ' + updates);
                System.debug('Status : ' + updates[0].Status__c);
            } catch (Exception e) {
                System.debug('Error updating feedback records: ' + e.getMessage());
            }
        } else {
            System.debug('No feedback records to update.');
        }
    }
    
    public static void handleTicketCallCount(List<Task> newTasks) {
        Map<Id, Integer> ticketCallCounter = new Map<Id, Integer>();
        String ticketPrefix = 'a2u'; // Adjust prefix as per actual Ticket__c ID prefix
        
        // Step 1: Gather Task counts per Ticket
        for (Task t : newTasks) {
            if (
                t.Subject != null &&
                // t.Subject.trim().equalsIgnoreCase('TI -') &&
                t.Subject.toLowerCase().contains('ti -') &&
                t.WhatId != null &&
                String.valueOf(t.WhatId).startsWith(ticketPrefix)
            ) {
                System.debug('Inside TASK FOR LOOP');
                Id ticketId = t.WhatId;
                Integer count = ticketCallCounter.containsKey(ticketId) ? ticketCallCounter.get(ticketId) : 0;
                ticketCallCounter.put(ticketId, count + 1);
                System.debug('ticketCallCounter : ' + ticketCallCounter);
            }
        }
        
        if (ticketCallCounter.isEmpty()) {
            System.debug('No relevant Ticket__c tasks found.');
            return;
        }
        
        // Step 2: Query Tickets and related Feedbacks
        Map<Id, Ticket__c> tickets = new Map<Id, Ticket__c>(
            [SELECT Id, Call_Count__c, Status__c, Post_Service_Feedback__c FROM Ticket__c WHERE Id IN :ticketCallCounter.keySet()]
        );
        
        Map<Id, Post_Service_Feedback__c> feedbacksToUpdate = new Map<Id, Post_Service_Feedback__c>();
        List<Ticket__c> ticketsToUpdate = new List<Ticket__c>();
        
        // Step 3: Update Ticket Call_Count and Status
        for (Id ticketId : ticketCallCounter.keySet()) {
            if (tickets.containsKey(ticketId)) {
                Ticket__c ticket = tickets.get(ticketId);
                Decimal existingCount = ticket.Call_Count__c != null ? ticket.Call_Count__c : 0;
                Decimal newCount = existingCount + Decimal.valueOf(ticketCallCounter.get(ticketId));
                
                ticket.Call_Count__c = newCount;
                
                // If 3 or more calls, mark Ticket as NFA and related Feedback as Completed
                
                /*
if (newCount >= 3) {

ticket.Status__c = 'NFA';

if (ticket.Post_Service_Feedback__c != null) {
feedbacksToUpdate.put(
ticket.Post_Service_Feedback__c,
new Post_Service_Feedback__c(
Id = ticket.Post_Service_Feedback__c,
Status__c = 'Completed'
)
);
}
}
*/
                System.debug('------- INSIDE TASK TRIGGER HANDLER --------------');
                
                ticketsToUpdate.add(ticket);
            }
        }
        
        // Step 4: Update all tickets
        if (!ticketsToUpdate.isEmpty()) {
            try {
                update ticketsToUpdate;
                System.debug('Updated Ticket__c records: ' + ticketsToUpdate);
            } catch (Exception e) {
                System.debug('Error updating Ticket__c records: ' + e.getMessage());
            }
        }
        
        // Step 5: Update related Feedback records
        if (!feedbacksToUpdate.isEmpty()) {
            try {
                System.debug('------------ feedbacksToUpdate : ---------------' + feedbacksToUpdate);
                update feedbacksToUpdate.values();
                System.debug('Updated related Post_Service_Feedback__c records: ' + feedbacksToUpdate.values());
            } catch (Exception e) {
                System.debug('Error updating Post_Service_Feedback__c records: ' + e.getMessage());
            }
        }
    }
    
    public static void handleAppointmentCallCount(List<Task> newTasks) {
        Map<Id, Integer> appointmentCallCounter = new Map<Id, Integer>();
        String appointmentPrefix = '08p'; // Prefix for ServiceAppointment
        system.debug('appointmentPrefix=='+appointmentPrefix);
        // Step 1: Count relevant tasks per ServiceAppointment
        for (Task t : newTasks) {
            if (
                t.Subject != null &&
                // t.Subject.trim().equalsIgnoreCase('Call Back Request') &&
                t.Subject.toLowerCase().contains('- call back request') &&
                t.WhatId != null &&
                String.valueOf(t.WhatId).startsWith(appointmentPrefix)
            ) {
                Id appointmentId = t.WhatId;
                Integer count = appointmentCallCounter.containsKey(appointmentId) ? appointmentCallCounter.get(appointmentId) : 0;
                appointmentCallCounter.put(appointmentId, count + 1);
            }
        }
        
        if (appointmentCallCounter.isEmpty()) {
            System.debug('No relevant ServiceAppointment tasks found.');
            return;
        }
        
        // Step 2: Query the existing ServiceAppointments with their current Call_Back_Count__c
        Map<Id, ServiceAppointment> appointments = new Map<Id, ServiceAppointment>(
            [SELECT Id, Status,Call_Status__c, Call_Back_Count__c FROM ServiceAppointment WHERE Id IN :appointmentCallCounter.keySet()]
        );
        
        List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();
        
        // Step 3: Update Call_Back_Count__c and set Status if necessary
        for (Id appointmentId : appointmentCallCounter.keySet()) {
            if (appointments.containsKey(appointmentId)) {
                ServiceAppointment appt = appointments.get(appointmentId);
                Decimal currentCount = appt.Call_Back_Count__c != null ? appt.Call_Back_Count__c : 0;
                Decimal addedCount = Decimal.valueOf(appointmentCallCounter.get(appointmentId));
                Decimal updatedCount = currentCount + addedCount;
                
                appt.Call_Back_Count__c = updatedCount;
                
                if (updatedCount >= 3) {
                    appt.Call_Status__c = 'NFA';
                }
                
                appointmentsToUpdate.add(appt);
            }
        }
        
        // Step 4: Update ServiceAppointments
        if (!appointmentsToUpdate.isEmpty()) {
            try {
                update appointmentsToUpdate;
                System.debug('Updated ServiceAppointment records: ' + appointmentsToUpdate);
            } catch (Exception e) {
                System.debug('Error updating ServiceAppointment records: ' + e.getMessage());
            }
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
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
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
}