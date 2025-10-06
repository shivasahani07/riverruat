/******************************************************************************
* Class Name: PaymentTriggerHandler
* Created by : Sudarshan N B - 1/10/23
* Last Modified By : Sudarshan N B - 10/07/2024
* Description : Handler for payment trigger
*****************************************************************************/
public class PaymentTriggerHandler {
    
    public static void insertHandler(List<Payment__c> newRecords){
        try{
            Set<Id> recordIds = new Set<Id>();
            List<Order_Payment__c> paymentsToUpdate = new List<Order_Payment__c>();
            
            for(Payment__c p : newRecords){
                if(p.Payment_Status__c == 'Success')
                    recordIds.add(p.Id);
            }
            if(!recordIds.isEmpty()){
                List<Order_Payment__c> orderPayments = [SELECT Id, Amount1__c, Payments__r.Amount__c  from Order_Payment__c WHERE Payments__c IN :recordIds];
                for(Order_Payment__c op: orderPayments){
                    Order_Payment__c opRecord = op;
                    opRecord.Amount1__c = op.Payments__r.Amount__c;
                    paymentsToUpdate.add(opRecord);   
                }

                if(paymentsToUpdate != null){
                    database.update(paymentsToUpdate,false);
                }
            }
        }catch(exception e){
            System.debug('Error =======>' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
    }
    
    public static void updateHandler(List<Payment__c> newRecords, Map<id,Payment__c> oldMap){
        try{
            Set<Id> recordIds = new Set<Id>();
            List<Order_Payment__c> paymentsToUpdate = new List<Order_Payment__c>();
            
            for(Payment__c p : newRecords){
                if(p.Payment_Status__c == 'Success')
                    recordIds.add(p.Id);
            }
            
            if(!recordIds.isEmpty()){
                List<Order_Payment__c> orderPayments = [SELECT Id, Amount1__c, Payments__r.Amount__c  from Order_Payment__c WHERE Payments__c IN :recordIds];
                List<Order_Payment__c> opList = new List<Order_Payment__c>();
                Map<Id,Order_Payment__c> mappaymentIdtoOp = new Map<Id,Order_Payment__c>();
                
                for(Order_Payment__c op: orderPayments){
                    if(!mappaymentIdtoOp.containsKey(op.Payments__c)){
                        mappaymentIdtoOp.put(op.Payments__c,op);
                    }
                }  

                for(Payment__c p : newRecords){
                    if(p.Payment_Status__c == 'Success' && p.Payment_Status__c != oldMap.get(p.Id).Payment_Status__c){
                        opList.add(mappaymentIdtoOp.get(p.Id));
                    }
                }

                if(opList != null){
                    OrderStatusHandler.sendPreOrderReceipt01(opList);
                } 
            }
        
        }catch(exception e){
            System.debug('Error =======>' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
    }

    public static void onCreationOfPaymentUnderOpportunityCreateOrderAndOrderPayment(Map<Id, Payment__c> mapOfPayment) {
        try {
            Map<Id, Id> mapOfPaymentWRTOpportunity = new Map<Id, Id>();
            for (Payment__c paymentRec : mapOfPayment.values()) {
                if (paymentRec.Enquiry__c != null) {
                    mapOfPaymentWRTOpportunity.put(paymentRec.Id, paymentRec.Enquiry__c);
                }
            }
            
            if (mapOfPaymentWRTOpportunity.isEmpty()) return;
            
            Map<Id, Opportunity> mapOfOpp = new Map<Id, Opportunity>([
                SELECT Id, AccountId, Pricebook2Id,OwnerId,Preferred_Seller__c,PreferredSeller__c,
                (SELECT Id, Product2Id, PricebookEntryId, UnitPrice, Quantity,Order_Item_Id__c,Offer_Amount__c,Offer_Description__c
                FROM OpportunityLineItems)
                FROM Opportunity 
                WHERE Id IN :mapOfPaymentWRTOpportunity.values()
            ]);
            
            Pricebook2 defaultPB = [
                SELECT Id FROM Pricebook2 WHERE IsActive = true AND IsStandard = true LIMIT 1
            ];
            
            List<Order> ordersToInsert = new List<Order>();
            List<OrderItem> orderItemsToInsert = new List<OrderItem>();
            List<Order_Payment__c> orderPaymentsToInsert = new List<Order_Payment__c>();
            List<Opportunity> OpportunityToUpdate = new List<Opportunity>();
            
            Id orderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
            
            for (Payment__c paymentRec : mapOfPayment.values()) {
                Opportunity opp = mapOfOpp.get(paymentRec.Enquiry__c);

                Opportunity oppToUpdate = new Opportunity();
                oppToUpdate.Id = opp.Id;
                oppToUpdate.Booking_Amount__c = paymentRec.Amount__c;
                oppToUpdate.StageName = 'Closed Won';
                OpportunityToUpdate.add(oppToUpdate);
                
                Order orderObj = new Order();
                orderObj.RecordTypeId = orderRecordTypeId;
                orderObj.OpportunityId = opp.Id;
                orderObj.AccountId = opp.AccountId;
                orderObj.AccountId = opp.AccountId;
                orderObj.Booking_Amount__c = paymentRec.Amount__c;
                orderObj.OwnerId = opp.OwnerId;
                orderObj.Dealer__c = opp.PreferredSeller__c;
                orderObj.Status = 'Booking';
                orderObj.EffectiveDate = Date.today();
                orderObj.Pricebook2Id = opp.Pricebook2Id != null ? opp.Pricebook2Id : defaultPB.Id;
                
                ordersToInsert.add(orderObj);
            }
            
            if (!ordersToInsert.isEmpty()) {
                insert ordersToInsert;
                
                Integer index = 0;
                for (Payment__c paymentRec : mapOfPayment.values()) {
                    Opportunity opp = mapOfOpp.get(paymentRec.Enquiry__c);
                    Order createdOrder = ordersToInsert[index++];
                    
                    Order_Payment__c ordPay = new Order_Payment__c();
                    ordPay.Order__c = createdOrder.Id;
                    ordPay.Payments__c = paymentRec.Id;
                    ordPay.Type__c = 'Down Payment';
                    orderPaymentsToInsert.add(ordPay);
                    
                    for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                        OrderItem ordItem = new OrderItem();
                        ordItem.OrderId = createdOrder.Id;
                        ordItem.PricebookEntryId = oli.PricebookEntryId;
                        ordItem.Product2Id = oli.Product2Id;
                        ordItem.Quantity = oli.Quantity;
                        ordItem.Order_Item_Id__c = oli.Order_Item_Id__c != null ? oli.Order_Item_Id__c : '';
                        ordItem.Offer_Amount__c =  oli.Offer_Amount__c != null ? decimal.valueOf(oli.Offer_Amount__c) : 0;
                        ordItem.Offer_Description__c = oli.Offer_Description__c != null ? oli.Offer_Description__c : '';
                        ordItem.UnitPrice = oli.UnitPrice;
                        orderItemsToInsert.add(ordItem);
                    }
                }

                if (!orderPaymentsToInsert.isEmpty()) insert orderPaymentsToInsert;
                if (!orderItemsToInsert.isEmpty()) insert orderItemsToInsert;
                if (!OpportunityToUpdate.isEmpty()) update OpportunityToUpdate;

            }
            
        } catch (Exception e) {
            System.debug('Error =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
    }

    public static void throwErrorIfTheOppProductsAreNull(List<Payment__c> newRecords) {
        try {
            Set<Id> stOfOppId = new Set<Id>();

            for (Payment__c p : newRecords) {
                if (p.Enquiry__c != null) {
                    stOfOppId.add(p.Enquiry__c);
                }
            }

            if (!stOfOppId.isEmpty()) {
                Map<Id, AggregateResult> oppIdToCount = new Map<Id, AggregateResult>([SELECT OpportunityId oppId, COUNT(Id) cnt FROM OpportunityLineItem WHERE OpportunityId IN :stOfOppId GROUP BY OpportunityId]);
                System.debug('oppIdToCount =======> ' + oppIdToCount);
                for (Payment__c p : newRecords) {
                    if (p.Enquiry__c != null) {
                        if (!oppIdToCount.containsKey(p.Enquiry__c) || (Integer)oppIdToCount.get(p.Enquiry__c).get('cnt') == 0) {
                            System.debug('Inside =======> ');
                            p.addError('Please add the products to the opportunity');
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error =======> ' + e.getMessage() +' at line number =======> ' + e.getLineNumber());
        }
    }

    

    @AuraEnabled
    public static void subsidyDocumentCollected(string recordId){
        try {
            if(recordId !=  null){
                Order ord = new Order();
                ord.Id = recordId;
                ord.Subsidy_Document_Collected__c = true;
                ord.PME_Drive__c = true;
                update ord;
            }
        } catch (Exception e) {
            System.debug('Error =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static void PDIDocumentCollected(string recordId){
        try {
            if(recordId !=  null){
                Order ord = new Order();
                ord.Id = recordId;
                ord.PDI_Document_Collected__c = true;
                update ord;
            }
        } catch (Exception e) {
            System.debug('Error =======> ' + e.getMessage() + ' at line number =======> ' + e.getLineNumber());
        }
    }
}