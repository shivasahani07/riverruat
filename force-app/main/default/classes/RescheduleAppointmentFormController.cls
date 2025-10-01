public class RescheduleAppointmentFormController {

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
    public static AppointmentWrapper  getvehicleRecord(String sourceIdStr) {
        System.debug('---------- getvehicleRecord ---------------');
        System.debug('sourceIdStr : ' + sourceIdStr);
         AppointmentWrapper apppointRec = new AppointmentWrapper();   
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
        Date appointmentDate;
        
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
        }else if (objectApi == 'Appointment__c') {
            Appointment__c tk = [
                SELECT id, Service_Appointment__r.Vehicle__c,Appointment_Date__c
                FROM   Appointment__c
                WHERE  Id = :recordId
                LIMIT  1
            ];
            vehicleId = tk.Service_Appointment__r.Vehicle__c;
            appointmentDate = tk.Appointment_Date__c;
			apppointRec.appointmentDATE = appointmentDate;
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
		apppointRec.vehicleRecord = vehicleRec;
		system.debug('vehicleRec==='+vehicleRec);
        return apppointRec ;
    }

	public class AppointmentWrapper {
        @AuraEnabled public Vehicle vehicleRecord {get;set;}
        @AuraEnabled public Date appointmentDATE {get;set;}
        
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
        Boolean isAppointment = (parentType == 'Appointment__c'); 
        /*if (!isServiceAppt && !isTicket) {
            throw new AuraHandledException('Unsupported parent record.');
        }*/
        
        
        Appointment__c newApp = new Appointment__c();
        newApp.Id   = parentId;
        newApp.Appointment_Date__c = appointmentDate;
        newApp.Additional_Information__c = appointmentDecription;
        newApp.Type_Of_Requested_Services__c = serviceType;
        
         
        Update newApp;
        String newAppId = newApp.Id;  // ← capture Id
        
        Appointment_Slot__c slotRec = [
            SELECT Id, Appointment__c
            FROM   Appointment_Slot__c
            WHERE  Id = :slotId
            LIMIT  1
        ];
         
        update slotRec;
        
        Appointment_Slot_Item__c slotItemRec = [
            SELECT Id, Booking_Status__c,Start_Time__c,End_Time__c
            FROM   Appointment_Slot_Item__c
            WHERE  Id = :slotItemId
            LIMIT  1
        ];
        slotItemRec.Booking_Status__c = 'Booked';
        slotItemRec.Appointment__c = newApp.Id;
        update slotItemRec;

		 Appointment_Slot_Item__c slotItemRecord = [
            SELECT Id, Booking_Status__c,Start_Time__c,End_Time__c
            FROM   Appointment_Slot_Item__c
            WHERE Appointment__c =: parentId  
            LIMIT  1
        ];
        
		delete slotItemRecord;

        Appointment__c appointRec = [Select id ,Service_Appointment__c,Appointment_Date__c from Appointment__c where Id =:parentId];
		Id saId = appointRec.Service_Appointment__c;
        Date rescheduleappointmentDate = appointRec.Appointment_Date__c;
        if (isAppointment) {
            ServiceAppointment sa = [
                SELECT Id, Call_Status__c,Account.Email__c,Account.Name,Asset_Milestone__r.MilestoneDate,Service_Centre__r.Name
                FROM   ServiceAppointment
                WHERE  Id = :saId
                LIMIT  1
            ];
            system.debug('beforeUpdatesa '+sa);
            system.debug('Account.Email__c '+Account.Email__c);
            sa.Call_Status__c = 'Appointment Booked';
            update sa;
            system.debug('UpdatedServiceAppointment '+sa);
            ServiceAppointment serviceupdate = [
                SELECT Id, Call_Status__c,Account.Email__c,Account.Name,Asset_Milestone__r.MilestoneDate,Service_Centre__r.Name
                FROM   ServiceAppointment
                WHERE  Id = :saId
                LIMIT  1
            ];
            system.debug('serviceupdate '+serviceupdate.Account.Email__c);
            OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'River Mobility' LIMIT 1 ];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { serviceupdate.Account.Email__c });
            

               //appointmentDate = sa.Asset_Milestone__r.MilestoneDate;
Datetime milestoneDT = Datetime.newInstance(rescheduleappointmentDate, Time.newInstance(0,0,0,0));
String milestoneDateStr = milestoneDT.format('dd MMM yyyy');

// Convert time fields
Time startTime = slotItemRec.Start_Time__c;
Time endTime   = slotItemRec.End_Time__c;

Datetime startDT = Datetime.newInstance(Date.today(), startTime);
Datetime endDT   = Datetime.newInstance(Date.today(), endTime);

String startTimeStr = startDT.format('hh:mm a');
String endTimeStr   = endDT.format('hh:mm a');

// Subject + Body
mail.setSubject(
    sa.Account.Name + ': ' + milestoneDateStr + 'Your Service Appointment is Rescheduled'
);

String body = 'Hey ' + sa.Account.Name + ',' +
    '\n\nYour service appointment has been successfully booked!' +
    '\n\n📅 Reschedule Date: ' + milestoneDateStr +
    '\n🕒 Reschedule Time: ' + startTimeStr + ' to ' + endTimeStr +
    '\n🏢 Service Center: ' + sa.Service_Centre__r.Name +
    '\n\nFor any changes or assistance, please contact our Service Advisor.' +
    '\n\nThank you for choosing us!';
 
           mail.setPlainTextBody(body);
           mail.setOrgWideEmailAddressId(owea.Id);
           Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
           system.debug('Mail sent Successfully to customer ');
        }
        
        
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
       // insert reminder;
        System.debug('newAppId==='+newAppId);
        return newAppId;
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
        
        // Fetch ALL slots for given date / center
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