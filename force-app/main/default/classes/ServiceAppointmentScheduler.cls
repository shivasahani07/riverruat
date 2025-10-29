global class ServiceAppointmentScheduler implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date targetDate = System.today().addDays(20);
        System.debug('targetDate: ' + targetDate);
        list<AssetMilestone> listmilestone = [SELECT Id, Name, MilestoneDate, Stage, AssetId, VehicleId,Vehicle.Dealer__c, Vehicle.CurrentOwnerId FROM AssetMilestone WHERE MilestoneDate != NULL  AND MilestoneDate > TODAY AND MilestoneDate <= :targetDate AND Stage = 'Tentative'];
        System.debug('listmilestone: ' + listmilestone);
        return Database.getQueryLocator([
            SELECT Id, Name, MilestoneDate, Stage, AssetId, VehicleId,Vehicle.Dealer__c, Vehicle.CurrentOwnerId FROM AssetMilestone WHERE MilestoneDate != NULL  AND MilestoneDate > TODAY AND MilestoneDate <= :targetDate AND Stage = 'Tentative']);
    }
    
    global void execute(Database.BatchableContext bc, List<AssetMilestone> scope) {
        try {
            system.debug('scope: ' + scope);
            List<ServiceAppointment> appointmentsToInsert = new List<ServiceAppointment>();
            Map<Id, AssetMilestone> milestoneToAppointmentMap = new Map<Id, AssetMilestone>();
            Set<Id> vehicleIds = new Set<Id>();

             
            for (AssetMilestone milestone : scope) {
                vehicleIds.add(milestone.VehicleId);
                ServiceAppointment sa = new ServiceAppointment();
                sa.Subject = 'Service Appointment for Milestone: ' + milestone.Name;
                sa.Appointment_Date__c = milestone.MilestoneDate;
                sa.Asset_Milestone__c = milestone.Id;   
                sa.EarliestStartTime = DateTime.newInstance(milestone.MilestoneDate, Time.newInstance(0, 0, 0, 0));
                sa.DueDate = milestone.MilestoneDate;
                sa.Description = 'Auto-created Service Appointment for milestone ' + milestone.Name;
                sa.Vehicle__c = milestone.VehicleId;
                sa.Call_Status__c = 'Pending';
                sa.Service_Centre__c = milestone.Vehicle.Dealer__c;
                sa.ParentRecordId = milestone.Vehicle.CurrentOwnerId;  
                appointmentsToInsert.add(sa);
                milestoneToAppointmentMap.put(milestone.Id, milestone);
            }

            if (!appointmentsToInsert.isEmpty()) {
                insert appointmentsToInsert;
                system.debug('Service Appointments Inserted: ' + appointmentsToInsert);

                Set<Id> vehicleIdSet = new Set<Id>();
                Set<Id> SAids = new Set<Id>();
                for(ServiceAppointment saRec : appointmentsToInsert){
                    vehicleIdSet.add(saRec.Vehicle__c);
                    SAids.add(saRec.Id);
                }

                List<Task> tasksToInsert = new List<Task>();

                if(!vehicleIdSet.isEmpty()) {
                    
                    List<Vehicle> vehicleList = [
                        SELECT Id, Account__c, CurrentOwner.Phone, Dealer__c
                        FROM Vehicle
                        WHERE CurrentOwner.Type = 'Customer'
                        AND Id IN :vehicleIdSet
                    ];
                    
                    Map<Id, Vehicle> mapVehicleById = new Map<Id, Vehicle>(vehicleList);
                    Set<Id> accIds = new Set<Id>();
                    for(Vehicle v : vehicleList) {
                        accIds.add(v.Dealer__c);
                    }

                    
                    List<Contact> contactList = [SELECT Id, AccountId FROM Contact WHERE Designation__c = 'CRE'AND AccountId IN :accIds];

                    Set<Id> conIds = new Set<Id>();
                    for(Contact conRec : contactList){
                        conIds.add(conRec.Id);
                    }

                    
                    List<User> userList = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE ContactId IN :conIds];

                    Map<Id, User> mapAccountOnUser = new Map<Id, User>();
                    for(User u : userList) {
                        mapAccountOnUser.put(u.Contact.AccountId, u);
                    }

                     
                    Map<Id, WorkOrder> recentWorkOrderByVehicle = new Map<Id, WorkOrder>();
                    List<WorkOrder> workOrders = [SELECT Id, Vehicle__c, Asset_Milestone__c, OwnerId, CreatedDate FROM WorkOrder WHERE Vehicle__c IN :vehicleIdSet AND Asset_Milestone__c != NULL ORDER BY CreatedDate DESC LIMIT 10000];

                    for (WorkOrder wo : workOrders) {
                        
                        if (!recentWorkOrderByVehicle.containsKey(wo.Vehicle__c)) {
                            recentWorkOrderByVehicle.put(wo.Vehicle__c, wo);
                        }
                    }

                     
                    List<ServiceAppointment> saList = [
                        SELECT Id, AppointmentNumber, Service_Centre__c, Appointment_Date__c,
                               Vehicle__c, ParentRecordId,
                               Vehicle__r.CurrentOwnerId, Vehicle__r.CurrentOwner.Phone, 
                               Vehicle__r.CurrentOwner.Email__c
                        FROM ServiceAppointment
                        WHERE Id IN :SAids
                    ];

                    for (ServiceAppointment sa : saList) {
                        Task t = new Task();
                        RecordType recid = [ SELECT Id FROM RecordType WHERE SobjectType = 'Task' AND DeveloperName = 'Task_Reminder' LIMIT 1];

                        t.Subject = sa.AppointmentNumber + '- Call_N10';
                        t.WhatId = sa.Id;   
                        t.ActivityDate = sa.Appointment_Date__c.addDays(-10);
                        t.Customer__c = sa.Vehicle__r.CurrentOwnerId;
                        t.Phone_number__c = sa.Vehicle__r.CurrentOwner.Phone;
                        t.Customer_Email__c = (sa.Vehicle__r != null && sa.Vehicle__r.CurrentOwner != null && String.isNotBlank(sa.Vehicle__r.CurrentOwner.Email__c)) ? sa.Vehicle__r.CurrentOwner.Email__c : '';
                        t.Appointment_Date__c = sa.Appointment_Date__c;
                        t.RecordTypeId = recid.Id;    
                        t.Vehicle__c = sa.Vehicle__c;    
                        t.Status = 'Not Started';
                        t.Priority = 'High';
 
                        User mappedUser = mapAccountOnUser.get(sa.Service_Centre__c);
                        WorkOrder recentWO = recentWorkOrderByVehicle.get(sa.Vehicle__c);

                        if (recentWO != null && recentWO.Asset_Milestone__c != null) {
                            // If recent WorkOrder exists, use its owner
                            t.OwnerId = recentWO.OwnerId;
                        } else if (mappedUser != null) {
                            // Else fallback to mapped CRE user
                            t.OwnerId = mappedUser.Id;
                        }

                        tasksToInsert.add(t);
                    }

                    if (!tasksToInsert.isEmpty()) {
                        insert tasksToInsert;
                        system.debug('Tasks Inserted: ' + tasksToInsert);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error Message ==> ' + e.getMessage() + ' && Error Line ==> ' + e.getLineNumber());
        }   
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch processing completed for Service Appointments and Tasks.');
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ServiceAppointmentScheduler(), 50);
    }
}