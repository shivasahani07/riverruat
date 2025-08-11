public without  sharing class AppointmentFormController {
    
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
        ServiceCenterWrapper wrapper = new ServiceCenterWrapper();

        Id userid = UserInfo.getUserId();
        User userRec = [
            SELECT Id, Contact.AccountId, Contact.Account.Name 
            FROM User 
            WHERE Id = :userid 
            LIMIT 1
        ];
        System.debug('userRec : ' + userRec);

        Account accRec = [SELECT Id, Name FROM Account WHERE Id = :userRec.Contact.AccountId LIMIT 1];
        //Account accRec = [SELECT Id, Name FROM Account WHERE Id = :userRec.Contact.AccountId LIMIT 1];
        System.debug('accRec : ' + accRec);
        wrapper.accountName = accRec.Name;
        wrapper.accountId = accRec.Id;

        return wrapper;
    }

    @AuraEnabled(cacheable=true)
    public static String getVehicleOwnerContacts(String ticketId){
        System.debug(' ----------- getVehicleOwnerContacts -------------');
        System.debug('targetId : ' + ticketId);
        
        // Query Ticket → Job Card → Vehicle → Contacts
        Ticket__c ticket = [
            SELECT Id, Job_Card__c, Job_Card__r.Vehicle__r.Id, Job_Card__r.Vehicle__r.CurrentOwnerId
            FROM Ticket__c
            WHERE Id = :ticketId
            LIMIT 1
        ];
        System.debug('Ticket : ' + ticket);
        
        Id vehicleId = ticket?.Job_Card__r?.Vehicle__r?.Id;
        if(vehicleId == null){
            return 'No Contact Number Found';
        }
        System.debug('vehicleId : ' + vehicleId);
        
        Id accountId = ticket?.Job_Card__r?.Vehicle__r?.CurrentOwnerId;
        System.debug('accountId : ' + accountId);
        
        List<Contact> contactList = [
            SELECT Id, Name, Phone, MobilePhone, Email
            FROM Contact
            WHERE AccountId = :accountId
        ];
        System.debug('contactList : ' + contactList);
        System.debug('contact Phone Number : ' + contactList[0].Phone != null ? contactList[0].Phone : contactList[0].MobilePhone);
        
        return contactList[0].Phone != null ? contactList[0].Phone : contactList[0].MobilePhone;
    }
    
    @AuraEnabled
    public static Vehicle  getvehicleRecord(String sourceIdStr) {
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
            Task t = [
                SELECT WhatId
                FROM   Task
                WHERE  Id = :recordId
                LIMIT  1
            ];
            if (t.WhatId == null) return null;              // Task without WhatId
            recordId   = t.WhatId;
            objectApi  = recordId.getSObjectType().getDescribe().getName();
            System.debug('objectApi : ' + objectApi);
        }
        
        // ------------------------------------------------------------------
        // 2. Derive the Vehicle Id from ServiceAppointment or Ticket__c
        // ------------------------------------------------------------------
        Id vehicleId;
        
        if (objectApi == 'ServiceAppointment') {
            ServiceAppointment sa = [
                SELECT Vehicle__c
                FROM   ServiceAppointment
                WHERE  Id = :recordId
                LIMIT  1
            ];
            vehicleId = sa.Vehicle__c;
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
    
    
    @AuraEnabled
    public static void createAppointment(Id ticketId, Id accountId, String vrn, Date appointmentDate, String contactNumber) {
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
    
    /* ===============================================================
AppointmentFormController.cls  •  Updated create‑method
=============================================================== */
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
        String appointmentDecription
    ) {
        if (serviceAppId == null || slotId == null || slotItemId == null) {
            throw new AuraHandledException('Required parameters missing.');
        }
        
        /*--------------------------------------------------------------
* 1. Resolve to the TRUE parent Id (SA or Ticket)
*------------------------------------------------------------*/
        Id parentId       = serviceAppId;
        String parentType = parentId.getSObjectType().getDescribe().getName();
        
        if (parentType == 'Task') {
            // Follow the WhatId
            Task t = [SELECT WhatId FROM Task WHERE Id = :parentId LIMIT 1];
            if (t.WhatId == null) {
                throw new AuraHandledException('Task is not linked to a record.');
            }
            parentId   = t.WhatId;
            parentType = parentId.getSObjectType().getDescribe().getName();
        }
        
        Boolean isServiceAppt = (parentType == 'ServiceAppointment');
        Boolean isTicket      = (parentType == 'Ticket__c');
        
        if (!isServiceAppt && !isTicket) {
            throw new AuraHandledException('Unsupported parent record.');
        }
        
        /*--------------------------------------------------------------
* 2. Create Appointment__c
*------------------------------------------------------------*/
        Appointment__c newApp = new Appointment__c();
        newApp.Service_Center__c   = accountId;
        newApp.VRN__c              = vrn;
        newApp.Status__c           = 'Open';
        newApp.Appointment_Date__c = appointmentDate;
        newApp.Contact_Number__c   = contactNumber;
        newApp.Mode_of_Reception__c = 'Appointment';
        newApp.Additional_Information__c = appointmentDecription;
        newApp.Type_Of_Requested_Services__c = serviceType;
        
        if (isServiceAppt) {
            newApp.Service_Appointment__c = parentId;
        } else {
            newApp.Ticket__c = parentId;
            
            
        }
        insert newApp;
        String newAppId = newApp.Id;  // ← capture Id
        
        /*--------------------------------------------------------------
* 3. Tie slot & slot‑item to the new appointment
*------------------------------------------------------------*/
        Appointment_Slot__c slotRec = [
            SELECT Id, Appointment__c
            FROM   Appointment_Slot__c
            WHERE  Id = :slotId
            LIMIT  1
        ];
        // slotRec.Appointment__c = newApp.Id;
        update slotRec;
        
        Appointment_Slot_Item__c slotItemRec = [
            SELECT Id, Booking_Status__c
            FROM   Appointment_Slot_Item__c
            WHERE  Id = :slotItemId
            LIMIT  1
        ];
        slotItemRec.Booking_Status__c = 'Booked';
        slotItemRec.Appointment__c = newApp.Id;
        update slotItemRec;
        
        /*--------------------------------------------------------------
* 4. Update ServiceAppointment status (if applicable)
*------------------------------------------------------------*/
        if (isServiceAppt) {
            ServiceAppointment sa = [
                SELECT Id, Call_Status__c
                FROM   ServiceAppointment
                WHERE  Id = :parentId
                LIMIT  1
            ];
            sa.Call_Status__c = 'Appointment Booked';
            update sa;
        }
        
        /*--------------------------------------------------------------
* 5. Complete open tasks under the parent (SA or Ticket)
*------------------------------------------------------------*/
        List<Task> openTasks = [
            SELECT Id, Status,Sub_status__c
            FROM   Task
            WHERE  WhatId = :parentId
            AND    Status != 'Completed'
        ];
        for (Task t : openTasks) {
            t.Status = 'Completed';
            t.Sub_status__c = 'Appointment';
            t.Appointment_Date__c = appointmentDate;
            t.Appointment_Description__c = appointmentDecription;
        }
        if (!openTasks.isEmpty()) update openTasks;
        
        /*--------------------------------------------------------------
* 6. Create reminder task under the Appointment
*------------------------------------------------------------*/

        /*
        Ticket__c appointmentTicket = [
            SELECT Id, Name, Job_Card__c, Job_Card__r.Vehicle__c, Job_Card__r.Vehicle__r.CurrentOwnerId, Post_Service_Feedback__c, Post_Service_Feedback__r.Name,
            Job_Card__r.Vehicle__r.CurrentOwner.Name, Job_Card__r.Vehicle__r.CurrentOwner.Phone,  
            Job_Card__r.Vehicle__r.CurrentOwner.Email__c, Job_Card__r.Vehicle__r.CurrentOwner.Secondary_Phone_Number__c 
            FROM Ticket__c
            WHERE Id = :parentId
            LIMIT 1
        ];
        */

        Vehicle vehicleRec = [SELECT Id, CurrentOwnerId, CurrentOwner.Name
            FROM Vehicle 
            WHERE VehicleRegistrationNumber =: vrn ];

        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Task Reminder').getRecordTypeId();
        
        Appointment__c appointmentRec = [Select Id,Name,Service_Appointment__r.AppointmentNumber from Appointment__c where Id =:newApp.Id limit 1];

        Task reminder = new Task();
        reminder.WhatId                         = newApp.Id;
        reminder.Subject                        = appointmentRec.Service_Appointment__r.AppointmentNumber + ' ' + appointmentRec.Name + ' - Appointment Reminder';
        reminder.Status                         = 'Not Started';
        reminder.Priority                       = 'High';
        reminder.Vehicle__c                     = vehicleRec.id;
        reminder.ActivityDate                   = appointmentDate.addDays(-1);
        reminder.RecordTypeId                   = recordTypeId;
        reminder.Phone_Number__c                = contactNumber;
        reminder.Customer__c                    = vehicleRec.CurrentOwnerId != null ?  vehicleRec.CurrentOwnerId : null;
        reminder.Call_To_c__c                   = vehicleRec.CurrentOwner.Name != null ? vehicleRec.CurrentOwner.Name : null;
        reminder.Appointment_Date__c            = appointmentDate;
        reminder.Appointment_Description__c     = appointmentDecription;
        insert reminder;
        System.debug('newAppId==='+newAppId);
        return newAppId;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Appointment_Slot__c> getAvailableSlots(Id appointmentId) {
        // Customize filter logic as needed
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
            List<Task> tasksToComplete = [
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
                }
            
            response = 'success';
        } catch (Exception e) {
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            response = e.getMessage();
        }
        return response;
    }
    @AuraEnabled
    public static SlotResponse getSlotItems(Id serviceCenterId, Date appointmentDate) {
        
        // Find ONE slot for that date / center
        List<Appointment_Slot__c> slots = [
            SELECT Id
            FROM   Appointment_Slot__c
            WHERE  Service_Center__c      = :serviceCenterId
            AND    Appointment_Slot_Date__c = :appointmentDate
            LIMIT  1
        ];
        
        if (!slots.isEmpty()) {
            Id slotId = slots[0].Id;
            
            List<Appointment_Slot_Item__c> items = [
                SELECT Id, Name,Start_Time__c, End_Time__c
                FROM   Appointment_Slot_Item__c
                WHERE  Appointment_Slot__c = :slotId AND Booking_Status__c = 'Available'
            ];
            
            return new SlotResponse(slotId, items);
        }
        
        // Nothing found – return an empty wrapper
        return new SlotResponse(null, new List<Appointment_Slot_Item__c>());
    }
    public class SlotResponse {
        @AuraEnabled public Id   slotId;
        @AuraEnabled public List<Appointment_Slot_Item__c> slotItems;
        
        public SlotResponse(Id slotId, List<Appointment_Slot_Item__c> slotItems) {
            this.slotId    = slotId;
            this.slotItems = slotItems;
        }
    }
     @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String objectApiName, String fieldApiName) {
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
    
    
}