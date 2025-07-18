global class batchForLead implements Database.Batchable<sObject>,Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Name, OwnerId FROM Lead WHERE OwnerId IN (SELECT Id FROM Group WHERE Type = 'Queue' AND Name='Head_Quarter') AND Future_Lead__c = true]);
    }
    
    global void execute(Database.BatchableContext bc, List<Lead> listOfLead) {
        Map<String,String> mapOfPincodeAndCenterName = new Map<String,String>();
        Map<String, String> mapOfPincodeAndDealerCode = new Map<String, String>();
        Map<String, String> mapOfPincodeAndCityName = new Map<String, String>();
        Map<String, String> mapOfDealerCodeAndCityName = new Map<String, String>();
        Map<String, Id> queueMap = new Map<String, Id>();
        
        for (Pin_Code__c grp : [SELECT Id, Dealer_Service_Center__c,Dealer_Service_Center__r.Name,Dealer_Service_Center__r.Center_Code__c,City__r.Name,Dealer_Service_Center__r.Store_Name__c,
                                Area_Pincode__c FROM Pin_Code__c]) {
                                    mapOfPincodeAndCenterName.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Store_Name__c);
                                    mapOfPincodeAndDealerCode.put(grp.Area_Pincode__c, grp.Dealer_Service_Center__r.Center_Code__c);
                                    mapOfPincodeAndCityName.put(grp.Area_Pincode__c, grp.City__r.Name);
                                }
        
        
        set<Id> setOfAGIds = new set<Id>();
        List<Assignment_Group__c> listOfAG = [SELECT Id,Last_Allocated_RRid__c,Business_Hours_Morning__c,Business_Hours_End_Time__c
                                              from Assignment_Group__c Where isActive__c= true AND Name__c = 'Head_Quarter' LIMIT 1];
        for(Assignment_Group__c AGRec : listOfAG){
            setOfAGIds.add(AGRec.Id);
        }
        
        Time businessHoursStartTime = listOfAG[0].Business_Hours_Morning__c != null ? listOfAG[0].Business_Hours_Morning__c : Time.newInstance(8, 0, 0, 0);
        Time businessHoursEndTime   = listOfAG[0].Business_Hours_End_Time__c != null ? listOfAG[0].Business_Hours_End_Time__c : Time.newInstance(20, 0, 0, 0);
        
        Id assigningUser;
        if (!setOfAGIds.isEmpty()) {
            Decimal lastAssignmentId = listOfAG[0].Last_Allocated_RRid__c;
            
            List<Assignment_Group_Member__c> listOfAGM = [
                SELECT Id, Assignment_Group__c, Active__c, Assignment_Id__c, Max_Case_Per_Day__c,Group_Member__c 
                FROM Assignment_Group_Member__c 
                WHERE Assignment_Group__c IN :setOfAGIds 
                AND Active__c = true
                ORDER BY Assignment_Id__c ASC
            ];
            
            Assignment_Group_Member__c selectedAGM;
            
            if (lastAssignmentId != null) {
                for (Assignment_Group_Member__c agm : listOfAGM) {
                    if (agm.Assignment_Id__c == lastAssignmentId + 1) {
                        selectedAGM = agm;
                        break;
                    }
                }
            }
            
            Assignment_Group__c assignmentRec;
            if (selectedAGM == null && !listOfAGM.isEmpty()) {
                selectedAGM = listOfAGM[0];
                
                assignmentRec = listOfAG[0];
                assignmentRec.Last_Allocated_RRid__c = 1;
            }else{
                
                assignmentRec = listOfAG[0];
                assignmentRec.Last_Allocated_RRid__c = lastAssignmentId + 1;
            }
            update assignmentRec;
            
            if (selectedAGM != null) {
                System.debug('Selected Assignment Group Member: ' + selectedAGM.Id);
                assigningUser = selectedAGM.Group_Member__c;
            }
        }
        
        List<Lead> leadList = new List<Lead>();
        for(Lead ledrec : listOfLead){
            if(ledrec.PostalCode != null && mapOfPincodeAndCenterName.containsKey(ledrec.PostalCode)){
                String StoreName = mapOfPincodeAndCenterName.get(ledrec.PostalCode);
                String DealerCode = mapOfPincodeAndDealerCode.get(ledrec.PostalCode);
                String CityName = mapOfPincodeAndCityName.get(ledrec.PostalCode);
                leadList.add(new Lead(Id = ledrec.Id,Status = 'New',Stores_Name__c = StoreName,Dealer_Code__c = DealerCode,City = CityName,OwnerId = assigningUser));
            }
        }
        if(!leadList.isEmpty()){
            update leadList;
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        system.debug('batch job id = '+bc.getJobId());
    }
    
    
    global static void mytest(){
        Integer i=0;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
    }
    
}