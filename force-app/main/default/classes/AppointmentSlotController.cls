public with sharing class AppointmentSlotController {

    @AuraEnabled
    public static Integer getServiceBayCount(Id serviceCenterId) {
        return [
            SELECT COUNT()
            FROM Service_Bay__c
            WHERE Service_Center__c = :serviceCenterId AND Is_Active__c = True
        ];
    }
  

    @AuraEnabled(cacheable=true)
    public static serviceCenterAppointmentWrapper getCurrentContactServiceCenter(){
        try{
            serviceCenterAppointmentWrapper wrapper = new serviceCenterAppointmentWrapper();
        Id userid = UserInfo.getUserId();
        User userRec = [
            SELECT Id, Contact.AccountId, Contact.Account.Name 
            FROM User 
            WHERE Id = :userid 
            LIMIT 1
        ];
        

        Account accRec = [SELECT Id, Name FROM Account WHERE Id =:userRec.Contact.AccountId LIMIT 1];
        wrapper.accountName = accRec.Name;
        wrapper.accountId = accRec.Id;

        List<Appointment_Slot__c> appointSLot = [
            SELECT Id, Service_Center__c, Appointment_Slot_Date__c, Start_Slot_Time__c, End_Slot_Time__c, Slot_Duration_Minute__c, Status__c
            FROM Appointment_Slot__c 
            WHERE Service_Center__c = :accRec.Id
        ];

        if (!appointSLot.isEmpty()) {
            Set<Id> appointSlotIds = new Set<Id>();
            for (Appointment_Slot__c appRec : appointSLot) {
                appointSlotIds.add(appRec.Id);
            }

            List<Appointment_Slot_Item__c> appointmentLineItemList = [
                SELECT Id, Name, Service_Bay__c, Service_Bay__r.Name, Appointment_Slot_Date__c, 
                       Start_Time__c, End_Time__c, Appointment_Slot__r.Name, Booking_Status__c, Appointment_Slot__c
                FROM Appointment_Slot_Item__c 
                WHERE Appointment_Slot__c IN :appointSlotIds 
                ORDER BY Appointment_Slot_Date__c DESC
            ];

            wrapper.asiList = appointmentLineItemList;
        }

        return wrapper;
        }
        catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            return null;
        }
        
    }

    public class serviceCenterAppointmentWrapper {
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public List<Appointment_Slot_Item__c> asiList;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getRemainingBayCountForRange(Id serviceCenterId, Date startDate, Date endDate) {
        try{
           Integer totalBays = [SELECT COUNT() FROM Service_Bay__c WHERE Service_Center__c = :serviceCenterId AND Is_Active__c = True];

        List<AggregateResult> booked = [
            SELECT Appointment_Slot_Date__c bookedDate, Service_Bay__c bay
            FROM Appointment_Slot_Item__c
            WHERE Appointment_Slot__r.Service_Center__c = :serviceCenterId
              AND Appointment_Slot_Date__c >= :startDate
              AND Appointment_Slot_Date__c <= :endDate
              AND Booking_Status__c = 'Available'
            GROUP BY Appointment_Slot_Date__c, Service_Bay__c
        ];

        Set<String> bookedKeys = new Set<String>();
        for (AggregateResult r : booked) {
            bookedKeys.add(
                String.valueOf((Date) r.get('bookedDate')) + '-' + String.valueOf((Id) r.get('bay'))
            );
        }

        Set<Date> dates = new Set<Date>();
        for (Date current = startDate; current <= endDate; current = current.addDays(1)) {
            dates.add(current);
        }

        Integer maxUsedPerDay = 0;
        for (Date d : dates) {
            Integer usedToday = 0;
            for (String key : bookedKeys) {
                if (key.startsWith(String.valueOf(d) + '-')) usedToday++;
            }
            if (usedToday > maxUsedPerDay) maxUsedPerDay = usedToday;
        }

        return totalBays - maxUsedPerDay; 
        }
        catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            return null;
        }
        
    }

    @AuraEnabled   
    public static Id createSlot(
        Id serviceCenterId,
        Date startDate,
        Date endDate,
        String dayStartTime,
        String dayEndTime,
        Integer serviceBaynumber,
        Integer slotDurationMins
    ) {
        
        try{
            Time startT = toTime(dayStartTime);
        Time endT = toTime(dayEndTime);

        List<Date> dateList = new List<Date>();
        for (Date d = startDate; d <= endDate; d = d.addDays(1)) {
            dateList.add(d);
        }

        // Get existing slot items
        Map<Date, List<Appointment_Slot_Item__c>> existingItemsMap = new Map<Date, List<Appointment_Slot_Item__c>>();
        for (Appointment_Slot_Item__c item : [
            SELECT Id, Appointment_Slot__r.Appointment_Slot_Date__c, Service_Bay__c
            FROM Appointment_Slot_Item__c
            WHERE Appointment_Slot__r.Service_Center__c = :serviceCenterId
            AND Appointment_Slot__r.Appointment_Slot_Date__c IN :dateList
        ]) {
            Date d = item.Appointment_Slot__r.Appointment_Slot_Date__c;
            if (!existingItemsMap.containsKey(d)) {
                existingItemsMap.put(d, new List<Appointment_Slot_Item__c>());
            }
            existingItemsMap.get(d).add(item);
        }

        // Get bays
        List<Service_Bay__c> allBayList = [
            SELECT Id, Vehicle_Capacity__c 
            FROM Service_Bay__c 
            WHERE Service_Center__c = :serviceCenterId AND Is_Active__c = True
            ORDER BY Name
        ];

        if (allBayList.isEmpty()) {
            throw new AuraHandledException('This Service Center has no Service Bay records.');
        }

        Map<Id, Integer> bayCapacityMap = new Map<Id, Integer>();
        for (Service_Bay__c bay : allBayList) {
            Integer cap = (bay.Vehicle_Capacity__c == null || bay.Vehicle_Capacity__c < 1) ? 1 : bay.Vehicle_Capacity__c.intValue();
            bayCapacityMap.put(bay.Id, cap);
        }

        List<Appointment_Slot__c> newSlots = new List<Appointment_Slot__c>();
        Map<Date, Appointment_Slot__c> slotMapByDate = new Map<Date, Appointment_Slot__c>();

        for (Date d : dateList) {
            // Check used bays
            Set<Id> usedBayIds = new Set<Id>();
            if (existingItemsMap.containsKey(d)) {
                for (Appointment_Slot_Item__c item : existingItemsMap.get(d)) {
                    usedBayIds.add(item.Service_Bay__c);
                }
            }

            // Find available bays
            List<Id> availableBayIds = new List<Id>();
            for (Service_Bay__c bay : allBayList) {
                if (!usedBayIds.contains(bay.Id)) {
                    availableBayIds.add(bay.Id);
                }
            }

            if (availableBayIds.isEmpty()) {
                continue; // skip date if all bays are occupied
            }

            Integer count = Math.min(serviceBaynumber, availableBayIds.size());
            system.debug('count==='+count);
            List<Id> baysToUse = new List<Id>();
            for (Integer i = 0; i < count; i++) {
                baysToUse.add(availableBayIds[i]);
            }

            Appointment_Slot__c newSlot = new Appointment_Slot__c(
                Service_Center__c = serviceCenterId,
                Appointment_Slot_Date__c = d,
                Start_Slot_Time__c = startT,
                End_Slot_Time__c = endT,
                Slot_Duration_Minute__c = slotDurationMins,
                Status__c = 'Published'
            );
            newSlots.add(newSlot);
            slotMapByDate.put(d, newSlot);
        }

        if (!newSlots.isEmpty()) {
            insert newSlots;
        }

        // Build Slot Item records
        Map<Date, Id> dateToSlotId = new Map<Date, Id>();
        for (Appointment_Slot__c s : newSlots) {
            dateToSlotId.put(s.Appointment_Slot_Date__c, s.Id);
        }

        List<Appointment_Slot_Item__c> newItems = new List<Appointment_Slot_Item__c>();

        for (Date d : dateList) {
            if (!dateToSlotId.containsKey(d)) continue;

            Id slotId = dateToSlotId.get(d);

            Set<Id> usedBayIds = new Set<Id>();
            if (existingItemsMap.containsKey(d)) {
                for (Appointment_Slot_Item__c item : existingItemsMap.get(d)) {
                    usedBayIds.add(item.Service_Bay__c);
                }
            }

            List<Id> availableBayIds = new List<Id>();
            for (Service_Bay__c bay : allBayList) {
                if (!usedBayIds.contains(bay.Id)) {
                    availableBayIds.add(bay.Id);
                }
            }

            Integer count = Math.min(serviceBaynumber, availableBayIds.size());
            List<Id> baysToUse = new List<Id>();
            for (Integer i = 0; i < count; i++) {
                baysToUse.add(availableBayIds[i]);
            }

            Time cursor = startT;
            while (cursor.addMinutes(slotDurationMins) <= endT) {
                Time sliceEnd = cursor.addMinutes(slotDurationMins);
                for (Id bayId : baysToUse) {
                    Integer capacity = bayCapacityMap.get(bayId);
                    for (Integer i = 0; i < capacity; i++) {
                        newItems.add(new Appointment_Slot_Item__c(
                            Appointment_Slot__c = slotId,
                            Service_Bay__c = bayId,
                            Start_Time__c = cursor,
                            End_Time__c = sliceEnd,
                            Booking_Status__c = 'Available'
                        ));
                    }
                }
                cursor = sliceEnd;
            }
        }

        if (!newItems.isEmpty()) {
            insert newItems;
        }

        return !slotMapByDate.isEmpty() ? slotMapByDate.values()[0].Id : null;
        }
        catch (Exception e){
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
            return null;
        }
        
    }

    private static Time toTime(String input) {
        if (String.isBlank(input)) return null;
        List<String> parts = input.split(':');
        Integer h = Integer.valueOf(parts[0]);
        Integer m = Integer.valueOf(parts[1]);
        return Time.newInstance(h, m, 0, 0);
    }
}