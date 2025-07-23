@RestResource(urlMapping='/createLeadWithChildren')
global with sharing class LeadWithChildrenAPI {

    @HttpPost
    global static String createLeadWithChildren() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String requestBody = req.requestBody.toString();
        
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        Map<String, Object> leadData = (Map<String, Object>) payload.get('lead');
        List<Object> testDrivesData = (List<Object>) payload.get('testDrives');
        List<Object> followUpsData = (List<Object>) payload.get('followUps');
        
        Lead existingLead;
        String email = (String) leadData.get('Email');
        String phone = (String) leadData.get('Phone');
        
        // Check for duplicate
        List<Lead> duplicateLeads = [
            SELECT Id, FirstName, LastName FROM Lead 
            WHERE (Email = :email OR Phone = :phone) 
            LIMIT 1
        ];
        
        if (!duplicateLeads.isEmpty()) {
            existingLead = duplicateLeads[0];
        }
        
        Lead lead;
        if (existingLead == null) {
            // Create Lead
            lead = new Lead();
            lead.FirstName = (String) leadData.get('FirstName');
            lead.LastName = (String) leadData.get('LastName');
            lead.Email = email;
            lead.Phone = phone;
            lead.Company = (String) leadData.get('Company');
            insert lead;
        } else {
            lead = existingLead;
        }

        List<Test_Drive__c> testDrives = new List<Test_Drive__c>();
        for (Object tdObj : testDrivesData) {
            Map<String, Object> tdMap = (Map<String, Object>) tdObj;
            Test_Drive__c td = new Test_Drive__c();
            td.Lead__c = lead.Id;
            td.Vehicle__c = (String) tdMap.get('Vehicle__c');
            td.Test_Ride_Date__c = (DateTime) tdMap.get('Test_Ride_Date__c');
            testDrives.add(td);
        }

        List<Follow_Up__c> followUps = new List<Follow_Up__c>();
        for (Object fuObj : followUpsData) {
            Map<String, Object> fuMap = (Map<String, Object>) fuObj;
            Follow_Up__c fu = new Follow_Up__c();
            fu.Lead__c = lead.Id;
           // fu.Remarks__c = (String) fuMap.get('Remarks__c');
            fu.Follow_Up_Date__c = (DateTime) fuMap.get('Follow_Up_Date__c');
            followUps.add(fu);
        }

        if (!testDrives.isEmpty()) insert testDrives;
        if (!followUps.isEmpty()) insert followUps;

        return JSON.serializePretty(new Map<String, Object>{
            'message' => existingLead == null ? 'New Lead Created' : 'Existing Lead Used',
            'leadId' => lead.Id,
            'testDrivesInserted' => testDrives.size(),
            'followUpsInserted' => followUps.size()
        });
    }
}