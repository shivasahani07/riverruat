trigger WorkOrderTrigger on WorkOrder (before insert, before update, after update, after Insert) {
    
    if(trigger.isBefore && trigger.isUpdate){
        for(WorkOrder wo : trigger.new){
            if(wo.Status == 'Completed' && trigger.oldMap.get(wo.Id).Invoice_Date__c == null){
                wo.Invoice_Date__c = Datetime.now();
            }
        }
    }
    
    
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        try{Set<Id> vehicleSet = new Set<Id>();
            Map<Id, Set<Id>> mapVehicleIdToWoIds = new Map<Id, Set<Id>>();
            Set<Id> newVehicleSet = new Set<Id>();
            
            for (WorkOrder wo : Trigger.new) {
                if (wo.Vehicle__c != null) {
                    vehicleSet.add(wo.Vehicle__c);
                }
            }
            
            // Query existing work orders for duplicate check (excluding completed/canceled)
            List<WorkOrder> existingWorkOrders = [
                SELECT Id, Vehicle__c, Vehicle_Identification_number__c, Vehicle_registration_number__c 
                FROM WorkOrder 
                WHERE Vehicle__c IN :vehicleSet 
                AND Status NOT IN ('Completed', 'Canceled')
            ];
            
            for (WorkOrder wo : existingWorkOrders) {
                if (!mapVehicleIdToWoIds.containsKey(wo.Vehicle__c)) {
                    mapVehicleIdToWoIds.put(wo.Vehicle__c, new Set<Id>());
                }
                mapVehicleIdToWoIds.get(wo.Vehicle__c).add(wo.Id);
            }
            
            // Fetch last odometer reading per vehicle from any previous job card (any status)
            Map<Id, Decimal> mapVehicleIdToMaxOdometer = new Map<Id, Decimal>();
            List<AggregateResult> lastOdometerReadings = [
                SELECT Vehicle__c vehicleId, MAX(Odometer_Reading__c) maxOdo
                FROM WorkOrder
                WHERE Vehicle__c IN :vehicleSet
                AND Id NOT IN :Trigger.newMap.keySet()
                GROUP BY Vehicle__c
            ];
            
            for (AggregateResult ar : lastOdometerReadings) {
                mapVehicleIdToMaxOdometer.put((Id)ar.get('vehicleId'), (Decimal)ar.get('maxOdo'));
            }
            
            for (WorkOrder wo : Trigger.new) {
                // Duplicate VIN/VRN validation
                if (Trigger.isInsert) {
                    if ((mapVehicleIdToWoIds.containsKey(wo.Vehicle__c) && mapVehicleIdToWoIds.get(wo.Vehicle__c).size() > 0) ||
                        newVehicleSet.contains(wo.Vehicle__c)) {
                            wo.Vehicle__c.addError('A job card already exists for this vehicle with the same VIN or VRN.');
                        }
                    newVehicleSet.add(wo.Vehicle__c);
                } else {
                    if (mapVehicleIdToWoIds.containsKey(wo.Vehicle__c) && 
                        mapVehicleIdToWoIds.get(wo.Vehicle__c).size() > 0 &&
                        Trigger.oldMap.get(wo.Id).Vehicle__c != wo.Vehicle__c) {
                            
                            if (!(mapVehicleIdToWoIds.get(wo.Vehicle__c).size() == 1 &&
                                  mapVehicleIdToWoIds.get(wo.Vehicle__c).contains(wo.Id))) {
                                      wo.Vehicle__c.addError('A job card already exists for this vehicle with the same VIN or VRN.');
                                  }
                        }
                    
                    if (!mapVehicleIdToWoIds.containsKey(wo.Vehicle__c)) {
                        mapVehicleIdToWoIds.put(wo.Vehicle__c, new Set<Id>());
                    }
                    mapVehicleIdToWoIds.get(wo.Vehicle__c).add(wo.Id);
                }
                
                // Odometer reading validation
                if (wo.Odometer_Reading__c != null && mapVehicleIdToMaxOdometer.containsKey(wo.Vehicle__c)) {
                    Decimal previousOdo = mapVehicleIdToMaxOdometer.get(wo.Vehicle__c);
                    if (wo.Odometer_Reading__c <= previousOdo) {
                        wo.Odometer_Reading__c.addError('Odometer reading must be greater than the previous recorded value: ' + previousOdo);
                    }
                }
            }
           }
        Catch(exception e){
            system.debug('Error Message======>'+e.getMessage()+ ' at Line Number =======>'+ e.getlineNumber());
            
        }
    }
    
    
    
    if (trigger.isafter &&  trigger.isUpdate) {
        
        Set<String> vehicleSet = new Set<String>();
        list<Vehicle>vehicleList= new list<Vehicle>();
        
        for (WorkOrder wo : Trigger.new) {
            if (WO.Vehicle__c != null && WO.Odometer_Reading__c != null && WO.status=='Completed' && WO.status != trigger.oldMap.get(WO.Id).status) {
                
                If(!vehicleSet.contains(WO.Vehicle__c)){
                    
                    Vehicle vehicle = new Vehicle();
                    vehicle.Id = WO.Vehicle__c;
                    vehicle.LastOdometerReading = WO.Odometer_Reading__c;
                    vehicle.OdometerReadingDate = system.Today();
                    
                    vehicleList.add(vehicle);
                    vehicleSet.add(WO.Vehicle__c);
                }
            }
        }
        
        if(!vehicleList.isEmpty())
        {
            Database.update(vehicleList,false);
        }  
        
    }
    //code Added by Aniket on 14/02/2025
    if(Trigger.isAfter && Trigger.isUpdate){
        // WorkOrderTriggerHandler.updatePDIAfterCompetetion(Trigger.new,Trigger.oldMap); 
        WorkOrderTriggerHandler.createSkippedActionPlan(Trigger.new, Trigger.oldMap);
        //code Added by Sagar on 14/04/2025
        // WorkOrderTriggerHandler.handleJobCardCompletion(Trigger.new,Trigger.oldMap);
    }
    
    //code Added by Sagar on 07/04/2025
    if (trigger.isAfter && trigger.isInsert) {
        // WorkOrderTriggerHandler.handleNewJobCards(trigger.new);
    }
    
}