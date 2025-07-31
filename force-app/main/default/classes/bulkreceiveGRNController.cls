/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public  Without Sharing class bulkreceiveGRNController {

	  @AuraEnabled //(Cacheable = true)
    public static List<ShipmentItem> getPOrelatedPLI(String recordId) {
        try {
            if (String.isNotBlank(recordId) && recordId != null) {
                return [ SELECT Id, Quantity, Product2.Name, ShipmentId,Shipment.DestinationLocationId,Shipment.SourceLocationId, Product2.ProductCode,Product2Id FROM ShipmentItem  WHERE ShipmentId  =:recordId];
            }
        } catch (Exception e) {
            System.debug('Error in getPOrelatedPLI == > ' + e.getMessage() + ' && at Line == > ' + e.getLineNumber());
        }
        return new List<ShipmentItem>(); 
    } 

	 @AuraEnabled 
    public static Shipment getShipmentDetail(String recordId){
        System.debug('recordId=======> ' + recordId);
        try{
            if(String.isNotBlank(recordId) && recordId != null){
                return [SELECT Id,Is_Discrepancy_Created__c from Shipment WHERE Id =:recordId LIMIT 1];
                
            }else{
                return null;
            }
        }catch (Exception e) {
            System.debug('Error in getPOrelatedPLI == > ' + e.getMessage() + ' && at Line == > ' + e.getLineNumber());
            return null;
        }
        
        // return [SELECT Id,Status from Shipment WHERE Id =:recordId LIMIT 1];
    }
	 @AuraEnabled
    public static void updateProductTransferReceivedQuantity(List<ShipmentItem> shipmenItemList){
        System.debug('shipmenItemList==>'+shipmenItemList);
        try{
            Set<Id> shipmentItemIds = new Set<Id>();
            if(!shipmenItemList.isEmpty()){
                for(ShipmentItem shipment : shipmenItemList){
                    shipmentItemIds.add(shipment.Id);
                }
            }
            
            Set<Id> orderIds = new Set<Id>();
            Map<Id,Decimal> quantityMap = new Map<Id,Decimal>();
            List<ShipmentItem> finalShipmentItemList = [Select Id,Product2Id,Quantity_Received__c,ShipmentId,Shipment.Order__c from ShipmentItem WHERE Id IN:shipmentItemIds];
            System.debug('finalShipmentItemList==>'+finalShipmentItemList);
            if(!finalShipmentItemList.isEmpty()){
                for(ShipmentItem s : finalShipmentItemList){
                    if(s.Shipment.Order__c != null){
                        orderIds.add(s.Shipment.Order__c);
                        quantityMap.put(s.Shipment.Order__c,s.Quantity_Received__c);
                    }
                }
            }
            System.debug('quantityMap==>'+quantityMap);
            List<ProductTransfer> productTransferList = [Select id,Product2Id,IsReceived,QuantityReceived,Order__c from ProductTransfer WHERE Order__c IN:orderIds];
            System.debug('productTransferList==>'+productTransferList);
            List<ProductTransfer> productTransferToUpdate = new List<ProductTransfer>();
            if(!productTransferList.isEmpty()){
                for(ProductTransfer p : productTransferList){
                    System.debug('p==>'+p);
                    ProductTransfer ppp = new ProductTransfer();
                    ppp.Id=p.Id;
                    ppp.QuantityReceived = p.QuantityReceived + quantityMap.get(p.Order__c);
                    ppp.IsReceived = true;
                    productTransferToUpdate.add(ppp);
                    System.debug('productTransferToUpdate==>'+productTransferToUpdate);
                    System.debug('ppp==>'+ppp);
                    
                }
                if(!productTransferToUpdate.isEmpty()){
                    try {
                        update productTransferToUpdate;
                        System.debug(' Updated ProductTransfers: ' + productTransferToUpdate);
                    } catch (Exception e) {
                        System.debug(' DML Exception: ' + e.getMessage());
                        System.debug('Error Occured In Line Number Siva ==>'+e.getLineNumber());
                    }
                }
            }
            
            
            
        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Occured In Line Number ==>'+e.getLineNumber());
        }
    }
	@AuraEnabled
    public static string updateShipmentItemQuantities(String updatedItemsJson, String recordId) {
        try {
            System.debug('Received updatedItemsJson: ' + updatedItemsJson);
            
            Map<String, Object> updatedItems = (Map<String, Object>) JSON.deserializeUntyped(updatedItemsJson);
            if (updatedItems == null || updatedItems.isEmpty()) {
                System.debug('No valid shipment items to update!');
                return 'Error: No valid shipment items to update!';
            }
            
            List<ShipmentItem> shipmentItemsToUpdate = new List<ShipmentItem>();
            
            for (String shipmentItemId : updatedItems.keySet()) {
                if (!String.isEmpty(shipmentItemId)) {
                    Object itemDetails = updatedItems.get(shipmentItemId);
                    if (itemDetails instanceof Map<String, Object>) {
                        Map<String, Object> itemData = (Map<String, Object>) itemDetails;
                        
                        if (itemData.containsKey('receivedQuantity')) {
                            ShipmentItem item = new ShipmentItem(
                                Id = Id.valueOf(shipmentItemId),
                                Quantity_Received__c = Decimal.valueOf(String.valueOf(itemData.get('receivedQuantity')))
                            );
                            
                            if (itemData.containsKey('remarks')) {
                                item.Remarks__c = String.valueOf(itemData.get('remarks'));
                            }
                            
                            shipmentItemsToUpdate.add(item);
                            System.debug('Preparing to update Shipment Item ID: ' + shipmentItemId + ' with Received Quantity: ' + itemData.get('receivedQuantity'));
                        }
                    }
                }
            }
            
            if (!shipmentItemsToUpdate.isEmpty()) {
                system.debug('Inside======');
                update shipmentItemsToUpdate;
                
                //Added by Aniket on 30/07/2025
                Set<Id> shipmentId = new Set<Id>();
                for(ShipmentItem s : shipmentItemsToUpdate){
                    shipmentId.add(s.ShipmentId);
                }
                Shipment s =[SELECT Id,Order__c,Order__r.Status,Status FROM Shipment WHERE Id=:shipmentId LIMIT 1];
                s.Status='Delivered';
                update s;
                Order o = [SELECT Id,Status FROM Order WHERE Id=:s.Order__c LIMIT 1];
                o.Status='Delivered';
                update o;
                //Added by Aniket upto here
                System.debug('Updated ' + shipmentItemsToUpdate.size() + ' Shipment Items successfully.');
                updateProductTransferReceivedQuantity(shipmentItemsToUpdate);//added By Aniket on 30/04/2025
                return 'SUCCESS';
            } else {
                System.debug('No shipment items were updated!');
                return 'Error: No shipment items were updated!';
            }
            
        } catch (Exception e) {
            System.debug('Error updating shipment items: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }

	private static void processLineItem(Map<String, Object> data, String fieldName, String shipmentItemId, Map<String, Id> discrepancyIdMap, Map<Id, List<Discrepancy_Line_Item__c>> existingLineItemsMap, List<Discrepancy_Line_Item__c> disLineItemsToInsert) {
        System.debug('Data For Creating DLIs==>'+data);
        if (data.containsKey(fieldName) && discrepancyIdMap.containsKey(shipmentItemId)) {
            String quantityStr = String.valueOf(data.get(fieldName));
            if (!String.isEmpty(quantityStr)) {
                try {
                    Integer quantity = Integer.valueOf(quantityStr);
                    Id discrepancyId = discrepancyIdMap.get(shipmentItemId);
                    
                    Boolean exists = false;
                    if (existingLineItemsMap.containsKey(discrepancyId)) {
                        for (Discrepancy_Line_Item__c existingItem : existingLineItemsMap.get(discrepancyId)) {
                            if (existingItem.Quantity__c == quantity) {
                                exists = true;
                                System.debug('⚠️ Existing line item found for Discrepancy: ' + discrepancyId);
                                break;
                            }
                        }
                    }
                    
                    if (!exists) {
                        Discrepancy_Line_Item__c lineItem = new Discrepancy_Line_Item__c();
                        //   lineItem.Name = fieldName;
                        lineItem.Discrepancy__c = discrepancyId;
                        lineItem.Quantity__c = quantity;
                        lineItem.Type__c = fieldName;
                        lineItem.status__c = 'New';
                        disLineItemsToInsert.add(lineItem);
                    }
                } catch (Exception e) {
                    System.debug('Error parsing quantity for ' + shipmentItemId + ': ' + e.getMessage());
                }
            }
        }
    }

	  @AuraEnabled
    public static string createDiscrepancyAndLineitem(String updatedItems,string recordId) {
        System.debug('Received updatedItems: ' + updatedItems);
        
        try {
            Map<String, Object> updatedItemsMap = (Map<String, Object>) JSON.deserializeUntyped(updatedItems);
            System.debug('Parsed JSON Data: ' + updatedItemsMap);
            
            if (updatedItemsMap == null || updatedItemsMap.isEmpty()) {
                System.debug('No data received!');
                return 'Error: No data received!';
            }
            
            Set<Id> shipmentItemIds = new Set<Id>();
            Map<Id, Decimal> shipmentItemReceivedQtyMap = new Map<Id, Decimal>();
            
            for (String key : updatedItemsMap.keySet()) { 
                if (!String.isEmpty(key)) {
                    shipmentItemIds.add(Id.valueOf(key));
                    
                    Object itemDetails = updatedItemsMap.get(key);
                    if (itemDetails instanceof Map<String, Object>) {
                        Map<String, Object> itemData = (Map<String, Object>) itemDetails;
                        if (itemData.containsKey('receivedQuantity')) {
                            shipmentItemReceivedQtyMap.put(Id.valueOf(key), Decimal.valueOf(String.valueOf(itemData.get('receivedQuantity'))));
                            System.debug('Shipment Item ID: ' + key + ', Received Quantity: ' + itemData.get('receivedQuantity'));
                        }
                    }
                }
            }
            
            Map<Id, Id> shipmentItemToShipmentMap = new Map<Id, Id>();
            
            if (!shipmentItemIds.isEmpty()) {
                for (ShipmentItem item : [SELECT Id, ShipmentId FROM ShipmentItem WHERE Id IN :shipmentItemIds]) {
                    shipmentItemToShipmentMap.put(item.Id, item.ShipmentId);
                    System.debug('Mapped Shipment Item ID: ' + item.Id + ' to Shipment ID: ' + item.ShipmentId);
                }
            }
            
            List<Discrepancy__c> discrepanciesToInsert = new List<Discrepancy__c>();
            Map<String, Id> discrepancyIdMap = new Map<String, Id>();
            Map<Id, Decimal> discrepancyReceivedQuantityMap = new Map<Id, Decimal>();
            
            for (String shipmentItemId : updatedItemsMap.keySet()) {
                if (String.isEmpty(shipmentItemId)) {
                    continue;
                }
                
                Discrepancy__c disRec = new Discrepancy__c();
                disRec.Shipment_Item__c = shipmentItemId;
                
                if (shipmentItemToShipmentMap.containsKey(Id.valueOf(shipmentItemId))) {
                    disRec.Shipment__c = shipmentItemToShipmentMap.get(Id.valueOf(shipmentItemId));
                }
                
                Object itemDetails = updatedItemsMap.get(shipmentItemId);
                if (itemDetails instanceof Map<String, Object>) {
                    Map<String, Object> itemData = (Map<String, Object>) itemDetails;
                    if (itemData.containsKey('receivedQuantity')) {
                        Integer receivedQty = Integer.valueOf(String.valueOf(itemData.get('receivedQuantity')));
                        disRec.Received_Quantity__c = receivedQty;
                        System.debug('Discrepancy for Shipment Item ID: ' + shipmentItemId + ', Received Quantity: ' + receivedQty);
                    }
                }
                discrepanciesToInsert.add(disRec);
            }
            
            if (!discrepanciesToInsert.isEmpty()) {
                insert discrepanciesToInsert;
                for (Discrepancy__c disRec : discrepanciesToInsert) {
                    discrepancyIdMap.put(disRec.Shipment_Item__c, disRec.Id);
                    discrepancyReceivedQuantityMap.put(disRec.Id, disRec.Received_Quantity__c);
                    System.debug('Inserted Discrepancy ID: ' + disRec.Id + ' for Shipment Item ID: ' + disRec.Shipment_Item__c);
                }
            } else {
                System.debug('No Discrepancy records created!');
                return 'Error: No Discrepancy records created!';
            }
            
            Map<Id, List<Discrepancy_Line_Item__c>> existingLineItemsMap = new Map<Id, List<Discrepancy_Line_Item__c>>();
            List<Discrepancy_Line_Item__c> existingLineItems = [
                SELECT Id, Discrepancy__c, Quantity__c FROM Discrepancy_Line_Item__c 
                WHERE Discrepancy__c IN :discrepancyIdMap.values()
            ];
            
            for (Discrepancy_Line_Item__c lineItem : existingLineItems) {
                if (!existingLineItemsMap.containsKey(lineItem.Discrepancy__c)) {
                    existingLineItemsMap.put(lineItem.Discrepancy__c, new List<Discrepancy_Line_Item__c>());
                }
                existingLineItemsMap.get(lineItem.Discrepancy__c).add(lineItem);
            }
            
            List<Discrepancy_Line_Item__c> disLineItemsToInsert = new List<Discrepancy_Line_Item__c>();
            
            for (String shipmentItemId : updatedItemsMap.keySet()) {
                Object recValue = updatedItemsMap.get(shipmentItemId);
                
                if (recValue instanceof Map<String, Object>) {
                    Map<String, Object> data = (Map<String, Object>) recValue;
                    
                    // ✅ Process line items and ensure null/empty values are skipped
                    processLineItem(data, 'DIT', shipmentItemId, discrepancyIdMap, existingLineItemsMap, disLineItemsToInsert);
                    processLineItem(data, 'MIT', shipmentItemId, discrepancyIdMap, existingLineItemsMap, disLineItemsToInsert);
                    processLineItem(data, 'WP', shipmentItemId, discrepancyIdMap, existingLineItemsMap, disLineItemsToInsert);
                    processLineItem(data, 'Extra', shipmentItemId, discrepancyIdMap, existingLineItemsMap, disLineItemsToInsert); // ✅ New "Extra" field added
                }
            }
            
            if (!disLineItemsToInsert.isEmpty()) {
                insert disLineItemsToInsert;
                Shipment shiprec  = [Select id,Is_Discrepancy_Created__c,Status,Order__c From Shipment where Id =:recordId];
                system.debug('shiprec======'+shiprec);
                shiprec.Is_Discrepancy_Created__c = True;
                shiprec.Status='Delivered';
                update shiprec;
                
                Order o = [SELECT Id,Status FROM Order WHERE Id=:shiprec.Order__c];
                o.Status='Delivered';
                Update o;


                


                System.debug('Inserted ' + disLineItemsToInsert.size() + ' Discrepancy Line Items');
            }
            
            List<Discrepancy__c> discrepanciesToUpdate = new List<Discrepancy__c>();
            for (Id disId : discrepancyReceivedQuantityMap.keySet()) {
                Discrepancy__c dis = new Discrepancy__c(Id = disId, Received_Quantity__c = discrepancyReceivedQuantityMap.get(disId));
                discrepanciesToUpdate.add(dis);
            }
            
            if (!discrepanciesToUpdate.isEmpty()) {
                update discrepanciesToUpdate;
                System.debug('Updated ' + discrepanciesToUpdate.size() + ' Discrepancies with received quantity');
            }
            
            if (!shipmentItemReceivedQtyMap.isEmpty()) {
                List<ShipmentItem> shipmentItemsToUpdate = new List<ShipmentItem>();
                for (Id shipmentItemId : shipmentItemReceivedQtyMap.keySet()) {
                    ShipmentItem shipmentItemToUpdate = new ShipmentItem(Id = shipmentItemId, Quantity_Received__c = shipmentItemReceivedQtyMap.get(shipmentItemId));
                    
                    Object itemDetails = updatedItemsMap.get(String.valueOf(shipmentItemId));
                    if (itemDetails instanceof Map<String, Object>) {
                        Map<String, Object> itemData = (Map<String, Object>) itemDetails;
                        if (itemData.containsKey('remarks')) {
                            String remarksValue = String.valueOf(itemData.get('remarks'));
                            if (String.isNotEmpty(remarksValue)) {
                                shipmentItemToUpdate.Remarks__c = remarksValue;
                                System.debug('Updating Shipment Item ID: ' + shipmentItemId + ' with Remarks: ' + remarksValue);
                            }
                        }
                    }
                    
                    shipmentItemsToUpdate.add(shipmentItemToUpdate);
                }
                
                if (!shipmentItemsToUpdate.isEmpty()) {
                    update shipmentItemsToUpdate;
                    System.debug('Updated ' + shipmentItemsToUpdate.size() + ' Shipment Items');
                }
            }
            
            return 'SUCCESS';
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
}