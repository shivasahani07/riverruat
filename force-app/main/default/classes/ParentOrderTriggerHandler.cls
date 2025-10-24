/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-16-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class ParentOrderTriggerHandler extends BasdeOrderTriggerHandler{
    public override void beforeInsert(){
        System.debug('Executing Before Insert Triggers');
        OrderTriggerHandler.maintainOrderCounter(Trigger.new);

    }
    public override void beforeUpdate(){
       
        System.debug('Executing Before Update Triggers');

        OrderTriggerHandler.maintainOrderCounter(Trigger.new);
        OrderTriggerHandler.paymentDueIsNotNull((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.moveStatusToPreInvoiceIfFullPaymentIsDoneAndVehicleIsDone((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.dontAllowUserToTagSameVehicleToMultipleOrders((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.thorwErrorIfBasicDetailsAreNull(Trigger.new);
        OrderTriggerHandler.throwErrorIfRemainingAmountIsMoreThanZero((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.NewRegistrationdate((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        // OrderTriggerHandler.NewDeliverydate(Trigger.new,Trigger.oldMap);
        OrderTriggerHandler.throwErrorIfRefundStatusIsCompletedAndAmountAndUTRAreNull((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.throwErrorIfCustomerApprovalIsNotThere((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.throwErrorIfInsuranceDetailsNotFilled((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.moveStageToRTOIfAllTheInsuranceDetailsIsFilled((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.updateOrderStatusAsOrderCancelledIfTheOrderRefundIfFilledAndRefundStatusIsCompleted((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.throwErrorIfVRNisMissingWhenStageIsReadyForDelivery((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.moveStageToInvoiceAndInsuranceIfCustomerApproves((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        GatePassQRController.checkAndGenerateQR((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);

    }
    public override void beforeDelete(){

        System.debug('Executing Before Delete Triggers');

        EnquiryRecordLock.PreventUpdateForEnquiryStage(trigger.old);
        DMLLogger.logChanges(Trigger.oldMap, null, 'DELETE', 'Order');
    }
    public override void afterInsert(){
        System.debug('Executing After Insert Triggers');
        //OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new);
    }
    public override void afterUpdate(){
        System.debug('Executing After Update Triggers');
        OrderTriggerHandler.createTaskForOrderOwnerIfDueDateIsNotNull((List<Order>)Trigger.new,(Map<Id,Order>) Trigger.oldMap);
        OrderTriggerHandler.handleOrderUpdate((List<Order>)Trigger.new, (Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.createProductTransferForBackOrder((Map<Id,Order>)Trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        OrderTriggerHandler.afterUpdate((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        OrderTriggerHandler.sendWhatsAppAfterOrderCreation((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        form22Controller.handleOrderUpdate((List<Order>)Trigger.new, (Map<Id,Order>)Trigger.oldMap);
        // OrderTriggerHandler.sendPDFAfterRTO(Trigger.new,Trigger.oldMap);
        //OrderTriggerHandler.processOrderMilestones((List<Order>)Trigger.new,(Map<Id,Order>) Trigger.oldMap);
        //OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new);
        //added by Aniket on 05/03/2025 for Ew Integration
        //OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);

        List<Order> newOrders = (List<Order>)Trigger.new;
        Map<Id, Order> oldOrderMap = (Map<Id, Order>)Trigger.oldMap;

        for (Order o : newOrders) {
            Order oldOrder = oldOrderMap.get(o.Id);
            if (o.Status == 'Invoice and Insurance' && oldOrder.Status != 'Invoice and Insurance') {
                OrderTriggerHandler.sendPDFAfterRTO(newOrders, oldOrderMap);
                break; 
            }
        }
        // for (Order o : Trigger.new) {
        //     if (o.Status == 'Invoice and Insurance' && (Map<Id,Order>)Trigger.oldMap.get(o.Id).Status != 'Invoice and Insurance') {
        //         OrderTriggerHandler.sendPDFAfterRTO((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);
        //         //  OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);
        //         //OrderTriggerHandler.processOrderMilestones(Trigger.new, Trigger.oldMap);
        //         // OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);
        //         break; 
        //     }
        // }
        OrderInvoiceGenerationOTCController.eWAndRSACallout((List<Order>)Trigger.new, (Map<Id,Order>)Trigger.oldMap);//added by Aniket on 19/09/2025
        ExtendedWarrantyForVehicleOrder.punchOTCMethod((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);//added by Aniket on 19/09/2025
        SimActivationHandler.activateSim((List<Order>)Trigger.new,(Map<Id,Order>)Trigger.oldMap);//added by Aniket on 13/10/2025
    }
    public override void afterDelete(){
        System.debug('Executing After Delete Triggers');
    }
}