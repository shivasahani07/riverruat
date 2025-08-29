trigger TriggerOnTicket on Ticket__c (after update, before insert, before update, before delete) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        TriggerOnTicketHelper.afterTicketUpdate(trigger.new);
        
        TriggerOnTicketHelper.updateOwnerOnPending(trigger.new, trigger.oldMap);
    }
    
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && (trigger.IsUpdate)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    if(trigger.IsBefore && (trigger.IsInsert)){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.new);
    }
    //Added By Ram 24/06/2025
    if(trigger.IsBefore && trigger.IsDelete){
        JobCardRecordLock.PreventUpdateForJobCardStatus(trigger.old);
    }
}