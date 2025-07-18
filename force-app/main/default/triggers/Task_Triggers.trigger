trigger Task_Triggers on Task (after insert, before insert,after Update ) {
	if (Trigger.isAfter && Trigger.isInsert) {
        TaskHandler.handleAfterInsert(Trigger.new);
        TaskHandler.handleTicketCallCount(Trigger.new);
        TaskHandler.handleAppointmentCallCount(Trigger.new);
    }
    
    if(Trigger.isBefore && Trigger.isInsert){
		//TaskHandler.preventTaskIfPSFHas3Calls(Trigger.new);        
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        //TaskHandler.handleWrongNumberStatus(Trigger.new, Trigger.oldMap);
    }
}