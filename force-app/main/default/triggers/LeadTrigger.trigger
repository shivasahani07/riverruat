trigger LeadTrigger on Lead (before Insert, after insert,after update,before update) {
    if(trigger.isafter && trigger.Isinsert){
        //LeadTriggerHandler.callQueableMethodForNewLead(Trigger.new);
        String ApexClass = System.label.ApexClass;
        if(ApexClass == 'true'){
            LeadTriggerHandler.enqueueLeadProcessing(trigger.new); 
            LeadTriggerHandler.callFutureLeadConversion(trigger.new);
            //LeadTriggerHandler.callFutureLeadConversion(trigger.new);
            // LeadTriggerHandler.createTaskUnderLeadIfLeadIsNotConverted(trigger.new);
             GenericRecordSharer.shareRecordsWithHierarchy(Trigger.NewMap, 'Lead', 'Edit', 'Manual');
        }
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        LeadTriggerHandler.callQueableMethodForAfterUpdate(Trigger.new,Trigger.oldMap);
        LeadTriggerHandler.callQueueableAfterRNR(Trigger.new,Trigger.oldMap);
        LeadTriggerHandler.assignLeadsTestDriveAndFollowUpToOppOwnerWhenLeadIsConverted(Trigger.new);    
    }

    if(Trigger.isBefore && Trigger.isUpdate){
        System.debug('Lead Trigger Before Update');
        //LeadTriggerHandler.thresholdCallAttempt(Trigger.new,Trigger.oldMap);
        //LeadTriggerHandler.beforeConversionCheckAnyFollowIsOpendThenThrowError(Trigger.new,Trigger.oldMap);
        LeadTriggerHandler.phoneNumberValidation(Trigger.new);
        LeadTriggerHandler.updateLeadSourceForDMSUser(trigger.new,Trigger.oldMap);
        LeadTriggerHandler.pincodeChangeMakeTheDealerMapping(trigger.new,Trigger.oldMap);
        LeadTriggerHandler.pincodeIsMandatory(Trigger.new);
        LeadTriggerHandler.checkForConversion(Trigger.new, Trigger.oldMap);
        if(!LeadTriggerHandler.isConverting) {
            LeadTriggerHandler.dontCreateDuplicateLead(Trigger.new);
        }
    }

    if(Trigger.IsBefore && Trigger.IsInsert){
        /*LeadTriggerHandler.updatePreferredSeller(Trigger.new);
        LeadTriggerHandler.phoneNumberValidation(Trigger.new);
        LeadTriggerHandler.updateLeadSourceForDMSUser(trigger.new,trigger.oldMap);
        LeadTriggerHandler.pincodeIsMandatory(Trigger.new);
        LeadTriggerHandler.OthersIsMandatoryIsSourceIsOther(Trigger.new);        
        LeadTriggerHandler.dontCreateDuplicateLead(Trigger.new);*/
    }
    
}