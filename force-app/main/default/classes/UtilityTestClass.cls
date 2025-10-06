public class UtilityTestClass {
    public static User createSalesManagerUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        User u = new User(
            FirstName = 'Anurag', LastName = 'Raichand', Alias = 'smanag', Email = 'sales.manager@example.com', Username = 'sales.manager.' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id, TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        insert u; return u;
    }
    
    public static User createSalesManagerUser1() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager (Partner)' LIMIT 1];
        Account acc = UtilityTestClass.createTestAccount('Partner Store', 'D001', 'Demo Partner Store','560076', 'Dealer');
        
        Contact con = createTestContact('Partner','Manager','partner.manager@example.com','9876543218',acc.Id, 'Sales');
        
        User u = new User(
            FirstName = 'Partner', LastName = 'Manager', Alias = 'pmanag',  Email = 'partner.manager@example.com', Username = 'partner.manager.' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id, TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', ContactId = con.Id
        );
        insert u; return u;
    }
    
    public static Account createTestAccount(String name, String centerCode, String StoreName, String billingPostalCode, String accType) {
        User ownerUser = [SELECT Id, UserRoleId FROM User WHERE UserRoleId != null LIMIT 1];
        Account acc = new Account(Name = name, Center_Code__c = centerCode, Store_Name__c = StoreName , BillingPostalCode = billingPostalCode, Type = accType );
        acc.OwnerId = ownerUser.Id;
        insert acc; return acc;
    }
    
    public static Lead createLead(){
        Lead lead =  new Lead(
            LastName = 'Test No Conversion', Company = 'Test Company', Status = 'New', Phone = '9009244455', PostalCode = '123456', LeadSource = 'Online', 
            Secondary_Sources__c = 'Google'
        );
        insert lead; return lead;
    }
    
    public static Lead createTestLead(String lastName, String company , String status, String phone, String postalCode, String leadSource, String secondardSources){
        Lead lead =  new Lead( LastName = lastName, Company = company, Status = status, Phone = phone, PostalCode = postalCode, LeadSource = leadSource, Secondary_Sources__c = secondardSources );
        insert lead; return lead;
    }
    
    public static Opportunity createTestOpportunity(String name, Id accountId, String stageName, Date closeDate, Decimal amount) {
        Opportunity opp = new Opportunity( Name = name, AccountId = accountId, StageName = stageName, CloseDate = closeDate, Amount = amount);
        insert opp; return opp;
    }
    
    Public static Test_Drive__c createTestDriver(){
        Lead l = createLead();
        Test_Drive__c testDrive = new Test_Drive__c(Name = 'Test Drive', Lead__c = l.Id, Test_Drive_Status__c = 'New', OwnerId = UserInfo.getUserId() );
        insert testDrive; return testDrive;
    }
    
    Public static Test_Drive__c createTest1Driver(String name,Id opportunity, String testDriveStatus){
        Test_Drive__c testDrive = new Test_Drive__c(Name = name, Opportunity__c = opportunity, Test_Drive_Status__c = testDriveStatus);
        testDrive.OwnerId = UserInfo.getUserId(); testDrive.Test_Drive_Date__c = Date.today();
        insert testDrive; return testDrive;
    }
    
    public static Follow_Up__c createFollowUp(String name, Id lead,  Id opportunity){
        Follow_Up__c FollUp = new Follow_Up__c(Name = name, Follow_Up_Date__c = DateTime.now(), Lead__c = lead, Opportunity__c = opportunity);
        insert FollUp; return FollUp;
    }
    
    public static Pin_Code__c createTestPinCode(Id dealerId, String pincode, String cityName) {
        system.debug('dealerId ====>'+ dealerId);
        system.debug('pincode ==>'+ pincode);
        system.debug('cityName ====>'+ cityName);
        List<Pricebook2> pb = [SELECT Id, Name, IsActive, IsStandard FROM Pricebook2 WHERE IsActive = true AND Name = 'Bengaluru PB' LIMIT 1];
        City__c city = new City__c(Name = cityName, Price_Book__c =pb[0].Id );
        insert city;
        system.debug('city ====>'+ city);
        Pin_Code__c pin = new Pin_Code__c(Area_Pincode__c = pincode, Dealer_Service_Center__c = dealerId, City__c = city.Id);
        system.debug('pin ====>'+ pin);
        insert pin; return pin;
    }
    
    public static Task createTestTask(Id leadId, String status, Date activityDate) {
        Task t = new Task(WhoId = leadId, Subject = 'Call', Status = status, ActivityDate = activityDate);
        insert t; return t;
    }
    
    public static Contact createTestContact(String firstName, String lastName, String mail, String phone,Id accountId, String roleType ){       
        List<Schema.Location> locList = [SELECT Id, Name FROM Location LIMIT 1];
        //Schema.Location loc = locList[0];
        Schema.Location loc = new Schema.Location(Name = 'River Store - Indiranagar', LocationType= 'State');
        insert loc;
        Account acc = UtilityTestClass.createTestAccount('Partner Store', 'D001', 'Demo Partner Store','560076', 'Dealer');
        Contact con = new Contact(FirstName = firstName, LastName = lastName, Email = mail, Phone = phone, AccountId = accountId, Role_Type__c = roleType, Location__c =loc.Id);
        con.Designation__c = 'WM';
        insert con; return con;
    }

}