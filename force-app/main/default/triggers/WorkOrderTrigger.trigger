trigger WorkOrderTrigger on WorkOrder (before insert, before update, after update, after Insert) {
    
    if(trigger.isBefore && trigger.isUpdate){
        for(WorkOrder wo : trigger.new){
            if(wo.Status == 'Completed' && trigger.oldMap.get(wo.Id).Invoice_Date__c == null){
                wo.Invoice_Date__c = Datetime.now();
            }
        }
    }
    
    
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
         WorkOrderTriggerHandler.validateWorkOrders(trigger.new, trigger.oldmap);
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