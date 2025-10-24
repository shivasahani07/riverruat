@isTest
public class SendEmailSchedulerTest {
	
    @isTest
    public static void testSendEmail(){
        Account testAccount = new Account(Name = 'Test Account',Center_Code__c = '291002',Email__c = 'test@example.com',Phone='0987654321');
        insert testAccount;
        
        Schema.Location testLocation = new Schema.Location(Name = 'Test Location', LocationType = 'State',State__c = 'Karnataka');
        insert testLocation;
        
        Contact c = new Contact(LastName='Good',Email='test@exmple.com',Role_Type__c='Sales',Location__c =testLocation.id,Phone='0987654321',AccountId=testAccount.Id);
        insert c;
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'Good', IsActive = true, HSN_Code__c = '12345', Type__c= 'Accessories');
        insert testProduct;
       
        
        RecordType otcRecordType = [
            SELECT Id FROM RecordType
            WHERE DeveloperName = 'Vehicle' AND SObjectType = 'Order'
            LIMIT 1
        ];
        Asset testAsset = new Asset(Name='Test Asset 1',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition 1',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version 1');
        insert testSV;
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle 2', Account__c=testAccount.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3C4D5E6F7G8H9I',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true,VehicleRegistrationNumber='098765',RSA_Activation__c=false);
        insert testVehicle;
        
        Order order = new Order(
            AccountId = testAccount.Id,
            Status = 'New',
            RecordTypeId = otcRecordType.Id,
            EffectiveDate = Date.today(),
            Assigned_Vehicle__c = testVehicle.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;
        
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
         
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.id,
            Type__c = 'Accessories'
        );
        insert orderItem;
        
        Payment__c p = new Payment__c(Mode_Of_Payment__c='Cash',Payment_Status__c='Success',Source_Of_Payment__c='Website',Transaction_Id__c='ev46vt35');
        insert p;
        
        Order_Payment__c opp2 = new Order_Payment__c(Payments__c=p.Id,Type__c='Down Payment',Order__c=order.Id);
        insert opp2; 
        
        
        
        Order_Invoice__c o1 = new Order_Invoice__c();
        o1.Name='Accessories Invoice';
        o1.Invoice_Type__c='Accessories Invoice';
        o1.Invoice_Number__c='Test1234';
        o1.Order__c=order.Id;
        insert o1;
        
        List<attachment> attachmentsToInsert = new List<attachment>();
        Attachment att1 = new Attachment();
        att1.Name = 'Pre Order Receipt' + order.Id + '.pdf';
        att1.Body = Blob.valueOf('test data');
        att1.ParentId = order.Id;
        att1.ContentType = 'application/pdf';
        
        attachmentsToInsert.add(att1);
        insert attachmentsToInsert;
        
        SendEmailScheduler s = new SendEmailScheduler(opp2.Id,attachmentsToInsert);
        Test.startTest();
        s.execute(null);
        Test.stopTest();
    }
}