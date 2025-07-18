public class OpportunityTriggerHandler {
    
    public static void updateLeadOwner(List<Opportunity> OppList){
        User usr = [SELECT Id, Username, LastName, FirstName, Name FROM User where Name = 'Binesh Nair' LIMIT 1];
        for(Opportunity opp: OppList){
            opp.OwnerId = usr.Id;
        }
    }
    
    public static void thresholdCallAttempt(List<Opportunity> OppList,Map<Id, Opportunity> oldMap){
        try{
            for(Opportunity oppRec : OppList){
                String thresCount = System.label.Threshold_Count;
                if(oppRec.Threshold_Count__c != oldMap.get(oppRec.Id).Threshold_Count__c  && oppRec.Threshold_Count__c >= decimal.valueOf(thresCount)){
                    oppRec.StageName = 'Close lost';
                }   
            }
        }catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
        }
    }
    
    public static void createTaskWhenOppAssignedToUser(List<Opportunity> newLeads, Map<Id, Opportunity> oldMap) {
        try {
            List<Task> tskList = new List<Task>();
            CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Notification_To_Record_Owner'];
            System.debug('Fetched CustomNotificationType: ' + cnType);
            
            for (Opportunity ledRec : newLeads) {
                System.debug('Processing Opportunity: ' + ledRec.Id);
                Opportunity oldLead = oldMap.get(ledRec.Id);
                String OwnerId = ledRec.OwnerId;
                
                if (ledRec.Is_Assigned_to_User__c == true && oldLead != null && ledRec.Is_Assigned_to_User__c != oldLead.Is_Assigned_to_User__c && OwnerId.startsWithIgnoreCase('005') && ledRec.OwnerId != oldLead.OwnerId) {
                    System.debug('Conditions met for task creation');
                    tskList.add(new Task(
                        OwnerId = ledRec.OwnerId,
                        Subject = 'A new Opportuntiy has been assigned to you',
                        Priority = 'Normal',
                        whatId = ledRec.Id,
                        ActivityDate = System.today() + 5
                    ));
                    
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Please check the Opportuntiy details');
                    customNotificationObj.setTitle('A new Opportuntiy has been assigned to you');
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setTargetId(ledRec.Id);
                    customNotificationObj.send(new Set<String> {ledRec.OwnerId});
                    System.debug('Notification sent to OwnerId: ' + ledRec.OwnerId);
                }
            }
            
            if (!tskList.isEmpty()) {
                System.debug('Inserting tasks: ' + tskList);
                insert tskList;
            }
            
        } catch (Exception e) {
            System.debug('Error =====> ' + e.getMessage() + ' at Line Number =====> ' + e.getLineNumber());
        }
    }
    
    public static void createTaskWhenOppIsInFollowup(List<Opportunity> newLeads, Map<Id, Opportunity> oldMap) {
        try {
            System.debug('Method createTaskWhenOppIsInFollowup started');
            List<Task> tskList = new List<Task>();
            CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Notification_To_Record_Owner'];
            System.debug('Fetched CustomNotificationType: ' + cnType);
            
            for (Opportunity ledRec : newLeads) {
                System.debug('Processing Opportunity: ' + ledRec.Id);
                Opportunity oldLead = oldMap.get(ledRec.Id);
                
                if (ledRec.StageName != null && ledRec.StageName == 'Follow Up' && oldLead != null && ledRec.StageName != oldLead.StageName) {
                    System.debug('Conditions met for task creation');
                    tskList.add(new Task(
                        OwnerId = ledRec.OwnerId,
                        Subject = 'A new Opportunity has been assigned to you',
                        Priority = 'Normal',
                        whatId = ledRec.Id,
                        ActivityDate = System.today() + 5
                    ));
                    
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Please check the Opportunity details');
                    customNotificationObj.setTitle('A new Opportunity has been assigned to you');
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setTargetId(ledRec.Id);
                    customNotificationObj.send(new Set<String> {ledRec.OwnerId});
                    System.debug('Notification sent to OwnerId: ' + ledRec.OwnerId);
                }
            }
            
            if (!tskList.isEmpty()) {
                System.debug('Inserting tasks: ' + tskList);
                insert tskList;
            }
            
            System.debug('Method createTaskWhenOppIsInFollowup completed');
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String createEvent(Map<String, Object> dateObj) {
        try {
            System.debug('Received dateObj: ' + JSON.serialize(dateObj));
            
            Datetime startDateTime = null;
            Datetime endDateTime = null;
            String whatId = null;
            String Status = null;
            
            
            
            if (dateObj != null) {
                if (dateObj.containsKey('StartDate') && dateObj.get('StartDate') != null) {
                    String startDateString = String.valueOf(dateObj.get('StartDate'));
                    startDateString = startDateString.replace('T', ' ').replace('Z', '');
                    startDateTime = Datetime.valueOf(startDateString);
                }
                
                if (dateObj.containsKey('EndDate') && dateObj.get('EndDate') != null) {
                    String endDateString = String.valueOf(dateObj.get('EndDate'));
                    endDateString = endDateString.replace('T', ' ').replace('Z', '');
                    endDateTime = Datetime.valueOf(endDateString);
                }
                
                if (dateObj.containsKey('Status') && dateObj.get('Status') != null) {
                    Status = String.valueOf(dateObj.get('Status'));
                }
                
                if (dateObj.containsKey('recordId') && dateObj.get('recordId') != null) {
                    whatId = String.valueOf(dateObj.get('recordId'));
                }
            }
            Lead leadrec = new Lead();
            Opportunity opprec = new Opportunity();
            if(whatId != null && whatId.startsWithIgnoreCase('00Q')){
                leadrec = [SELECT Id, Name FROM Lead WHERE Id = :whatId LIMIT 1];
            }else if (whatId != null && whatId.startsWithIgnoreCase('006')){
                opprec = [SELECT Id, Name FROM Opportunity WHERE Id = :whatId LIMIT 1];
            }
            
            if (startDateTime != null && endDateTime != null && Status == 'Scheduled') {
                Test_Drive__c newEvent = new Test_Drive__c(
                    Start_Date__c = startDateTime,
                    End_Date__c = endDateTime,
                    Subject__c = 'Scheduled Event for Test Ride',
                    DurationInMinutes__c = 45,
                    Test_Drive_Status__c = Status
                );
                
                if (String.isNotBlank(whatId)) {
                    if (whatId.startsWithIgnoreCase('006')) {
                        newEvent.Opportunity__c = whatId;
                    } else if (whatId.startsWithIgnoreCase('00Q')) {
                        newEvent.Lead__c = whatId;
                    }
                }
                if(leadrec.Name != null){
                    newEvent.Name = leadrec.Name +'- Test Drive';
                }else if(opprec.Name != null){
                    newEvent.Name = opprec.Name +'- Test Drive';
                }else{
                    newEvent.Name = 'Test Drive';
                }
                insert newEvent;
                System.debug('Event successfully created =====> ' + newEvent.Id);
                
                return 'Event Scheduled Successfully';
            } else {
                Test_Drive__c newEvent = new Test_Drive__c(
                    Subject__c = 'Scheduled Event for Test Ride',
                    DurationInMinutes__c = 45,
                    Test_Drive_Status__c = Status
                );
                
                if(startDateTime != null) {
                    newEvent.Start_Date__c = startDateTime;
                } if(endDateTime != null) {
                    newEvent.End_Date__c = endDateTime;
                }
                
                if (String.isNotBlank(whatId)) {
                    if (whatId.startsWithIgnoreCase('006')) {
                        newEvent.Opportunity__c = whatId;
                    } else if (whatId.startsWithIgnoreCase('00Q')) {
                        newEvent.Lead__c = whatId;
                    }
                }
                
                if(leadrec.Name != null){
                    newEvent.Name = leadrec.Name +'- Test Drive';
                }else if(opprec.Name != null){
                    newEvent.Name = opprec.Name +'- Test Drive';
                }else{
                    newEvent.Name = 'Test Drive';
                }
                insert newEvent;
                System.debug('Event successfully created without dates =====> ' + newEvent.Id);
                
                return 'Event Created Successfully';
            }
        } catch (Exception e) {
            System.debug('Error message ====>' + e.getMessage() + ' at Line number ====>' + e.getLineNumber());
            return e.getMessage();
        }
    }
    
}