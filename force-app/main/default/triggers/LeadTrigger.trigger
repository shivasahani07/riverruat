/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 05-29-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger LeadTrigger on Lead (before Insert, after insert,after update,before update) {
    if(trigger.isafter && trigger.Isinsert){
        LeadTriggerHandler.callQueableMethodForNewLead(Trigger.new);
        String ApexClass = System.label.ApexClass;
        if(ApexClass == 'true'){
            LeadTriggerHandler.checkLeadStatus(trigger.new); 
            GenericRecordSharer.shareRecordsWithHierarchy(Trigger.NewMap, 'Lead', 'Read', 'Manual');
            // LeadTriggerHandler.handleLeadConversionAndTestDriveCreation(trigger.new); 
        }
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        LeadTriggerHandler.callQueableMethodForAfterUpdate(Trigger.new,Trigger.oldMap);
        LeadTriggerHandler.callQueueableAfterRNR(Trigger.new,Trigger.oldMap);
        String labelvalue = System.Label.Feedback_Lead;
        if(labelvalue == 'true'){
            FeedbackResponseController.generateFeedbackUrl(Trigger.new, Trigger.oldMap);
            FeedbackResponseController.sendWhatsAppMessageWithFeedbackUrl(Trigger.new, Trigger.oldMap);    
        }
        
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        System.debug('Lead Trigger Before Update');
        //LeadTriggerHandler.thresholdCallAttempt(Trigger.new,Trigger.oldMap);
        //LeadTriggerHandler.beforeConversionCheckAnyFollowIsOpendThenThrowError(Trigger.new,Trigger.oldMap);
        LeadTriggerHandler.phoneNumberValidation(Trigger.new);
        LeadTriggerHandler.updateLeadSourceForDMSUser(trigger.new, Trigger.oldMap);
    }
    if(Trigger.IsBefore && Trigger.IsInsert){
        LeadTriggerHandler.updatePreferredSeller(Trigger.new);
        LeadTriggerHandler.phoneNumberValidation(Trigger.new);
        LeadTriggerHandler.updateLeadSourceForDMSUser(trigger.new,trigger.oldMap);
    }
}