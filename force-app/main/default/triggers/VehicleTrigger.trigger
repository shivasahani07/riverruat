trigger VehicleTrigger on Vehicle (before update) {
    if (Trigger.IsBefore && Trigger.isUpdate) {
        VehicleTriggerHandler.validatePDIPass(Trigger.new, Trigger.oldMap);
    }
}