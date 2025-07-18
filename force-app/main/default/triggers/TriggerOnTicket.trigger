trigger TriggerOnTicket on Ticket__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        TriggerOnTicketHelper.afterTicketUpdate(trigger.new);
        
        TriggerOnTicketHelper.updateOwnerOnPending(trigger.new, trigger.oldMap);
    }
}