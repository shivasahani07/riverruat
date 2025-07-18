/**
* @File Name : UserTrackingcontrollerTest.cls
* @Description :
* @Author : Rohit SIngh Bisht
* @Last Modified By :
* @Last Modified On : April 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 3, 2025 |   | Initial Version
**/

@isTest
public class UserTrackingcontrollerTest {

    static testMethod void testOnpageLoad_CheckinExists_CheckoutNull() {
        User testUser = createTestUser();
        insert testUser;

        User_Tracking__c ut = new User_Tracking__c(
            Member__c = testUser.Id,
            Checkin_Datetime__c = DateTime.now()
            // Checkout_Datetime__c is intentionally left null
        );
        insert ut;

        Test.startTest();
        UserTrackingcontroller.UserTrack result = UserTrackingcontroller.OnpageLoad(testUser.Id);
        Test.stopTest();
    }

    static testMethod void testOnpageLoad_NoTrackingRecord() {
        User testUser = createTestUser();
        insert testUser;

        Test.startTest();
        UserTrackingcontroller.UserTrack result = UserTrackingcontroller.OnpageLoad(testUser.Id);
        Test.stopTest();
    }

    static testMethod void testUserCheckin_NewCheckin() {
        User testUser = createTestUser();
        insert testUser;

       Group leadQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Head_Quarter' LIMIT 1];


        Assignment_Group__c aGroup = new Assignment_Group__c(
            Name = 'Testing',
            Supported_Sobject__c = 'Lead',
            Round_Robin_Queue_Name__c = 'Head_Quarter',
            Max_Sobject_Assignment_Count__c = 9999,
            Max_Lead_Per_Day__c = 50,
            Case_to_Assign_in_Single_Transaction__c = 999999,
            Case_Stage_Exceed_Count__c = 999999,
            Minimum_Case_Volume__c = 999999,
            Last_Allocated_RRid__c = 0,
            // Execution_SOQL__c = 'SELECT Id, Name, OwnerId FROM Lead WHERE OwnerId IN (SELECT Id FROM Group WHERE Type = \'Queue\' AND Name=\'Head_Quarter\') AND Status IN (\'New\',\'Test Ride\') AND Future_Lead__c = false',
            Execution_SOQL__c = 'SELECT Id, Name, OwnerId FROM Lead WHERE Status IN (\'New\',\'Test Ride\') AND Future_Lead__c = false',
            isActive__c = true
        ); 
        insert aGroup;

        Assignment_Group_Member__c agm = new Assignment_Group_Member__c(
            Group_Member__c = testUser.Id,
            Out_Of_Office__c = true,
            Active__c = true,
            Assignment_Id__c = 1,
            Max_Case_Per_Day__c = 50,
            Assignment_Group__c = aGroup.Id
        );
        insert agm;

        List<Lead> testLeads = new List<Lead>{
            new Lead(LastName = 'Lead One', Phone = '9560687654', Company = 'Company 1', Status = 'New',Future_Lead__c = false, OwnerId = leadQueue.Id),
            new Lead(LastName = 'Lead Two', Phone = '0987654321', Company = 'Company 12', Status = 'New',Future_Lead__c = false, OwnerId = leadQueue.Id),
            new Lead(LastName = 'Lead Three', Phone = '1112223333', Company = 'Company 123', Status = 'New',Future_Lead__c = false, OwnerId = leadQueue.Id) 
        };
        insert testLeads;
        
        Test.startTest();
        UserTrackingcontroller.UserTrackWrapperAfterCheckin result = UserTrackingcontroller.UserCheckin(testUser.Id);
        // SobjectLoadAssignmentHelper.testCodeCoverage();
        Test.stopTest();
    }

    static testMethod void testUserCheckin_AlreadyCheckedIn() {
        User testUser = createTestUser();
        insert testUser;

        insert new User_Tracking__c(
            Member__c = testUser.Id,
            Checkin_Datetime__c = DateTime.now()
        );

        Test.startTest();
        UserTrackingcontroller.UserTrackWrapperAfterCheckin result = UserTrackingcontroller.UserCheckin(testUser.Id);
        Test.stopTest();
    }

    static testMethod void testUserCheckout() {
        User testUser = createTestUser();
        insert testUser;

        insert new User_Tracking__c(
            Member__c = testUser.Id,
            Checkin_Datetime__c = DateTime.now()
        );

        Assignment_Group__c aGroup = new Assignment_Group__c(
            Name = 'Testing',
            Supported_Sobject__c = 'Lead',
            Round_Robin_Queue_Name__c = 'Head_Quarter',
            Max_Sobject_Assignment_Count__c = 9999,
            Max_Lead_Per_Day__c = 50,
            Case_to_Assign_in_Single_Transaction__c = 999999,
            Case_Stage_Exceed_Count__c = 999999,
            Minimum_Case_Volume__c = 999999,
            Execution_SOQL__c = 'SELECT Id, Name, OwnerId FROM Lead WHERE OwnerId IN (SELECT Id FROM Group WHERE Type = \'Queue\' AND Name=\'Head_Quarter\') AND Status IN (\'New\',\'Test Ride\') AND Future_Lead__c = false',
            isActive__c = true
        ); 
        insert aGroup;

        Assignment_Group_Member__c agm = new Assignment_Group_Member__c(
            Group_Member__c = testUser.Id,
            Out_Of_Office__c = false,
			Active__c = true,
            Assignment_Id__c = 1,
            Max_Case_Per_Day__c = 50,
            Assignment_Group__c = aGroup.Id
        );
        insert agm;

        Test.startTest();
        String result = UserTrackingcontroller.UserCheckout(testUser.Id);
        Test.stopTest();
    }

    static testMethod void testUserCheckout_WithoutCheckin() {
        User testUser = createTestUser();
        insert testUser;

        Test.startTest();
        String result = UserTrackingcontroller.UserCheckout(testUser.Id);
        Test.stopTest();
    }

    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
    }
}