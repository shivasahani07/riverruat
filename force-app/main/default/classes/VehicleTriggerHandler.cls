public class VehicleTriggerHandler {
   public static void validatePDIPass(List<Vehicle> newVehicles, Map<Id, Vehicle> oldVehicleMap) {
    System.debug('=== validatePDIPass method started ===');

    Set<Id> vehicleIdsToCheck = new Set<Id>();

    for (Vehicle veh : newVehicles) {
        if (veh.PDI_Status_Pass__c == true && oldVehicleMap.get(veh.Id).PDI_Status_Pass__c == false) {
            vehicleIdsToCheck.add(veh.Id);
        }
    }

    System.debug('Vehicle IDs to check for PDI Pass validation: ' + vehicleIdsToCheck);

    if (vehicleIdsToCheck.isEmpty()) {
        System.debug('No vehicles require PDI Pass validation. Exiting method.');
        return;
    }

    Map<Id, String> recordTypeMap = new Map<Id, String>();
    for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'WorkOrder']) {
        recordTypeMap.put(rt.Id, rt.DeveloperName);
    }

    System.debug('Retrieved WorkOrder Record Type Map: ' + recordTypeMap);

    Map<Id, List<WorkOrder>> vehicleJobCardsMap = new Map<Id, List<WorkOrder>>();
    for (WorkOrder wo : [
        SELECT Id, Vehicle__c, Status, RecordTypeId 
        FROM WorkOrder 
        WHERE Vehicle__c IN :vehicleIdsToCheck
    ]) {
        String recordTypeName = recordTypeMap.get(wo.RecordTypeId);
        if (recordTypeName == 'Vehicle_PDI') {
            if (!vehicleJobCardsMap.containsKey(wo.Vehicle__c)) {
                vehicleJobCardsMap.put(wo.Vehicle__c, new List<WorkOrder>());
            }
            vehicleJobCardsMap.get(wo.Vehicle__c).add(wo);
        }
    }

    System.debug('Mapped Job Cards to Vehicles: ' + vehicleJobCardsMap);

    for (Vehicle veh : newVehicles) {
        if (vehicleIdsToCheck.contains(veh.Id)) {
            List<WorkOrder> jobCards = vehicleJobCardsMap.get(veh.Id);
            if (jobCards != null) {
                for (WorkOrder wo : jobCards) {
                    if (wo.Status != 'Completed') {
                        System.debug('Validation failed for Vehicle ID: ' + veh.Id + ', Open Job Card ID: ' + wo.Id);
                        veh.addError('Vehicle cannot be marked as PDI Complete if a related Job Card is open.');
                        break;
                    }
                }
            }
        }
    }

    System.debug('=== validatePDIPass method completed ===');
}

}