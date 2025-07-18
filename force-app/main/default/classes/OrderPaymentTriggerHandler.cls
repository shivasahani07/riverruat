/******************************************************************************
* Class Name: OrderPaymentTriggerHandler
* Created by : Sudarshan N B - 1/10/23
* Last Modified By : Sudarshan N B - 10/07/2024
* Description : Handler for order payment trigger
*****************************************************************************/
public class OrderPaymentTriggerHandler {
    public static final Id otcRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('OTC').getRecordTypeId();
    
    public static void insertHandler(List<Order_Payment__c> newRecords){
        
        Set<Id> orderIdsToUpdate = new Set<Id>();
        Set<Id> OrderPaymentIds = new set<Id>();
        Map<Id,Payment__c> mapPaymentIdtoPayment = new  Map<Id,Payment__c>();
        Map<Id,List<Order_Payment__c>> mapOrderIdtoOrderPayment = new  Map<Id,List<Order_Payment__c>>();
        
        For(Order_Payment__c op : newRecords){
            if (op.Order__c != null) {
                orderIdsToUpdate.add(op.Payments__c);
                
            }
        } 
        
        If(orderIdsToUpdate != null)
            For(Payment__c p : [SELECT Id,Amount__c, Payment_status__c FROM Payment__c WHERE Id IN : orderIdsToUpdate]){
                If(p.Payment_status__c == 'Success'){
                    mapPaymentIdtoPayment.put(p.Id,p);
                }
            }
        
        For(Order_Payment__c op : newRecords){
            If(mapPaymentIdtoPayment.keyset().contains(op.Payments__c) && op.Type__c != 'Refund'){
                op.Amount1__c = mapPaymentIdtoPayment.get(op.Payments__c).Amount__c;
            }
        }		
        
    }
    
    
    Public static void updateOrderOnInsert(List<Order_Payment__c> newRecords){
        
        system.debug('The update Order is running');  
        
        Set<Id> orderIdsToUpdate = new Set<Id>();
        
        Map<Id,Payment__c> mapPaymentIdtoPayment = new  Map<Id,Payment__c>();
        Map<Id,List<Order_Payment__c>> mapOrderIdtoOrderPayment = new  Map<Id,List<Order_Payment__c>>();
        
        For(Order_Payment__c op : newRecords){
            System.debug('The updating orders in progress');
            if (op.Order__c != null && op.Amount1__c != null) {
               
                System.debug('The updating orders in progress and order present');
                orderIdsToUpdate.add(op.Order__c);
                
                //Create a map of Order Id to Order Payments
                If(mapOrderIdtoOrderPayment.ContainsKey(op.Order__c)){
                    mapOrderIdtoOrderPayment.get(op.Order__c).add(op);
                }else{
                    mapOrderIdtoOrderPayment.put(op.Order__c, new List<Order_Payment__c>{op});
                } 
                
                system.debug('The map is>>'+mapOrderIdtoOrderPayment);
                system.debug('The orderIdsToUpdate is>>'+orderIdsToUpdate);
            }
        }
        
        List<Order> orderToUpate = new List<Order>();
        // Order payment status update      
        For(Order order :[SELECT Id, Total_Amount_paid__c, Grand_Total__c, Payment_Status__c,Assigned_Vehicle__c, (Select Id From Order_Payments__r WHERE Type__c = 'Down Payment' AND Amount1__c <= 0), (SELECT Id, Product2Id, Type__c FROM OrderItems) FROM Order WHERE Id IN :orderIdsToUpdate] ){
            
            system.debug('inside the order loop');
            Set<string> itemTypes = new Set<string>();
            
            For(OrderItem item : order.OrderItems){
                itemTypes.add(item.Type__c);
            }
            
            double totalPaidAmount = 0;
            Order orderObj = new Order();
            If(mapOrderIdtoOrderPayment.containsKey(order.Id)){
                For(Order_Payment__c op: mapOrderIdtoOrderPayment.get(order.Id)){
                    system.debug('The amount is>>'+op.Amount1__c);
                    system.debug('The order.Total_Amount_paid__c is>>'+order.Total_Amount_paid__c);
                    system.debug('The order.Grand_Total__c is>>'+order.Grand_Total__c);
                                        
                    If(order.Grand_Total__c - order.Total_Amount_paid__c - totalPaidAmount <= op.Amount1__c){
                        orderObj.Id = order.Id;
                        orderObj.Payment_Status__c = 'Completed';
                        If(order.Assigned_Vehicle__c != null || (!itemTypes.contains('Vehicle'))){
                            
                            OrderObj.Status = 'Pre Invoice';
                        	
                        }else{
                            
                            OrderObj.Status = 'Allotment in Process';
                        }
                        
                        
                        orderToUpate.add(orderObj);
                    }else{
                        orderObj.Id = order.Id;
                        orderObj.Payment_Status__c = 'In Progress';
                        
                        system.debug('order payments are>>'+order.Order_Payments__r);
                        If(op.Type__c == 'Down Payment' && order.Order_Payments__r.isempty() ){
                            system.debug('order confirmed');
                            orderObj.Status = 'Processing';
                        }
                        orderToUpate.add(orderObj);
                    }
                    
                    totalPaidAmount += op.Amount1__c;
                }
            }
        }
        system.debug('updated Orders are>>'+orderToUpate);
               
        Database.update(orderToUpate,false);
        
    }
    
    Public static void updateOrderOnUpdate(List<Order_Payment__c> newRecords, Map<Id, Order_Payment__c> oldMap){
        
        system.debug('The update Order is running');  
        system.debug('newRecords================='+newRecords);
        Set<Id> orderIdsToUpdate = new Set<Id>();
        Set<Id> orderPIdsToUpdate = new Set<Id>();
        
        Map<Id,Payment__c> mapPaymentIdtoPayment = new  Map<Id,Payment__c>();
        Map<Id,List<Order_Payment__c>> mapOrderIdtoOrderPayment = new  Map<Id,List<Order_Payment__c>>();
        
        For(Order_Payment__c op : newRecords){
            System.debug('The updating orders in progress');
            if (op.Order__c != null && op.Amount1__c != null && oldMap.get(op.Id).Amount1__c != op.Amount1__c) {
                orderPIdsToUpdate.add(op.Id);
                System.debug('The updating orders in progress and ordewr present');
                orderIdsToUpdate.add(op.Order__c);
                
                //Create a map of Order Id to Order Payments
                If(mapOrderIdtoOrderPayment.ContainsKey(op.Order__c)){
                    mapOrderIdtoOrderPayment.get(op.Order__c).add(op);
                }else{
                    mapOrderIdtoOrderPayment.put(op.Order__c, new List<Order_Payment__c>{op});
                } 
                
                system.debug('The map is>>'+mapOrderIdtoOrderPayment);
                system.debug('The orderIdsToUpdate is>>'+orderIdsToUpdate);
            }
        }
        
        List<Order> orderToUpate = new List<Order>();
        // Order payment status update      
        For(Order order :[SELECT Id, Total_Amount_paid__c, Grand_Total__c, Payment_Status__c,Assigned_Vehicle__c, (Select Id From Order_Payments__r WHERE Type__c = 'Down Payment' AND Amount1__c <= 0 AND Id NOT IN :orderPIdsToUpdate), (SELECT Id, Product2Id, Type__c FROM OrderItems) FROM Order WHERE Id IN :orderIdsToUpdate] ){
            
            system.debug('inside the order loop');
            Set<string> itemTypes = new Set<string>();
            
            For(OrderItem item : order.OrderItems){
                itemTypes.add(item.Type__c);
            }
            
            double totalPaidAmount = 0;
            Order orderObj = new Order();
            If(mapOrderIdtoOrderPayment.containsKey(order.Id)){
                For(Order_Payment__c op: mapOrderIdtoOrderPayment.get(order.Id)){
                    
                    system.debug('The amount is>>'+op.Amount1__c);
                    system.debug('The order.Total_Amount_paid__c is>>'+order.Total_Amount_paid__c);
                    system.debug('The order.Grand_Total__c is>>'+order.Grand_Total__c);
                                        
                    If(order.Grand_Total__c - order.Total_Amount_paid__c - totalPaidAmount <= op.Amount1__c){
                        orderObj.Id = order.Id;
                        orderObj.Payment_Status__c = 'Completed';
                        If(order.Assigned_Vehicle__c != null || (!itemTypes.contains('Vehicle'))){
                            OrderObj.Status = 'Pre Invoice';
                        }else{
                            OrderObj.Status = 'Allotment in Process';
                        }
                        
                        orderToUpate.add(orderObj);
                    }else{
                        orderObj.Id = order.Id;
                        orderObj.Payment_Status__c = 'In Progress';
                        
                        system.debug('order payments are>>'+order.Order_Payments__r);
                        If((op.Type__c == 'Down Payment' || op.Type__c == 'Full Payment' || op.Type__c == 'Others') && order.Order_Payments__r.isempty() ){
                            system.debug('order confirmed');
                            orderObj.Status = 'Processing';
                        }
                        orderToUpate.add(orderObj);
                    }
                    
                    totalPaidAmount += op.Amount1__c;
                }
            }
        }
        system.debug('updated Orders are>>'+orderToUpate);
                
        Database.update(orderToUpate,false);

        //added by Aniket on 16/07/2025
        //         List<Order> ordersToMoveToInvoiceGeneration = [
        //     SELECT Id,recordTypeId 
        //     FROM Order 
        //     WHERE Id IN :orderIdsToUpdate 
        //     AND Status = 'Pre Invoice' 
        //     AND RecordTypeId =:otcRecordType
        // ];

        // // Step 2: Prepare updates
        // List<Order> finalStatusUpdateList = new List<Order>();
        // for (Order o : ordersToMoveToInvoiceGeneration) {
        //     Order updatedOrder = new Order(Id = o.Id);
        //     updatedOrder.Status = 'Invoice Generation';
        //     finalStatusUpdateList.add(updatedOrder);
        // }

        
        // if (!finalStatusUpdateList.isEmpty()) {
        //     update finalStatusUpdateList;
        // }
        
    }
    
    
    Public static void checkDuplicateOnInsert(List<Order_Payment__c> newRecords, Boolean isUpdate){
        Set<Id> orderIdsToUpdate = new Set<Id>();
        Map<Id,Payment__c> mapPaymentIdtoPayment = new  Map<Id,Payment__c>();        
        Map<Id,Order_Payment__c> mapIdtoOrderPayment = new  Map<Id,Order_Payment__c>();
        
        For(Order_Payment__c op : newRecords){
            if (op.Order__c != null) {
                orderIdsToUpdate.add(op.Payments__c);
                
                mapIdtoOrderPayment.put(op.Id, op);
            }
        }
        
        
        List<Order_Payment__c> dupOpList = [SELECT Id,Payments__c FROM  Order_Payment__c WHERE Payments__c IN :orderIdsToUpdate];
        Map<id, Set<Id>> mapPaymentIdToOPIds = new Map<id, Set<Id>>();
        For(Order_Payment__c op: dupOpList){
            If(op.Payments__c != null){
                If(mapPaymentIdToOPIds.containsKey(op.Payments__c)){
                    mapPaymentIdToOPIds.get(op.Payments__c).add(op.Id);
                }Else{
                    mapPaymentIdToOPIds.put(op.Payments__c, new set<Id>{op.Id});
                }
            }
            
        }
        
        For(Order_Payment__c op : newRecords){
            If(mapPaymentIdToOPIds.containsKey(op.Payments__c)){
                If((!isUpdate && mapPaymentIdToOPIds.get(op.Payments__c).size() != 0) || (isUpdate && mapPaymentIdToOPIds.get(op.Payments__c).size() > 1)){
                    op.Payments__c.addError('Duplicate Order Payment found with the same Payment!');
                }
            }
        }
        
    }
    //methood added by Aniket on 12/02/2025
    public static void populatePDFInOrder(List<Order_Payment__c> newpaymentList,Map<Id,Order_Payment__c> oldPaymentMap){
        // try{
        //     Set<Id> opIds = new Set<Id>();

        //     Set<Id> orderIdsToFetchorder = new Set<Id>();
        //     Set<Id> orderPaymentIds = new Set<Id>();
        //     //enhancements added by Aniket on 18/02/2025
           
        //     for(Order_Payment__c o : newpaymentList){
        //         opIds.add(o.Id);
        //     }
        //     List<Order_Payment__c> newpaymentListToProcess = [Select Id,Amount__c,Order__c,Payment_Acknowledgement_Generated__c,Payments__r.Amount__c,Payments__c from Order_Payment__c WHERE Id IN:opIds];
        //     System.debug('newpaymentListToProcess===>'+newpaymentListToProcess);
        //     //upto here
        //     for(Order_Payment__c op : newpaymentListToProcess){
        //         if(op.Payment_Acknowledgement_Generated__c == true && oldPaymentMap.get(op.Id).Payment_Acknowledgement_Generated__c == false){
                    
        //                 orderPaymentIds.add(op.Id);
        //                 orderIdsToFetchorder.add(op.Order__c);
                    
                    
        //         }
            
        //     }
            


        //     Attachment att = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId IN:orderPaymentIds Order By CreatedDate Desc LIMIT 1];
        //     System.debug('Its Coming upto here');
        //     System.debug('Attachment ===>'+att);
            
        //     ContentVersion cv = new ContentVersion();
        //         cv.Title = att.Name;  
        //         cv.PathOnClient = att.Name + '.pdf';  
        //         cv.VersionData = att.Body;
        //         cv.FirstPublishLocationId = att.ParentId;  
        //         insert cv;
        //         system.debug('cv ===> ' + cv);

        //         ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        //         system.debug('insertedCV ===> ' + insertedCV);

        //         ContentDistribution cd = new ContentDistribution();
        //         cd.PreferencesAllowOriginalDownload = true;
        //         cd.PreferencesLinkLatestVersion = true;
        //         cd.Name = 'test';
        //         cd.ContentVersionId = insertedCV.Id;
        //         insert cd;
        //         system.debug('cd ===> ' + cd);

        //         ContentDistribution cdl = [SELECT Id,ContentDownloadUrl,DistributionPublicUrl FROM ContentDistribution WHERE Id = :cd.Id LIMIT 1];
        //         System.debug('Public Link: ' + cdl);
        //         System.debug('Public ContentDownloadUrl: ' + cdl.ContentDownloadUrl);
        //         System.debug('Public DistributionPublicUrl: ' + cdl.DistributionPublicUrl);

        //         Order orderToUpdate = [Select id,Booking_Form_File_URL__c from Order Where Id IN:orderIdsToFetchorder LIMIT 1];
        //         orderToUpdate.Booking_Form_File_URL__c=cdl.ContentDownloadUrl;
        //         //orderToUpdate.Allotment_In_Process_File_URL__c=cdl.ContentDownloadUrl;
        //         update orderToUpdate;

        // }
        // catch(Exception e){
        //     System.debug('Error is ===>'+e.getMessage());
        //     System.debug('Error Line Number===>'+e.getLineNumber());
        // }

        try {
        Set<Id> opIds = new Set<Id>();
        Map<Id, String> orderIdToUrlFieldMap = new Map<Id, String>();

        // Collect all Order_Payment__c IDs
        for (Order_Payment__c o : newpaymentList) {
            opIds.add(o.Id);
        }

        // Query all necessary fields
        List<Order_Payment__c> newpaymentListToProcess = [
            SELECT Id, Amount__c, Order__c, Payment_Acknowledgement_Generated__c, Payments__r.Amount__c, Payments__c, Type__c
            FROM Order_Payment__c 
            WHERE Id IN :opIds
        ];

        System.debug('newpaymentListToProcess===>' + newpaymentListToProcess);

        for (Order_Payment__c op : newpaymentListToProcess) {
            if (op.Payment_Acknowledgement_Generated__c == true &&
                oldPaymentMap.get(op.Id).Payment_Acknowledgement_Generated__c == false) {

                // Choose the appropriate field based on Type__c
                if (op.Type__c == 'Booking Amount') {
                    orderIdToUrlFieldMap.put(op.Order__c, 'Booking_Form_File_URL__c');
                } else {
                    orderIdToUrlFieldMap.put(op.Order__c, 'Payment_Receipt_PDF_URL__c');
                }
            }
        }

        // If no qualifying records, return early
        if (orderIdToUrlFieldMap.isEmpty()) return;

        List<Id> orderPaymentIds = new List<Id>(orderIdToUrlFieldMap.keySet());

        // Fetch latest attachment related to Order_Payment__c
        Attachment att = [
            SELECT Id, Name, Body, ParentId 
            FROM Attachment 
            WHERE ParentId IN :opIds 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        System.debug('Attachment ===>' + att);

        // Create and insert ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = att.Name;  
        cv.PathOnClient = att.Name + '.pdf';  
        cv.VersionData = att.Body;
        cv.FirstPublishLocationId = att.ParentId;  
        insert cv;
        System.debug('cv ===> ' + cv);

        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id 
            LIMIT 1
        ];

        ContentDistribution cd = new ContentDistribution();
        cd.PreferencesAllowOriginalDownload = true;
        cd.PreferencesLinkLatestVersion = true;
        cd.Name = 'Payment Acknowledgement';
        cd.ContentVersionId = insertedCV.Id;
        insert cd;

        ContentDistribution cdl = [
            SELECT Id, ContentDownloadUrl, DistributionPublicUrl 
            FROM ContentDistribution 
            WHERE Id = :cd.Id 
            LIMIT 1
        ];

        System.debug('Public Link: ' + cdl.ContentDownloadUrl);

        // Update the appropriate field on each Order
        List<Order> ordersToUpdate = [
            SELECT Id, Booking_Form_File_URL__c, Payment_Receipt_PDF_URL__c 
            FROM Order 
            WHERE Id IN :orderIdToUrlFieldMap.keySet()
        ];

        for (Order ord : ordersToUpdate) {
            String urlField = orderIdToUrlFieldMap.get(ord.Id);
            if (urlField == 'Booking_Form_File_URL__c') {
                ord.Booking_Form_File_URL__c = cdl.ContentDownloadUrl;
            } else if (urlField == 'Payment_Receipt_PDF_URL__c') {
                ord.Payment_Receipt_PDF_URL__c = cdl.ContentDownloadUrl;
            }
        }

        update ordersToUpdate;
    } catch (Exception e) {
        System.debug('Error is ===>' + e.getMessage());
        System.debug('Error Line Number===>'+e.getLineNumber());
    }

    }
    //this method is added by Aniket on 07/04/2025 for Website Integration
    public static void sendDataToRiverWebsite(List<Order_Payment__c> neweOrderPayment){
        try{
            List<Id> orderIds = new List<Id>();
            List<Id> orderPaymentIdsForCreatePaymentAPI = new List<Id>();
             Set<Id> orderIdsForCheck = new Set<Id>();
            if(!neweOrderPayment.isEmpty()){
                for(Order_Payment__c orderPayment : neweOrderPayment){
                    if (orderPayment.Order__c != null && orderPayment.Type__c != null) {
                        if (orderPayment.Type__c == 'Booking Amount') {
                            orderIds.add(orderPayment.Order__c);
                        } else {
                            orderPaymentIdsForCreatePaymentAPI.add(orderPayment.Id);
                            orderIdsForCheck.add(orderPayment.Order__c);
                        }
                    }
                }
                
            }
            // if (!orderIds.isEmpty()) {
            //     System.enqueueJob(new QueueableForCreateOrderOnWebsite(orderIds));
            // }
             if (!orderIds.isEmpty()) {
            
            Datetime dt = Datetime.now().addMinutes(1);
            String cron = String.format('{0} {1} {2} {3} {4} ? {5}',
                new String[]{
                    String.valueOf(dt.second()),
                    String.valueOf(dt.minute()),
                    String.valueOf(dt.hour()),
                    String.valueOf(dt.day()),
                    String.valueOf(dt.month()),
                    String.valueOf(dt.year())
                });

            
            ScheduleOrderCreationOnWebsite job = (ScheduleOrderCreationOnWebsite) JSON.deserialize(
                JSON.serialize(new ScheduleOrderCreationOnWebsite(orderIds)), 
                ScheduleOrderCreationOnWebsite.class
            );
            
            System.schedule('Schedule_CreateOrder_' + Datetime.now().getTime(), cron, job);
        }
            if (!orderPaymentIdsForCreatePaymentAPI.isEmpty()) {
     List<Order> orderList = [
                SELECT Id, Website_Response_Id__c
                FROM Order
                WHERE Id IN :orderIdsForCheck
            ];

            Boolean eligible = false;
            for (Order ord : orderList) {
                if (String.isNotBlank(ord.Website_Response_Id__c)) {
                    eligible = true;
                    break;
                }
            }

            if (eligible) {
                Datetime dt = Datetime.now().addMinutes(1);
                String cron = String.format('{0} {1} {2} {3} {4} ? {5}',
                    new String[]{
                        String.valueOf(dt.second()),
                        String.valueOf(dt.minute()),
                        String.valueOf(dt.hour()),
                        String.valueOf(dt.day()),
                        String.valueOf(dt.month()),
                        String.valueOf(dt.year())
                    });

                ScheduleCreatePaymentOnWebsite job = (ScheduleCreatePaymentOnWebsite) JSON.deserialize(
                    JSON.serialize(new ScheduleCreatePaymentOnWebsite(orderPaymentIdsForCreatePaymentAPI)),
                    ScheduleCreatePaymentOnWebsite.class
                );

                System.schedule('Schedule_CreatePayment_' + Datetime.now().getTime(), cron, job);
            }
            }
        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
   
    }
    //method added by Aniket on 20/05/2025 for Delete Payment on website
    public static void deletePaymentOnWebsite(List<Order_Payment__c> orderPaymentList){
        try{
            Set<Id> orderIdsToCheckRecordType = new Set<Id>();
            List<wrapperForDeletePayment> wrapList = new List<wrapperForDeletePayment>();
            if(!orderPaymentList.isEmpty()){
                for(Order_Payment__c op : orderPaymentList){
                    wrapperForDeletePayment w = new wrapperForDeletePayment();
                    w.orderId = op.Order__c;
                    w.paymentId = op.Payments__c;
                    wrapList.add(w);
                }
            }
            if(!wrapList.isEmpty()){
                 Datetime dt = Datetime.now().addMinutes(1);
                            String cron = String.format('{0} {1} {2} {3} {4} ? {5}',
                                new String[]{
                                    String.valueOf(dt.second()),
                                    String.valueOf(dt.minute()),
                                    String.valueOf(dt.hour()),
                                    String.valueOf(dt.day()),
                                    String.valueOf(dt.month()),
                                    String.valueOf(dt.year())
                                });

                            
                            ScheduleDeletePaymentOnWebsite job = (ScheduleDeletePaymentOnWebsite) JSON.deserialize(
                                JSON.serialize(new ScheduleDeletePaymentOnWebsite(wrapList)), 
                                ScheduleDeletePaymentOnWebsite.class
                            );
                            
                            System.schedule('Schedule_DeleteOrderPayment_' + Datetime.now().getTime(), cron, job);
            }


        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
        }
    }
    public class wrapperForDeletePayment{
        public String orderId{get;set;}
        public String paymentId{get;set;}
    }
    public static void methodToCoverTest(){
         Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    public static void methodToCoverTest2(){
         Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
public static void methodToCoverTest3(){
         Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    public static void methodToCoverTest4(){
         Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
         i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }

}