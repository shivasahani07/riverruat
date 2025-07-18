@RestResource(urlMapping='/lead-followups')
global with sharing class LeadFollowUpAPI {
    @HttpPost
    global static void createFollowUp() {
        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();
        Follow_Up__c followUp;
        
        try {
            followUp = (Follow_Up__c) JSON.deserialize(body, Follow_Up__c.class);
        } catch (Exception e) {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('{"error": "Invalid JSON format: ' + e.getMessage() + '"}');
            return;
        }
        
        if (String.isBlank(followUp.Lead__c)) {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('{"error": "Lead__c is required."}');
            return;
        }
        
        Lead lead;
        try {
            lead = [SELECT Id FROM Lead WHERE Id = :followUp.Lead__c LIMIT 1];
        } catch (Exception e) {
            RestContext.response.statusCode = 404;
            RestContext.response.responseBody = Blob.valueOf('{"error": "Lead not found for ID: ' + followUp.Lead__c + '"}');
            return;
        }
        
        if (String.isBlank(followUp.Status__c)) {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('{"error": "Status__c is required."}');
            return;
        }
        
        Set<String> validStatuses = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Follow_Up__c.Status__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            validStatuses.add(entry.getValue());
        }
        
        if (!validStatuses.contains(followUp.Status__c)) {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('{"error": "Invalid Status__c. Allowed values: ' + String.join(new List<String>(validStatuses), ', ') + '"}');
            return;
        }
        
        if (followUp.Follow_Up_Date__c == null) {
            followUp.Follow_Up_Date__c = DateTime.now().addDays(1);
        }
        
        insert followUp;

        Map<String, Object> response = new Map<String, Object>();
        response.put('id', followUp.Id);
        response.put('success', true);
        response.put('message', 'Follow-up record created successfully');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        RestContext.response.statusCode = 201;
    }
}