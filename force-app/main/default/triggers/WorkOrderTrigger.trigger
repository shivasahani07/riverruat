trigger WorkOrderTrigger on WorkOrder (before insert, before update, after update, after Insert) {
    public static Boolean isFirstRun = true;
    
    if(trigger.isBefore && trigger.isUpdate){
        for(WorkOrder wo : trigger.new){
            if(wo.Status == 'Completed' && trigger.oldMap.get(wo.Id).Invoice_Date__c == null){
                wo.Invoice_Date__c = Datetime.now();
            }
        }
    }
    
     if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        if (!isFirstRun) {
            //return;
        }
        Set<Id> vehicleSet = new Set<Id>();
        Map<Id, Set<Id>> mapVehicleIdToWoIds = new Map<Id, Set<Id>>();
        Set<Id> newVehicleSet = new Set<Id>();
        Map<Id, Decimal> vehicleOdoMap = new Map<Id, Decimal>();
        Map<Id,WorkOrder> oldJCbyId = new Map<Id,WorkOrder>();
        
        // Collect Vehicle IDs from Trigger.new
        for (WorkOrder wo : Trigger.new) {
            if (wo.Vehicle__c != null) {
                vehicleSet.add(wo.Vehicle__c);
            }
        }
         
                 
         if (Trigger.isUpdate) {
             oldJCbyId.putAll(Trigger.oldMap);
         }
        
        if (!vehicleSet.isEmpty()) {
            
            // Query WorkOrders and build Vehicle -> WorkOrder map in one go
            for (WorkOrder wo : [
                SELECT Id, Vehicle__c, Odometer_Reading__c, Status,Vehicle__r.LastOdometerReading
                FROM WorkOrder
                WHERE Vehicle__c IN :vehicleSet]) 
            {
                vehicleOdoMap.put(wo.Vehicle__c, wo.Vehicle__r.LastOdometerReading);
                if (!mapVehicleIdToWoIds.containsKey(wo.Vehicle__c)) {
                    mapVehicleIdToWoIds.put(wo.Vehicle__c, new Set<Id>());
                }
                if (wo.Status != 'Completed' && wo.Status != 'Canceled') {
                    mapVehicleIdToWoIds.get(wo.Vehicle__c).add(wo.Id);
                }
            }
            
            for (WorkOrder wo : Trigger.new) {
                // Odometer validation
                Decimal lastOdo = vehicleOdoMap.get(wo.Vehicle__c);
                WorkOrder oldWo=oldJCbyId.get(wo.id);
                if (lastOdo != null && wo.Odometer_Reading__c != null &&
                    wo.Odometer_Reading__c <= lastOdo && (oldWo == null || oldWo.Status != 'Submit For Approval')) {
                        wo.Odometer_Reading__c.addError(
                            'Odometer reading must be greater than the Vehicle record value: ' + lastOdo
                        );
                    }
                
                // VIN/VRN uniqueness
                if (Trigger.isInsert) {
                    if ((mapVehicleIdToWoIds.containsKey(wo.Vehicle__c) && 
                         !mapVehicleIdToWoIds.get(wo.Vehicle__c).isEmpty()) 
                        || newVehicleSet.contains(wo.Vehicle__c)) {
                            wo.Vehicle__c.addError('A job card already exists for this vehicle with same VIN or VRN.');
                        }
                    newVehicleSet.add(wo.Vehicle__c);
                    
                } else { // Update
                    if (mapVehicleIdToWoIds.containsKey(wo.Vehicle__c) && 
                        !mapVehicleIdToWoIds.get(wo.Vehicle__c).isEmpty() &&
                        Trigger.oldMap.get(wo.Id).Vehicle__c != wo.Vehicle__c) {
                            
                            if (!(mapVehicleIdToWoIds.get(wo.Vehicle__c).size() == 1 && 
                                  mapVehicleIdToWoIds.get(wo.Vehicle__c).contains(wo.Id))) {
                                      wo.Vehicle__c.addError('A job card already exists for this vehicle with same VIN or VRN.');
                                  }
                        }
                    if (wo.Vehicle__c != null && mapVehicleIdToWoIds.containsKey(wo.Vehicle__c)) {
                        mapVehicleIdToWoIds.get(wo.Vehicle__c).add(wo.Id);
                    }
                }
            }
        }
        isFirstRun = false;
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
       // WorkOrderTriggerHandler.onJobcardCompleteUpdateAssetMilestone(Trigger.new, Trigger.oldMap);
        //code Added by Sagar on 14/04/2025
        // WorkOrderTriggerHandler.handleJobCardCompletion(Trigger.new,Trigger.oldMap);
    }
    
    //code Added by Sagar on 07/04/2025
    if (trigger.isAfter && trigger.isInsert) {
        // WorkOrderTriggerHandler.handleNewJobCards(trigger.new);
        // WorkOrderTriggerHandler.onJobcardOpenUdpateAssetMilestone(trigger.new);
    }
    
}