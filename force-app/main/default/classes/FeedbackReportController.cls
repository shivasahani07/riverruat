public class FeedbackReportController {
     public class ReportRow {
        @AuraEnabled public String feedbackName;
        @AuraEnabled public String feedbackId;
        @AuraEnabled public String status;
        @AuraEnabled public String serviceCenter;
        @AuraEnabled public String city;
        @AuraEnabled public String workOrderNumber;
        @AuraEnabled public String jobType;
        @AuraEnabled public String serviceAdvisor;
 
        @AuraEnabled public String q1;
        @AuraEnabled public String q2;
        @AuraEnabled public String q3;
        @AuraEnabled public String q4;
        @AuraEnabled public String q5;
        @AuraEnabled public String q6;
        @AuraEnabled public String q7;
    }
 
    @AuraEnabled(cacheable=true)
public static List<Map<String,Object>> getFeedbackReport() {
    List<Feedback_Response__c> responses = [
        SELECT Id, Name, Response_Status__c,
               Job_Card__r.WorkOrderNumber,
               Job_Card__r.RR_Job_Type__c,
               Job_Card__r.Service_Center__r.Name,
               Job_Card__r.Account.Name, Job_Card__r.RR_Service_Advisor__r.Name,
               Job_Card__r.City__r.Name,
               (SELECT Question__c, Answer__c FROM Feedback_Response_Answers__r)
        FROM Feedback_Response__c
        WHERE Response_Status__c = 'Submitted' AND Name_Of_Form__c = 'PSF' AND Id='a2pBh0000002f3tIAA'
        LIMIT 500
    ];

    List<Map<String,Object>> reportData = new List<Map<String,Object>>();

    for (Feedback_Response__c res : responses) {
        Map<String,Object> row = new Map<String,Object>();
        row.put('feedbackName', res.Name);
        row.put('feedbackId', res.Id);
        row.put('status', res.Response_Status__c);
        row.put('serviceCenter', res.Job_Card__r.Account.Name);
        row.put('city', res.Job_Card__r.City__r.Name);
        row.put('workOrderNumber', res.Job_Card__r.WorkOrderNumber);
        row.put('jobType', res.Job_Card__r.RR_Job_Type__c);
        row.put('serviceAdvisor', res.Job_Card__r.RR_Service_Advisor__r.Name);

        
        for (Feedback_Response_Answers__c ans : res.Feedback_Response_Answers__r) {
            row.put(ans.Question__c, ans.Answer__c);
        }

        reportData.add(row);
    }

    return reportData;
}

    @AuraEnabled(cacheable = true)
public static String getFeedbackReportCSV() {
    List<Feedback_Response__c> responses = [
        SELECT Id, Name, Response_Status__c,
               Job_Card__r.WorkOrderNumber,
               Job_Card__r.RR_Job_Type__c,
               Job_Card__r.Service_Center__r.Name,
               Job_Card__r.Account.Name, Job_Card__r.RR_Service_Advisor__r.Name,
               Job_Card__r.City__r.Name,
               (SELECT Question__c, Answer__c FROM Feedback_Response_Answers__r)
        FROM Feedback_Response__c
        WHERE Response_Status__c = 'Submitted' AND Name_Of_Form__c = 'PSF' AND Id='a2pBh0000002f3tIAA'
        LIMIT 500
    ];

    Set<String> questionHeadersSet = new Set<String>();
    for (Feedback_Response__c res : responses) {
        for (Feedback_Response_Answers__c ans : res.Feedback_Response_Answers__r) {
            questionHeadersSet.add(ans.Question__c);
        }
    }

    List<String> questionHeaders = new List<String>(questionHeadersSet);
    questionHeaders.sort(); 

    
    List<String> csvLines = new List<String>();

   
    List<String> headers = new List<String>{
        'Feedback Name','Feedback Id','Status','Service Center','City','Work Order','Job Type','Service Advisor'
    };
    headers.addAll(questionHeaders); 
    csvLines.add(String.join(headers, ','));

    // CSV Rows
    for (Feedback_Response__c res : responses) {
        Map<String, String> ansMap = new Map<String, String>();
        for (Feedback_Response_Answers__c ans : res.Feedback_Response_Answers__r) {
            ansMap.put(ans.Question__c, ans.Answer__c);
        }
         System.debug('ansMap==>'+ansMap);

        List<String> rowValues = new List<String>{
            res.Name,
            res.Id,
            res.Response_Status__c,
            res.Job_Card__r.Account.Name,
            res.Job_Card__r.City__r.Name,
            res.Job_Card__r.WorkOrderNumber,
            res.Job_Card__r.RR_Job_Type__c,
            res.Job_Card__r.RR_Service_Advisor__r.Name
        };

       
        for (String q : questionHeaders) {
            rowValues.add(ansMap.containsKey(q) ? ansMap.get(q) : '');
        }

       
        List<String> escapedValues = new List<String>();
        for (String val : rowValues) {
            escapedValues.add('"' + (val != null ? val.replace('"','""') : '') + '"');
        }

        csvLines.add(String.join(escapedValues, ','));
    }
   

    return EncodingUtil.base64Encode(Blob.valueOf(String.join(csvLines, '\n')));
} 
}