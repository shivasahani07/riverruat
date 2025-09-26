global class ServiceAppointmentScheduler implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date targetDate = System.today().addDays(20);
        System.debug('targetDate: ' + targetDate);
        
        return Database.getQueryLocator([
            SELECT Id, Name, MilestoneDate, Stage, AssetId, VehicleId,Vehicle.Dealer__c, Vehicle.CurrentOwnerId FROM AssetMilestone WHERE MilestoneDate != NULL AND MilestoneDate > TODAY  AND MilestoneDate <= :targetDate AND Stage = 'Tentative'  
        ]);
        
    }
    global void execute(Database.BatchableContext bc, List<AssetMilestone> scope) {
        
        try{
            system.debug('scope'+scope);
            List<ServiceAppointment> appointmentsToInsert = new List<ServiceAppointment>();
            Map<Id, AssetMilestone> milestoneToAppointmentMap = new Map<Id, AssetMilestone>();
            
            for (AssetMilestone milestone : scope) {
                system.debug('insideLOOP');
                ServiceAppointment sa = new ServiceAppointment();
                sa.Subject = 'Service Appointment for Milestone: ' + milestone.Name;
                sa.Appointment_Date__c = milestone.MilestoneDate;
                sa.Asset_Milestone__c = milestone.id;   
                sa.EarliestStartTime = DateTime.newInstance(milestone.MilestoneDate, Time.newInstance(0, 0, 0, 0));
                sa.DueDate = milestone.MilestoneDate;
                sa.Description = 'Auto-created Service Appointment for milestone ' + milestone.Name;
                sa.Vehicle__c = milestone.VehicleId;
                sa.Call_Status__c  = 'Pending';
                sa.Service_Centre__c = milestone.Vehicle.Dealer__c;
                sa.ParentRecordId = milestone.Vehicle.CurrentOwnerId;  
                appointmentsToInsert.add(sa);
                milestoneToAppointmentMap.put(milestone.Id, milestone);
            }
            if (!appointmentsToInsert.isEmpty()) {
                insert appointmentsToInsert;
                system.debug('SA Is Inseterted==='+appointmentsToInsert);
                
                set<Id> vehiclId = new Set<Id>();
                Set<Id> SAids = new Set<Id>();
                for(ServiceAppointment SARec : appointmentsToInsert){
                    vehiclId.add(SARec.Vehicle__c);
                    SAids.add(SARec.Id);
                }
                system.debug('vehiclId==='+vehiclId);
                List<Task> tasksToInsert = new List<Task>();
                IF(vehiclId != NULL){
                    List<Vehicle> vehicleList = [select id,Account__c,CurrentOwner.Phone,Dealer__c from Vehicle where CurrentOwner.Type = 'Customer' AND ID IN:vehiclId];
                    system.debug('vehicleList==='+vehicleList);
                    
                    
                    Map<Id,Vehicle> mapAccountOnVehicelId = new Map<Id,Vehicle>();
                    Set<Id> accIds = new Set<ID>();
                    
                    For(Vehicle vehiclRec :vehicleList){
                        accIds.add(vehiclRec.Dealer__c);
                        mapAccountOnVehicelId.put(vehiclRec.id,vehiclRec);
                    }
                    system.debug('accIds==='+accIds);
                    List<Contact> contactList = [Select id From Contact Where Designation__c = 'CRE' AND AccountID IN:accIds];
                    system.debug('contactList==='+contactList);
                    Set<Id> conIds = new Set<Id>();
                    
                    For(Contact conRec :contactList ){
                        conIds.add(conRec.Id);
                    }                             
                    List<User> userList = [select  id,ContactId,Contact.AccountId from user where ContactId IN:conIds];
                    system.debug('userList==='+userList);
                    Map<Id,User> mapAccountOnUser = new Map<Id,User>();
                    
                    for(User userRec : userList){
                        mapAccountOnUser.put(userRec.Contact.AccountId,userRec);
                    }
                    if(SAids != null){
                        List<ServiceAppointment> serviceAppointmentList = [Select id,AppointmentNumber,Service_Centre__c,Appointment_Date__c,Vehicle__c,ParentRecordId,Vehicle__r.CurrentOwnerId,Vehicle__r.CurrentOwner.Phone,Vehicle__r.CurrentOwner.Email__c from ServiceAppointment where ID IN:SAids];
                        system.debug('serviceAppointmentList===='+serviceAppointmentList);
                        string custome = serviceAppointmentList[0].Vehicle__r.CurrentOwnerId;
                        system.debug('custome===='+custome);
                        string customerPhone = serviceAppointmentList[0].Vehicle__r.CurrentOwner.Phone;
                        string customerEmail = serviceAppointmentList[0].Vehicle__r.CurrentOwner.Email__c;
                        system.debug('customerPhone===='+customerPhone);
                        If(!serviceAppointmentList.IsEmpty()){
                            for (ServiceAppointment sa : serviceAppointmentList) {
                                Task t = new Task();
                                RecordType recid =[Select id from RecordType where SobjectType ='Task' AND DeveloperName = 'Task_Reminder'];
                                t.Subject =   sa.AppointmentNumber +  '- Call_N10';
                                t.WhatId = sa.Id;   
                                t.ActivityDate = sa.Appointment_Date__c.addDays(-10);
                                t.Customer__c       = sa.Vehicle__r.CurrentOwnerId;
                                t.Phone_number__c   = sa.Vehicle__r.CurrentOwner.Phone;
                                t.Customer_Email__c = sa.Vehicle__r.CurrentOwner.Email__c;
                                t.Appointment_Date__c = sa.Appointment_Date__c;
                                t.RecordTypeId = recid.Id;    
                                t.Vehicle__c = sa.Vehicle__c;    
                                if (sa.ParentRecordId != null) {
                                    User mappedUser = mapAccountOnUser.get(sa.Service_Centre__c);
                                    if (mappedUser != null) {
                                        t.OwnerId = mappedUser.Id;
                                    }
                                }
                                t.Status = 'Not Started';
                                t.Priority = 'High';
                                tasksToInsert.add(t);
                                
                            } 
                        }
                        
                        if (!tasksToInsert.isEmpty()) {
                            insert tasksToInsert;
                            system.debug('Task Is Inseterted==='+tasksToInsert);
                        }
                    }
                    
                }
            }
        }catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
        }   
        
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch processing completed for Service Appointments and Tasks.');
    }
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ServiceAppointmentScheduler(), 50);
    }
}