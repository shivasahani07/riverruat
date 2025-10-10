/**
* @description       :
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             :
* @last modified on  : 03-18-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
Trigger OrderTrigger on Order (before insert, after update, after insert, before update,before delete) {
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        System.debug('Inside Order Insert or Updadte Trigger');
        OrderTriggerHandler.maintainOrderCounter(Trigger.new);
        //EnquiryRecordLock.PreventUpdateForEnquiryStage(trigger.new);
    }
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        OrderTriggerHandler.paymentDueIsNotNull(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.moveStatusToPreInvoiceIfFullPaymentIsDoneAndVehicleIsDone(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.dontAllowUserToTagSameVehicleToMultipleOrders(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.thorwErrorIfBasicDetailsAreNull(Trigger.new);
        OrderTriggerHandler.throwErrorIfRemainingAmountIsMoreThanZero(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.NewRegistrationdate(Trigger.new,Trigger.oldMap);
        // OrderTriggerHandler.NewDeliverydate(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.throwErrorIfRefundStatusIsCompletedAndAmountAndUTRAreNull(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.throwErrorIfCustomerApprovalIsNotThere(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.throwErrorIfInsuranceDetailsNotFilled(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.moveStageToRTOIfAllTheInsuranceDetailsIsFilled(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.updateOrderStatusAsOrderCancelledIfTheOrderRefundIfFilledAndRefundStatusIsCompleted(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.throwErrorIfVRNisMissingWhenStageIsReadyForDelivery(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.moveStageToInvoiceAndInsuranceIfCustomerApproves(Trigger.new,Trigger.oldMap);
        GatePassQRController.checkAndGenerateQR(Trigger.new,Trigger.oldMap);
    }

    if(Trigger.isBefore && Trigger.isdelete){
        EnquiryRecordLock.PreventUpdateForEnquiryStage(trigger.old);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        System.debug('Inside Orderrrrrrrrr Updadte Trigger');
        OrderTriggerHandler.createTaskForOrderOwnerIfDueDateIsNotNull(Trigger.new, Trigger.oldMap);
        OrderTriggerHandler.handleOrderUpdate(Trigger.new, Trigger.oldMap);
        OrderTriggerHandler.createProductTransferForBackOrder(Trigger.oldMap, Trigger.newMap);
        OrderTriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new,Trigger.oldMap);
        form22Controller.handleOrderUpdate(Trigger.new, Trigger.oldMap);
        // OrderTriggerHandler.sendPDFAfterRTO(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.processOrderMilestones(Trigger.new, Trigger.oldMap);
        //OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new);
        //added by Aniket on 05/03/2025 for Ew Integration
        //OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);
        for (Order o : Trigger.new) {
            if (o.Status == 'Invoice and Insurance' && Trigger.oldMap.get(o.Id).Status != 'Invoice and Insurance') {
                OrderTriggerHandler.sendPDFAfterRTO(Trigger.new,Trigger.oldMap);
                //  OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);
                //OrderTriggerHandler.processOrderMilestones(Trigger.new, Trigger.oldMap);
                // OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);
                break; 
            }
        }
        OrderInvoiceGenerationOTCController.eWAndRSACallout(Trigger.new, Trigger.oldMap);//added by Aniket on 19/09/2025
        ExtendedWarrantyForVehicleOrder.punchOTCMethod(Trigger.new,Trigger.oldMap);//added by Aniket on 19/09/2025
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        //OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new);
    }
}