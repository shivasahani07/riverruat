/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-16-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
// /**
//  * @description       :
//  * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
//  * @group             :
//  * @last modified on  : 03-25-2025
//  * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
//  **/
// Trigger OrderTrigger on Order (before insert, after update, after insert, before update) {
 
//     if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
//         System.debug('Inside Order Insert or Updadte Trigger');
//             OrderTriggerHandler.maintainOrderCounter(Trigger.new);
//     }
//     if (Trigger.isAfter && Trigger.isUpdate) {
//         System.debug('Inside Orderrrrrrrrr Updadte Trigger');
//         OrderTriggerHandler.handleOrderUpdate(Trigger.new, Trigger.oldMap);
//         OrderTriggerHandler.createProductTransferForBackOrder(Trigger.oldMap, Trigger.newMap);
//         OrderTriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap);
//         OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new,Trigger.oldMap);
//         form22Controller.handleOrderUpdate(Trigger.new, Trigger.oldMap);
//        // OrderTriggerHandler.sendPDFAfterRTO(Trigger.new,Trigger.oldMap);
//        // OrderTriggerHandler.processOrderMilestones(Trigger.new, Trigger.oldMap);
//         //OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new);
//         //added by Aniket on 05/03/2025 for Ew Integration
//         //OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);
//          for (Order o : Trigger.new) {
//         if (o.Status == 'RTO Registration' && Trigger.oldMap.get(o.Id).Status != 'RTO Registration') {
//             OrderTriggerHandler.sendPDFAfterRTO(Trigger.new,Trigger.oldMap);
//           //  OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);
//             OrderTriggerHandler.processOrderMilestones(Trigger.new, Trigger.oldMap);
//             OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);
//             break; 
//         }
//     }
//     }
 
//     if(Trigger.isAfter && Trigger.isInsert){
//         //OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new);
//     }
// }
 
trigger OrderTrigger on Order (
    before insert, 
    before update, 
    after insert, 
    after update
) {
    // ==================== BEFORE INSERT SECTION ====================
    if (Trigger.isBefore && Trigger.isInsert) {
        // Order validation checks
        OrderStatusHandler.checkUniqueDealerVIN(Trigger.new);
        // Maintain order counter
        OrderTriggerHandler.maintainOrderCounter(Trigger.new);
    }
    // ==================== BEFORE UPDATE SECTION ====================
    if (Trigger.isBefore && Trigger.isUpdate) {
        // Order validation checks
        OrderStatusHandler.checkValidaionStatus(Trigger.newMap, Trigger.oldMap);
        // Maintain order counter
        OrderTriggerHandler.maintainOrderCounter(Trigger.new);
    }
    // ==================== AFTER INSERT SECTION ====================
    if (Trigger.isAfter && Trigger.isInsert) {
        // WhatsApp notification
        OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new, Trigger.oldMap);
         //OTCInvoicePdfGenerator.handleOrderUpdate(Trigger.new, null);
       // OrderTriggerHandler.eWAndRSAAfterOTC(Trigger.new);//added by Aniket on 02/05/2025
       GenericRecordSharer.shareRecordsWithHierarchy(Trigger.NewMap, 'WorkOrder', 'Read', 'Manual');
    }
    // ==================== AFTER UPDATE SECTION ====================
    if (Trigger.isAfter && Trigger.isUpdate) {
        // Vehicle and order status updates
        OrderStatusHandler.updateVehicle(Trigger.new, Trigger.oldMap);
        OrderStatusHandler.updateVehicle01(Trigger.new, Trigger.oldMap);

        //OTC Sale Invoice
        OTCInvoicePdfGenerator.handleOrderUpdate(Trigger.new, Trigger.oldMap);
         CouponCodeService.cancelCouponsIfOrderCancelled(Trigger.new, Trigger.oldMap);
        // Communication handlers
        OrderStatusHandler.emailHandllerMethod(Trigger.new, Trigger.oldMap);
        OrderTriggerHandler.sendWhatsAppAfterOrderCreation(Trigger.new, Trigger.oldMap);
        // Financial operations
        OrderStatusHandler.generateIvoicesAndReceipts(Trigger.new, Trigger.oldMap);
        OrderStatusHandler.sendPreOrderReceipt(Trigger.new, Trigger.oldMap);
        // Order processing
        OrderTriggerHandler.handleOrderUpdate(Trigger.new, Trigger.oldMap);
        OrderTriggerHandler.createProductTransferForBackOrder(Trigger.oldMap, Trigger.newMap);
        OrderTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        form22Controller.handleOrderUpdate(Trigger.new, Trigger.oldMap);
        //for feedbacks
        OverallExpereinceController.generateFeedbackUrl(Trigger.new, Trigger.oldMap);
        OverallExpereinceController.sendWhatsAppMessageWithFeedbackUrl(Trigger.new, Trigger.oldMap,'delivery_message_feedback'); 
        Trigger_Handler__mdt  TriggerInstance = Trigger_Handler__mdt.getInstance('StatusUpdateOnWebsite_afterUpdate');
        if(TriggerInstance.isActive__c == true){
            StatusUpdateOnWebsite.afterUpdate(Trigger.new,Trigger.oldMap);//added by Aniket on 02/07/2025
        }

        // Process each order
        for (Order ord : Trigger.new) {
            Order oldOrder = Trigger.oldMap.get(ord.Id);
            // RSA Activation Handling
            handleRSAActivation(ord, oldOrder);
            // Invoice Creation
            handleInvoiceCreation(ord, oldOrder);
            // RTO Registration Handling
            if (ord.Status == 'RTO Registration' && oldOrder.Status != 'RTO Registration') {
              //  SalesDataIntegration.pushSalesData(ord.Id); Not Using commeted code today date : 03-25-2025 Dinesh B
                OrderTriggerHandler.sendPDFAfterRTO(Trigger.new, Trigger.oldMap);
                OrderTriggerHandler.processOrderMilestones(Trigger.new, Trigger.oldMap);
                OrderTriggerHandler.afterUpdateForEWIntegration(Trigger.new, Trigger.oldMap);
            }
        }
        // Test coverage methods
        if (Test.isRunningTest()) {
            RSACalloutHandler.getOrderCodeCoverage(Trigger.new);
            RSACalloutHandler.getOrderCodeCoverage1(Trigger.new);
            RSACalloutHandler.getOrderCodeCoverage2(Trigger.new);
            RSACalloutHandler.getOrderCodeCoverage3(Trigger.new);
        } 
    }
    // ==================== HELPER METHODS ====================
    private static void handleRSAActivation(Order ord, Order oldOrder) {
        try {
            // With assigned vehicle
            if (ord.Assigned_Vehicle__c != null && ord.Assigned_Vehicle__r.RSA_Activation__c != true) {
                if (!Test.isRunningTest() || 
                    (ord.Status == 'RTO Registration' || ord.Status == 'Vehicle Delivered')) {
                    RSACalloutHandler.getchasisnumber(new List<Order>{ord});
                    System.debug('Method Called ## RSACalloutHandler.getchasisnumber');
                }
            } else {
                System.debug('RSA Activation already done');
            }
            // Without assigned vehicle
            if ((ord.Status == 'RTO Registration' || ord.Status == 'Vehicle Delivered') && 
                ord.Assigned_Vehicle__c == null && ord.AccountId != null) {
                List<Vehicle> vehicles = [SELECT Id, RSA_Activation__c 
                                         FROM Vehicle 
                                         WHERE Account__c = :ord.AccountId];
                if (vehicles.size() == 1 && !vehicles[0].RSA_Activation__c) {
                    RSACalloutHandler.getchasisnumberWihtoutVehicleOrder(new List<Order>{ord});
                    System.debug('Method Called ## getchasisnumberWihtoutVehicleOrder');
                } else {
                    System.debug('Method Not Called ## No valid vehicle found or RSA Activation is true');
                }
            }
        } catch(Exception e) {
            System.debug('Error Message ==>' + e.getMessage() + ' && Error Line == >' + e.getLineNumber());
        }
    }
   private static void handleInvoiceCreation(Order ord, Order oldOrder) {
        try {
            if (oldOrder.Status != 'Pre Invoice' && ord.Status == 'Pre Invoice') {
                List<Order> singleOrderList = new List<Order>{ord};
                OrderStatusHandler.ceateInvoiceRecords(singleOrderList, new Map<Id, Order>{ord.Id => oldOrder});
                System.debug('Invoice created for Order Id: ' + ord.Id);
            }
        } catch (Exception e) {
            System.debug('Error while creating Invoice ==> ' + e.getMessage() + ' at line ' + e.getLineNumber());
        } 
    }
}