@RestResource(urlMapping='/leadTestDriveStatus')
global with sharing class LeadTestDriveStatusAPI {

    @HttpGet
    global static void getTestDriveStatus() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        List<LeadStatusWrapper> leadStatusList = new List<LeadStatusWrapper>();

        // Query Leads with LeadSource = 'WhatsApp' and their related Test Drives
        List<Lead> leads = [
            SELECT Id, Name, LeadSource,
                (SELECT Id, Test_Drive_Status__c, Test_Ride_Date__c 
                 FROM Test_Drives__r 
                 ORDER BY LastModifiedDate DESC 
                 LIMIT 1)
            FROM Lead
            WHERE LeadSource = 'OzoneTel WhatsApp'
        ];

        for (Lead l : leads) {
            String testDriveStatus = 'No Test Drive';
            DateTime testDriveDate;

            if (!l.Test_Drives__r.isEmpty()) {
                Test_Drive__c td = l.Test_Drives__r[0];
                testDriveStatus = td.Test_Drive_Status__c;
                testDriveDate = td.Test_Ride_Date__c;
            }

            leadStatusList.add(new LeadStatusWrapper(
                l.Id, l.Name, testDriveStatus, testDriveDate
            ));
        }

        res.responseBody = Blob.valueOf(JSON.serialize(leadStatusList));
        res.statusCode = 200;
    }

    global class LeadStatusWrapper {
        public Id LeadId;
        public String LeadName;
        public String TestDriveStatus;
        public DateTime TestDriveDate;

        public LeadStatusWrapper(Id id, String name, String status, DateTime testDriveDate) {
            this.LeadId = id;
            this.LeadName = name;
            this.TestDriveStatus = status;
            this.TestDriveDate = testDriveDate;
        }
    }
}