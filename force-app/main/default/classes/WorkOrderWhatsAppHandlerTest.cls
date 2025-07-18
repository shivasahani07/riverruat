@isTest
public class WorkOrderWhatsAppHandlerTest {
    @isTest
    public static void testMethodCoverage(){
        Account acc = new Account(Name = 'Test Account',Center_Code__c='o87gt');
        insert acc;
       

       
        Account serviceCenter = new Account(Name = 'Service Center',Type='Service Center',Center_Code__c='87t5g');
        insert serviceCenter;
       

        
        Contact primaryContact = new Contact(
            FirstName = 'Primary',
            LastName = 'ContactForTest',
            AccountId = acc.Id,
            Phone = '9876543211',
            Primary_Contact__c = true
        );
        insert primaryContact;
        
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

            ServiceResource sr = new ServiceResource(
                Name = 'Test Advisor',
                RelatedRecordId = testUser.Id 
            );
            insert sr;

        
        Product2 testProduct = new Product2(Name = 'Test Product 1', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
        insert testProduct;
        
        Asset testAsset = new Asset(Name='Test Asset 1',AccountId=acc.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition 1',ProductId=testProduct.Id);
        insert testVD;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version 1');
        insert testSV;
        
        
        Vehicle vehicle = new Vehicle(Name='Test Vehicle 2', Account__c=acc.Id, AssetId=testAsset.Id,  VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3C4',  Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
        insert vehicle;
        
        Contact wmContact = new Contact(
            FirstName = 'WM',
            LastName = 'WMName',
            AccountId = serviceCenter.Id,
            Phone = '9123456789',
            Designation__c = 'WM'
        );
        insert wmContact;
        
        User managerUser = new User(
        Username = 'manager@example.com.test',
        Alias = 'mgruser',
        Email = 'manager@example.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Manager',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = UserInfo.getProfileId(),
        TimeZoneSidKey = 'America/Los_Angeles'
    );
    insert managerUser;


        User currentUser = [SELECT Id, ManagerId FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.ManagerId = managerUser.Id;
        update currentUser;
        
        WorkOrder cloned = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id,
            Status = 'New',
            Vehicle__c = vehicle.Id,
            Service_Center__c = serviceCenter.Id,
            RR_Technician__c=primaryContact.Id,
            RR_Service_Advisor__c = sr.Id
        );
        insert cloned;
        cloned.Status='In Progress';
        update cloned;
        cloned.Status='Ready for Delivery';
        update cloned;
        cloned.Status='Completed';
        update cloned;
    }

}