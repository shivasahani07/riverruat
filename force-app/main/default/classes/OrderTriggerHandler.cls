/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 03-18-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class OrderTriggerHandler {
    
    public static final Id vehicleRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
    private static Boolean isExecuted = false;

    public static void thorwErrorIfBasicDetailsAreNull(List<Order> newOrders) {
        try {
            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordTypeId) {
                    if (ord.Status == 'Payment and Allocation') {

                        if (ord.Occupation__c == null) {
                            ord.Occupation__c.addError('Occupation is required.');
                        }
                        if (ord.Account_email__c == null) {
                            ord.Account_email__c.addError('Email is required.');
                        }
                        if (ord.Gender__c == null) {
                            ord.Gender__c.addError('Gender is required.');
                        }
                        if (ord.BillingStreet == null) {
                            ord.BillingStreet.addError('Billing Street is required.');
                        }
                        if (ord.BillingCity == null) {
                            ord.BillingCity.addError('Billing City is required.');
                        }
                        // if (ord.BillingState == null) {
                        //     ord.BillingState.addError('Billing State is required.');
                        // }
                        if (ord.BillingPostalCode == null) {
                            ord.BillingPostalCode.addError('Billing Postal Code is required.');
                        }
                        // if (ord.BillingCountry == null) {
                        //     ord.BillingCountry.addError('Billing Country is required.');
                        // }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    public static void moveStageToInvoiceAndInsuranceIfCustomerApproves(List<Order> newOrders, Map<Id, Order> oldOrderMap){
        try {
            for (Order ord : newOrders) {
                if(ord.Customer_Approval__c == 'Yes' && ord.Customer_Approval__c != oldOrderMap.get(ord.Id).Customer_Approval__c){
                    ord.Status = 'Invoice and Insurance';
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }
    
    public static void paymentDueIsNotNull(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordTypeId) {
                    if ((ord.Payment_Due_Date__c != null && oldOrderMap.get(ord.Id).Payment_Due_Date__c != ord.Payment_Due_Date__c) || 
                        (oldOrderMap.get(ord.Id).Payment_And_Allocation_Stage__c != ord.Payment_And_Allocation_Stage__c && ord.Payment_And_Allocation_Stage__c == true)) {
                        ord.Status = 'Payment and Allocation';
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    public static void moveStatusToPreInvoiceIfFullPaymentIsDoneAndVehicleIsDone(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
    System.debug('Entered moveStatusToPreInvoiceIfFullPaymentIsDoneAndVehicleIsDone');
    try {
        System.debug('newOrders size: ' + (newOrders != null ? newOrders.size() : 0));
        System.debug('oldOrderMap size: ' + (oldOrderMap != null ? oldOrderMap.size() : 0));

        for (Order ord : newOrders) {
            System.debug('------------------------------------------------------');
            System.debug('Processing Order Id: ' + ord.Id);
            System.debug('RecordTypeId: ' + ord.RecordTypeId);
            System.debug('Status: ' + ord.Status);
            System.debug('Assigned_Vehicle__c (new): ' + ord.Assigned_Vehicle__c);
            System.debug('Remaining_Amount__c (new): ' + ord.Remaining_Amount__c);

            Order oldOrder = oldOrderMap != null && oldOrderMap.containsKey(ord.Id) ? oldOrderMap.get(ord.Id) : null;
            if (oldOrder != null) {
                System.debug('Old Order found: ' + oldOrder.Id);
                System.debug('Assigned_Vehicle__c (old): ' + oldOrder.Assigned_Vehicle__c);
            } else {
                System.debug('Old Order record not found for this Id');
            }

            if (ord.RecordTypeId == vehicleRecordTypeId) {
                System.debug('RecordType matches vehicleRecordTypeId: ' + vehicleRecordTypeId);

                Boolean isStatusMatch = (ord.Status == 'Payment and Allocation');
                Boolean isVehicleNowAssigned = (ord.Assigned_Vehicle__c != null && oldOrder != null && oldOrder.Assigned_Vehicle__c == null);
                Boolean isPaymentComplete = (ord.Remaining_Amount__c != null && ord.Remaining_Amount__c == 0);

                System.debug('isStatusMatch (Status == Payment and Allocation): ' + isStatusMatch);
                System.debug('isVehicleNowAssigned (Vehicle newly assigned): ' + isVehicleNowAssigned);
                System.debug('isPaymentComplete (Remaining Amount = 0): ' + isPaymentComplete);

                if (isStatusMatch && isVehicleNowAssigned && isPaymentComplete) {
                    System.debug('✅ All conditions met for Order Id: ' + ord.Id);
                    System.debug('Before Update → Status: ' + ord.Status + ', Payment_status__c: ' + ord.Payment_status__c);

                    ord.Status = 'Pre Invoice';
                    ord.Payment_status__c = 'Completed';

                    System.debug('After Update → Status: ' + ord.Status + ', Payment_status__c: ' + ord.Payment_status__c);
                } else {
                    System.debug('❌ Conditions not met for Order Id: ' + ord.Id);
                    if (!isStatusMatch) System.debug('Reason: Status not "Payment and Allocation"');
                    if (!isVehicleNowAssigned) System.debug('Reason: Vehicle not newly assigned');
                    if (!isPaymentComplete) System.debug('Reason: Remaining amount not 0 or null');
                }
            } else {
                System.debug('Skipped Order Id: ' + ord.Id + ' as RecordTypeId does not match vehicleRecordTypeId');
            }
        }
        System.debug('Completed processing all Orders.');
    } catch (Exception e) {
        System.debug('Error in moveStatusToPreInvoiceIfFullPaymentIsDoneAndVehicleIsDone: ' + e.getMessage() + 
                     ' at line no: ' + e.getLineNumber() + 
                     ' Stack Trace: ' + e.getStackTraceString());
    }
}


    public static void dontAllowUserToTagSameVehicleToMultipleOrders(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            Set<Id> vehicleIds = new Set<Id>();
            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordTypeId && 
                    ord.Assigned_Vehicle__c != null && 
                    oldOrderMap.get(ord.Id).Assigned_Vehicle__c != ord.Assigned_Vehicle__c) {
                    vehicleIds.add(ord.Assigned_Vehicle__c);
                }
            }

            if (!vehicleIds.isEmpty()) {
                Map<Id, Id> vehicleIdToOrderId = new Map<Id, Id>();
                for (Order existingOrder : [SELECT Id, Assigned_Vehicle__c FROM Order WHERE Assigned_Vehicle__c IN :vehicleIds]) {
                    vehicleIdToOrderId.put(existingOrder.Assigned_Vehicle__c, existingOrder.Id);
                }

                for (Order ord : newOrders) {
                    if (ord.RecordTypeId == vehicleRecordTypeId && ord.Assigned_Vehicle__c != null && oldOrderMap.get(ord.Id).Assigned_Vehicle__c != ord.Assigned_Vehicle__c) {
                        if (vehicleIdToOrderId.containsKey(ord.Assigned_Vehicle__c) &&
                            vehicleIdToOrderId.get(ord.Assigned_Vehicle__c) != ord.Id) {
                            ord.Assigned_Vehicle__c.addError('This vehicle is already assigned to another order. Please select a different vehicle.');
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    public static void throwErrorIfCustomerApprovalIsNotThere(List<Order> newOrders, Map<Id, Order> oldOrderMap){
        try{
            for(Order ord : newOrders){
                if(ord.RecordTypeId == vehicleRecordTypeId && (ord.Customer_Approval__c == null || ord.Customer_Approval__c == '' || ord.Customer_Approval__c == 'No') && oldOrderMap.get(ord.Id).Status != ord.Status && ord.Status != null && ord.Status == 'Invoice and Insurance'){
                    ord.addError('Please obtain customer approval before proceeding to Invoice and Insurance.');
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    public static void moveStageToRTOIfAllTheInsuranceDetailsIsFilled(List<Order> newOrders, Map<Id, Order> oldOrderMap){
        try {
            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordTypeId && ord.Status == 'Invoice and Insurance') {
                    if(ord.Insurance_Type__c == 'In House' && (ord.Insurance__c != null && ord.Insurance_Amount__c != null && ord.Policy_Number__c != null )){
                        ord.Status = 'RTO Registration';
                    }
                    if (ord.Insurance_Type__c == 'Out House' && (ord.Other_Insurance_Provider_Name__c != null && ord.Insurance_Amount__c != null && ord.Policy_Number__c != null )) {
                        ord.Status = 'RTO Registration';
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    public static void throwErrorIfVRNisMissingWhenStageIsReadyForDelivery(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            Set<Id> vehicleIds = new Set<Id>();

            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordTypeId && ord.Status == 'Ready For Delivery' && oldOrderMap.get(ord.Id).Status != ord.Status && ord.Assigned_Vehicle__c != null) {
                    vehicleIds.add(ord.Assigned_Vehicle__c);
                }
            }

            if (!vehicleIds.isEmpty()) {
                Map<Id, Vehicle> vehicleMap = new Map<Id, Vehicle>([SELECT Id, VehicleRegistrationNumber FROM Vehicle WHERE Id IN :vehicleIds]);

                for (Order ord : newOrders) {
                    if (ord.RecordTypeId == vehicleRecordTypeId && ord.Status == 'Ready For Delivery' && oldOrderMap.get(ord.Id).Status != ord.Status && ord.Assigned_Vehicle__c != null) {
                        Vehicle v = vehicleMap.get(ord.Assigned_Vehicle__c);
                        if (v == null || String.isBlank(v.VehicleRegistrationNumber)) {
                            ord.addError('Please fill the Vehicle Registration Number on the assigned Vehicle before moving to Ready For Delivery.');
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    public static void throwErrorIfInsuranceDetailsNotFilled(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordTypeId && oldOrderMap.get(ord.Id).Status != ord.Status && ord.Status == 'RTO Registration') {
                    if (ord.Insurance_Type__c == null || ord.Insurance_Type__c == '') {
                        ord.Insurance_Type__c.addError('Please select Insurance Type.');
                    }

                    if (ord.Insurance_Type__c == 'In House') {
                        if (ord.Policy_Number__c == null) {
                            ord.Policy_Number__c.addError('Policy Number is required for In House type.');
                        }
                    }

                    if (ord.Insurance_Type__c == 'Out House') {
                        if (ord.Policy_Number__c == null) {
                            ord.Policy_Number__c.addError('Policy Number is required for Out House type.');
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }


    public static void createTaskForOrderOwnerIfDueDateIsNotNull(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            List<Task> taskList = new List<Task>();
            Set<Id> orderIds = new Set<Id>();

            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordTypeId) {
                    if (ord.Status == 'Payment and Allocation' && oldOrderMap.get(ord.Id).Payment_Due_Date__c != ord.Payment_Due_Date__c && ord.Payment_Due_Date__c != null && ord.Remaining_Amount__c != null && ord.Remaining_Amount__c >= 0) {
                            orderIds.add(ord.Id);
                    }
                }
            }

            if (!orderIds.isEmpty()) {
                Map<Id, Task> latestTaskMap = new Map<Id, Task>();
                for (Task t : [SELECT Id, WhatId, Status, CreatedDate FROM Task WHERE WhatId IN :orderIds AND Status != 'Completed' ORDER BY CreatedDate DESC]) {
                    if (!latestTaskMap.containsKey(t.WhatId)) {
                        latestTaskMap.put(t.WhatId, t);
                    }
                }

                for (Order ord : newOrders) {
                    if (orderIds.contains(ord.Id)) {
                        Task latestTask = latestTaskMap.get(ord.Id);
                        if (latestTask == null) {
                            Task task = new Task();
                            task.Subject = 'Call for Payment from Customer';
                            task.WhatId = ord.Id;
                            task.ActivityDate = ord.Payment_Due_Date__c;
                            task.OwnerId = ord.OwnerId;
                            task.Status = 'Not Started';
                            task.Priority = 'High';
                            taskList.add(task);
                        }
                    }
                }
            }

            if (!taskList.isEmpty()) {
                insert taskList;
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    
    public static void throwErrorIfRemainingAmountIsMoreThanZero(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        System.debug('### 1');
        try {
            for (Order ord : newOrders) {
                System.debug('### 2 Order Id: ' + ord.Id);
                if (ord.RecordTypeId == vehicleRecordTypeId ) {
                    System.debug('### 3 RecordType matched Vehicle');

                    if(ord.Remaining_Amount__c > 0 && ord.Status == 'Payment And Allocation' && ord.Payment_And_Allocation_Stage__c == true ){
                        ord.Payment_And_Allocation_Stage__c.addError('You cannot make this true if the full payment is not done.Please Fill the Payment Due Date or else make full payment');
                    }

                    if (ord.Insurance_Type__c == null && ord.Status == 'Pre Invoice') {
                        System.debug('### 4 Insurance_Type__c is null and Status = Pre Invoice');
                        ord.Insurance_Type__c.addError('Please Select Insurance Type.');
                    }

                    if((ord.Status == 'Booking' || ord.Status == 'Payment and Allocation') && ord.Customer_Approval__c != null){
                        ord.addError('You Cannot make customer Approval');
                    }   

                    if (ord.Insurance_Type__c != null && ord.Status == 'Pre Invoice') {
                        System.debug('### 5 Insurance_Type__c not null and Status = Pre Invoice, Value: ' + ord.Insurance_Type__c);

                        if (ord.Insurance_Type__c == 'In House') {
                            System.debug('### 6 Inside In House');
                            if (ord.Insurance__c == null) {
                                System.debug('### 7 Insurance__c null');
                                ord.Insurance__c.addError('Insurance is required for In House type.');
                            }
                            if (ord.Insurance_Amount__c == null) {
                                System.debug('### 8 Insurance_Amount__c null');
                                ord.Insurance_Amount__c.addError('Insurance Amount is required for In House type.');
                            }
                            if(ord.Policy_Number__c != null){
                                ord.Policy_Number__c.addError('Please Fill Policy Number at Invoice And Insurance Stage.');
                            }
                        }

                        if (ord.Insurance_Type__c == 'Out House') {
                            System.debug('### 9 Inside Out House');
                            if (ord.Other_Insurance_Provider_Name__c == null) {
                                System.debug('### 10 Other_Insurance_Provider_Name__c null');
                                ord.Other_Insurance_Provider_Name__c.addError('Other Insurance Provider Name is required for Out House type.');
                            }
                            if (ord.Insurance_Amount__c == null) {
                                System.debug('### 11 Insurance_Amount__c null');
                                ord.Insurance_Amount__c.addError('Insurance Amount is required for Out House type.');
                            }
                            if(ord.Policy_Number__c != null){
                                ord.Policy_Number__c.addError('Please Fill Policy Number at Invoice And Insurance Stage.');
                            }
                        }
                    }

                    if (ord.Finance__c != null && ord.Status == 'Pre Invoice') {
                        System.debug('### 12 Finance not null and Status = Pre Invoice');

                        if (ord.EMI_Amount__c == null) {
                            System.debug('### 13 EMI_Amount__c null');
                            ord.EMI_Amount__c.addError('Please enter EMI Amount before moving to Pre Invoice.');
                        }
                        if (ord.Tenure__c == null) {
                            System.debug('### 14 Tenure__c null');
                            ord.Tenure__c.addError('Please enter Tenure before moving to Pre Invoice.');
                        }
                        if (ord.Tenure_Type__c == null) {
                            System.debug('### 15 Tenure_Type__c null');
                            ord.Tenure_Type__c.addError('Please select Tenure Type before moving to Pre Invoice.');
                        }
                        if (ord.Financed_Amount__c == null) {
                            System.debug('### 16 Financed_Amount__c null');
                            ord.Financed_Amount__c.addError('Please enter Financed Amount before moving to Pre Invoice.');
                        }
                        if (ord.Delivery_Order_Obtained__c == false) {
                            System.debug('### 17 Delivery_Order_Obtained__c false');
                            ord.Delivery_Order_Obtained__c.addError('Please Check Delivery Obtained before moving to Pre Invoice.');
                        }
                        if (ord.Loan_Start_Date__c == null) {
                            System.debug('### 18 Loan_Start_Date__c null');
                            ord.Loan_Start_Date__c.addError('Please enter Loan Start Date before moving to Pre Invoice.');
                        }
                    }

                    if (ord.Remaining_Amount__c > 0 && ord.Vehicle_Assigned__c == false && ord.Assigned_Vehicle__c != null && (ord.Status == 'Pre Invoice' || ord.Status == 'Payment and Allocation')) {
                        System.debug('### 19 Remaining_Amount__c > 0 and Vehicle_Assigned__c = false and Assigned_Vehicle__c not null');
                        ord.addError('Cannot allot the vehicle until full payment is done.');
                    }

                    if (ord.Remaining_Amount__c == 0 && ord.Assigned_Vehicle__c == null && ord.Status == 'Pre Invoice') {
                        System.debug('### 20 Remaining_Amount__c == 0, Assigned_Vehicle__c null, Status = Pre Invoice');
                        ord.addError('Please assign the vehicle before marking status as Pre Invoice.');
                    }

                    if(ord.Remaining_Amount__c > 0 && ord.Vehicle_Assigned__c == true && ord.Status == 'Pre Invoice'){
                        ord.addError('Please Make the Full Payment');
                    }

                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    public static void sendWhatsaapMessageToCustomer(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            System.debug('Inside sendWhatsaapMessageToCustomer');
            Set<Id> setOfAccountId = new Set<Id>();
            for(Order ord : newOrders){
                if(ord.AccountId != null){
                    setOfAccountId.add(ord.AccountId);
                }
            }
            map<Id,Account> accMap = new map<Id,Account>();
            if(!setOfAccountId.isEmpty()){
                 accMap = new Map<Id, Account>([SELECT Id, Phone FROM Account WHERE Id IN :setOfAccountId]);
            }
            WhatsappIntegration__c wConfig = WhatsappIntegration__c.getInstance('WhatsApp API');

            List<Id> bookingIds = new List<Id>();
            Map<Id, String> bookingPhoneMap = new Map<Id, String>();

            List<Id> preInvoiceIds = new List<Id>();
            Map<Id, String> preInvoicePhoneMap = new Map<Id, String>();

            List<Id> fullPaymentIds = new List<Id>();
            Map<Id, String> fullPaymentPhoneMap = new Map<Id, String>();

            List<Id> thanksIds = new List<Id>();
            Map<Id, String> thanksPhoneMap = new Map<Id, String>();

            List<Id> negativeAckIds = new List<Id>();
            Map<Id, String> negativeAckPhoneMap = new Map<Id, String>();

            for (Order ord : newOrders) {
                Order oldOrd = oldOrderMap.get(ord.Id);

                // if (ord.Status == 'Booking' && oldOrd == null) {
                //     bookingIds.add(ord.Id);
                //     bookingPhoneMap.put(ord.Id, accMap.get(ord.AccountId).phone);
                // }
                if (ord.Status == 'Pre Inovice' && oldOrd != null && ord.Status != oldOrd.Status) {
                    preInvoiceIds.add(ord.Id);
                    preInvoicePhoneMap.put(ord.Id, ord.Phone__c);
                }
                if (ord.Status == 'Payment and Allocation' && oldOrd != null 
                    && ord.Remaining_Amount__c != oldOrd.Remaining_Amount__c && ord.Remaining_Amount__c == 0) {
                    fullPaymentIds.add(ord.Id);
                    fullPaymentPhoneMap.put(ord.Id, ord.Phone__c);
                }
                if (ord.Status == 'Pre Inovice' && oldOrd != null 
                    && ord.Customer_Approval__c != oldOrd.Customer_Approval__c && ord.Customer_Approval__c == 'Yes') {
                    thanksIds.add(ord.Id);
                    thanksPhoneMap.put(ord.Id, ord.Phone__c);
                }
                if (ord.Status == 'Pre Inovice' && oldOrd != null 
                    && ord.Customer_Approval__c != oldOrd.Customer_Approval__c && ord.Customer_Approval__c == 'No') {
                    negativeAckIds.add(ord.Id);
                    negativeAckPhoneMap.put(ord.Id, ord.Phone__c);
                }
            }
            if (!bookingIds.isEmpty()) {
                System.enqueueJob(new QueueableTempWithoutParams(bookingIds, 'booking_completed', bookingPhoneMap));
            }
            if (!preInvoiceIds.isEmpty()) {
                System.enqueueJob(new QueueableTempWithoutParams(preInvoiceIds, 'pre_invoice_communication_to_customer', preInvoicePhoneMap));
            }
            if (!fullPaymentIds.isEmpty()) {
                System.enqueueJob(new QueueableTempWithoutParams(fullPaymentIds, 'full_payment_completed', fullPaymentPhoneMap));
            }
            if (!thanksIds.isEmpty()) {
                System.enqueueJob(new QueueableTempWithoutParams(thanksIds, 'thanks_for_confirming', thanksPhoneMap));
            }
            if (!negativeAckIds.isEmpty()) {
                System.enqueueJob(new QueueableTempWithoutParams(negativeAckIds, 'acknowledgement_to_customer_on_negative_response', negativeAckPhoneMap));
            }

        } catch(Exception e) {
            System.debug('error message =======>' + e.getMessage() + ' at line number =======> '+ e.getLineNumber());
        }
    }


    
    public static void NewRegistrationdate(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            for (Order ord : newOrders) {
                if (ord.Status == 'RTO Registration' && ord.Status != oldOrderMap.get(ord.Id).Status) {
                    ord.Registration_Date__c = System.today();
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }
    
    public static void NewDeliverydate(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            for (Order ord : newOrders) {
                if (ord.Status == 'Vehicle Delivered' && ord.Status != oldOrderMap.get(ord.Id).Status) {
                    ord.Delivery_Date__c = System.today();
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    public static void updateOrderStatusAsOrderCancelledIfTheOrderRefundIfFilledAndRefundStatusIsCompleted(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordTypeId) {
                    if (ord.Refund_Status__c != null && ord.Refund_Status__c == 'Completed' && (ord.Refunded_UTR_Details__c != null && ord.Refunded_UTR_Details__c != '' && ord.Refund_Amount__c != null 
                        && ord.Refund_Amount__c != 0) && oldOrderMap.get(ord.Id).Refund_Status__c != ord.Refund_Status__c) {
                            ord.Status = 'Order Cancelled';
                            ord.Cancelled_Date__c = System.now();
                        }
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }

    public static void throwErrorIfRefundStatusIsCompletedAndAmountAndUTRAreNull(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        try {
            for (Order ord : newOrders) {
                if (ord.RecordTypeId == vehicleRecordTypeId) {
                    if (ord.Refund_Status__c != null && ord.Refund_Status__c == 'Completed' && (ord.Refunded_UTR_Details__c == null || ord.Refunded_UTR_Details__c == '' || ord.Refund_Amount__c == null 
                        || ord.Refund_Amount__c == 0) && oldOrderMap.get(ord.Id).Refund_Status__c != ord.Refund_Status__c) {
                            ord.addError('Please enter Refunded UTR Details before marking Refund Status as Completed And Refund Amount should be greater than 0');
                        }
                }
            }
        } catch (Exception e) {
            System.debug('Error in ======>: ' + e.getMessage() + ' at line no ======> ' + e.getLineNumber());
        }
    }
    
    // ===========================================================================================================================================
    
    public static void handleOrderUpdate(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        // Collect Orders where Status changed to 'Vehicle Delivered'
        try{       
            Set<Id> orderIdsToProcess = new Set<Id>();
            System.debug('oldOrderMap>>'+oldOrderMap);
            System.debug('newOrders>>'+newOrders);
            for (Order newOrder : newOrders) {
                Order oldOrder = oldOrderMap.get(newOrder.Id);
                if (newOrder.Status == 'Vehicle Delivered' && oldOrder.Status != 'Vehicle Delivered') {
                    orderIdsToProcess.add(newOrder.Id);
                    System.debug('oldOrder.Status>>'+oldOrder.Status);
                    System.debug('newOrder.Status>>'+newOrder.Status);
                }
            }
            if (orderIdsToProcess.isEmpty()) {
                return;
            }
            
            System.debug('orderIdsToProcess::::::::' + orderIdsToProcess); 
            
            createAssetsForOrders(orderIdsToProcess);
            
        } catch (Exception ex) {
            System.debug('Error in handleOrderUpdate: ' + ex.getMessage());
        }
    }
    
    private static void createAssetsForOrders(Set<Id> orderIds) {
        if (orderIds == null) {
            return;
        }
        
        try {
            List<OrderItem> orderItems = [
                SELECT Id, Product2Id, Product2.Name, OrderId, Order.AccountId, 
                Quantity, Total_Price__c, Order.Assigned_Vehicle__c, 
                Order.Assigned_Vehicle__r.VehicleIdentificationNumber, Order.Assigned_Vehicle__r.RR_Battery_Number__c, 
                Order.Assigned_Vehicle__r.EngineNumber,
                Order.Assigned_Vehicle__r.Purchased_Date__c
                FROM OrderItem
                WHERE OrderId IN :orderIds
            ];
            
            List<Asset> assetsToInsert = new List<Asset>();
            System.debug('orderItems>>'+orderItems);
            System.debug('orderItems.size>>'+orderItems.size());
            
            for (OrderItem oI : orderItems) {
                Asset asset = new Asset();
                asset.Name = oI.Product2.Name; 
                asset.Product2Id = oI.Product2Id; 
                asset.AccountId = oI.Order.AccountId;
                asset.Vehicle__c = oI.Order.Assigned_Vehicle__c; 
                //asset.SerialNumber = oI.OrderItemNumber; 
                asset.Status = 'Purchased'; 
                asset.Price = oI.Total_Price__c; 
                asset.Quantity = oI.Quantity; 
                asset.PurchaseDate = oI.Order.Assigned_Vehicle__r.Purchased_Date__c;
                asset.InstallDate = Date.today(); // need to ask what is the value here
                asset.Battery_Number__c = oI.Order.Assigned_Vehicle__r.RR_Battery_Number__c;
                asset.Vehicle_Identification_Number__c = oI.Order.Assigned_Vehicle__r.VehicleIdentificationNumber;
                asset.Motor_Number__c = oI.Order.Assigned_Vehicle__r.EngineNumber;
                
                assetsToInsert.add(asset);
            }
            
            if (!assetsToInsert.isEmpty()) {
                try {
                    insert assetsToInsert;
                } catch (DmlException ex) {
                    System.debug('Error while inserting Assets: ' + ex.getMessage());
                }
            }
            else {
                System.debug('No Assets to insert.');
            }
        } catch (Exception ex) {
            System.debug('Error in createAssetsForOrders: ' + ex.getMessage());
        }
    }
    
    public static void createProductTransferForBackOrder(Map<Id, Order> oldOrderMap, Map<Id, Order> newOrderMap) {
        // 1. product is taggerd, qs 
        
        //Id transferRecordTypeId = Schema.SObjectType.ProductTransfer.getRecordTypeInfosByName().get('Transfer').getRecordTypeId();
        List<ProductTransfer> transfersToCreate = new List<ProductTransfer>();
        
        Set<Id> orderIdsToProcess = new Set<Id>();
        Set<Id> purchaseOrderIds = new Set<Id>();
        Set<Id> product2Ids = new Set<Id>();
        Map<Id, Order> ordersToProcess = new Map<Id, Order>();
        
        // Collect necessary data
        for (Id orderId : newOrderMap.keySet()) {
            Order oldOrder = oldOrderMap.get(orderId);
            Order newOrder = newOrderMap.get(orderId);
            
            if (oldOrder.Status == 'Back Order' && newOrder.Status == 'Activated' && newOrder.Purchase_Order__c != null) {
                orderIdsToProcess.add(orderId);
                purchaseOrderIds.add(newOrder.Purchase_Order__c);
                ordersToProcess.put(orderId, newOrder);
            }
        }
        System.debug('purchaseOrderIds==>'+purchaseOrderIds);
        
        if (orderIdsToProcess.isEmpty()) {
            return; // Nothing to process
        }
        
        // Query Purchase Orders and their Line Items
        Map<Id, ProductRequest> purchaseOrderMap = new Map<Id, ProductRequest>([SELECT Id, DestinationLocationId, (SELECT Id, QuantityRequested, Product2Id FROM ProductRequestLineItems) FROM ProductRequest WHERE Id IN :purchaseOrderIds]);
        
        System.debug('purchaseOrderMap===>'+purchaseOrderMap);
        
        
        
        // Query Order Items
        Map<Id, List<OrderItem>> orderItemsMap = new Map<Id, List<OrderItem>>();
        for (OrderItem oi : [
            SELECT Id, Product2Id, Quantity, OrderId
            FROM OrderItem
            WHERE OrderId IN :orderIdsToProcess
        ]) {
            if (!orderItemsMap.containsKey(oi.OrderId)) {
                orderItemsMap.put(oi.OrderId, new List<OrderItem>());//for test 
            }
            orderItemsMap.get(oi.OrderId).add(oi);
            product2Ids.add(oi.Product2Id);
        }
        System.debug('Product2 Ids =='+product2Ids);
        
        Set<Id> destinationLocationIds = new Set<Id>();
        for (ProductRequest pr : purchaseOrderMap.values()) {
            if (pr.DestinationLocationId != null) {
                destinationLocationIds.add(pr.DestinationLocationId);
            }
        }
        
        Map<Id, ProductItem> productItemMap = new Map<Id, ProductItem>();
        for (ProductItem pi : [ SELECT Id, Product2Id, LocationId FROM ProductItem WHERE Product2Id IN :product2Ids AND LocationId IN :destinationLocationIds]) {
            productItemMap.put(pi.Product2Id, pi);
        }
        
        System.debug('orderItemsMap====>'+orderItemsMap);
        System.debug('purchaseOrderMap====>'+purchaseOrderMap);
        System.debug('productItemMap====>'+productItemMap);
        
        // Query Product Items (Product Inventory)
        //purchase ord=er is product request
        
        
        // Create Product Transfers
        for (Id orderId : ordersToProcess.keySet()) {
            Order newOrder = ordersToProcess.get(orderId);
            ProductRequest purchaseOrder = purchaseOrderMap.get(newOrder.Purchase_Order__c);
            List<OrderItem> orderItems = orderItemsMap.get(orderId);
            System.debug('orderItems::::'+orderItems);
            
            if (purchaseOrder != null && orderItems != null) {
                for (OrderItem oi : orderItems) {
                    if (productItemMap.containsKey(oi.Product2Id)) {
                        ProductItem matchingProductItem = productItemMap.get(oi.Product2Id);
                        System.debug('matchingProductItem::::'+ matchingProductItem);
                        
                        ProductTransfer pt = new ProductTransfer();
                        pt.Product2Id = oi.Product2Id;
                        pt.Order__c = orderId;
                        //pt.RecordTypeId = transferRecordTypeId;
                        pt.Order_Product__c = oi.Id;
                        pt.QuantitySent = oi.Quantity;
                        pt.QuantityReceived = 0;
                        pt.Driver_Phone__c = '0';
                        pt.LR_Number__c = '0';
                        pt.DestinationLocationId = purchaseOrder.DestinationLocationId;
                        pt.Product_Inventory__c = matchingProductItem.Id;
                        
                        // need to tag 2 things daily ledger and Shipment Item
                        transfersToCreate.add(pt);
                    }
                }
            }
        }
        
        // Insert Product Transfers
        if (!transfersToCreate.isEmpty()) {
            try {
                insert transfersToCreate;
            } catch (DmlException e) {
                System.debug('Error inserting Product Transfers: ' + e.getMessage());
            }
        }
    }
     
    public static void maintainOrderCounter(List<Order> orderList) {
        if (isExecuted) {
            System.debug('Method already executed, skipping execution');
            return; // Prevent multiple executions
        }
        
        isExecuted = true;
        OrderCounter__c counterSetting = OrderCounter__c.getInstance('Count');
        if (counterSetting == null) {
            System.debug('OrderCounter__c custom setting is not initialized');
            return;
        }
        
        Decimal baseCounter = counterSetting.Counter__c;
        Decimal counter = baseCounter;
        
        Set<Id> accountIds = new Set<Id>();
        Set<Id> dealerIds = new Set<Id>();
        
        for (Order ord : orderList) {
            accountIds.add(ord.AccountId);
            dealerIds.add(ord.Dealer__c);   
        }
        system.debug('accountIds == >'+accountIds+' && dealerIds == >'+dealerIds);
        Map<Id, Account> accountMap = new Map<Id, Account>( [SELECT Id, AccountSource, Center_Code__c FROM Account WHERE Id IN :accountIds] );
        Map<Id, Account> dealerMap = new Map<Id, Account>( [SELECT Id, Center_Code__c FROM Account WHERE Id IN :dealerIds] );
        system.debug('accountMap == >'+accountMap+' && dealerMap == >'+dealerMap);        
        for (Order ord : orderList) {
            Account acc = accountMap.get(ord.AccountId);
            //  Removed this condtion with Pratap consent :  if (acc != null && acc.AccountSource != 'River Website' && ord.Website_Order_Id__c==null) {
            if (acc != null &&  ord.Website_Order_Id__c==null) {
                System.debug('Counter before increment: ' + counter);
                counter++;
                System.debug('Counter after increment: ' + counter);
                String paddedCounter = String.valueOf(Integer.valueOf(counter));
                while (paddedCounter.length() < 5) {
                    paddedCounter = '0' + paddedCounter;
                }
                Account dealerAccount = dealerMap.get(ord.Dealer__c);
                if (dealerAccount != null) {
                    String centerCode = dealerAccount.Center_Code__c;
                    ord.Website_Order_Id__c = 'SB' + centerCode + DateTime.now().format('MMYYYY') + paddedCounter;
                    System.debug('Website_Order_Id__c: ' + ord.Website_Order_Id__c);
                }
            }else{
                system.debug('condition matached : Website_Order_Id__c ');
            }
        }
        counterSetting.Counter__c = counter;
        update counterSetting;
    }
    
    //code added by Aniket on 27/01/2025 for WhatsApp Integration
    public static void afterUpdate(List<Order> newOrderList,Map<Id,Order> oldOrderMap){
        try{
            System.debug('Inside WhatsApp Integration After Update');
            //dataSetForAllotmentIn Process
            List<Id> orderIdsToProcessWhenAllotment = new List<Id>();
            Map<Id,String> orderByPhoneMapWhenAllotment = new Map<Id,String>();
            String templateNameForAllotment='fullpayment_done';
            
            List<WhatsappIntegration__c> ws1 = WhatsappIntegration__c.getAll().values();
            WhatsappIntegration__c w1 = WhatsappIntegration__c.getInstance('WhatsApp API');
            String imageForAllotment;
            if(w1 != null){
                imageForAllotment = w1.fullpayment_done__c;
            }else{
                System.debug('w1 Null values come==>');
            }
            
            System.debug('imageForAllotment==>'+imageForAllotment);
            //dataSet for Delivery Stage
            List<Id> orderIdsToProcessWhenDelivered = new List<Id>();
            Map<Id,String> orderByPhoneMapWhenDelivered = new Map<Id,String>();
            String templateNameForDelivered = 'indie_deliverd_with_feedback_form';
            
            //dataSet for RTO Stage
            // List<Id> orderIdsToProcessWhenRTO = new List<Id>();
            // Map<Id,String> orderByPhoneMapWhenRTO = new Map<Id,String>();
            // String templateNameForRTO = 'order_status_indie_allocated';
            
            //dataSet for RTO
            List<Id> orderIdsForRTO = new List<Id>();
            Map<Id, String> orderPhoneMapForRTO = new Map<Id, String>();
            
            //dataSet for ready for delivery stage
            List<Id> orderIdsToProcessWhenReadyForDelivery = new List<Id>();
            Map<Id,String> orderByPhoneMapWhenReadyForDelivery = new Map<Id,String>();
            String templateNameForReadyForDelivery = 'ready_for_delivery';
            
            //dataSet for order cancelled stage
            List<WhatsappIntegration__c> ws = WhatsappIntegration__c.getAll().values();
            WhatsappIntegration__c w = WhatsappIntegration__c.getInstance('WhatsApp API');
            String imageUrlForOrderCancel;
            if(w != null){
                imageUrlForOrderCancel = w.order_cancelled__c; 
            }else{
                System.debug('w Null values come==>');
            }
            
            List<Id> orderIdsToProcessWhenOrderCancelled = new List<Id>();                                                                                                                                                   
            Map<Id,String> orderByPhoneMapWhenOrderCancelled = new Map<Id,String>();
            String templateNameForOrderCancelled = 'order_cancelled';
            
            //additional validation added by Aniket on 10/02/2025
            Set<Id> orderIdsToFetchOrderProducts = new Set<Id>();
            //additional by Aniket on 18/02/2025
            Set<Id> orderIdsToTakeForward = new Set<Id>();
            
            Map<Id,Id> orderAndOrderProductMap = new Map<Id,Id>();
            for(Order order : newOrderList){
                if(vehicleRecordTypeId !=null && order.RecordTypeId == vehicleRecordTypeId && order.Status != oldOrderMap.get(order.Id).Status /*&& order.Status == 'Allotment in Process'*/){
                    orderIdsToFetchOrderProducts.add(order.Id);
                    //additional
                    orderIdsToTakeForward.add(order.Id);
                    
                }
            }
            List<OrderItem> orderProductList = [SELECT Id,OrderId,Type__c from OrderItem WHERE OrderId IN:orderIdsToFetchOrderProducts]; 
            for(OrderItem oi : orderProductList){
                if(oi.Type__c == 'Vehicle' && oi.OrderId != null){
                    orderAndOrderProductMap.put(oi.OrderId,oi.Id);
                }
            }
            System.debug('orderAndOrderProductMap===>'+orderAndOrderProductMap);
            //upto this
            //code added on 11/02/2025 by Aniket
            Set<Id> accountIdsToGetAccounts= new Set<Id>();
            
            for(Order o : newOrderList ){
                if(o.AccountId != null){
                    accountIdsToGetAccounts.add(o.AccountId);
                }
            }
            // Map<Id,wrapperForAllotment> toPassToQueueable = new Map<Id,wrapperForAllotment>();
            
            List<Id> orderIdsToProcess = new List<Id>();
            
            List<Order> finalOrderList = [Select Id,RecordTypeId,Status,AccountId,Phone__c,Assigned_Vehicle__c,(Select id,Type__c from OrderItems) from Order Where Id IN:orderIdsToTakeForward]; 
            System.debug('finalOrderList==>'+finalOrderList);
            if(!finalOrderList.isEmpty()){
                for(Order o : finalOrderList){
                    //Id vehicleRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
                    System.debug('vehicleRecordTypeId==>'+vehicleRecordTypeId);
                    if(vehicleRecordTypeId != null && o.RecordTypeId == vehicleRecordTypeId){
                        if( o.Status != oldOrderMap.get(o.Id).Status && o.AccountId != null && o.Phone__c!=null){
                            if(o.Status == 'Allotment in Process'){
                                if(orderAndOrderProductMap.containsKey(o.Id) && o.Assigned_Vehicle__c != null){
                                    orderByPhoneMapWhenAllotment.put(o.Id,o.Phone__c);
                                    orderIdsToProcessWhenAllotment.add(o.Id);
                                }
                            }
                            else if(o.Status == 'Vehicle Delivered'){
                                if(orderAndOrderProductMap.containsKey(o.Id)){
                                    orderByPhoneMapWhenDelivered.put(o.Id,o.Phone__c);
                                    orderIdsToProcessWhenDelivered.add(o.Id); 
                                }
                                
                            }else if(o.Status == 'RTO Registration'){
                                if(orderAndOrderProductMap.containsKey(o.Id)){
                                    
                                }
                                
                            }else if(o.Status == 'Ready For Delivery'){
                                if(orderAndOrderProductMap.containsKey(o.Id)){
                                    orderByPhoneMapWhenReadyForDelivery.put(o.Id,o.Phone__c);
                                    orderIdsToProcessWhenReadyForDelivery.add(o.Id);  
                                }
                                
                            }else if(o.Status == 'Order Cancelled'){
                                if(orderAndOrderProductMap.containsKey(o.Id)){
                                    orderByPhoneMapWhenOrderCancelled.put(o.Id,o.Phone__c);
                                    orderIdsToProcessWhenOrderCancelled.add(o.Id);     
                                }
                                
                            }
                        }
                    }
                    
                }
            }
            System.debug('WhatsApp Pdf generation stage');
            // if (!orderIdsForRTO.isEmpty()) {
            //     System.debug('orderIdsForRTO'+orderIdsForRTO);
            //     // Attachment att = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId IN :orderIdsForRTO AND Name LIKE 'Vehicle Tax Invoice%' 
            //     //                   ORDER BY CreatedDate DESC LIMIT 1];
            //     List<Attachment> attList = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId IN :orderIdsForRTO AND Name LIKE 'Vehicle Tax Invoice%' 
            //     ORDER BY CreatedDate DESC LIMIT 1];
            //     System.debug('attList==>'+attList);
            //     if(attList.size()>0){
            //         Attachment att = attList[0];
            //         ContentVersion cv = new ContentVersion();
            //         cv.Title = att.Name;
            //         cv.PathOnClient = att.Name + '.pdf';
            //         cv.VersionData = att.Body;
            //         cv.FirstPublishLocationId = att.ParentId;
            //         insert cv;
            
            //         ContentDistribution cd = new ContentDistribution();
            //         cd.PreferencesAllowOriginalDownload = true;
            //         cd.PreferencesLinkLatestVersion = true;
            //         cd.Name = 'test';
            //         cd.ContentVersionId = cv.Id;
            //         insert cd;
            
            //         ContentDistribution cdl = [SELECT Id,ContentDownloadUrl,DistributionPublicUrl FROM ContentDistribution WHERE Id = :cd.Id LIMIT 1];
            //         System.debug('Public Link: ' + cdl);
            //         System.debug('Public ContentDownloadUrl: ' + cdl.ContentDownloadUrl);
            //         System.debug('Public DistributionPublicUrl: ' + cdl.DistributionPublicUrl);
            
            
            //         wrapperForAllotment w2 = new wrapperForAllotment();
            //         w2.phoneNumber = orderPhoneMapForRTO.get(cv.FirstPublishLocationId);
            //         w2.allotMentFileLinks = cdl.ContentDownloadUrl;
            //         w2.fileName = att.Name;
            
            //         toPassToQueueable.put(cv.FirstPublishLocationId, w2);
            //         orderIdsToProcess.add(cv.FirstPublishLocationId);
            //     }                  
            
            //     else{
            //         System.debug('No such Attachment found');
            //     }
            
            
            // System.debug('orderIdsToProcessForRTO==>'+orderIdsToProcess);
            // System.debug('toPassToQueueable==>'+toPassToQueueable);
            
            //upto here
            system.debug('orderByPhoneMap ===> ' + orderByPhoneMapWhenDelivered);
            system.debug('orderIdsToProcess ===> ' + orderIdsToProcessWhenDelivered);
            
            //}
            if(!orderIdsToProcessWhenAllotment.isEmpty() &&(templateNameForAllotment!=null && imageForAllotment!=null && orderByPhoneMapWhenAllotment!=null)){
                System.enqueueJob(new QueueableForImageTemplateMsg(orderIdsToProcessWhenAllotment, templateNameForAllotment,imageForAllotment, orderByPhoneMapWhenAllotment));
                System.debug('orderIdsToProcessWhenAllotment==>'+orderIdsToProcessWhenAllotment);
                System.debug('templateNameForAllotment==>'+templateNameForAllotment);
                System.debug('imageForAllotment==>'+imageForAllotment);
                System.debug('orderByPhoneMapWhenAllotment==>'+orderByPhoneMapWhenAllotment);
            }
            
            if(!orderIdsToProcessWhenDelivered.isEmpty() &&(templateNameForDelivered!=null && orderByPhoneMapWhenDelivered!=null)){
                System.enqueueJob(new QueueableTempWithoutParams(orderIdsToProcessWhenDelivered, templateNameForDelivered, orderByPhoneMapWhenDelivered));
            }
            // 
            // if(!orderIdsToProcess.isEmpty() && toPassToQueueable!=null){
            //     System.enqueueJob(new QueueableOnOrderRTOStage(orderIdsToProcess,toPassToQueueable));
            // }
            
            if(!orderIdsToProcessWhenReadyForDelivery.isEmpty()&&(templateNameForReadyForDelivery !=null && orderByPhoneMapWhenReadyForDelivery!=null)){
                System.enqueueJob(new QueueableTempWithoutParams(orderIdsToProcessWhenReadyForDelivery, templateNameForReadyForDelivery, orderByPhoneMapWhenReadyForDelivery));
            }
            if(!orderIdsToProcessWhenOrderCancelled.isEmpty()&&(templateNameForOrderCancelled!=null&&imageUrlForOrderCancel!=null && orderByPhoneMapWhenOrderCancelled!=null)){
                System.enqueueJob(new QueueableForImageTemplateMsg(orderIdsToProcessWhenOrderCancelled, templateNameForOrderCancelled,imageUrlForOrderCancel, orderByPhoneMapWhenOrderCancelled));
            }     
        }catch(Exception e){
            system.debug('error ===> ' + e.getMessage());
            system.debug('error Line===> ' + e.getLineNumber());
        }
    }
    
    //code added by Aniket on 20/02/2025
    public static void sendPDFAfterRTO(List<Order> newOrderList,Map<Id,Order> oldOrderMap){
        try{
            List<Id> orderIdsForRTO = new List<Id>();
            Map<Id,String> orderPhoneMapForRTO = new Map<Id,String>();
            Set<Id> orderIdsToFetchOrderProducts = new Set<Id>();
            Set<Id> orderIdsToTakeForward = new Set<Id>();
            Map<Id,wrapperForAllotment> toPassToQueueable = new Map<Id,wrapperForAllotment>();
            List<Id> orderIdsToProcess = new List<Id>();
            Map<Id,Id> orderAndOrderProductMap = new Map<Id,Id>();
            for(Order order : newOrderList){
                if(vehicleRecordTypeId !=null && order.RecordTypeId == vehicleRecordTypeId && order.Is_Invoice_PDF_Generated__c == true && oldOrderMap.get(order.Id).Is_Invoice_PDF_Generated__c == false /*&& order.Status == 'Allotment in Process'*/){
                    orderIdsToFetchOrderProducts.add(order.Id);
                    //additional
                    orderIdsToTakeForward.add(order.Id);
                    
                }
            }
            List<OrderItem> orderProductList = [SELECT Id,OrderId,Type__c from OrderItem WHERE OrderId IN:orderIdsToFetchOrderProducts]; 
            for(OrderItem oi : orderProductList){
                if(oi.Type__c == 'Vehicle' && oi.OrderId != null){
                    orderAndOrderProductMap.put(oi.OrderId,oi.Id);
                }
            }
            System.debug('orderAndOrderProductMap===>'+orderAndOrderProductMap);
            
            List<Order> finalOrderList = [Select Id,RecordTypeId,Status,AccountId,Phone__c,Is_Invoice_PDF_Generated__c,Assigned_Vehicle__c/*,(Select id,Type__c from OrderItems)*/ from Order Where Id IN:orderIdsToTakeForward]; 
            if(!finalOrderList.isEmpty()){
                for(Order o:finalOrderList){
                    if(vehicleRecordTypeId != null && o.RecordTypeId == vehicleRecordTypeId && orderAndOrderProductMap.containsKey(o.Id)){
                        if( o.Is_Invoice_PDF_Generated__c == true && oldOrderMap.get(o.Id).Is_Invoice_PDF_Generated__c == false && o.AccountId != null && o.Phone__c!=null){
                            orderIdsForRTO.add(o.Id);
                            orderPhoneMapForRTO.put(o.Id, o.Phone__c);
                        }
                    }
                }
            }
            if (!orderIdsForRTO.isEmpty()) {
                System.debug('orderIdsForRTO'+orderIdsForRTO);
                // Attachment att = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId IN :orderIdsForRTO AND Name LIKE 'Vehicle Tax Invoice%' 
                //                   ORDER BY CreatedDate DESC LIMIT 1];
                List<Attachment> attList = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId IN :orderIdsForRTO AND Name LIKE 'Vehicle Tax Invoice%' 
                                            ORDER BY CreatedDate DESC LIMIT 1];
                System.debug('attList==>'+attList);
                if(attList.size()>0){
                    Attachment att = attList[0];
                    ContentVersion cv = new ContentVersion();
                    cv.Title = att.Name;
                    cv.PathOnClient = att.Name + '.pdf';
                    cv.VersionData = att.Body;
                    cv.FirstPublishLocationId = att.ParentId;
                    insert cv;
                    
                    ContentDistribution cd = new ContentDistribution();
                    cd.PreferencesAllowOriginalDownload = true;
                    cd.PreferencesLinkLatestVersion = true;
                    cd.Name = 'test';
                    cd.ContentVersionId = cv.Id;
                    insert cd;
                    
                    ContentDistribution cdl = [SELECT Id,ContentDownloadUrl,DistributionPublicUrl FROM ContentDistribution WHERE Id = :cd.Id LIMIT 1];
                    System.debug('Public Link: ' + cdl);
                    System.debug('Public ContentDownloadUrl: ' + cdl.ContentDownloadUrl);
                    System.debug('Public DistributionPublicUrl: ' + cdl.DistributionPublicUrl);
                    
                    
                    wrapperForAllotment w3 = new wrapperForAllotment();
                    w3.phoneNumber = orderPhoneMapForRTO.get(cv.FirstPublishLocationId);
                    w3.allotMentFileLinks = cdl.ContentDownloadUrl;
                    w3.fileName = att.Name;
                    
                    toPassToQueueable.put(cv.FirstPublishLocationId, w3);
                    orderIdsToProcess.add(cv.FirstPublishLocationId);
                } else{
                    System.debug('No such Attachment found');
                }       
                System.debug('orderIdsToProcessForRTO==>'+orderIdsToProcess);
                System.debug('toPassToQueueable==>'+toPassToQueueable);
                
                if(!orderIdsToProcess.isEmpty() && toPassToQueueable!=null){
                    System.enqueueJob(new QueueableOnOrderRTOStage(orderIdsToProcess,toPassToQueueable));
                }
                
                
                
                
                
                
            }
        }catch(Exception e){
            System.debug('Error is ==>'+e.getMessage());
            System.debug('Error Line Number ==>'+e.getLineNumber());
        }
    }
    
    //code added by Aniket on 11/02/2025
    public static void sendWhatsAppAfterOrderCreation(List<Order> newOrderList, Map<Id, Order> oldOrderMap) {
        try {
            System.debug('Inside sendWhatsAppAfterOrderCreation');

            Set<Id> orderIdsToGet = new Set<Id>();
            List<Id> fullPaymentOrderIds = new List<Id>();
            List<Id> customerApprovalOrderIds = new List<Id>();
            Map<Id, String> orderIdToPhoneMap = new Map<Id, String>();
            Map<Id, String> customerApprovalPhoneMap = new Map<Id, String>();

            for (Order newOrder : newOrderList) {
                Order oldOrder = oldOrderMap.get(newOrder.Id);
                if (newOrder == null || oldOrder == null) continue;

                if (newOrder.RecordTypeId == vehicleRecordTypeId && newOrder.AccountId != null && 
                    newOrder.Booking_Form_File_URL__c != oldOrder.Booking_Form_File_URL__c) {
                    orderIdsToGet.add(newOrder.Id);
                }

                if (newOrder.Remaining_Amount__c != oldOrder.Remaining_Amount__c && 
                    newOrder.Remaining_Amount__c == 0 && 
                    newOrder.RecordTypeId == vehicleRecordTypeId) {
                    fullPaymentOrderIds.add(newOrder.Id);
                    orderIdToPhoneMap.put(newOrder.Id, newOrder.Phone__c);
                }

                if (newOrder.Customer_Approval__c != oldOrder.Customer_Approval__c && 
                    newOrder.Customer_Approval__c == 'Yes' && 
                    newOrder.RecordTypeId == vehicleRecordTypeId) {
                    customerApprovalOrderIds.add(newOrder.Id);
                    customerApprovalPhoneMap.put(newOrder.Id, newOrder.Phone__c);
                }
            }

            System.debug('orderIdsToGet => ' + orderIdsToGet);
            System.debug('fullPaymentOrderIds => ' + fullPaymentOrderIds);
            System.debug('customerApprovalOrderIds => ' + customerApprovalOrderIds);

            Map<Id, Order> orderMap = new Map<Id, Order>([
                SELECT Id, Phone__c, RecordTypeId, Account.Name, Website_Order_Id__c,
                    Booking_Form_File_URL__c, Status
                FROM Order
                WHERE Id IN :orderIdsToGet
            ]);

            Set<Id> combinedOrderIds = new Set<Id>();
            combinedOrderIds.addAll(orderIdsToGet);
            combinedOrderIds.addAll(fullPaymentOrderIds);
            combinedOrderIds.addAll(customerApprovalOrderIds);

            Map<Id, String> orderIdToColorMap = new Map<Id, String>();

            if (!combinedOrderIds.isEmpty()) {
                Map<Id, Id> orderToProductMap = new Map<Id, Id>();
                for (OrderItem oi : [
                    SELECT OrderId, Product2Id
                    FROM OrderItem
                    WHERE OrderId IN :combinedOrderIds AND Type__c = 'Vehicle'
                ]) {
                    orderToProductMap.put(oi.OrderId, oi.Product2Id);
                }

                if (!orderToProductMap.isEmpty()) {
                    Map<Id, Product2> prodMap = new Map<Id, Product2>([
                        SELECT Id, Colour__c FROM Product2 WHERE Id IN :orderToProductMap.values()
                    ]);
                    for (Id orderId : orderToProductMap.keySet()) {
                        Product2 prod = prodMap.get(orderToProductMap.get(orderId));
                        if (prod != null && prod.Colour__c != null) {
                            orderIdToColorMap.put(orderId, prod.Colour__c);
                        }
                    }
                }
            }

            Map<Id, wrapperForBooking> bookingPayloadMap = new Map<Id, wrapperForBooking>();
            for (Order orderRec : orderMap.values()) {
                if (orderRec.RecordTypeId == vehicleRecordTypeId && orderRec.Status == 'Booking') {
                    wrapperForBooking wrap = new wrapperForBooking();
                    wrap.phoneNumber = orderRec.Phone__c;
                    wrap.bookingId = orderRec.Website_Order_Id__c;
                    wrap.color = orderIdToColorMap.get(orderRec.Id);
                    wrap.pdfLink = orderRec.Booking_Form_File_URL__c;
                    wrap.fileName = 'River Indie Booking Receipt';
                    wrap.templateName = 'booking_completed';
                    bookingPayloadMap.put(orderRec.Id, wrap);
                }
            }

            if (!bookingPayloadMap.isEmpty()) {
                System.enqueueJob(new QueueableOnOrderCreationAfterBooking(
                    new List<Id>(bookingPayloadMap.keySet()), bookingPayloadMap
                ));
            }

            if (!fullPaymentOrderIds.isEmpty()) {
                System.enqueueJob(new QueueableTempWithoutParams(
                    fullPaymentOrderIds, 'full_payment_completed', orderIdToPhoneMap
                ));
            }

            if (!customerApprovalOrderIds.isEmpty()) {
                System.enqueueJob(new QueueableTempWithoutParams(
                    customerApprovalOrderIds, 'thanks_for_confirming', customerApprovalPhoneMap
                ));
            }

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }


    
    public static void processOrderMilestones(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        System.debug('In processOrderMilestones');
        if (newOrders == null || newOrders.isEmpty() || oldOrderMap == null) {
            return;
        }
        
        Set<Id> vehicleIds = new Set<Id>();
        
        for (Order ord : newOrders) {
            if (ord.Assigned_Vehicle__c != null && oldOrderMap.containsKey(ord.Id)) {
                vehicleIds.add(ord.Assigned_Vehicle__c);
            }
        }
        
        if (vehicleIds.isEmpty()) {
            return;
        }
        
        Map<Id, Asset> vehicleToAssetMap = new Map<Id, Asset>();
        Map<Id, Vehicle> vehicleMap = new Map<Id, Vehicle>();
        
        List<Asset> assetList = [SELECT Id, VehicleId FROM Asset WHERE VehicleId IN :vehicleIds];
        for (Asset asset : assetList) {
            vehicleToAssetMap.put(asset.VehicleId, asset);
        }
        
        List<Vehicle> vehicleList = [SELECT Id, Purchased_Date__c FROM Vehicle WHERE Id IN :vehicleIds];
        for (Vehicle vehicle : vehicleList) {
            vehicleMap.put(vehicle.Id, vehicle);
        }
        
        System.debug('vehicleMap ===> ' + vehicleMap);
        
        Map<String, Boolean> existingMilestones = new Map<String, Boolean>();
        List<AssetMilestone> existingMilestonesList = [SELECT MilestoneType, VehicleId FROM AssetMilestone WHERE VehicleId IN :vehicleIds];
        
        for (AssetMilestone am : existingMilestonesList) {
            existingMilestones.put(am.VehicleId + '-' + am.MilestoneType, true);
        }
        
        List<AssetMilestone> milestonesToInsert = new List<AssetMilestone>();
        List<Vehicle> vehiclesToUpdate = new List<Vehicle>();
        
        for (Order ord : newOrders) {
            if (ord.Assigned_Vehicle__c == null || !oldOrderMap.containsKey(ord.Id)) {
                continue;
            }
            
            Order oldOrder = oldOrderMap.get(ord.Id);
            Asset asset = vehicleToAssetMap.get(ord.Assigned_Vehicle__c);
            
            if (ord.Status != oldOrder.Status) {
                String milestoneType;
                Date milestoneDate = System.today();
                
                if (ord.Status == 'RTO Registration') {
                    milestoneType = 'Sold';
                    
                    Vehicle vehicleToUpdate = vehicleMap.get(ord.Assigned_Vehicle__c);
                    if (vehicleToUpdate != null) {
                        if (vehicleToUpdate.Purchased_Date__c == null) {
                            vehicleToUpdate.Purchased_Date__c = System.today();
                            vehiclesToUpdate.add(vehicleToUpdate);
                        }
                    }
                } else if (ord.Status == 'Vehicle Delivered') {
                    milestoneType = 'Customer Delivery';
                } else {
                    continue;
                }
                
                String key = ord.Assigned_Vehicle__c + '-' + milestoneType;
                if (!existingMilestones.containsKey(key)) {
                    System.debug('Inserting milestone: ' + milestoneType + ' for Vehicle ID: ' + ord.Assigned_Vehicle__c + ', Date: ' + milestoneDate);
                    
                    milestonesToInsert.add(new AssetMilestone(
                        MilestoneType = milestoneType,
                        Name = milestoneType,
                        MilestoneDate = milestoneDate,
                        Stage = 'Active',
                        UsageType = 'Automotive',
                        VehicleId = ord.Assigned_Vehicle__c,
                        AssetId = (asset != null) ? asset.Id : null
                    ));
                    
                    existingMilestones.put(key, true);
                }
            }
        }
        
        if (!milestonesToInsert.isEmpty()) {
            System.debug('Final Milestones to Insert: ' + milestonesToInsert);
            insert milestonesToInsert;
        }
        
        if (!vehiclesToUpdate.isEmpty()) {
            System.debug('Updating Purchased Date for Vehicles: ' + vehiclesToUpdate);
            update vehiclesToUpdate;
        }
    }
    
    //this method is added by Aniket on 05/03/2025 for EW Integration
    public static void afterUpdateForEWIntegration(List<Order> orderList,Map<Id,Order> oldOrderMap){
        try{
            Set<Id> orderIdsToGetProducts = new Set<Id>();
            //dataSet when Assigned Vehicle
            List<Id> orderIdsToProcessWhenAssignedVehicle = new List<Id>();
            Map<Id,wrapperForEWIntegration> mapWhenAssignedVehicle = new Map<Id,wrapperForEWIntegration>();
            //dataSet when No Assigned Vehicle
            List<Id> orderIdsToProcessWhenNoAV = new List<Id>();
            Map<Id,wrapperForEWIntegration> mapWhenNoAV = new Map<Id,wrapperForEWIntegration>();
            for(Order o : orderList){
                if(/*o.Status == 'RTO Registration' && o.Status!=oldOrderMap.get(o.Id).Status && */o.RecordTypeId == vehicleRecordTypeId){
                    orderIdsToGetProducts.add(o.Id);
                }
            }
            List<OrderItem> orderProducts = [SELECT Id, Type__c, OrderId, Product2.ProductCode FROM OrderItem WHERE OrderId IN :orderIdsToGetProducts 
                                             AND (Type__c = 'Vehicle' OR Type__c = 'Accessories')];
            
            System.debug('Fetched Order Products ==>'+orderProducts);
            boolean vehiclePresent = false;
            boolean ewExists = false;
            if(!orderProducts.isEmpty()){
                for(OrderItem oi : orderProducts){
                    if(oi.Type__c == 'Vehicle'){
                        vehiclePresent = true;
                    }
                    if(oi.Type__c == 'Accessories' && oi.Product2.ProductCode != null && oi.Product2.ProductCode.startsWith('RV-EW')){
                        ewExists = true;
                    }
                }
            }
            //changes
            if (vehiclePresent && ewExists) {
                
                List<Order> finalOrderList = [SELECT Id, AccountId, Assigned_Vehicle__c FROM Order WHERE Id IN :orderIdsToGetProducts];
                
                Set<Id> vehicleIds = new Set<Id>();
                Set<Id> accountIds = new Set<Id>();
                
                for (Order order : finalOrderList) {
                    if (order.Assigned_Vehicle__c != null) {
                        vehicleIds.add(order.Assigned_Vehicle__c);
                    } else {
                        accountIds.add(order.AccountId);
                    }
                }
                
                
                Map<Id, Vehicle> vehicleMap = new Map<Id, Vehicle>();
                if (!vehicleIds.isEmpty()) {
                    for (Vehicle v : [SELECT Id, Purchased_Date__c, ChassisNumber, Name,VehicleIdentificationNumber, RR_Battery_Number__c, EngineNumber, Charger_PC_Number__c, Account__c, Account__r.Center_Code__c,CurrentOwnerId,CurrentOwner.Center_Code__c, CreatedDate
                                      FROM Vehicle WHERE Id IN :vehicleIds]) {
                                          vehicleMap.put(v.Id, v);
                                      }
                }
                
                
                Map<Id, Account> accountMap = new Map<Id, Account>();
                if (!accountIds.isEmpty()) {
                    for (Account acc : [SELECT Id, Center_Code__c FROM Account WHERE Id IN :accountIds]) {
                        accountMap.put(acc.Id, acc);
                    }
                }
                
                
                Map<Id, Vehicle> latestVehicleByAccount = new Map<Id, Vehicle>();
                if (!accountIds.isEmpty()) {
                    for (Vehicle vv : [SELECT Id, Purchased_Date__c,VehicleIdentificationNumber,ChassisNumber, Name, RR_Battery_Number__c, EngineNumber,Charger_PC_Number__c, Account__c,CurrentOwnerId,CurrentOwner.Center_Code__c, CreatedDate 
                                       FROM Vehicle  WHERE Account__c IN :accountIds  ORDER BY CreatedDate DESC]) {
                                           if (!latestVehicleByAccount.containsKey(vv.Account__c)) {
                                               latestVehicleByAccount.put(vv.Account__c, vv);
                                           }
                                       }
                }
                
                for (Order order : finalOrderList) {
                    if (order.Assigned_Vehicle__c != null && vehicleMap.containsKey(order.Assigned_Vehicle__c)) {
                        Vehicle v = vehicleMap.get(order.Assigned_Vehicle__c);
                        wrapperForEWIntegration w = new wrapperForEWIntegration();
                        w.vehicleId = v.Id;
                        w.dealerCode = v.CurrentOwner.Center_Code__c !=null ? v.CurrentOwner.Center_Code__c : '';
                        w.purchaseDate = v.Purchased_Date__c != null ? v.Purchased_Date__c : null;
                        w.chassisNumber = v.VehicleIdentificationNumber != null ? v.VehicleIdentificationNumber :'';
                        w.model = v.Name != null ? v.Name :'';
                        w.battery = v.RR_Battery_Number__c != null ? v.RR_Battery_Number__c : '';
                        w.engineNumber = v.EngineNumber != null ? v.EngineNumber : '';
                        w.charger = v.Charger_PC_Number__c != null ? v.Charger_PC_Number__c : '';
                        orderIdsToProcessWhenAssignedVehicle.add(order.Id);
                        mapWhenAssignedVehicle.put(order.Id, w);
                    } else if (accountMap.containsKey(order.AccountId)) {
                        Account acc = accountMap.get(order.AccountId);
                        if (latestVehicleByAccount.containsKey(acc.Id)) {
                            Vehicle vv = latestVehicleByAccount.get(acc.Id);
                            wrapperForEWIntegration ww = new wrapperForEWIntegration();
                            ww.vehicleId = vv.Id;
                            ww.dealerCode = acc.Center_Code__c != null ? acc.Center_Code__c : '';
                            ww.purchaseDate = vv.Purchased_Date__c != null ? vv.Purchased_Date__c : null;
                            ww.chassisNumber = vv.VehicleIdentificationNumber != null ? vv.VehicleIdentificationNumber : '';
                            ww.model = vv.Name != null ? vv.Name : '';
                            ww.battery = vv.RR_Battery_Number__c != null ? vv.RR_Battery_Number__c : '';
                            ww.engineNumber = vv.EngineNumber != null ? vv.EngineNumber : '';
                            ww.charger = vv.Charger_PC_Number__c != null ? vv.Charger_PC_Number__c : '';
                            orderIdsToProcessWhenNoAV.add(order.Id);
                            mapWhenNoAV.put(order.Id, ww);
                        }
                    }else{
                        System.debug('Both EW And Vehicle are not present');
                    }
                }
            }
            //upto here
            if(!orderIdsToProcessWhenAssignedVehicle.isEmpty()){
                System.enqueueJob(new QueueableForEWIntegration(orderIdsToProcessWhenAssignedVehicle,mapWhenAssignedVehicle));
            }
            if(!orderIdsToProcessWhenNoAV.isEmpty()){
                System.enqueueJob(new QueueableForEWIntegration(orderIdsToProcessWhenNoAV,mapWhenNoAV));
            }
        }
        catch(Exception e){
            System.debug('Error occured ===>'+e.getMessage());
            System.debug('Error Line Number Is ===>'+e.getLineNumber());
        }
    } 
    
    public class wrapperForBooking{
        public String phoneNumber{get;set;}
        public String bookingId{get;set;}
        public String color{get;set;}
        public String pdfLink{get;set;}
        public String fileName{get;set;}
        public String templateName{get;set;}
    }
    
    public class wrapperForAllotment{
        public String phoneNumber{get;set;}
        public String allotMentFileLinks{get;set;}
        public String fileName{get;set;}
    }
    
    public class wrapperForEWIntegration{
        public Id vehicleId{get;set;}
        public String dealerCode{get;set;}
        public Date purchaseDate{get;set;}
        public String chassisNumber{get;set;}
        public String model{get;set;}
        public String battery{get;set;}
        public String engineNumber{get;set;}
        public String charger{get;set;}
    }    
}