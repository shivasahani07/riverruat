public class FollowUpTriggerController {

    public static void updateFollowUpName(List<Follow_Up__c> newListFollowUp){
        
        Set<Id> leadIds = new Set<Id>();
        for (Follow_Up__c followUp : newListFollowUp) {
            if (followUp.Lead__c != null) {
                leadIds.add(followUp.Lead__c);
            }
        }
        List<Lead> leadtoupdate = new List<Lead>(); 
        Map<Id, Integer> followUpCounts = new Map<Id, Integer>();
        List<AggregateResult> results = [SELECT Lead__c, COUNT(Id) followUpCount FROM Follow_Up__c WHERE Lead__c IN :leadIds GROUP BY Lead__c];
        if (!leadIds.isEmpty()) {
            for(Lead l : [select id,status from lead where id = :leadIds]){
                l.Status = 'Follow Up';
                leadtoupdate.add(l);
            }
            for (AggregateResult ar : results) {
                followUpCounts.put((Id) ar.get('Lead__c'), (Integer) ar.get('followUpCount'));
            }
            
        }
        
        Map<Id, Lead> leads = new Map<Id, Lead>();
        if (!leadIds.isEmpty()) {
            leads = new Map<Id, Lead>([
                SELECT Id, Name FROM Lead WHERE Id IN :leadIds
            ]);
        }
        
        
        for (Follow_Up__c followUp : newListFollowUp) {
            if (followUp.Lead__c != null && leads.containsKey(followUp.Lead__c)) {
                Lead relatedLead = leads.get(followUp.Lead__c);Integer currentCount = followUpCounts.containsKey(followUp.Lead__c) ? followUpCounts.get(followUp.Lead__c) : 0;
                followUp.Name = relatedLead.Name + ' - Follow up ' + (currentCount + 1);
                followUpCounts.put(followUp.Lead__c, currentCount + 1);
            }
            
        }
        
        if(!leadtoupdate.isempty()){
            update leadtoupdate;
        }
    }
    
    public static void updateFeedBack(List<Follow_Up__c> newListFollowUp,Map<Id,Follow_Up__c> oldMap){
        Set<Id> setID = new Set<Id>();
        for(Follow_Up__c objFollow: newListFollowUp){
            if(objFollow.FeedBack1__c != null && objFollow.FeedBack1__c != oldMap.get(objFollow.Id).FeedBack1__c){
                setID.add(objFollow.Id);
            }
        }
        List<Follow_Up__History> lstHistory =[SELECT OldValue, NewValue, Field, CreatedDate,ParentId FROM Follow_Up__History WHERE Field = 'FeedBack1__c' AND ParentId =: setID];
        Map<Id,List<Follow_Up__History>> mapHistory = new Map<Id,List<Follow_Up__History>>();
        for(Follow_Up__History objHis : lstHistory){
            if(!mapHistory.containsKey(objHis.ParentId)){
                mapHistory.put(objHis.ParentId,new List<Follow_Up__History>());
            }
            mapHistory.get(objHis.ParentId).add(objHis);
        }
        for(Follow_Up__c objFollow: newListFollowUp){
            
            if(mapHistory.containskey(objFollow.Id)){
                // objFollow.Folllow_Up1_Summary__c ='';
                List<Follow_Up__History> lstHisNew = mapHistory.get(objFollow.Id);
                for(Follow_Up__History objHis: lstHisNew){
                    //objFollow.Folllow_Up1_Summary__c += Date.valueOf(objHis.CreatedDate).format() + '-' + objHis.NewValue+ '\n';
                }
            }
        }
    }

    public static void updateleadstatus(list<Follow_Up__c> newListFollowUp){
        set<Id> idss=new set<Id>();
        
        for(Follow_Up__c newfollowup:newListFollowUp){
            idss.add(newfollowup.Lead__c);
        }

        list<Lead> getlead = new list<Lead>();

        if(idss.isEmpty()){
            getlead = [select Id,Status from Lead where Id IN :idss ];
        }

        list<lead> upleadlst = new list<lead>();
        for(lead l:getlead){
            l.Status='Follow Up';
            upleadlst.add(l);
        }
        update upleadlst;
    }
   
    public static void previousfeedback(list<Follow_Up__c> newListFollowUp){
        system.debug('enter previousfeedback');
        Map<Id,List<Follow_Up__c>> mapLead = new Map<Id,List<Follow_Up__c>>();
        Set<Id> setLeadId = new Set<Id>();
        for(Follow_Up__c objFollow : newListFollowUp){
            setLeadId.add(objFollow.Lead__c);
        }
        List<Follow_Up__c> lstFollow = new List<Follow_Up__c>();
        if(!setLeadId.isEmpty()){
            lstFollow = [SELECT Id,Feedback__c,Follow_Up_Date__c,CreatedDate, Lead__c,Previous_Feedback__c,Previous_Followup_date__c  FROM Follow_Up__c WHERE Lead__c IN: setLeadId ORDER BY CreatedDate DESC limit 1];
        }

        if(!lstFollow.isEmpty()){
            for(Follow_Up__c objFollow : newListFollowUp){
                for(Follow_Up__c oldfolowup : lstFollow){
                    system.debug('ggggg'+oldfolowup.Follow_Up_Date__c);
                    objFollow.Previous_Followup_date__c=oldfolowup.Follow_Up_Date__c;
                    // objFollow.Previous_Feedback__c=oldfolowup.Feedback__c;
                }
            }
        }
    }   

    public static void folowuptype(list<Follow_Up__c> newListFollowUp){
        string leadids;
        system.debug('enter'+newListFollowUp);
        for(Follow_Up__c f:newListFollowUp){
            if(f.Lead__c != null){
                leadids = f.Lead__c;
            }
        }
        system.debug('id'+leadids);

        List<Lead> leadlst = new List<Lead>();
        if(leadids == null){
            leadlst = [select id,(select Id from Follow_Ups__r) from Lead where Id =:leadids];
        }
        
        if(!leadlst.isEmpty()){
            for(Lead L:leadlst){
                for(Follow_Up__c fl:newListFollowUp){
                    if(l.Follow_Ups__r.size()==0){
                        fl.Follow_Up__c='Follow up 1';
                    }else if(l.Follow_Ups__r.size()==1){
                        fl.Follow_Up__c='Follow up 2';
                    }else if(l.Follow_Ups__r.size()==2){
                        fl.Follow_Up__c='Follow up 3';
                    }else if(l.Follow_Ups__r.size()==3){
                        fl.Follow_Up__c='Follow up 4';
                    }else if(l.Follow_Ups__r.size()==4){
                        fl.Follow_Up__c='Follow up 5';
                    }else if(l.Follow_Ups__r.size()==5){
                        fl.Follow_Up__c='Follow up 6';
                    }else if(l.Follow_Ups__r.size()==6){
                        fl.Follow_Up__c='Follow up 7';
                    }else if(l.Follow_Ups__r.size()==7){
                        fl.Follow_Up__c='Follow up 8';
                    }else if(l.Follow_Ups__r.size()==8){
                        fl.Follow_Up__c='Follow up 9';
                    }else if(l.Follow_Ups__r.size()==9){
                        fl.Follow_Up__c='Follow up 10';
                    }else{
                        fl.Follow_Up__c=null;
                    }
                }
            }
        }
        
    }

    ////////////// This Code Added By Anwar //////////////

    public static void showFollowUpCount(List<Follow_Up__c> newListFollowUp){
        try{
            Set<Id> setOfOppId = new Set<Id>(); 
            set<Id> setOfZeroValue = new set<Id>();
            for(Follow_Up__c followUprec : newListFollowUp){
                if(followUprec.Opportunity__c != null){
                    setOfOppId.add(followUprec.Opportunity__c);
                }
            }
            System.debug('setOfOppId ====>'+ setOfOppId);
            List<AggregateResult> groupedResults = new List<AggregateResult>();
            if(!setOfOppId.isEmpty()){
                groupedResults = [SELECT COUNT(Id) totalRecord, Opportunity__c FROM Follow_Up__c WHERE Opportunity__c IN :setOfOppId GROUP BY Opportunity__c];
                System.debug('groupedResults ====>'+ groupedResults);
            }

            Map<Id,Integer> mapOfOppAndFollowUpCount = new Map<Id,Integer>();
            for(AggregateResult ar : groupedResults){
                Id OpportunityId = (Id)ar.get('Opportunity__c');
                Integer totalRec = (Integer)ar.get('totalRecord');
                mapOfOppAndFollowUpCount.put(OpportunityId,totalRec);
                setOfZeroValue.add(OpportunityId);
            }
            System.debug('mapOfOppAndFollowUpCount ====>'+ mapOfOppAndFollowUpCount);
            
            List<Opportunity> oppListToBeUpdate = new List<Opportunity>();
            List<Opportunity> zeroOppList = new List<Opportunity>();
            List<Opportunity> oppList = new List<Opportunity>();
            if(!setOfOppId.isEmpty()){
                oppList = [SELECT Id,Follow_Up_Count__c FROM Opportunity WHERE Id IN :setOfOppId];
            }
            
            for(Opportunity opp : oppList){
                if(!setOfZeroValue.contains(opp.Id)){
                    Opportunity opps = new Opportunity();
                    opps.Id = opp.Id;
                    opps.Follow_Up_Count__c = 0;
                    zeroOppList.add(opps);
                }
            }
            for(Id oppRecId :mapOfOppAndFollowUpCount.keySet()){
                Opportunity opp = new Opportunity();
                opp.Id = oppRecId;
                opp.Follow_Up_Count__c = mapOfOppAndFollowUpCount.get(oppRecId);
                oppListToBeUpdate.add(opp);
            }  
            if(!oppListToBeUpdate.isEmpty()){
                update oppListToBeUpdate;
            }
            if(!zeroOppList.isEmpty()){
                update zeroOppList;
            }
            System.debug('oppListToBeUpdate ====>'+ oppListToBeUpdate);
        }catch(Exception e){
            System.debug( 'Error message' + e.getMessage() + ' at line number' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String createFollowup(Map<String, Object> dateObj) {
        try {
            System.debug('Received dateObj: ' + JSON.serialize(dateObj));
            
            Date DueDateTime = null;
            Datetime FollowUpDateTime = null;
            String whatId = null;
            String Status = null;

            if (dateObj != null) {
                
                // if (dateObj.containsKey('dueDate') && dateObj.get('dueDate') != null) {
                //     String followUpDateString = String.valueOf(dateObj.get('dueDate')).replace('T', ' ').replace('Z', '');
                //     DueDateTime = Date.valueOf(followUpDateString);
                // }
                if (dateObj.containsKey('FollowUpDate') && dateObj.get('FollowUpDate') != null) {
                    String followUpDateString = String.valueOf(dateObj.get('FollowUpDate')).replace('T', ' ').replace('Z', '');
                    FollowUpDateTime = Datetime.valueOf(followUpDateString);
                }
                
                if (dateObj.containsKey('Status') && dateObj.get('Status') != null) {
                    Status = String.valueOf(dateObj.get('Status'));
                }
                
                if (dateObj.containsKey('recordId') && dateObj.get('recordId') != null) {
                    whatId = String.valueOf(dateObj.get('recordId'));
                }
            }
            
            Lead leadrec = null;
            Opportunity opprec = null;

            List<Follow_Up__c> listOfFollowUps = new List<Follow_Up__c>();
            String Querys = 'SELECT Id, Opportunity__c FROM Follow_Up__c';
            
            if (String.isNotBlank(whatId)) {
                if (whatId.startsWithIgnoreCase('00Q')) {
                    leadrec = [SELECT Id, Name FROM Lead WHERE Id = :whatId LIMIT 1];
                    Querys += ' WHERE Lead__c = \'' + String.escapeSingleQuotes(whatId) + '\'';
                    Querys += ' AND Status__c NOT IN (\'Completed\') ORDER BY CreatedDate DESC';
                    listOfFollowUps = Database.query(Querys);
                } else if (whatId.startsWithIgnoreCase('006')) {
                    opprec = [SELECT Id, Name FROM Opportunity WHERE Id = :whatId LIMIT 1];
                    Querys += ' WHERE Opportunity__c = \'' + String.escapeSingleQuotes(whatId) + '\'';
                    Querys += ' AND Status__c NOT IN (\'Completed\') ORDER BY CreatedDate DESC';
                    listOfFollowUps = Database.query(Querys);
                }
            }

            if(listOfFollowUps.size() > 0){
                return 'Please Complete the previous Follow-Up before creating a new one.';
            }
            
            String query = 'SELECT Id FROM Follow_Up__c WHERE Status__c != \'Completed\' ';
            query += (whatId != null) ? (whatId.startsWithIgnoreCase('00Q') ? 'AND Lead__c = \'' + whatId + '\' ' : 'AND Opportunity__c = \'' + whatId + '\' ') : '';
            
            query += 'ORDER BY CreatedDate DESC';
            
            List<Follow_Up__c> followUpRec = Database.query(query);
            
            if(!followUpRec.isEmpty()){
                return 'Please Complete the Recent the Follow-Up';
            }
            if (FollowUpDateTime != null) {
                Follow_Up__c newEvent = new Follow_Up__c(
                    //Due_Date__c = Date.valueOf(DueDateTime),
                    Follow_Up_Date__c = FollowUpDateTime,
                    Status__c = Status
                );
                
                if (String.isNotBlank(whatId)) {
                    if (whatId.startsWithIgnoreCase('006')) {
                        newEvent.Opportunity__c = whatId;
                    } else if (whatId.startsWithIgnoreCase('00Q')) {
                        newEvent.Lead__c = whatId;
                    }
                }
                
                if (leadrec != null) {
                    newEvent.Name = leadrec.Name + ' - Follow-Up';
                } else if (opprec != null) {
                    newEvent.Name = opprec.Name + ' - Follow-Up';
                } else {
                    newEvent.Name = 'Test Drive';
                }
                
                insert newEvent;

                if (whatId.startsWithIgnoreCase('006')) {
                    Opportunity opp = new Opportunity();
                    opp.StageName = 'Decision Pending/ Follow-Up';
                    opp.Id = whatId;
                    update opp;
                } else if (whatId.startsWithIgnoreCase('00Q')) {
                    Lead led = new lead();
                    led.Id = whatId;
                    led.Status = 'Follow Up';
                    update led;
                }

                System.debug('Event successfully created =====> ' + newEvent.Id);
            }
            return 'Event Scheduled Successfully';
        } catch (Exception e) {
            System.debug('Error message ====>' + e.getMessage() + ' at Line number ====>' + e.getLineNumber());
            return e.getMessage();
        }
    }

    public static void createNewFollowUpIfTheNextFollowUpIsNotNullOrChanged(List<Follow_Up__c> newListFollowUp, Map<Id, Follow_Up__c> oldFollowUp){
        try{
            List<Follow_Up__c> newFollowUpListToBeInserted = new List<Follow_Up__c>();
            List<Follow_Up__c> oldFollowUpToBeUpdated = new List<Follow_Up__c>();
            CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Avalailable_Qunatity_is_Zero'];
            for(Follow_Up__c followUprec : newListFollowUp){
                if(followUprec.Next_Follow_Up_Date__c != null && oldFollowUp.containsKey(followUprec.Id) && oldFollowUp.get(followUprec.Id).Next_Follow_Up_Date__c != followUprec.Next_Follow_Up_Date__c){
                    Follow_Up__c newFollowUp = new Follow_Up__c(
                        Due_Date__c = Date.ValueOf(followUprec.Next_Follow_Up_Date__c),
                        Follow_Up_Date__c = followUprec.Next_Follow_Up_Date__c,
                        OwnerId = followUprec.OwnerId,
                        Status__c = 'New',
                        Name = followUprec.Name
                    );
                    if(followUprec.Opportunity__c != null){
                        newFollowUp.Opportunity__c = followUprec.Opportunity__c;
                    }
                    if(followUprec.Lead__c != null){
                        newFollowUp.Lead__c = followUprec.Lead__c;
                    }
                    newFollowUpListToBeInserted.add(newFollowUp);
                    Follow_Up__c oldFollowUps = new Follow_Up__c(
                        Id = followUprec.Id,
                        Status__c = 'Completed'
                    );
                    oldFollowUpToBeUpdated.add(oldFollowUps);
                }
            }

            if(!oldFollowUpToBeUpdated.isEmpty()){
                update oldFollowUpToBeUpdated;   
            }
            if(!newFollowUpListToBeInserted.isEmpty()){
                insert newFollowUpListToBeInserted;   
                for(Follow_Up__c followUpre : newFollowUpListToBeInserted){
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('New Follow-Up is Created');
                    customNotificationObj.setTitle('Follow-Up !!');
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(UserInfo.getUserId());
                    customNotificationObj.setTargetId(followUpre.Id);
                    customNotificationObj.send(new Set<String> {followUpre.OwnerId});
                }
            }
            
        }catch(Exception e){
            System.debug('Error ============> ' + e.getMessage() + ' at line number ============>' + e.getLineNumber() + ' Cause ============> ' + e.getCause() );
        }
    }

    public static void deleteOldNotCompletedFollowUp(List<Follow_Up__c> newListFollowUp){
        try{
            set<Id> setOfoppId = new set<Id>();
            set<Id> setOfTestDriveId = new set<Id>();
            for(Follow_Up__c followUpRec : newListFollowUp){
                if(followUpRec.Opportunity__c != null){
                    setOfoppId.add(followUpRec.Opportunity__c);
                    setOfTestDriveId.add(followUpRec.Id);
                }
            }
            if(!setOfoppId.isEmpty()){
                List<Follow_Up__c> listOfOldFollowUpWhichIsNotCompeleted = [Select Id from Follow_Up__c Where Id NOT IN: setOfTestDriveId AND Opportunity__c IN: setOfoppId AND Status__c != 'Completed'];
                delete listOfOldFollowUpWhichIsNotCompeleted;
            }
        }catch(Exception e){
            System.debug('Error ============> ' + e.getMessage() + ' at line number ============>' + e.getLineNumber() + ' Cause ============> ' + e.getCause() );
        }
        
    }

    public static void assignSameOwnerOfLeadAndOppToTestDriveOwner(List<Follow_Up__c> newListFollowUp) {
        Set<Id> setOfLeadId = new Set<Id>();
        Set<Id> setOfOppId = new Set<Id>();

        for (Follow_Up__c followUprec : newListFollowUp) {
            if (followUprec.Lead__c != null) {
                setOfLeadId.add(followUprec.Lead__c);
            }
            if (followUprec.Opportunity__c != null) {
                setOfOppId.add(followUprec.Opportunity__c);
            }
        }

        Map<Id, Id> mapOfLeadOwner = new Map<Id, Id>();
        Map<Id, Id> mapOfOppOwner = new Map<Id, Id>();

        for (Lead lead : [SELECT Id, OwnerId FROM Lead WHERE Id IN :setOfLeadId]) {
            mapOfLeadOwner.put(lead.Id, lead.OwnerId);
        }

        for (Opportunity opp : [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :setOfOppId]) {
            mapOfOppOwner.put(opp.Id, opp.OwnerId);
        }

        for (Follow_Up__c followUprec : newListFollowUp) {
            if (mapOfOppOwner.containsKey(followUprec.Opportunity__c)) {
                followUprec.OwnerId = mapOfOppOwner.get(followUprec.Opportunity__c);
            } else if (mapOfLeadOwner.containsKey(followUprec.Lead__c)) {
                followUprec.OwnerId = mapOfLeadOwner.get(followUprec.Lead__c);
            }
        }
    }
}