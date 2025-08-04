/**
* @description       : 
* @author            : Aniket Karmakar
* @group             : 
* @last modified on  : 08-01-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/shipment2')
global without sharing class OrderAndShipmentController {
    
    @HttpPost
    global static void createOrderShipment(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        Id OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        Id hardcodedSourceLocationId = System.Label.Default_River_Warehouse;
        System.debug('hardcodedSourceLocationId==>'+hardcodedSourceLocationId);
        System.debug('OrderPurchaseRecordType==>'+OrderPurchaseRecordType);
        String reqBody;
        try{
            //Savepoint sp = Database.setSavepoint();
            Map<String, String> objectErrorMessages = new Map<String, String>();
            Savepoint sp1 = Database.setSavepoint();

            reqBody = request.requestBody != null ? request.requestBody.toString() : '';
            System.debug('Request Body ==> ' + reqBody);
            
            Map<String, Object> requestMap = (reqBody != '') ?  (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String,Object>();
            System.debug('Request Map ==>' + requestMap);
            
            List<String> failedObjects = new List<String>();
            List<String> successObjects = new List<String>();
            
            Map<String, Object> shipmentDetails = (Map<String, Object>) requestMap.get('shipment');
            
            String sapDeliveryNo= shipmentDetails.containsKey('sap_delivery_no') ? (String)shipmentDetails.get('sap_delivery_no') : 'Not Found';
            
            
            if (String.isBlank(sapDeliveryNo)) {
                response.statusCode = 400;
                response.responseBody = responseUtility('sap delivery number is missing',false);
                return;
            }
            
            Set<String> shipmentPicklistrValues = statusPicklistValues();
            String availablePicklistValues = String.join(shipmentPicklistrValues,', ');
            String statusOfShipment = shipmentDetails.containsKey('status') ? (String)shipmentDetails.get('status') : 'Not Found';
            if(!shipmentPicklistrValues.contains(statusOfShipment)){
                response.statusCode = 400;
                response.responseBody = responseUtility('Status Value Does Not match With Salesforce Shipment Status API Name .It Needs to be amongst these value == >' + availablePicklistValues  ,false);
                return;
            }
            String shipToName = shipmentDetails.containsKey('ShipToName') ? (String)shipmentDetails.get('ShipToName') : 'Not Found';
            
            List<Order> existingOrders = [SELECT Id,Purchase_Order__c,sap_delivery_no__c FROM Order WHERE sap_delivery_no__c = :sapDeliveryNo LIMIT 1];
            if (!existingOrders.isEmpty()) {
                
                Id existingOrderId = existingOrders[0].Id;
                String sapShipment = shipmentDetails.containsKey('sap_shipment_id') ? (String)shipmentDetails.get('sap_shipment_id') : 'Not Found';
                List<Shipment> existingShipments = [SELECT Id FROM Shipment WHERE sap_shipment_id__c = :sapShipment LIMIT 1];
                
                if (!existingShipments.isEmpty()) {
                    response.statusCode = 400;
                    response.responseBody = responseUtility('Shipment with ' + sapShipment + ' already exists'  ,false);
                    return;
                }
                Savepoint sp = Database.setSavepoint();

                Shipment s = new Shipment();
                s.Order__c = existingOrderId;
                s.Status = 'New';
               // s.Status = 'Preparing for Dispatch';
                s.SourceLocationId = hardcodedSourceLocationId;
                s.ShipToName = shipToName;
                s.sap_shipment_id__c = sapShipment;
                //s.Purchase_Order__c=existingOrders[0].Purchase_Order__c;
                
                try {
                    insert s;
                    successObjects.add('Shipment');
                    System.debug('Shipment 1==>'+s);
                } catch (Exception e) {
                    System.debug('Error==>' + e.getMessage());
                    objectErrorMessages.put('Shipment==>', e.getMessage());
                    failedObjects.add('Shipment');
                }
                
                
                List<Object> rawLineItems = (List<Object>) shipmentDetails.get('lineItems');
                List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
                
                for (Object item : rawLineItems) {
                    lineItems.add((Map<String, Object>) item);
                }
                
                List<String> itemCodes = new List<String>();
                for (Map<String, Object> item : lineItems) {
                    itemCodes.add((String)item.get('item_code'));
                }
                
                Map<String, Product2> itemCodeToProductMap = new Map<String, Product2>();
                for (Product2 prod : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :itemCodes]) {
                    itemCodeToProductMap.put(prod.ProductCode, prod);
                }
                
                List<ShipmentItem> shipmentItemsToInsert = new List<ShipmentItem>();
                for (Map<String, Object> item : lineItems) {
                    String itemCode = (String)item.get('item_code');
                    Decimal quantity = item.containsKey('quantity') ? (Decimal)item.get('quantity') : 0;
                    
                    if (itemCodeToProductMap.containsKey(itemCode)) {
                        Product2 prod = itemCodeToProductMap.get(itemCode);
                        
                        ShipmentItem sri = new ShipmentItem();
                        sri.Product2Id = prod.Id;
                        sri.Quantity = quantity;
                        sri.Parent_Shipment__c = s.Id;
                        sri.ShipmentId=s.Id;
                        shipmentItemsToInsert.add(sri);
                    }
                }
                
                try {
                    if (!shipmentItemsToInsert.isEmpty()) insert shipmentItemsToInsert;
                    System.debug('shipmentItemsToInsert1==>'+shipmentItemsToInsert);
                    successObjects.add('Shipment Items');
                } catch (Exception e) {
                  
                    System.debug('Error==>' + e.getMessage());
                    objectErrorMessages.put('Shipment Line Items==>', e.getMessage());
                    failedObjects.add('Shipment Items');
                    
                }
                
                
                Map<String, Object> finalResponse = new Map<String, Object>();
                if (!failedObjects.isEmpty()) {
                   
                    Database.rollback(sp1);

                    String combinedErrors='';
                    for (String objName : objectErrorMessages.keySet()) {
                    combinedErrors += objName + ' => ' + objectErrorMessages.get(objName) + '\n';
                    }
                    finalResponse.put('success',false );
                    finalResponse.put('status code', '400');
                    finalResponse.put('message', 'Error in Creating Shipment');
                    response.statusCode = 400;

                    Integration_Log__c logObj = new Integration_Log__c(  
                    Integration_Type__c = 'SAP',  
                    Request_Payload__c = reqBody,  
                    Response_Payload__c = JSON.serializePretty(finalResponse),
                    Error_Message__c = combinedErrors,
                    Status__c = 'Failed'  
                    );  
                    insert logObj; 

                    
                } else {
                    finalResponse.put('success', true);
                    finalResponse.put('status code', 200);
                    finalResponse.put('message', 'Shipment and Shipment Items inserted successfully');
                    finalResponse.put('salesforce_shipment_id',String.valueof(s.Id));
                    response.statusCode=200;
                }
                
                response.responseBody = Blob.valueOf(JSON.serializePretty(new Map<String, Object>{
                    'data' => finalResponse
                        }));
                return;
            }
            //If Order does not exist only then create the Order and Order Products(Ref. By Aniket)
            
            List<SObject> recordToInsert = new List<SObject>();
            
            String poNumber = shipmentDetails.containsKey('po_number') ? (String)shipmentDetails.get('po_number') : 'Not Found';
            System.debug('poNumber==>'+poNumber);
            
            String sapShipment = shipmentDetails.containsKey('sap_shipment_id') ? (String)shipmentDetails.get('sap_shipment_id') : 'Not Found';
            
            List<Shipment> shipmentList = [SELECT Id,sap_shipment_id__c FROm Shipment WHERE sap_shipment_id__c=:sapShipment LIMIT 1];
            if(!shipmentList.isEmpty()){
                response.statusCode = 400;
                response.responseBody = responseUtility('Shipment with '+sapShipment+' already Exists',false);
                return;
            }
            
            String drivername = shipmentDetails.containsKey('driver_name') ? (String)shipmentDetails.get('driver_name') : 'Not Found';
            String driverPhone = shipmentDetails.containsKey('driver_phone') ? (String)shipmentDetails.get('driver_phone') : 'Not Found';
            
            ProductRequest p;
            ProductRequestLineItem pr;
            Id pricebookId;
            List<ProductRequest> purchaseOrderList = [SELECT Id,Account__c,ProductRequestNumber,Destination_Location__c,Destination_Location__r.Price_Book__c,ShipmentType,Contact__c,Contact__r.Email,Status FROM ProductRequest WHERE ProductRequestNumber =:poNumber LIMIT 1];
            System.debug('purchaseOrderList==>'+purchaseOrderList);
            if(!purchaseOrderList.isEmpty()){
                p = purchaseOrderList[0];
                System.debug('Fetched Purchase Order ==>'+p);
            }else if(purchaseOrderList.isEmpty()){
                response.statusCode = 400;
                response.responseBody = responseUtility('No PR was found for '+ poNumber,false);
                return;
            }
            List<ProductRequestLineItem> prliList = [SELECT Id, Product2Id, Product2.Name, ParentId, Parent.Destination_Location__c, Parent.Destination_Location__r.Name,  Parent.Account__c, QuantityRequested, Alloted_Quantity__c,Price_Book__c,CGST__c,SGST__c,IGST__c FROM ProductRequestLineItem WHERE ParentId=:p.Id];
            if(!prliList.isEmpty()){
                pr=prliList[0];
            }
            if(p != null && p.Destination_Location__c != null && p.Destination_Location__r.Price_Book__c != null){
                pricebookId = p.Destination_Location__r.Price_Book__c;
            }
            
            Order newOrder = new Order();
            newOrder.AccountId = p.Account__c;
            newOrder.Contact__c=p.Contact__c;
            newOrder.Purchase_Order__c=p.Id;
            newOrder.Status='Draft';//added by Aniket after UAT Feedback from Hiba and Patrick
            newOrder.ISVOR__c=p.ShipmentType != null && p.ShipmentType == 'VOR' ? True : False;
            newOrder.EffectiveDate=System.Today();
            newOrder.Pricebook2Id=pricebookId;
            newOrder.RecordTypeId=OrderPurchaseRecordType;
            newOrder.sap_delivery_no__c=sapDeliveryNo;
            
            try {
                insert newOrder;
               
                successObjects.add('Order');
            } catch (Exception e) {
                System.debug('Error==>'+e.getMessage());
                objectErrorMessages.put('Order=>', e.getMessage());
                failedObjects.add('Order');
            }
            List<Object> rawLineItems = (List<Object>) shipmentDetails.get('lineItems');
            List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
            
            for (Object item : rawLineItems) {
                lineItems.add((Map<String, Object>) item);
            }
            
            
            List<String> itemCodes = new List<String>();
            for (Map<String, Object> item : lineItems) {
                itemCodes.add((String)item.get('item_code'));
            }    
            System.debug('itemCodes==>'+itemCodes);

            Map<String, Product2> itemCodeToProductMap = new Map<String, Product2>();
            for (Product2 prod : [SELECT Id, ProductCode, Name,IsActive FROM Product2 WHERE ProductCode IN :itemCodes AND IsActive = true]) {
                itemCodeToProductMap.put(prod.ProductCode, prod);
            }
            System.debug('itemCodeToProductMap==>'+itemCodeToProductMap);

            Map<Id, PricebookEntry> productToPBEMap = new Map<Id, PricebookEntry>();
            List<PricebookEntry> pricebookList = [SELECT Id, Product2Id, UnitPrice,Dealer_List_Price__c,CGST_Percentage__c,SGST_Percentage__c,IGST_Percentage__c FROM PricebookEntry WHERE Product2Id IN :itemCodeToProductMap.values() AND Pricebook2Id = :pricebookId AND IsActive = TRUE];
            if(pricebookList.isEmpty()){
                 response.statuscode=400;
                 response.responseBody = responseUtility('Pricebook Entry Not Found Or Not Active',false);
                 //return;
            }
            System.debug('pricebookList==>'+pricebookList);
            for (PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice,Dealer_List_Price__c,CGST_Percentage__c,SGST_Percentage__c,IGST_Percentage__c FROM PricebookEntry WHERE Product2Id IN :itemCodeToProductMap.values() AND Pricebook2Id = :pricebookId AND IsActive = TRUE]) {
                productToPBEMap.put(pbe.Product2Id, pbe);
            }
            System.debug('productToPBEMap==>'+productToPBEMap);
            
            Map<Id,Decimal> orderItemProductMap = new Map<Id,Decimal>();
            
            List<OrderItem> orderItems = new List<OrderItem>();
            for (Map<String, Object> item : lineItems) {
                String itemCode = (String)item.get('item_code');
                Decimal quantity = item.containsKey('quantity') ? (Decimal)item.get('quantity') : 0;
                
                if (itemCodeToProductMap.containsKey(itemCode)) {
                    Product2 prod = itemCodeToProductMap.get(itemCode);
                    if (productToPBEMap.containsKey(prod.Id)) {
                        PricebookEntry pbe = productToPBEMap.get(prod.Id);
                        
                        OrderItem oi = new OrderItem();
                        oi.OrderId = newOrder.Id;
                        oi.Product2Id = prod.Id;
                        oi.PricebookEntryId = pbe.Id;
                        oi.Quantity = quantity;
                        oi.UnitPrice = pbe.Dealer_List_Price__c != null ? pbe.Dealer_List_Price__c : 0;
                        oi.SGST__c=pbe.SGST_Percentage__c;
                        oi.CGST__c=pbe.CGST_Percentage__c;
                        oi.IGST__c=pbe.IGST_Percentage__c;
                        
                        orderItems.add(oi);
                        orderItemProductMap.put(oi.Product2Id,quantity);//added by Aniket on 22/07/2025 for PO Stage Move
                    }
                }
            }
            System.debug('orderItemProductMap==>'+orderItemProductMap);
            
            try {
                if (!orderItems.isEmpty()) insert orderItems;
                newOrder.Status='Invoice Generation';
                update newOrder;//added by Aniket after UAT Feedback from Hiba and Patrick
                System.debug('lineItems Size=>'+lineItems.size());
                System.debug('orderItems.size=>'+orderItems.size());
                if(lineItems.size() != orderItems.size()){
                    failedObjects.add('OrderItem Partial Failed');
                    objectErrorMessages.put('Order Items', 'Not all Order Items got Inserted');
                }
                System.debug('orderItems==>'+orderItems);
                successObjects.add('Order Items');
            } catch (Exception e) {
                System.debug('Error==>'+e.getMessage());
                objectErrorMessages.put('Order Items=>', e.getMessage());
                failedObjects.add('OrderItem');
            }
            List<ProductRequestLineItem> polisToUpdate = [SELECT Id,Alloted_Quantity__c,Product2Id,ParentId FROM ProductRequestLineItem WHERE ParentId =:p.Id];
            System.debug('polisToUpdate==>'+polisToUpdate);
            List<ProductRequestLineItem> updatedpoli = new List<ProductRequestLineItem>();
            if(!polisToUpdate.isEmpty()){
                 for(ProductRequestLineItem p1 : polisToUpdate){
                    ProductRequestLineItem pp = new ProductRequestLineItem();
                    pp.Id = p1.Id;
                    Decimal newQty = orderItemProductMap.get(p1.Product2Id);
                    if (newQty == null) newQty = 0;
                    Decimal existingQty = p1.Alloted_Quantity__c != null ? p1.Alloted_Quantity__c : 0;
                    pp.Alloted_Quantity__c = existingQty + newQty;
                    updatedpoli.add(pp);
                 }
                 if(!updatedpoli.isEmpty()){
                    try{
                     update updatedpoli;
                     System.debug('updatedpoli==>'+updatedpoli);
                    }catch(Exception e){
                       System.debug('Error==>'+e.getMessage());
                       objectErrorMessages.put('Purchase Order=>', e.getMessage());
                    }
                    
                 }
            }
            Shipment s = new Shipment();
            s.Order__c=newOrder.Id;
            s.Status='New';
            //s.Status = 'Dispatched';
            //s.Purchase_Order__c=p.Id;
            s.SourceLocationId = hardcodedSourceLocationId;
            s.DestinationLocationId = p.Destination_Location__c;
            s.ShipToName=shipToName;
            s.sap_shipment_id__c=sapShipment;
            
            try {
                insert s;
                successObjects.add('Shipment');
            } catch (Exception e) {
                System.debug('Error==>'+e.getMessage());
                objectErrorMessages.put('Shipment=>', e.getMessage());
                failedObjects.add('Shipment');
            }
            
            List<ShipmentItem> shipmentItemsToInsert = new List<ShipmentItem>();
            for(OrderItem orderProducts : orderItems){
                ShipmentItem sri = new ShipmentItem();
                sri.Product2Id = orderProducts.Product2Id;
                sri.Quantity = orderProducts.Quantity;
                sri.Parent_Shipment__c = s.Id;
                sri.Is_VOR__c = orderProducts.Is_VOR__c;
                sri.Unit_Price__c = orderProducts.UnitPrice;
                sri.SGST__c = orderProducts.SGST__c;
                sri.CGST__c = orderProducts.CGST__c;
                sri.IGST__c = orderProducts.IGST__c;
                sri.Related_Order_Line_Item__c=orderProducts.Id ; 
                sri.ShipmentId=s.Id;
                shipmentItemsToInsert.add(sri);
            }
            try {
                if (!shipmentItemsToInsert.isEmpty()) insert shipmentItemsToInsert;
                successObjects.add('Shipment Items');
            } catch (Exception e) {
                System.debug('Error==>'+e.getMessage());
                objectErrorMessages.put('Shipmenmt Items=>', e.getMessage());
                failedObjects.add('Shipment Items');
            }
            p.Status='Processing';
            try{
               update p;
            }catch(Exception e){
            objectErrorMessages.put('Purchase Order Status Update=>', e.getMessage());
              System.debug('Error Occured==>'+e.getMessage());
              System.debug('Error Line Number Is ==>'+e.getLineNumber());
            }
            Map<String, Object> finalResponse = new Map<String, Object>();
            
            if (!failedObjects.isEmpty()) {
                Database.rollback(sp1);
                String combinedErrors = '';
                for (String objName : objectErrorMessages.keySet()) {
                    combinedErrors += objName + ' => ' + objectErrorMessages.get(objName) + '\n';
                }
                finalResponse.put('success', false);
                finalResponse.put('status code', 400); 
                finalResponse.put('message', 'Error In Inserting Order & Shipment');
                
                response.statusCode = 400;
                
                
                Integration_Log__c logObj = new Integration_Log__c(  
                Integration_Type__c = 'SAP',  
                Request_Payload__c = reqBody,  
                Response_Payload__c = JSON.serializePretty(finalResponse),
                Error_Message__c = combinedErrors,
                Status__c = 'Failed'  
                );  
                insert logObj; 
                
            } else {
                finalResponse.put('success', true);
                finalResponse.put('status code', 200);
                finalResponse.put('message', 'All records inserted successfully');
                finalResponse.put('salesforce_shipment_id', String.valueof(s.Id));
                response.statusCode = 200;
                //finalResponse.put('insertedObjects', successObjects);
            }
            
            response.responseBody = Blob.valueOf(JSON.serializePretty(new Map<String, Object>{
                'data' => finalResponse
                    }));
          
            
            
            
        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            response.statusCode = 500;
            Map<String, Object> errorResponse = new Map<String, Object>{
                'error' => e.getMessage(),
                    'line' => e.getLineNumber()
                    };
                        response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
        }
    }
    
    //***************************************************************************************************************************************************
    
    @HttpPatch
    global static void updateOrderShipment(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String reqBody;
         Savepoint sp = Database.setSavepoint();
        try{

           
            reqBody = request.requestBody != null ? request.requestBody.toString() : '';
            System.debug('Request Body ==> ' + reqBody);
            
            Map<String, Object> requestMap = (reqBody != '') ?  (Map<String, Object>) JSON.deserializeUntyped(reqBody) : new Map<String,Object>();
            System.debug('Request Map ==>' + requestMap);
            
            Object sapId = requestMap.get('sap_shipment_id');
            String sapShipmentId = sapId != null ? String.valueof(sapId) : 'Not Found';
            
            
            Date lrDate;
            String lrDateStr = (String) requestMap.get('LR_Date');
            if (!String.isBlank(lrDateStr)) {
                
                if (!Pattern.matches('^\\d{2}/\\d{2}/\\d{4}$', lrDateStr)) {
                    response.statusCode = 400;
                    response.responseBody = responseUtility('Invalid LR date format',false);
                    return;
                }
                lrDate = formattedDate(lrDateStr);
            }
            
            String lrNumber = requestMap.containsKey('LR_no') ? (String)requestMap.get('LR_no') : null;
            String eWayBill = requestMap.containsKey('e_way_bill_no') ? (String)requestMap.get('e_way_bill_no') : 'Not Found';
            
            Set<String> shipmentPicklistrValues = statusPicklistValues();
            String availablePicklistValues = String.join(shipmentPicklistrValues,', ');
            String statusOfShipment = requestMap.containsKey('status') ? (String)requestMap.get('status') : 'Not Found';
            if(!shipmentPicklistrValues.contains(statusOfShipment)){
                response.statusCode = 400;
                response.responseBody = responseUtility('Status Value Does Not match With Salesforce Shipment Status API Name .It Needs to be amongst these value' + '==> '+availablePicklistValues,false);
                return;
            }
            
            Date invoiceDate;
            String invoiceDateStr = (String) requestMap.get('invoice_date');
            if (!String.isBlank(invoiceDateStr)) {
                if (!Pattern.matches('^\\d{2}/\\d{2}/\\d{4}$', invoiceDateStr)) {
                    response.statusCode = 400;
                    Map<String, Object> errorResponse = new Map<String, Object>{
                        'message' => 'Invalid Invoice date format',
                            'status'=>false
                            };
                                response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));
                    return;
                }
                invoiceDate = formattedDate(invoiceDateStr);
            }
            
            String invoiceNumber = requestMap.containsKey('invoice_no') ? (String)requestMap.get('invoice_no') : 'Not Found';
            Object invoiceAmountObj = requestMap.get('invoice_amount');
            Decimal invoiceAmount = (invoiceAmountObj != null) ? Decimal.valueOf(String.valueOf(invoiceAmountObj)) : 0;
            
            
            String drivername = requestMap.containsKey('driver_name') ? (String)requestMap.get('driver_name') : 'Not Found';
            String driverPhone = requestMap.containsKey('driver_phone') ? (String)requestMap.get('driver_phone') : 'Not Found';
            
            List<Shipment> shipmentList = [SELECT Id,sap_shipment_id__c,LR_Date__c,LR_Number__c,E_Way_bill__c,Invoice_Date__c,Invoice_Amount__c,Driver_Name__c,Driver_Phone__c,Order__c FROM Shipment WHERE sap_shipment_id__c =:sapShipmentId LIMIT 1];
            System.debug('shipmentList==>'+shipmentList);
            if(shipmentList.isEmpty()){
                response.statusCode = 400;
                response.responseBody = responseUtility('Shipment with '+ sapShipmentId + ' does not exist in Salesforce',false);
                return;
             
            }
            Order o;
            List<Order> orderList = [SELECT Id,Status FROM Order WHERE Id=:shipmentList[0].Order__c];
            if(!orderList.isEmpty()){
                o=orderList[0];
            }else if(orderList.isEmpty()){
                response.statusCode = 400;
                response.responseBody = responseUtility('No Orders Found',false);
                return;
            }
            System.debug('shipmentList==>'+shipmentList);
            Shipment s = shipmentList[0];
            s.LR_Date__c=lrDate;
            s.LR_Number__c=lrNumber;
            s.E_Way_bill__c=eWayBill;
            s.Invoice_Date__c=invoiceDate;
            s.Invoice_No__c=invoiceNumber;
            s.Invoice_Amount__c=invoiceAmount;
            s.Driver_Name__c=drivername;
            s.Driver_Phone__c=driverPhone;
            s.Status='Dispatched';
            
            try{
            Database.update(s);
            System.debug('Updated Shipment==>'+s);
            o.Status='Dispatch';//added by Aniket After getting feedback from Hiba and Patrick
            update o;
            System.debug('Updated Order From SAP==>'+o);
            
            
            response.statusCode = 200;
            Map<String,Object> successMessage = new Map<String,Object>{'success'=>true,'message'=>'Shipment Details are updated successfully'};
                response.responseBody = Blob.valueOf(JSON.serializePretty(successMessage));

            }catch(Exception e){
                Database.rollback(sp);
                System.debug('Error Occured==>'+e.getMessage());
                System.debug('Error Line Number Is =='+e.getLineNumber());

                    logIntegrationError('SAP', JSON.serializePretty(reqBody), e.getMessage());
                    response.statusCode = 500;
                    Map<String, Object> errorResponse = new Map<String, Object>{
                        'error' => 'Error Updating Shipment Details',
                            'line' => e.getLineNumber()
                            };
                                response.responseBody = Blob.valueOf(JSON.serializePretty(errorResponse));

                                
                }
                
            
        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is =='+e.getLineNumber());
            
        }
    }
    public static Blob responseUtility(String Message,Boolean Status){
        try{
            Map<String,Object> errorRes = new Map<String,Object>();
            errorRes.put('message',Message);
            errorRes.put('status',Status);
            
            Blob serializedErrorRes = Blob.valueOf(JSON.serializePretty(errorRes));
            return serializedErrorRes;
            
            
        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            return null;
        }
    }
    public static Date formattedDate(String dateValue){
        try{
            Date salesforceFormat;
            List<String> dateString = dateValue.split('/');
            Integer day = Integer.valueOf(dateString[0]);
            Integer month = Integer.valueOf(dateString[1]);
            Integer year = Integer.valueOf(dateString[2]);
            salesforceFormat = Date.newInstance(year, month, day);
            return salesforceFormat;
        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is==>'+e.getLineNumber());
            return null;
        }
    }
    public static Set<String> statusPicklistValues(){
        try{
            Set<String> shipmentPicklistrValues = new Set<String>();
            List<Schema.PicklistEntry> picklistValuez = Shipment.Status.getDescribe().getPicklistValues();
            for (Schema.PicklistEntry picklistValue : picklistValuez){
                shipmentPicklistrValues.add(picklistValue.getValue());
            }  
            if(!shipmentPicklistrValues.isEmpty()){
                return shipmentPicklistrValues;
            }
            return null;
            
        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            return null;
        }
    }
    private static void logIntegrationError(String integrationType, String requestBody, String errorMessage) {
    try {
        Integration_Log__c logObj = new Integration_Log__c(
            Integration_Type__c = integrationType,
            Request_Payload__c = requestBody,
            Response_Payload__c = 'Error: ' + errorMessage,
            Error_Message__c = errorMessage,
            Status__c = 'Failed'
        );
        insert logObj;
    } catch (Exception logEx) {
        System.debug('Failed to insert integration log: ' + logEx.getMessage());
    }
}
}