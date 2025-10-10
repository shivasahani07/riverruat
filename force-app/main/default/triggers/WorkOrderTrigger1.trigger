/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 08-19-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger WorkOrderTrigger1 on WorkOrder (before insert, before update, after update, after Insert) {
    if (trigger.isAfter && trigger.isInsert) {
        WorkOrderTriggerHandler.handleNewJobCards(trigger.new);
        GenericRecordSharer.shareRecordsWithHierarchy(Trigger.NewMap, 'WorkOrder', 'Edit', 'Manual');
       
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        //code Added by Aniket on 14/02/2025
        Trigger_Handler__mdt  TriggerInstance = Trigger_Handler__mdt.getInstance('WorkOrderTriggerHandler_handleWorkPlanIn');
        if(TriggerInstance.isActive__c){
            WorkOrderTriggerHandler.PreventClosingifActionPlanIncomplete(Trigger.new, Trigger.oldMap);
        }
        
        Trigger_Handler__mdt workOrderHandler = 
            Trigger_Handler__mdt.getInstance('WorkOrderTriggerHandler_handleWorkPlanIn');
        
        // Check if this specific trigger handler is active
        
        
        Trigger_Handler__mdt  TriggerInstancee = Trigger_Handler__mdt.getInstance('WorkOrderTriggerHandler_handleWorkPlanIn');
        if(TriggerInstancee.isActive__c){
            WorkOrderTriggerHandler.PreventClosingifActionPlanIncomplete(Trigger.new, Trigger.oldMap);
        }
        
        WorkOrderTriggerHandler.ResetPDICheckAfterJobCardClosed(Trigger.new, Trigger.oldMap);
        WorkOrderTriggerHandler.updatePDIAfterCompetetion(Trigger.new,Trigger.oldMap); 
        
        //code Added by Sagar on 14/04/2025
        WorkOrderTriggerHandler.handleJobCardCompletion(Trigger.new,Trigger.oldMap);
        //WorkOrderTriggerHandler.JObCardStatusAfterUpdate(Trigger.new,Trigger.oldMap);  
        // Coded Added by Dinesh on 24/04/2025 - Approval Process fire when stauts is changed to cancellation requested
        WorkOrderTriggerHandler.sendApprovalonJCStausCancellationRequestedASM(Trigger.new, Trigger.oldMap);
        WorkOrderTriggerHandler.handleCompletedJobs(Trigger.new, Trigger.oldMap);
        //for Sending Feeback Form Link
        ServiceFeedbackController.generateFeedbackUrl(Trigger.new, Trigger.oldMap);
        ServiceFeedbackController.sendWhatsAppMessageWithFeedbackUrl(Trigger.new, Trigger.oldMap);
        //PSFController.generateFeedbackUrl(Trigger.new, Trigger.oldMap);
        //PSFController.sendWhatsAppMessageWithFeedbackUrl(Trigger.new, Trigger.oldMap);    
        //WorkOrderWhatsAppHandler.sendWhatsAppMsgMethod(Trigger.new, Trigger.oldMap);//added by Aniket on 17/06/2025
        //
        InvoicePDFLinkOnJobCard.afterUpdate(Trigger.new,Trigger.oldMap);
        
        //added by Ram 06/10/2025
        JobCardHandler.createClaimAndClaimItemOnWorkOrderCompletion(Trigger.new, Trigger.oldMap);
    }
    
    //added by Ram 15/07/2025

	if (Trigger.isUpdate && Trigger.isBefore) {
        JobCardValidationHandler.validateJobCardStatus(Trigger.new, Trigger.oldMap);
    }
	
}