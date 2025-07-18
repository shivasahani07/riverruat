trigger Task_Trigger on Task (after insert) {
if (Trigger.isAfter && Trigger.isInsert) {
        TaskHandler.handleAfterInsert(Trigger.new);
    }
}