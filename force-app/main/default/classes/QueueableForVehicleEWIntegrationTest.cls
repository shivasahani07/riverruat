@IsTest
public class QueueableForVehicleEWIntegrationTest {
     @IsTest
    static void testQueueableForEWIntegration(){
        EW_API_Details__c apiDetails = new EW_API_Details__c();
        apiDetails.Name='EW Integration';
        apiDetails.API_Endpoint__c='https://mock.com';
        apiDetails.API_Key__c='oiuytrewq';
        apiDetails.Cookie__c='PHD=t1432';    
        insert apiDetails;
        
        Account testAccount = VehicleQueueableTestUtility.createAccount();
        
        Schema.Location testLocation = VehicleQueueableTestUtility.createLocation();
        
        Contact con = VehicleQueueableTestUtility.createContact(testAccount.Id,testLocation.Id);
        
        Product2 testProduct =  VehicleQueueableTestUtility.createProduct();
        
        Id stdPrBk = Test.getStandardPricebookId();
        
        PricebookEntry testPricebookEntry =VehicleQueueableTestUtility.createPricebookEntry(stdPrBk,testProduct.Id);
        
        Asset testAsset = VehicleQueueableTestUtility.createAsset(testAccount.Id,testProduct.Id);
        
        VehicleDefinition testVD = VehicleQueueableTestUtility.createVehicleDef(testProduct.Id);
        
        Software_Version__c testSV = VehicleQueueableTestUtility.createSoftwareVersion();
        
        Vehicle testVehicle = VehicleQueueableTestUtility.createVehicle(testAccount.Id,testAsset.Id,testVD.Id,testSV.Id);
        
        AssetMilestone asm = VehicleQueueableTestUtility.createAssetMileStone(testAsset.Id,testVehicle.Id);
        
        Order oldOrder = VehicleQueueableTestUtility.createOrder(testAccount.Id,testVehicle.Id,stdPrBk,con.Id);
       
        OrderItem testOrderItem = VehicleQueueableTestUtility.createOrderItem(oldOrder.Id,testProduct.Id,testPricebookEntry.Id);
            
        Order_Invoice__c o = VehicleQueueableTestUtility.createInvoice(oldOrder.Id);
        
        List<Id> orderIds = new List<Id>{oldOrder.Id};
         ExtendedWarrantyForVehicleOrder.wrapperForEWIntegration ww = new ExtendedWarrantyForVehicleOrder.wrapperForEWIntegration();
                            ww.vehicleId = testVehicle.Id;
                            ww.dealerCode = testAccount.Center_Code__c;
                            ww.purchaseDate = testVehicle.Purchased_Date__c;
                            ww.chassisNumber = testVehicle.ChassisNumber;
                            ww.model = testVehicle.Name;
                            ww.battery = testVehicle.RR_Battery_Number__c;
                            ww.engineNumber = testVehicle.EngineNumber;
                            ww.charger = testVehicle.Charger_PC_Number__c;
        Map<Id,ExtendedWarrantyForVehicleOrder.wrapperForEWIntegration> wrapperValues = new Map<Id,ExtendedWarrantyForVehicleOrder.wrapperForEWIntegration>();
        wrapperValues.put(oldOrder.Id,ww);
        
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImplEW());  

         Test.startTest();
        
        QueueableForVehicleEWIntegration queueableJob = new QueueableForVehicleEWIntegration(orderIds,wrapperValues);
        System.enqueueJob(queueableJob);
        
        Test.stopTest();        
        
    }
    public class HttpCalloutMockImplEW implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(201);
            res.setBody('{"Message":"Extended Warranty created.","Policy No":"EW050","ChassisNo":"1234567890123121","EW Start Date":"26-07-2027","EW Expire Date":"25-07-2029","Dealer Amount":"4623","Customer Amount":"7079","Warranty Type":"Extended Warranty","Dealer Type":"FOFO - Sales","GST Number":"29AAMCB5945L1ZY","Dealer Name":"BALAJI ELECTRIC VEHICLES PRIVATE LIMITED - Yelahanka","State":"Karnataka","status":"success"}'); 
            return res;
        }
    }
    public class HttpCalloutMockImplEWFprfailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(400);
            res.setBody('{"Message":"Extended Warranty created.","Policy No":"EW050","ChassisNo":"1234567890123121","EW Start Date":"26-07-2027","EW Expire Date":"25-07-2029","Dealer Amount":"4623","Customer Amount":"7079","Warranty Type":"Extended Warranty","Dealer Type":"FOFO - Sales","GST Number":"29AAMCB5945L1ZY","Dealer Name":"BALAJI ELECTRIC VEHICLES PRIVATE LIMITED - Yelahanka","State":"Karnataka"}'); 
            return res;
        }
    }
    @IsTest
    static void testQueueableForEWIntegrationfFail(){
        EW_API_Details__c apiDetails = new EW_API_Details__c();
        apiDetails.Name='EW Integration';
        apiDetails.API_Endpoint__c='https://mock.com';
        apiDetails.API_Key__c='oiuytrewq';
        apiDetails.Cookie__c='PHD=t1432';    
        insert apiDetails;
        
        Account testAccount = VehicleQueueableTestUtility.createAccount();
        
        Schema.Location testLocation = VehicleQueueableTestUtility.createLocation();
        
        Contact con = VehicleQueueableTestUtility.createContact(testAccount.Id,testLocation.Id);
        
        Product2 testProduct =  VehicleQueueableTestUtility.createProduct();
        
        Id stdPrBk = Test.getStandardPricebookId();
        
        PricebookEntry testPricebookEntry =VehicleQueueableTestUtility.createPricebookEntry(stdPrBk,testProduct.Id);
        
        Asset testAsset = VehicleQueueableTestUtility.createAsset(testAccount.Id,testProduct.Id);
        
        VehicleDefinition testVD = VehicleQueueableTestUtility.createVehicleDef(testProduct.Id);
        
        Software_Version__c testSV = VehicleQueueableTestUtility.createSoftwareVersion();
        
        Vehicle testVehicle = VehicleQueueableTestUtility.createVehicle(testAccount.Id,testAsset.Id,testVD.Id,testSV.Id);
        
        AssetMilestone asm = VehicleQueueableTestUtility.createAssetMileStone(testAsset.Id,testVehicle.Id);
        
        Order oldOrder = VehicleQueueableTestUtility.createOrder(testAccount.Id,testVehicle.Id,stdPrBk,con.Id);
       
        OrderItem testOrderItem = VehicleQueueableTestUtility.createOrderItem(oldOrder.Id,testProduct.Id,testPricebookEntry.Id);
            
        Order_Invoice__c o = VehicleQueueableTestUtility.createInvoice(oldOrder.Id);
        
        List<Id> orderIds = new List<Id>{oldOrder.Id};
         ExtendedWarrantyForVehicleOrder.wrapperForEWIntegration ww = new ExtendedWarrantyForVehicleOrder.wrapperForEWIntegration();
                            ww.vehicleId = testVehicle.Id;
                            ww.dealerCode = testAccount.Center_Code__c;
                            ww.purchaseDate = testVehicle.Purchased_Date__c;
                            ww.chassisNumber = testVehicle.ChassisNumber;
                            ww.model = testVehicle.Name;
                            ww.battery = testVehicle.RR_Battery_Number__c;
                            ww.engineNumber = testVehicle.EngineNumber;
                            ww.charger = testVehicle.Charger_PC_Number__c;
        Map<Id,ExtendedWarrantyForVehicleOrder.wrapperForEWIntegration> wrapperValues = new Map<Id,ExtendedWarrantyForVehicleOrder.wrapperForEWIntegration>();
        wrapperValues.put(oldOrder.Id,ww);
        
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImplEWFprfailure());  

         Test.startTest();
        
        QueueableForVehicleEWIntegration queueableJob = new QueueableForVehicleEWIntegration(orderIds,wrapperValues);
        System.enqueueJob(queueableJob);
        
        Test.stopTest();        
        
    }

}