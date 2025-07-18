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
        list<Lead> getlead=[select Id,Status from Lead where Id IN :idss ];
        list<lead> upleadlst=new list<lead>();
        for(lead l:getlead){
            l.Status='Follow Up';
            upleadlst.add(l);
        }
        update upleadlst;
    }
   /* public static void Limitfolwupsforlead(list<Follow_Up__c> newListFollowUp){
        string leadids;
        system.debug('enter'+newListFollowUp);
        for(Follow_Up__c f:newListFollowUp){
          leadids=f.Lead__c;
        }
        system.debug('id'+leadids);
        List<Lead> leadlst=[select id,(select Id from Follow_Ups__r) from Lead where Id =:leadids];
        for(Lead L:leadlst){
                        system.debug('size'+l.Follow_Ups__r);
            system.debug('size'+l.Follow_Ups__r.size());
            if(l.Follow_Ups__r.size()>2){
                l.addError('Lead Has Contain 3 Followups');
            }
        }
    }*/
        public static void previousfeedback(list<Follow_Up__c> newListFollowUp){
            system.debug('enter previousfeedback');
            Map<Id,List<Follow_Up__c>> mapLead = new Map<Id,List<Follow_Up__c>>();
            Set<Id> setLeadId = new Set<Id>();
            for(Follow_Up__c objFollow : newListFollowUp){
                setLeadId.add(objFollow.Lead__c);
            }
            List<Follow_Up__c> lstFollow = [SELECT Id,Feedback__c,Follow_Up_Date__c,CreatedDate, Lead__c,Previous_Feedback__c,Previous_Followup_date__c  FROM Follow_Up__c WHERE Lead__c IN: setLeadId ORDER BY CreatedDate DESC limit 1];
            for(Follow_Up__c objFollow : newListFollowUp){
                for(Follow_Up__c oldfolowup : lstFollow){
                    system.debug('ggggg'+oldfolowup.Follow_Up_Date__c);
                    objFollow.Previous_Followup_date__c=oldfolowup.Follow_Up_Date__c;
                   // objFollow.Previous_Feedback__c=oldfolowup.Feedback__c;
                }
                
            }
        }   
    /*public static void previousfeedbackInsert(list<Follow_Up__c> newListFollowUp){
            system.debug('enter previousfeedback');
            Map<Id,List<Follow_Up__c>> mapLead = new Map<Id,List<Follow_Up__c>>();
            Set<Id> setLeadId = new Set<Id>();
            for(Follow_Up__c objFollow : newListFollowUp){
                setLeadId.add(objFollow.Lead__c);
            }
            List<Follow_Up__c> lstFollow = [SELECT Id,Feedback__c,Follow_Up_Date__c,CreatedDate, Lead__c,Previous_Feedback__c,Previous_Followup_date__c  FROM Follow_Up__c WHERE Lead__c =: setLeadId ORDER BY CreatedDate DESC];
            for(Follow_Up__c objFollow : lstFollow){
                if(objFollow.Lead__c != null){
                    if(!mapLead.containsKey(objFollow.Lead__c)){
                        mapLead.put(objFollow.Lead__c, new List<Follow_Up__c>());
                    }   
                    mapLead.get(objFollow.Lead__c).add(objFollow);
                }
            }
            List<Follow_Up__c> lstFollowUpUpdate = new List<Follow_Up__c>();
            for(Follow_Up__c objFollow : newListFollowUp){
                if(mapLead.containsKey(objFollow.Lead__c)){
                    List<Follow_Up__c> lstFollowUpnew = mapLead.get(objFollow.Lead__c);
                    for(Follow_Up__c objFollowNew : lstFollowUpnew){
                        if(objFollow.CreatedDate > objFollowNew.CreatedDate){
                            objFollow.Previous_Feedback__c = objFollowNew.Feedback__c; 
                            objFollow.Previous_Followup_date__c  = objFollowNew.Follow_Up_Date__c ; 
                            break;
                        } 
                    }
                }
            }
        }   */
     public static void folowuptype(list<Follow_Up__c> newListFollowUp){
        string leadids;
        system.debug('enter'+newListFollowUp);
        for(Follow_Up__c f:newListFollowUp){
          leadids=f.Lead__c;
        }
        system.debug('id'+leadids);
        List<Lead> leadlst=[select id,(select Id from Follow_Ups__r) from Lead where Id =:leadids];
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


    @AuraEnabled
    public static String createFollowup(Map<String, Object> dateObj) {
        try {
            System.debug('Received dateObj: ' + JSON.serialize(dateObj));
            
            Date DueDateTime = null;
            Datetime FollowUpDateTime = null;
            String whatId = null;
            String Status = null;
            
            if (dateObj != null) {
                
                if (dateObj.containsKey('dueDate') && dateObj.get('dueDate') != null) {
                    String followUpDateString = String.valueOf(dateObj.get('dueDate')).replace('T', ' ').replace('Z', '');
                    DueDateTime = Date.valueOf(followUpDateString);
                }
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
            
            if (String.isNotBlank(whatId)) {
                if (whatId.startsWithIgnoreCase('00Q')) {
                    leadrec = [SELECT Id, Name FROM Lead WHERE Id = :whatId LIMIT 1];
                } else if (whatId.startsWithIgnoreCase('006')) {
                    opprec = [SELECT Id, Name FROM Opportunity WHERE Id = :whatId LIMIT 1];
                }
            }
            
            String query = 'SELECT Id FROM Follow_Up__c WHERE Status__c != \'Completed\' ';
            query += (whatId != null) ? (whatId.startsWithIgnoreCase('00Q') ? 'AND Lead__c = \'' + whatId + '\' ' : 'AND Opportunity__c = \'' + whatId + '\' ') : '';
            
            query += 'ORDER BY CreatedDate DESC';
            
            List<Follow_Up__c> followUpRec = Database.query(query);
			
            if(!followUpRec.isEmpty()){
                return 'Please Complete the Recent the Follow-Up';
            }
            if (DueDateTime != null && FollowUpDateTime != null) {
                Follow_Up__c newEvent = new Follow_Up__c(
                    Due_Date__c = Date.valueOf(DueDateTime),
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
                System.debug('Event successfully created =====> ' + newEvent.Id);
            }
            return 'Event Scheduled Successfully';
        } catch (Exception e) {
            System.debug('Error message ====>' + e.getMessage() + ' at Line number ====>' + e.getLineNumber());
            return e.getMessage();
        }
    }

    
    }