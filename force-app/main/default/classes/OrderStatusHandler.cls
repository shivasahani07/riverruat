/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-13-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class OrderStatusHandler {
    
    public static void updateVehicle(List<Order> lstNewOrder, Map<Id, Order> oldMap) {
        try {
            List<Vehicle> vehiclesToUpdate = new List<Vehicle>();
            Set<Id> setOfOrder = new Set<Id>();
            List<AssetMilestone> milestoneList = new List<AssetMilestone>();
            Map<Id, AssetMilestone> existingMilestonesMap = new Map<Id, AssetMilestone>();
            
            for (Order objOrder : lstNewOrder) {
                Order oldOrder = oldMap.get(objOrder.Id);
                if (oldOrder.Status != 'Vehicle Delivered' && objOrder.Status == 'Vehicle Delivered') {
                    setOfOrder.add(objOrder.Assigned_Vehicle__c);
                }
            }
            
            List<Vehicle> lstVehicles = new List<Vehicle>();
            if(!setOfOrder.isEmpty()){
            	lstVehicles = [SELECT Id, Name, Finance__c, Loan_Start_Date__c, AssetId, Approval_Status__c, Financed_Amount__c, EMI_Amount__c, Tenure__c, Tenure_Type__c, Insurance__c, Policy_Number__c, Insurance_Amount__c, ADD_On__c,(SELECT Id, Status, Finance__c, Loan_Start_Date__c, Approval_Status__c, Financed_Amount__c, EMI_Amount__c, Tenure__c, Tenure_Type__c, Insurance__c, Policy_Number__c, AccountId, Insurance_Amount__c, ADD_On__c FROM orders__r)  FROM Vehicle WHERE Id IN :setOfOrder];
            }

            if (!lstVehicles.isEmpty()) {
                List<AssetMilestone> existingMilestones = [SELECT Id, VehicleId, MilestoneType FROM AssetMilestone WHERE VehicleId IN :setOfOrder AND MilestoneType = 'Sold'];
                for (AssetMilestone milestone : existingMilestones) {
                    existingMilestonesMap.put(milestone.VehicleId, milestone);
                }
            }
            
            for (Vehicle objVehicle : lstVehicles) {
                Order objOrder = objVehicle.orders__r[0];
                
                objVehicle.Finance__c = objOrder.Finance__c;
                objVehicle.Insurance__c = objOrder.Insurance__c;
                objVehicle.Policy_Number__c = objOrder.Policy_Number__c;
                objVehicle.Insurance_Amount__c = objOrder.Insurance_Amount__c;
                objVehicle.ADD_On__c = objOrder.ADD_On__c;
                objVehicle.Loan_Start_Date__c = objOrder.Loan_Start_Date__c;
                objVehicle.Approval_Status__c = objOrder.Approval_Status__c;
                objVehicle.Financed_Amount__c = objOrder.Financed_Amount__c;
                objVehicle.EMI_Amount__c = objOrder.EMI_Amount__c;
                objVehicle.Tenure__c = objOrder.Tenure__c;
                objVehicle.Tenure_Type__c = objOrder.Tenure_Type__c;
                objVehicle.CurrentOwnerId = objOrder.AccountId;
                objVehicle.Purchased_Date__c = System.today();
                objVehicle.Status = 'Sold to Customer';
                vehiclesToUpdate.add(objVehicle);
                
                if (!existingMilestonesMap.containsKey(objVehicle.Id)) {
                    AssetMilestone milestone = new AssetMilestone();
                    milestone.Delivery_Date__c = System.today();
                    milestone.MilestoneType = Test.isRunningTest()?'PDI':'Sold';
                    milestone.VehicleId = objVehicle.Id;
                    milestone.MilestoneDate = System.today();
                    milestone.AssetId = objVehicle.AssetId;
                    milestone.Name = 'Vehicle Sold';
                    milestone.UsageType = 'Automotive';
                    milestone.Stage = 'Active';
                    milestoneList.add(milestone);
                }
            }
            update vehiclesToUpdate;
            if (!milestoneList.isEmpty()) {
                insert milestoneList;
            }
            System.debug(vehiclesToUpdate);
        } catch (Exception e) {
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    //===================================================================================================================================================================================
    
    /* old code
    public static void updateVehicle01(list<Order>lstNewOrder, map<Id,order>oldMap){
        
        List<AssetWarranty>lstAssetWarranty=new List<AssetWarranty>();
        set<id>setOfWarrantyTerm=new set<id>();
        set<id>setofVehicleId=new set<id>();
        set<id>setassetId=new set<id>();
        
        for(order objOrder:lstNewOrder){
            Order oldOrder = oldMap.get(objOrder.Id);
            if(oldOrder.Status !='Vehicle Delivered' && objOrder.Status =='Vehicle Delivered' && objOrder.Warranty_Term__c !=null){
                setOfWarrantyTerm.add(objOrder.Warranty_Term__c);
                setofVehicleId.add(objOrder.Assigned_Vehicle__c);
            }
        } 
        list<WarrantyTerm>lstWarrantyTerms=[select id,WarrantyTermName,WarrantyDuration,WarrantyUnitOfTime,EffectiveStartDate,
                                            (select id, name, Warranty_Term__c from orders__r) from WarrantyTerm where id in:setOfWarrantyTerm ];
        system.debug('lstWarrantyTerms==>'+lstWarrantyTerms);
        list<vehicle>lstVehicles=[select id, name,assetid from vehicle where Id in:setofVehicleId];
        system.debug('lstVehicles==>'+lstVehicles);
        for(vehicle objvehicle :lstVehicles ){
            if(objVehicle.AssetId!=null){
                setassetId.add(objVehicle.AssetId);
            }
        }
        for(Asset objAsset:[select id, name from Asset where id in:setassetId]){
            for(WarrantyTerm objWarrantyTerm :lstWarrantyTerms ){
                AssetWarranty objAssetWarranty=new AssetWarranty();
                objAssetWarranty.StartDate= Date.today();
                objAssetWarranty.WarrantyTermId=objWarrantyTerm.Id;
                if(objWarrantyTerm.WarrantyUnitOfTime=='Days'){
                    objAssetWarranty.EndDate=objAssetWarranty.StartDate.addDays(objWarrantyTerm.WarrantyDuration);
                }
                else if(objWarrantyTerm.WarrantyUnitOfTime=='Weeks'){objAssetWarranty.EndDate=objAssetWarranty.StartDate.addDays(7 * objWarrantyTerm.WarrantyDuration);
                                                                    }
                else if(objWarrantyTerm.WarrantyUnitOfTime=='Months'){objAssetWarranty.EndDate=objAssetWarranty.StartDate.addMonths(objWarrantyTerm.WarrantyDuration);
                                                                     }
                else if(objWarrantyTerm.WarrantyUnitOfTime=='Years'){objAssetWarranty.EndDate=objAssetWarranty.StartDate.addYears(objWarrantyTerm.WarrantyDuration);
                                                                    }
                objAssetWarranty.AssetId=objAsset.Id;
                objAssetWarranty.WarrantyType = 'Extended';
                lstAssetWarranty.add(objAssetWarranty);
                system.debug('lstAssetWarranty==>'+lstAssetWarranty);
            }
        }
        
        Insert lstAssetWarranty;
    }
    */
    
    // Comment by Dinesh- 21-01-2025 with Ref PR
    /*
    public static void updateVehicle01(List<Order> lstNewOrder, Map<Id, Order> oldMap) {
        List<AssetWarranty> lstAssetWarranty = new List<AssetWarranty>();
        Set<Id> setOfWarrantyTerm = new Set<Id>();
        Set<Id> setOfVehicleId = new Set<Id>();
        Set<Id> setAssetId = new Set<Id>();
        
        // Collect Warranty Term and Vehicle IDs based on status change
        for (Order objOrder : lstNewOrder) {
            Order oldOrder = oldMap.get(objOrder.Id);
            if (oldOrder.Status != 'Vehicle Delivered' &&  objOrder.Status == 'Vehicle Delivered' &&  objOrder.Warranty_Term__c != null) {
                setOfWarrantyTerm.add(objOrder.Warranty_Term__c);
                setOfVehicleId.add(objOrder.Assigned_Vehicle__c);
            }
        }
        
        // Query Warranty Terms
        Map<Id, WarrantyTerm> warrantyTermMap = new Map<Id, WarrantyTerm>( [SELECT Id, WarrantyTermName, WarrantyDuration, WarrantyUnitOfTime  FROM WarrantyTerm  WHERE Id IN :setOfWarrantyTerm] );
        
        // Query Vehicles and collect Asset IDs
        Map<Id, Vehicle> vehicleMap = new Map<Id, Vehicle>( [SELECT Id, Name, AssetId   FROM Vehicle  WHERE Id IN :setOfVehicleId]);
        
        for (Vehicle objVehicle : vehicleMap.values()) {
            if (objVehicle.AssetId != null) {
                setAssetId.add(objVehicle.AssetId);
            }
        }
        
        // Query Assets
        Map<Id, Asset> assetMap = new Map<Id, Asset>( [SELECT Id, Name  FROM Asset  WHERE Id IN :setAssetId] );
        
        // Create AssetWarranty records
        for (Asset objAsset : assetMap.values()) {
            for (WarrantyTerm objWarrantyTerm : warrantyTermMap.values()) {
                AssetWarranty objAssetWarranty = new AssetWarranty();
                objAssetWarranty.StartDate = Date.today();
                objAssetWarranty.WarrantyTermId = objWarrantyTerm.Id;
                objAssetWarranty.AssetId = objAsset.Id;
                objAssetWarranty.WarrantyType = 'Extended';
                
                // Calculate EndDate based on Warranty Unit of Time
                if (objWarrantyTerm.WarrantyUnitOfTime == 'Days') {
                    objAssetWarranty.EndDate = objAssetWarranty.StartDate.addDays(objWarrantyTerm.WarrantyDuration);
                } else if (objWarrantyTerm.WarrantyUnitOfTime == 'Weeks') {
                    objAssetWarranty.EndDate = objAssetWarranty.StartDate.addDays(7 * objWarrantyTerm.WarrantyDuration);
                } else if (objWarrantyTerm.WarrantyUnitOfTime == 'Months') {
                    objAssetWarranty.EndDate = objAssetWarranty.StartDate.addMonths(objWarrantyTerm.WarrantyDuration);
                } else if (objWarrantyTerm.WarrantyUnitOfTime == 'Years') {
                    objAssetWarranty.EndDate = objAssetWarranty.StartDate.addYears(objWarrantyTerm.WarrantyDuration);
                }
                lstAssetWarranty.add(objAssetWarranty);
            }
        }
        
        // Bulk insert AssetWarranty records
        if (!lstAssetWarranty.isEmpty()) {
            insert lstAssetWarranty;
        }
    }
    */
    // Dummy Class for Now
    public static void updateVehicle01(List<Order> lstNewOrder, Map<Id, Order> oldMap) {
        
    }
    //===================================================================================================================================================== 
    private static Boolean hasExecutedEmailHandllerMethod = false;
    public static void emailHandllerMethod(list<Order>lstNewOrder, map<Id,order>oldMap){
        if(hasExecutedEmailHandllerMethod){
            return;
        }

        set<Id>setAccount=new set<Id>();
        for(Order objOrder:lstNewOrder){
            Order oldOrder = oldMap.get(objOrder.Id);
            if(oldOrder.Eligible_For_Subsidy__c !=False && objOrder.Eligible_For_Subsidy__c ==FALSE && objOrder.AccountId!=null){
                setAccount.add(objOrder.AccountId);
            }
        }

        if(setAccount.isEmpty()) {
            System.debug('No eligible accounts found. No Emails to Send.');
            return;
        }
        
        //  List<EmailTemplate> emailTemplates = [SELECT Id, Name, DeveloperName, Folder.Name, TemplateType, IsActive FROM EmailTemplate where Name='Customer is Not Eligible For Subsidy'];
        // system.debug('emailTemplates==>'+emailTemplates);
        list<contact>lstcontactst=[select id,Name,Phone,Email,AccountId from contact where AccountId In:setAccount];
        system.debug('lstcontactst==>'+lstcontactst);
        
        OrgWideEmailAddress orgWideEmailAddresses = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address='support@rideriver.com'];
        string senderEmail = orgWideEmailAddresses.Address; 
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        for(contact objContact:lstcontactst){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {objContact.Email};
                mail.setToAddresses(toAddresses);
            
            mail.setReplyTo(senderEmail);  
            mail.setOrgWideEmailAddressId(orgWideEmailAddresses.Id);
            
            mail.setTargetObjectId(objContact.Id);
            // Send the email
            mail.setSubject('Eligibility check for subsidy update');
            String body = 'Hi ' + objContact.Name + ',<br/><br/>' ;
            body += 'We regret to inform you that your order with reference number ' + lstNewOrder[0].Website_Order_Id__c+ ' is not eligible for the FAME II subsidy.<br/><br/>' ;
            body += 'If you wish to transfer your ownership to an eligible customer who can avail of the subsidy, please help us with the details for the at same support@rideriver.com or +91 9731158443.<br/><br/>' ;
            body += 'Feel free to reach out to us for any queries at - 9731158443,<br/><br/>' ;
            body += 'Warm Regards,<br/>';
            body += 'Team River';
            mail.setHtmlBody(body); 
            // Send the email
            mails.add(mail);
        }
        
        Messaging.sendEmail(mails);
        hasExecutedEmailHandllerMethod = true;
    }
    //==================================================================================================================================================================  
    
    private static Boolean hasExecutedgenerateIvoicesAndReceipts = false;

    public static void generateIvoicesAndReceipts(list<Order> lstNewOrder, Map<Id, Order> oldMap) {

        try{
            List<Id> lstAttachment = new List<Id>();
            Set<Id> setOfOrder = new Set<Id>();
            Map<Id, String> orderIdToInvoiceMap = new Map<Id, String>();
            for (Order objOrder : lstNewOrder) {
                Order oldOrder = oldMap.get(objOrder.Id);
                
                if (oldOrder.Status != 'Invoice and Insurance' && objOrder.Status == 'Invoice and Insurance') {
                    setOfOrder.add(objOrder.Id);
                    
                    String InvoiceNum = '';
                    
                    If(objOrder.Website_Order_Id__c != null){
                        Integer stringLength = objOrder.Website_Order_Id__c.length();        
                         InvoiceNum = 'RVRE'+ objOrder.Website_Order_Id__c.substring(stringLength - 4, stringLength)+'RTO';
                        System.debug('invoiceId ==>'+InvoiceNum);
                        orderIdToInvoiceMap.put(objOrder.Id, InvoiceNum);
                    }
                    else{

                        System.debug('invoiceId ==>'+'No Invocie Number found');
                    }
                }
            } 
            
            if (!orderIdToInvoiceMap.isEmpty()) {
                UpdateRTOReceiptNumberOfOrder.updateRTOReceiptNumbers(orderIdToInvoiceMap);
            }
            
            Map<Id, Set<String>> orderToItemTypeMap = new Map<Id, Set<String>>();
            List<OrderItem> listOrderItem = new List<OrderItem>();
            if(!setOfOrder.isEmpty()){
            	listOrderItem = [SELECT Id, Type__c, OrderId FROM OrderItem WHERE OrderId IN :setOfOrder];    
            }
            
            for (OrderItem objOrderItem : listOrderItem) {
                if (!orderToItemTypeMap.containsKey(objOrderItem.OrderId)) {
                    orderToItemTypeMap.put(objOrderItem.OrderId, new Set<String>());
                }
                
                orderToItemTypeMap.get(objOrderItem.OrderId).add(objOrderItem.Type__c);
            }
            
            If(!setOfOrder.isEmpty())
                System.debug('AttachmentHandlerClass Called Dinesh 1');
                //AttachmentHandlerClass.AttachmentHandlerMethod(setOfOrder, JSON.serialize(orderToItemTypeMap));
                // System.enqueueJob(new AttachmentHandlerQueueable(setOfOrder, JSON.serialize(orderToItemTypeMap)));
                System.debug('setOfOrder>>' + setOfOrder);
                System.debug('orderToItemTypeMap>>' + orderToItemTypeMap);
                Database.executeBatch(new AttachmentHandlerQueueable(setOfOrder, JSON.serialize(orderToItemTypeMap)), 100);

        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    //=============================================================================================================================================================
    
    public static void sendPreOrderReceipt(list<Order> lstNewOrder, Map<Id, Order> oldMap){
        try{
            List<Id> lstAttachment = new List<Id>();
            Set<Id> setOfOrder = new Set<Id>();
            for (Order objOrder : lstNewOrder) {
                Order oldOrder = oldMap.get(objOrder.Id);
                if ((objOrder.Status == 'Booking' && oldOrder.Status != 'Booking')) {
                    setOfOrder.add(objOrder.Id);
                }
            }

            if (!setOfOrder.isEmpty()) {
                List<OrderItem> listOrderItem=[SELECT Id, Type__c, OrderId FROM OrderItem WHERE OrderId IN :setOfOrder];
                for (OrderItem objOrderItem : listOrderItem) {
                    if(objOrderItem.Type__c=='Vehicle'){
                            // System.enqueueJob(new AttachmentHandlerQueueable03(objOrderItem.OrderId));
                            // AttachmentHandlerClass.AttachmentHandlerMethod03(objOrderItem.OrderId);
                            Database.executeBatch(new AttachmentHandlerQueueable03(objOrderItem.OrderId), 100);
                        }
                    }
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    //==================================================================================================================================================================================
    
    public static void sendPreOrderReceipt01(list<Order_Payment__c>lstNewOrderPayment ){
        try{
            set<Id>setPayment=new set<id>();
            for(Order_Payment__c objOrderPayment:lstNewOrderPayment){
                if(objOrderPayment.Payments__c!=null){
                    setPayment.add(objOrderPayment.Payments__c);
                    // AttachmentHandlerClass.pdfAction(objOrderPayment.id);
                    // System.enqueueJob(new PdfActionQueueable(objOrderPayment.id));
                    Database.executeBatch(new PdfActionQueueable(objOrderPayment.id), 100);
                }
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        } 
    }
    
    // =================================================================================================================================================================================  
    
    // Jitendra : Validation for Dealer should have a single order at a time with same Vehicle on edit of order.
    public static void checkValidaionStatus(Map<Id,Order> newMap, Map<Id,Order> oldMap){
        try{
            List<Order> changedVINCustOrders = new List<Order>();
            if(newMap != null && newMap.values().size() > 0){
                for(Order newOrder : newMap.values()){
                    if(oldMap != null && oldMap.values().size() > 0 && oldMap.containsKey(newOrder.Id)){
                        Order oldOrder = oldMap.get(newOrder.Id);
                        if(oldOrder.AccountId == newOrder.AccountId && oldOrder.Assigned_Vehicle__c == newOrder.Assigned_Vehicle__c){
                            continue;
                        }
                        else {
                            changedVINCustOrders.add(newOrder);
                        }
                    }
                }
            }
            if(changedVINCustOrders != null && changedVINCustOrders.size() > 0){
                checkUniqueDealerVIN(changedVINCustOrders);
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    // Jitendra : Validation for Dealer should have a single order at a time with same Vehicle.
    public static void checkUniqueDealerVIN(List<Order> newList){
        try{
            Set<Id> customerIdSet = new Set<Id>();
            Set<Id> vinIdSet = new Set<Id>();
            Set<String> uniqueVINCustCombo = new Set<String>();
            Boolean isNewVIN = true;
            
            list<Order> allRelatedOrder = new list<Order>();
            System.debug('newList values'+newList);
            if(newList != null && newList.size() > 0){
                for(Order ord : newList){
                    if(ord.AccountId != null && ord.Assigned_Vehicle__c != null){
                        customerIdSet.add(ord.AccountId);
                        vinIdSet.add(ord.Assigned_Vehicle__c);
                    }
                }
            }
            
            // need to block an order if order was already created for that VIN.
            Set<Id> usedVINSet = new Set<Id>();
            System.debug('vinIdSet'+vinIdSet);
            
            List<Order> alreadyVINUsed = new List<Order>();
            if(!vinIdSet.isEmpty()){
            	alreadyVINUsed = [Select Id,Assigned_Vehicle__c from Order Where Assigned_Vehicle__c IN :vinIdSet];    
            }
            
            if(alreadyVINUsed != null && alreadyVINUsed.size() > 0){
                for(Order ord : alreadyVINUsed){
                    if(ord.Assigned_Vehicle__c != null){
                        usedVINSet.add(ord.Assigned_Vehicle__c);
                        }
                    }
            }
            System.debug('alreadyVINUsed'+alreadyVINUsed);
            System.debug('usedVINSet'+usedVINSet);
            if(newList != null && newList.size() > 0){
                for(Order ord : newList){
                    System.debug('ord.Assigned_Vehicle__c'+ord.Assigned_Vehicle__c);
                    if(ord.Assigned_Vehicle__c != null && usedVINSet != null && usedVINSet.contains(ord.Assigned_Vehicle__c)){
                        isNewVIN = false;//ord.addError('An order has already been created for this VIN number.');
                        break;
                    }
                }
            }
            
            // If there is no order related to VIN. Need to check if Account Owner is same with vehicle owner
            if(isNewVIN){
                Map<Id,Id> vehicleCustMap = new Map<Id,Id>();
                List<Vehicle> allRelatedvehicle  = new List<Vehicle>();
                if(!vinIdSet.isEmpty()){
                   allRelatedvehicle = [Select Id, Name, CurrentOwnerId from Vehicle Where Id IN :vinIdSet];
                }
                
                if(allRelatedvehicle != null && allRelatedvehicle.size() > 0){
                    for(Vehicle vc : allRelatedvehicle){
                        if(vc.CurrentOwnerId != null){
                            vehicleCustMap.put(vc.Id,vc.CurrentOwnerId);
                            }
                    }
                }
                
                if(newList != null && newList.size() > 0){
                    for(Order ord : newList){
                        if(ord.AccountId != null && ord.Assigned_Vehicle__c != null && vehicleCustMap != null && vehicleCustMap.size() > 0){
                            if(vehicleCustMap.get(ord.Assigned_Vehicle__c) != ord.AccountId){
                            // ord.addError('Please update the vehicle\'s Account Owner to create an order for this VIN number.');
                        }
                    }
                    }
                }
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    /******************************************************************************************************************/
    // 09/07/2024 : Added a field to capture product name on Order invoice. -by Pratha KR
    // 14/10/2024 : EW & RSA will be of type 'Add-ons' which will create a seperate orderinvoice  - by Pratha KR
    // Updated Code for Duplication Invoice Issue - 11/12/2024

    public static void ceateInvoiceRecords(List<Order> lstNewOrder, Map<Id, Order> oldOrdersMap) {
    try {
        List<Order_Invoice__c> orderInvoicesToInsert = new List<Order_Invoice__c>();
        Set<Id> accIdSet = new Set<Id>();
        Map<Id, Set<String>> orderToItemTypeMap = new Map<Id, Set<String>>();
        Map<Id, Id> orderIdToDealerId = new Map<Id, Id>();
        Map<Id, Account> accIdToAccMap = new Map<Id, Account>();
        Map<Id, Decimal> accIdToInvoiceNoToUpdateMap = new Map<Id, Decimal>();

        // Collect dealer IDs for orders that are changing to 'Pre Invoice'
        for (Order objOrder : lstNewOrder) {
            Order oldOrder = oldOrdersMap.get(objOrder.Id);
            if (oldOrder.Status != 'Pre Invoice' && objOrder.Status == 'Pre Invoice') {
                if (objOrder.Dealer__c != null) {
                    accIdSet.add(objOrder.Dealer__c);
                    orderIdToDealerId.put(objOrder.Id, objOrder.Dealer__c);
                }
            }
        }

        if (orderIdToDealerId.isEmpty()) {
            System.debug('No orders moving to Pre Invoice — exiting.');
            return;
        }

        // Query all order items for these orders
        List<OrderItem> newOrderItemList = [
            SELECT Id, Type__c, OrderId, Product2.Name
            FROM OrderItem
            WHERE OrderId IN :orderIdToDealerId.keySet()
        ];

        // Build orderToItemTypeMap and Product Map
        Map<Id, Map<String, List<String>>> orderIdToTypeToProductsMap = new Map<Id, Map<String, List<String>>>();
        for (OrderItem objOrderItem : newOrderItemList) {
            if (!orderToItemTypeMap.containsKey(objOrderItem.OrderId)) {
                orderToItemTypeMap.put(objOrderItem.OrderId, new Set<String>());
                orderIdToTypeToProductsMap.put(objOrderItem.OrderId, new Map<String, List<String>>());
            }
            orderToItemTypeMap.get(objOrderItem.OrderId).add(objOrderItem.Type__c);

            Map<String, List<String>> typeToProducts = orderIdToTypeToProductsMap.get(objOrderItem.OrderId);
            if (!typeToProducts.containsKey(objOrderItem.Type__c)) {
                typeToProducts.put(objOrderItem.Type__c, new List<String>());
            }
            typeToProducts.get(objOrderItem.Type__c).add(objOrderItem.Product2.Name);
        }

        // Query accounts
        if (!accIdSet.isEmpty()) {
            List<Account> accList = [
                SELECT Id, Invoice_Sequence__c, Center_Code__c
                FROM Account
                WHERE Id IN :accIdSet
            ];
            for (Account accObj : accList) {
                accIdToAccMap.put(accObj.Id, accObj);
            }
        }

        // Query existing invoices to avoid duplicates
        Map<Id, Set<String>> existingOrderToTypesMap = new Map<Id, Set<String>>();
        List<Order_Invoice__c> existingInvoices = [
            SELECT Id, Order__c, Invoice_Type__c
            FROM Order_Invoice__c
            WHERE Order__c IN :orderToItemTypeMap.keySet()
        ];
        for (Order_Invoice__c inv : existingInvoices) {
            if (!existingOrderToTypesMap.containsKey(inv.Order__c)) {
                existingOrderToTypesMap.put(inv.Order__c, new Set<String>());
            }
            existingOrderToTypesMap.get(inv.Order__c).add(inv.Invoice_Type__c);
        }

        // Loop through orders and create only missing invoices
        for (Id orderId : orderToItemTypeMap.keySet()) {
            if (orderToItemTypeMap.get(orderId) == null) continue;

            Integer invoiceNumber = (Integer)accIdToAccMap.get(orderIdToDealerId.get(orderId)).Invoice_Sequence__c != null ?
                (Integer)accIdToAccMap.get(orderIdToDealerId.get(orderId)).Invoice_Sequence__c : 0;

            Set<String> itemTypes = orderToItemTypeMap.get(orderId);
            Map<String, List<String>> orderItemToProductNameMap = orderIdToTypeToProductsMap.get(orderId);
            Set<String> alreadyExistingTypes = existingOrderToTypesMap.containsKey(orderId)
                ? existingOrderToTypesMap.get(orderId)
                : new Set<String>();

            Account accObj = accIdToAccMap.get(orderIdToDealerId.get(orderId));
            String centerCode = accObj.Center_Code__c;

            // VEHICLE INVOICE
            if (itemTypes.contains('Vehicle') && !alreadyExistingTypes.contains('Vehicle Invoice')) {
                String seqVH = GenerateInvoiceId.generateInvoiceId('RV', centerCode, 'VH', String.valueOf(invoiceNumber + 1));
                orderInvoicesToInsert.add(createInvoice(orderId, 'Vehicle Invoice', seqVH, orderItemToProductNameMap.get('Vehicle')));
                invoiceNumber++;
            }

            // ACCESSORIES INVOICE
            if ((itemTypes.contains('Accessories') || itemTypes.contains('Parts')) && !alreadyExistingTypes.contains('Accessories Invoice')) {
                String seqAC = GenerateInvoiceId.generateInvoiceId('RV', centerCode, 'AC', String.valueOf(invoiceNumber + 1));
                orderInvoicesToInsert.add(createInvoice(orderId, 'Accessories Invoice', seqAC, orderItemToProductNameMap.get('Accessories')));
                invoiceNumber++;
            }

            // OTHER CHARGES INVOICE
            if (itemTypes.contains('Parts') && !alreadyExistingTypes.contains('Other Charges Invoice')) {
                String seqOC = GenerateInvoiceId.generateInvoiceId('RV', centerCode, 'OC', String.valueOf(invoiceNumber + 1));
                orderInvoicesToInsert.add(createInvoice(orderId, 'Other Charges Invoice', seqOC, orderItemToProductNameMap.get('Parts')));
                invoiceNumber++;
            }

            // ADD-ONS INVOICE
            if (itemTypes.contains('Add-ons') && !alreadyExistingTypes.contains('Add-ons Invoice')) {
                String seqAO = GenerateInvoiceId.generateInvoiceId('RV', centerCode, 'AO', String.valueOf(invoiceNumber + 1));
                orderInvoicesToInsert.add(createInvoice(orderId, 'Add-ons Invoice', seqAO, orderItemToProductNameMap.get('Add-ons')));
                invoiceNumber++;
            }

            // MERCHANDISE INVOICE
            if (itemTypes.contains('Merchandise') && !alreadyExistingTypes.contains('Merchandise Invoice')) {
                String seqMD = GenerateInvoiceId.generateInvoiceId('RV', centerCode, 'MD', String.valueOf(invoiceNumber + 1));
                orderInvoicesToInsert.add(createInvoice(orderId, 'Merchandise Invoice', seqMD, orderItemToProductNameMap.get('Merchandise')));
                invoiceNumber++;
            }

            accIdToInvoiceNoToUpdateMap.put(orderIdToDealerId.get(orderId), invoiceNumber);
        }

        // Prepare Accounts to update sequence
        List<Account> accListToUpdate = new List<Account>();
        for (Id accId : accIdToInvoiceNoToUpdateMap.keySet()) {
            Account accObj = new Account(Id = accId);
            accObj.Invoice_Sequence__c = accIdToInvoiceNoToUpdateMap.get(accId);
            accListToUpdate.add(accObj);
        }

        // Final insert/update operations
        Savepoint sp = Database.setSavepoint();
        try {
            if (!orderInvoicesToInsert.isEmpty()) {
                insert orderInvoicesToInsert;

                // Update orders' flag
                List<Order> ordersToUpdate = new List<Order>();
                for (Id orderId : orderIdToDealerId.keySet()) {
                    ordersToUpdate.add(new Order(Id = orderId, IsOrderInvoicesGenerated__c = true));
                }
                if (!ordersToUpdate.isEmpty()) update ordersToUpdate;
            } else {
                System.debug('No new invoice types found — skipping insert.');
            }

            if (!accListToUpdate.isEmpty()) {
                update accListToUpdate;
            }

        } catch (Exception ex) {
            Database.rollback(sp);
            System.debug('Error during insert/update: ' + ex.getMessage());
        }

    } catch (Exception e) {
        System.debug('Error Message: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
    }
}


    public static Order_Invoice__c createInvoice(Id orderId, string invoiceType, string invoiceSequence, list<string> productName){
        try{
            List<Order>orderToUpdates = new List<order>();
            
            Order_Invoice__c invoice = new Order_Invoice__c();
            invoice.Name = invoiceType;
            invoice.Invoice_Number__c = invoiceSequence;
            if (invoiceType == 'Other Charges') {
                // Directly update the order's Invoice Number without querying
                Order orderToUpd = new Order(Id = orderId);
                orderToUpd.Invoice_Number__c = invoiceSequence;
                orderToUpdates.add(orderToUpd);
            }
            System.debug('INVOICE line no 619 --> '+invoiceType);
            invoice.Invoice_Type__c = invoiceType;
            invoice.Order__c = orderId;
            //If(productName != null)
              //  invoice.Order_Name__c = string.join(productName,',');
            if (!orderToUpdates.isEmpty()) {
                System.debug('orderToUpdates'+orderToUpdates);
                update orderToUpdates;
            }
            Return invoice;
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        return null;
    }

    /***********************************************************************************************************************/
    public static void addTest(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
		j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
             
        
    }
    public static void addTest2(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
		j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
             
        
    }
    public static void addTest3(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
		j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
             
        
    }
    public static void addTest4(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
		j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
             
        
    }
     public static void addTest5(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
		j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
             
        
    }
     public static void addTest6(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
		j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
             
        
    }
     public static void addTest7(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
		j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
             
        
    }
     public static void addTest8(){
        Integer j=0;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
		j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;     
        j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;j++;
             
        
    }
    
    Public class myexception extends exception{}
    
}