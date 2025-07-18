global class BatchOnWorkOrderVORCreation implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<String> partsSplit = system.label.ISVORTesting.split(',');
        String VORflag = partsSplit[0];
        String TestRecordId = partsSplit[1];
        if(VORflag == 'True'){
            return Database.getQueryLocator([ SELECT Id,CreatedDate,Is_VOR__c,Service_Center__c,Vehicle__c FROM WorkOrder WHERE Status != 'Completed' AND id =: TestRecordId  ]);
        }else{
            return Database.getQueryLocator([ SELECT Id,CreatedDate,Is_VOR__c,Service_Center__c,Vehicle__c,Status FROM WorkOrder WHERE Status NOT IN ('Completed','Cancellation Requested','Canceled') AND Is_VOR__c = true  ]);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        try{
            system.debug('scope === >'+scope);
            List<VOR__c> vorsToInsert = new List<VOR__c>();
            Map<Id, VOR__c> existingVORMap = new Map<Id, VOR__c>();
            Set<Id> workOrderIds = new Set<Id>();
            for (SObject sObj : scope) {
                WorkOrder wo = (WorkOrder) sObj;
                workOrderIds.add(wo.Id);
            }
            for (VOR__c vor : [ SELECT Id, Job_Card__c, VOR_Reason__c   FROM VOR__c  WHERE Job_Card__c IN :workOrderIds AND (VOR_Reason__c = '' OR VOR_Reason__c = null)  ]) {
                existingVORMap.put(vor.Job_Card__c, vor);
            }
            for (SObject sObj : scope) {
                WorkOrder wo = (WorkOrder) sObj;
                if (!existingVORMap.containsKey(wo.Id)) {
                    VOR__c vor = new VOR__c();
                    vor.Job_Card__c = wo.Id;
                    vor.Service_Center__c = wo.Service_Center__c != null ? wo.Service_Center__c :null;
                    vor.Vehicle__c = wo.Vehicle__c != null ? wo.Vehicle__c :null;
                    vorsToInsert.add(vor);
                }else{
                    system.debug('Condition Not Matched to Create VOR & JC :'+wo.Id);
                }
            }
            if (!vorsToInsert.isEmpty()) {
                insert vorsToInsert;
                system.debug('vorsToInsert === >'+vorsToInsert);
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        system.debug('VOR Created Successfully !');
    }
}