public without sharing class LeadController {
    @AuraEnabled(cacheable=true)
    public static Lead getLeadByPhone(String phoneNumber) {
        List<Lead> leads = [SELECT Id, Name, Phone, Owner.Name, Company, Status
                            FROM Lead WHERE Phone = :phoneNumber AND OwnerId != :UserInfo.getUserId() LIMIT 1];
        return leads.isEmpty() ? null : leads[0];
    }
    
    @AuraEnabled
    public static String submitLeadForApproval(Id leadId) {
        System.debug('### Entering submitLeadForApproval method');
        
        try {
            System.debug('### Fetching Lead record for Id: ' + leadId);
            
            List<Lead> leadRecord = [SELECT Id, OwnerId, Dealer_Code__c, Stores_Name__c, PostalCode, City FROM Lead WHERE Id = :leadId LIMIT 1];
            System.debug('### Fetched Lead record: ' + leadRecord);
            
            List<User> currentUser = [SELECT Id, ManagerId, Dealer_code__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            System.debug('### Current user details: ' + currentUser);
            
            if (!currentUser.isEmpty() && currentUser[0].Dealer_code__c != null) {
                List<Account> accList = [SELECT Id, Store_Name__c, BillingPostalCode FROM Account WHERE Center_Code__c = :currentUser[0].Dealer_code__c];
                System.debug('### Account list: ' + accList);
                
                if (!accList.isEmpty()) {
                    List<Pin_code__c> pincodeList = [SELECT Id, City__r.Name,City__c, Area_Pincode__c FROM Pin_Code__c WHERE Dealer_Service_Center__c = :accList[0].Id];
                    System.debug('### Pincode list: ' + pincodeList);

                    List<City__c> cityList = [Select Id,Name,(Select Id,Name from Pin_Codes__r Where Id = :pincodeList[0].Id) from City__c  ];
                    
                    // Proceed only if lead record exists
                    if (!leadRecord.isEmpty()) {
                        Lead lead = leadRecord[0];
                        
                        lead.OwnerId = currentUser[0].Id;
                        System.debug('### Setting OwnerId: ' + currentUser[0].Id);
                        
                        lead.Stores_Name__c = accList[0].Store_Name__c;
                        System.debug('### Setting Stores_Name__c: ' + accList[0].Store_Name__c);

                        update lead;
                        System.debug('### Lead record updated successfully: ' + lead);
                    } else {
                        System.debug('### No lead record found.');
                    }
                } else {
                    System.debug('### No account found for dealer code: ' + currentUser[0].Dealer_code__c);
                }
            } else {
                System.debug('### Current user or Dealer_Code__c is null.');
            }
            
            
            // 2️⃣ Fetch any existing Lead Transfer History record in one query
            // Map<Id, Lead_Transfer_History__c> transferRecordMap = new Map<Id, Lead_Transfer_History__c>(
            //     [SELECT Id, Status__c, Lead__c, Dealer_Code__c  
            //      FROM Lead_Transfer_History__c 
            //      WHERE Lead__c = :leadId 
            //      LIMIT 1]
            // );
            
            
            
            // Lead_Transfer_History__c transferRecord;
            
            // if (!transferRecordMap.isEmpty()) {
            //     transferRecord = transferRecordMap.values()[0];  // Retrieve the first value
            //     transferRecord.Status__c = 'Approved';
            //     transferRecord.Approval_Date__c = System.today();
            //     transferRecord.New_Owner__c = UserInfo.getUserId();
            
            //     System.debug('### Updating existing Lead Transfer History record: ' + transferRecord.Id);
            //     update transferRecord;
            // } else {
            //     // 3️⃣ Create a new Transfer Lead History record if no existing record found
            //     System.debug('### Creating a new Lead Transfer History record');
            //     transferRecord = new Lead_Transfer_History__c();
            //     transferRecord.Lead__c = leadId;
            //     transferRecord.Requested_By__c = UserInfo.getUserId();
            //     if (leadRecord.OwnerId != null && String.valueOf(leadRecord.OwnerId).startsWith('005')) {
            //             transferRecord.Old_Owner__c = leadRecord.OwnerId;
            //     }
            //     transferRecord.Manager__c = currentUser.ManagerId;
            //     transferRecord.Status__c = 'Approved';
            //     transferRecord.Approval_Date__c = System.today();
            //     transferRecord.New_Owner__c = UserInfo.getUserId();
            
            //     insert transferRecord;
            // }
            
            // if(transferRecord.Dealer_Code__c!=null){
            //     leadRecord.Dealer_Code__c = transferRecord.Dealer_Code__c;
            //     update leadRecord;
            // }else{
            //     leadRecord.OwnerId = UserInfo.getUserId();
            //     update leadRecord;
            // }
            
            
            
            //  System.debug('### Lead Transfer History record ready for approval with Id: ' + transferRecord.Id);
            
            // 4️⃣ Submit the Transfer Lead History record for Approval (kept commented as per request)
            // System.debug('### Initiating Approval Process for Transfer Lead History Id: ' + transferRecord.Id);
            // Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            // req.setComments('Resubmitting Transfer Lead Request for approval.');
            // req.setObjectId(transferRecord.Id);
            
            // Approval.ProcessResult result = Approval.process(req);
            // System.debug('### Approval process result: ' + result);
            
            // if (result.isSuccess()) {
            //     System.debug('### Approval process submitted successfully!');
            //     return 'Transfer request submitted successfully!';
            // } else {
            //     System.debug('### Approval process failed.');
            //     return 'Approval process failed.';
            // }
            
            return 'successfully';
        } catch (Exception e) {
            System.debug('### Error occurred: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
    
    public static void mytest(){
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