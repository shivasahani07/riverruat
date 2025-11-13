public without  sharing class NewAppointementFormController {
    
    public class ServiceCenterWrapper {
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public List<Appointment_Slot_Item__c> asiList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getServiceCenters( ) {
        return [ SELECT Id, Name FROM Account WHERE Type = 'Service Center'  limit 10 ];
    }
    
    @AuraEnabled(cacheable=true)
    public static ServiceCenterWrapper getCurrentServiceCenter(){
        try{
            ServiceCenterWrapper wrapper = new ServiceCenterWrapper();
            
            Id userid = UserInfo.getUserId();
            User userRec = [SELECT Id, Contact.AccountId, Contact.Account.Name FROM User  WHERE Id = :userid LIMIT 1];
            System.debug('userRec : ' + userRec);
            
            Account accRec = [SELECT Id, Name FROM Account WHERE Id = :userRec.Contact.AccountId LIMIT 1];
            //Account accRec = [SELECT Id, Name FROM Account WHERE Id = :userRec.Contact.AccountId LIMIT 1];
            System.debug('accRec : ' + accRec);
            wrapper.accountName = accRec.Name;
            wrapper.accountId = accRec.Id;
            
            return wrapper;
        }
        catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            return null;
        } 
        
    }
       @AuraEnabled(cacheable=true)
    public static List<Vehicle> getVehicleRegByContact(String contactnumber) {
        try {
            if (String.isBlank(contactnumber)) return new List<Vehicle>();

            // Find vehicles where the CurrentOwner phone matches (exact match).
            // You may want to normalize numbers (strip spaces/plus) based on your data.
            List<Vehicle> vehicles = [
                SELECT Id,
                       VehicleRegistrationNumber,
                       VehicleIdentificationNumber,
                       CurrentOwner.Type,
                       CurrentOwner.Phone,
                       
                       CurrentOwnerId
                FROM Vehicle
                WHERE CurrentOwner.Phone = :contactnumber  
                  AND CurrentOwner.Type = 'Customer'
                ORDER BY VehicleRegistrationNumber
            ];

            return vehicles;
        } catch (Exception e) {
            System.debug('getVehicleRegByContact error: ' + e.getMessage());
            return new List<Vehicle>();
        }
    }

    
    @AuraEnabled(cacheable=true)
public static Map<String, Object> getVehicleByVIN(String vin) {
    Map<String, Object> result = new Map<String, Object>();
    try {
        if (String.isBlank(vin)) return result;

        Vehicle v = [
            SELECT Id, VehicleIdentificationNumber, Dealer__r.Name
                   
            FROM Vehicle
            WHERE VehicleIdentificationNumber = :vin
            LIMIT 1
        ];
        AssetMilestone assetRec = [SELECT Id, MilestoneDate,Stage FROM AssetMilestone WHERE  Stage = 'Tentative' AND VehicleId =:v.Id ORDER BY MilestoneDate ASC LIMIT 1];


        result.put('DealerName', v.Dealer__r != null ? v.Dealer__r.Name : '');
        if (assetRec != null) {
            result.put('MilestoneDate', assetRec.MilestoneDate);
            result.put('MilestoneId', assetRec.Id);
        }

        return result;
    } catch (Exception e) {
        System.debug('getVehicleByVIN error: ' + e.getMessage());
        return result;
    }
}

    @AuraEnabled(cacheable=true)
    public static String getVehicleOwnerContacts(String ticketId){
        
        try{
            System.debug(' ----------- getVehicleOwnerContacts -------------');
            System.debug('targetId : ' + ticketId);
            
            // Query Ticket → Job Card → Vehicle → Contacts
            Ticket__c ticket = [SELECT Id, Job_Card__c, Job_Card__r.Vehicle__r.Id, Job_Card__r.Vehicle__r.CurrentOwnerId FROM Ticket__c WHERE Id = :ticketId LIMIT 1];
            System.debug('Ticket : ' + ticket);
            
            Id vehicleId = ticket?.Job_Card__r?.Vehicle__r?.Id;
            if(vehicleId == null){
                return 'No Contact Number Found';
            }
            System.debug('vehicleId : ' + vehicleId);
            
            Id accountId = ticket?.Job_Card__r?.Vehicle__r?.CurrentOwnerId;
            System.debug('accountId : ' + accountId);
            
            List<Contact> contactList = [SELECT Id, Name, Phone, MobilePhone, Email FROM Contact WHERE AccountId = :accountId];
            System.debug('contactList : ' + contactList);
            System.debug('contact Phone Number : ' + contactList[0].Phone != null ? contactList[0].Phone : contactList[0].MobilePhone);
            
            return contactList[0].Phone != null ? contactList[0].Phone : contactList[0].MobilePhone;  
        }
        catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            return null;
        } 
        
    }
    
    @AuraEnabled
    public static Vehicle  getvehicleRecord(String sourceIdStr) {
        try{
            System.debug('---------- getvehicleRecord ---------------');
            System.debug('sourceIdStr : ' + sourceIdStr);
            
            if (String.isBlank(sourceIdStr)) return null;
            
            // ------------------------------------------------------------------
            // 1. Normalise the incoming Id (may be Task, ServiceAppointment, or Ticket)
            // ------------------------------------------------------------------
            Id recordId      = (Id)sourceIdStr;
            String objectApi = recordId.getSObjectType().getDescribe().getName();
            
            // If it’s a Task → follow the WhatId
            if (objectApi == 'Task') {
                Task t = [SELECT WhatId FROM   Task WHERE  Id = :recordId LIMIT  1];
                if (t.WhatId == null) return null;              // Task without WhatId
                recordId   = t.WhatId;
                objectApi  = recordId.getSObjectType().getDescribe().getName();
                System.debug('objectApi : ' + objectApi);
            }
            
            // ------------------------------------------------------------------
            // 2. Derive the Vehicle Id from ServiceAppointment or Ticket__c
            // ------------------------------------------------------------------
            Id vehicleId;
            Date appointmentDate;
           // Id assetMilestoneId;
            
            if (objectApi == 'ServiceAppointment') {
                ServiceAppointment sa = [
                    SELECT Vehicle__c 
                    FROM   ServiceAppointment
                    WHERE  Id = :recordId
                    LIMIT  1
                ];
                vehicleId = sa.Vehicle__c;
               // assetMilestoneId = sa.Asset_Milestone__c;
                System.debug('Inside If : ' + sa);
                
            }else if (objectApi == 'Ticket__c') {
                Ticket__c tk = [
                    SELECT Vehicle__c
                    FROM   Ticket__c
                    WHERE  Id = :recordId
                    LIMIT  1
                ];
                vehicleId = tk.Vehicle__c;
                System.debug('Inside Else If : ' + tk);
            }else if (objectApi == 'Appointment__c') {
                Appointment__c tk = [
                    SELECT id, Service_Appointment__r.Vehicle__c,Appointment_Date__c
                    FROM   Appointment__c
                    WHERE  Id = :recordId
                    LIMIT  1
                ];
                vehicleId = tk.Service_Appointment__r.Vehicle__c;
                
                System.debug('Inside Else If : ' + tk);
            }   
            /*else if (objectApi == 'Appointment__c') {
Appointment__c tk = [
SELECT Service_Appointment__r.Vehicle__c
FROM   Appointment__c
WHERE  Id = :recordId
LIMIT  1
];
vehicleId = tk.Service_Appointment__r.Vehicle__c;
System.debug('Inside Else If : ' + tk);
}*/
            else {
                // Unsupported object – just exit
                System.debug('Inside Else');
                return null;
            }
            
            if (vehicleId == null) return null;
            
            // ------------------------------------------------------------------
            // 3. Return the Vehicle record (only if CurrentOwner.Type = Customer)
            // ------------------------------------------------------------------
            Vehicle  vehicleRec  = [
                SELECT Id,VehicleRegistrationNumber,CurrentOwner.Type,CurrentOwner.Phone from  Vehicle 
                WHERE  Id              = :vehicleId
                AND    CurrentOwner.Type = 'Customer'
                LIMIT  1
            ];
            System.debug('vehicleRec : ' + vehicleRec);
            return vehicleRec ; 
        }
        catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            return null;
        } 
        
    }
    
    
    @AuraEnabled
    public static void createAppointment(Id ticketId, Id accountId, String vrn, Date appointmentDate, String contactNumber) {
        
        try{
            Appointment__c app = new Appointment__c();
            app.Service_Center__c = accountId;
            app.VRN__c = vrn;
            //app.Status__c = 'Open';
            app.Status__c = 'Pending';  // <-- Added new Stage Pending as per PRD
            app.Appointment_Date__c = appointmentDate;
            app.Contact_Number__c = contactNumber;    
            app.Ticket__c = ticketId; // Tag the appointment with the Ticket record
            insert app;
            
            Ticket__c ticketRec = [Select id,Sub_Status__c From Ticket__c where Id =: ticketId];
            ticketRec.Status__c = 'Closed'; // <-- Added
            ticketRec.Sub_Status__c = 'Appointment';
            update ticketRec; 
        }
        catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            
        } 
        
    }
    
    
@AuraEnabled
public static String createAppointmentforServiceAppointment(
    Id   serviceAppId,     // could be SA, Ticket, or Task
    Id   accountId,
    String vrn,
    Date appointmentDate,
    String contactNumber,
    String serviceType,
    Id   slotId,
    Id   slotItemId,
    String appointmentDecription,
    Id milestoneId
) {
    try {
        if (slotId == null || slotItemId == null) {
            throw new AuraHandledException('Required parameters missing.');
        }

        /*--------------------------------------------------------------
        * 1. Resolve TRUE parent Id (SA or Ticket) if provided
        *------------------------------------------------------------*/
        Id parentId;
        String parentType;
        Boolean isServiceAppt = false;
        Boolean isTicket = false;

        if (serviceAppId != null) {
            parentId = serviceAppId;
            parentType = parentId.getSObjectType().getDescribe().getName();

            if (parentType == 'Task') {
                Task t = [SELECT WhatId FROM Task WHERE Id = :parentId LIMIT 1];
                if (t.WhatId == null) {
                    throw new AuraHandledException('Task is not linked to a record.');
                }
                parentId = t.WhatId;
                parentType = parentId.getSObjectType().getDescribe().getName();
            }

            isServiceAppt = (parentType == 'ServiceAppointment');
            isTicket = (parentType == 'Ticket__c');
        }

        // ⭐ If not service appointment or ticket, just continue without linking
        Vehicle vecRec = [Select id From Vehicle where VehicleRegistrationNumber =: vrn];

        Appointment__c newApp = new Appointment__c();
        newApp.Service_Center__c   = accountId;
        newApp.VRN__c              = vrn;
        newApp.Status__c           = 'Open';
        newApp.Appointment_Date__c = appointmentDate;
        newApp.Contact_Number__c   = contactNumber;
        newApp.Mode_of_Reception__c = 'Appointment';
        newApp.Additional_Information__c = appointmentDecription;
        newApp.Type_Of_Requested_Services__c = serviceType;
        newApp.Vehicle__c = vecRec.Id;
        newApp.Asset_Milestone__c = milestoneId;

        if (isServiceAppt) {
            newApp.Service_Appointment__c = parentId;
        } else if (isTicket) {
            newApp.Ticket__c = parentId;
        }
        insert newApp;

        String newAppId = newApp.Id;

        /*--------------------------------------------------------------
        * 2. Update Slot and Slot Item
        *------------------------------------------------------------*/
        Appointment_Slot_Item__c slotItemRec = [
            SELECT Id, Booking_Status__c, Start_Time__c, End_Time__c
            FROM Appointment_Slot_Item__c
            WHERE Id = :slotItemId
            LIMIT 1
        ];
        slotItemRec.Booking_Status__c = 'Booked';
        slotItemRec.Appointment__c = newApp.Id;
        update slotItemRec;

        Appointment__c appointRec = [
            SELECT Id, Appointment_Date__c,Name,Asset_Milestone__r.MilestoneDate
            FROM Appointment__c
            WHERE Id = :newAppId
            LIMIT 1
        ];
        appointRec.Start_Time__c = slotItemRec.Start_Time__c;
        appointRec.End_Time__c   = slotItemRec.End_Time__c;
        update appointRec;

        Date bookedappointmentDate = appointRec.Asset_Milestone__r.MilestoneDate;

        /*--------------------------------------------------------------
        * 3. Handle ServiceAppointment update & email (same as before)
        *------------------------------------------------------------*/
        if (isServiceAppt) {
            ServiceAppointment sa = [
                SELECT Id, Call_Status__c, Account.Email__c, Account.Name,
                       Asset_Milestone__r.MilestoneDate, Service_Centre__r.Name, Asset_Milestone__c
                FROM ServiceAppointment
                WHERE Id = :parentId
                LIMIT 1
            ];
            sa.Call_Status__c = 'Appointment Booked';
            update sa;

            AssetMilestone assetRec = [
                SELECT Id FROM AssetMilestone WHERE Id = :sa.Asset_Milestone__c
            ];
            assetRec.Appointment_Date__c = bookedappointmentDate;
            update assetRec;

            OrgWideEmailAddress owea = [
                SELECT Id, Address, DisplayName FROM OrgWideEmailAddress 
                WHERE DisplayName = 'River Mobility' LIMIT 1
            ];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { sa.Account.Email__c });
            mail.setSubject(sa.Account.Name + ': ' + bookedappointmentDate.format() + 
                            ' Your Service Appointment is Confirmed');
            mail.setPlainTextBody(
                'Hey ' + sa.Account.Name + ',\n\n' +
                'Your service appointment has been successfully booked!\n\n' +
                '📅 Date: ' + bookedappointmentDate.format() +
                '\n🕒 Time: ' + slotItemRec.Start_Time__c + ' - ' + slotItemRec.End_Time__c +
                '\n🏢 Service Center: ' + sa.Service_Centre__r.Name +
                '\n\nThank you for choosing us!'
            );
            mail.setOrgWideEmailAddressId(owea.Id);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }

        /*--------------------------------------------------------------
        * 4. Complete open Tasks (if any)
        *------------------------------------------------------------*/
        if (serviceAppId != null) {
            List<Task> openTasks = [
                SELECT Id, Status, Sub_status__c
                FROM Task
                WHERE WhatId = :parentId
                AND Status != 'Completed'
            ];
            for (Task t : openTasks) {
                t.Status = 'Completed';
                t.Sub_status__c = 'Appointment';
                t.Appointment_Date__c = appointmentDate;
                t.Appointment_Description__c = appointmentDecription;
            }
            if (!openTasks.isEmpty()) update openTasks;
        }

        /*--------------------------------------------------------------
        * 5. ⭐ If serviceAppId was NULL → Create new Task linked to Appointment
        *------------------------------------------------------------*/
        if (serviceAppId == null) {
            Vehicle vehicleRec = [
                SELECT Id, CurrentOwnerId, CurrentOwner.Name
                FROM Vehicle
                WHERE VehicleRegistrationNumber = :vrn
                LIMIT 1
            ];

            Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Task Reminder').getRecordTypeId();
            Appointment__c appointRec1 = [
            SELECT Id, Appointment_Date__c,Name
            FROM Appointment__c
            WHERE Id = :newAppId
            LIMIT 1
        ];
            Task newTask = new Task();
            newTask.WhatId                      = newApp.Id;
            newTask.Subject                     = 'Appointment Reminder - ' + appointRec1.Name;
            newTask.Status                      = 'Not Started';
            newTask.Priority                    = 'High';
            newTask.Vehicle__c                  = vehicleRec.Id;
            newTask.ActivityDate                = appointmentDate.addDays(-1);
            newTask.RecordTypeId                = recordTypeId;
            newTask.Phone_Number__c             = contactNumber;
            newTask.Customer__c                 = vehicleRec.CurrentOwnerId;
            newTask.Call_To_c__c                = vehicleRec.CurrentOwner.Name;
            newTask.Appointment_Date__c         = bookedappointmentDate;
            newTask.Appointment_Description__c  = appointmentDecription;
            insert newTask;
        }

        return newAppId;
    } catch (Exception e) {
        System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
        return null;
    }
}

    
    
    @AuraEnabled(cacheable=true)
    public static List<Appointment_Slot__c> getAvailableSlots(Id appointmentId) {
        
        return [  SELECT Id, Name  FROM Appointment_Slot__c  WHERE Service_Center__c != NULL ORDER BY Name ];
    }
    
    /*@AuraEnabled(cacheable=true)
public static List<Appointment_Slot_Item__c> getSlotItemsBySlotId(Id slotId) {
List<Appointment_Slot_Item__c> AppSlotItemList = [ SELECT Id,Name, Start_Time__c, End_Time__c,Appointment_Slot__c,Booking_Status__c FROM Appointment_Slot_Item__c  WHERE Appointment_Slot__c = :slotId AND  Booking_Status__c != 'Confirmed' ORDER BY Start_Time__c];
System.debug('AppSlotItemList === >'+AppSlotItemList);
return  AppSlotItemList;
}*/
    
    @AuraEnabled
    public static String AllotBookingSlot(String AppointmentId, String AppoSlotId, String AppSItemId) {
        String response;
        try {
            // Fetch Appointment record
            Appointment__c appRec = [SELECT Id, No_Of_Appointment_Slots__c FROM Appointment__c WHERE Id = :AppointmentId LIMIT 1];
            
            // Fetch Appointment Slot Item
            Appointment_Slot_Item__c asiup = [SELECT Id, Booking_Status__c FROM Appointment_Slot_Item__c WHERE Id = :AppSItemId LIMIT 1];
            
            // Update Appointment Slot record
            Appointment_Slot__c oppSlot = new Appointment_Slot__c(Id = AppoSlotId, Appointment__c = AppointmentId);
            
            // Increment slot count
            if (appRec.No_Of_Appointment_Slots__c == null) {
                appRec.No_Of_Appointment_Slots__c = 0;
            }
            appRec.No_Of_Appointment_Slots__c += 1;
            
            // Confirm booking
            asiup.Booking_Status__c = 'Booked';
            
            // Query all Tasks related to this Appointment
            /*List<Task> tasksToComplete = [
                SELECT Id, Status 
                FROM Task 
                WHERE WhatId = :AppointmentId 
                AND Status != 'Completed'
            ];
            
            // Set all task statuses to "Completed"
            for (Task t : tasksToComplete) {
                t.Status = 'Completed';
            }
            
            // Perform all updates
            update new List<SObject>{ appRec, oppSlot, asiup };
                if (!tasksToComplete.isEmpty()) {
                    update tasksToComplete;
                }*/
            
            response = 'success';
        } catch (Exception e) {
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            response = e.getMessage();
        }
        return response;
    }
    
    
    @AuraEnabled
    public static SlotResponse getSlotItems(Id serviceCenterId, Date appointmentDate) {
        
        // Fetch ALL slots for given date / center
        try{
            List<Appointment_Slot__c> slots = [
                SELECT Id
                FROM   Appointment_Slot__c
                WHERE  Service_Center__c       = :serviceCenterId
                AND    Appointment_Slot_Date__c = :appointmentDate
            ];
            
            if (!slots.isEmpty()) {
                List<Id> slotIds = new List<Id>();
                for (Appointment_Slot__c slotRec : slots) {
                    slotIds.add(slotRec.Id);
                }
                
                List<Appointment_Slot_Item__c> items = [
                    SELECT Id, Name, Start_Time__c, End_Time__c
                    FROM   Appointment_Slot_Item__c
                    WHERE  Appointment_Slot__c IN :slotIds
                    AND    Booking_Status__c = 'Available'
                ];
                
                return new SlotResponse(slotIds, items);
            }
            
            // Nothing found – return empty wrapper
            return new SlotResponse(new List<Id>(), new List<Appointment_Slot_Item__c>());
        }
        catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            return null;
        } 
        
    }
    
    public class SlotResponse {
        @AuraEnabled public List<Id> slotIds;
        @AuraEnabled public List<Appointment_Slot_Item__c> slotItems;
        
        public SlotResponse(List<Id> slotIds, List<Appointment_Slot_Item__c> slotItems) {
            this.slotIds    = slotIds;
            this.slotItems  = slotItems;
        }
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String objectApiName, String fieldApiName) {
        try{
            List<String> picklistValues = new List<String>();
            
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
            if (targetType == null) return picklistValues;
            
            Schema.DescribeSObjectResult describeResult = targetType.getDescribe();
            Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get(fieldApiName).getDescribe();
            
            if (fieldResult != null && fieldResult.getType() == Schema.DisplayType.Picklist) {
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    picklistValues.add(entry.getLabel());
                }
            }
            
            return picklistValues;
            
        }
        catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            return null;
            
        } 
        
    }
    
}