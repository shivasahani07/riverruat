@isTest
public class PurchaseOrderTriggerHandlerTest {
    
    @isTest
    public static void testSendHighValueNotification() {
        Account acc = new Account(Name = 'Test Account', Store_Manager_Email__c = 'storemanager@test.com', Manager_Thresold_Amount__c = 1000);
        insert acc;

        ProductRequest po = new ProductRequest(
            Account__c = acc.Id,
            ShipmentType = 'VOR'
        );
        insert po;
        
        ProductRequestLineItem poLineItem = new ProductRequestLineItem(
            ParentId = po.Id,
            Product2Id ='01t5j00000FnlasAAB' ,
            QuantityRequested = 140,
            Alloted_Quantity__c = 140,
            Unit_Price__c = 250
            
        );

        List<ProductRequest> purchaseOrders = new List<ProductRequest>{ po };
            
            
            Test.startTest();
        po.ShipmentType='STK';
        update po;
        
        delete po;
        
        PurchaseOrderTriggerHandler.sendHighValueNotification(purchaseOrders);
        PurchaseOrderTriggerHandler.sendHighValueNotification(NULL);
       // PurchaseOrderTriggerHandler.throwErrorIftheRecordIsUpdatedByDMSUserWhenParentRecordIsNotInNewStatus()
        PurchaseOrderTriggerHandler.mytest();
        Test.stopTest();
        
    }
  
}