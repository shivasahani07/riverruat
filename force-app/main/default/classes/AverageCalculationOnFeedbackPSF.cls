/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-21-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class AverageCalculationOnFeedbackPSF {
    
    public static void calculateAverageRating(List<Feedback_Response__c> feedbackList, Map<Id, Feedback_Response__c> feedbackOldMap) {
        System.debug('Average Rating Calculation Method Entered');
        try {
            List<Feedback_Response__c> recordsToUpdate = new List<Feedback_Response__c>();

            if (!feedbackList.isEmpty()) {
                for (Feedback_Response__c f : feedbackList) {

                    String newAnswers = f.Answers_For_Post_7_Day_Service__c;
                    String oldAnswers = feedbackOldMap.containsKey(f.Id) ? feedbackOldMap.get(f.Id).Answers_For_Post_7_Day_Service__c : null;

                    if (newAnswers != oldAnswers && String.isNotBlank(newAnswers)) {
                        Decimal averageRating = calculateAverageFromAnswerString(newAnswers);

                        Integer finalRating = Integer.valueOf(Math.round(averageRating));


                         Feedback_Response__c updatedRecord = new Feedback_Response__c(
                            Id = f.Id,
                            Rating__c = finalRating
                        );

                        recordsToUpdate.add(updatedRecord);
                    }
                }
            }

            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }

        } catch (Exception e) {
            System.debug('Error Occurred ==> ' + e.getMessage());
            System.debug('Error Line Number Is ==> ' + e.getLineNumber());
        }
    }
    
    private static Decimal calculateAverageFromAnswerString(String answerString) {
        if (String.isBlank(answerString)) return 0;
        
        List<String> parts = answerString.split(',');
        Integer total = 0;
        Integer count = 0;
        
        for (String part : parts) {
            List<String> subParts = part.split('=');
            if (subParts.size() == 2) {
                String answer = subParts[1].trim().toLowerCase();
                System.debug('Answer ==>'+answer);

                try {
                    Integer val = Integer.valueOf(answer);
                    total += val;
                    count++;
                } catch (Exception ex) {
                    if (answer == 'Yes') {
                        total += 5;
                        count++;
                    } else if (answer == 'No') {
                        total += 1;
                        count++;
                    }
                }
            }
        }
        
        if (count > 0) {
            return (Decimal) total / count;
        }
        return 0;
    }
    public static void populateFormName(List<Feedback_Response__c> feedbackList){
        System.debug('Feedback List To Process==>'+feedbackList);
        
        try{
            Set<String> formNamesAvailable = new Set<String>();
    
            List<Schema.PicklistEntry> picklistValuez = Feedback_Question__c.Form_Name__c.getDescribe().getPicklistValues();
            for (Schema.PicklistEntry picklistValue : picklistValuez){
                formNamesAvailable.add(picklistValue.getValue());
            }  
            System.debug('formNamesAvailable==>'+formNamesAvailable);

            if(!feedbackList.isEmpty()){
                for(Feedback_Response__c f : feedbackList){
                    if(f.Form_URL__c != null || f.Form_URL__c != ''){
                        String nameOfForm = f.Form_URL__c.substringBetween('/FeedbackForm/', '?');
                         System.debug('Extracted nameOfForm ==> ' + nameOfForm);

                   
                    Map<String, String> urlToPicklistMap = new Map<String, String>{
                        'PrePurchaseExperience' => 'Pre-Purchase Experience',
                        'OverallExperience'     => 'Overall Experience',
                        'ProductReview'         => 'Product Review',
                        'ServiceFeedback'       => 'Service Feedback',
                        'PostServiceFeedback'   => 'PSF'
                    };

                    String displayFormName = urlToPicklistMap.containsKey(nameOfForm) ? urlToPicklistMap.get(nameOfForm) : null;

                    if (displayFormName != null && formNamesAvailable.contains(displayFormName)) {
                        f.Name_Of_Form__c = displayFormName;
                    } else {
                        System.debug('Form name not found in available picklist values or unknown form name.');
                    }
                        
                    }
                }
            }
            

        }catch(Exception e){
            System.debug('Error Occured ==>'+e.getMessage());
            System.debug('Error Line Number Is==>'+e.getLineNumber());
        }
    }
    //added by Aniket on 12/08/2025 for Report Issue
//     public static void createAnswerChildObject(List<Feedback_Response__c> newList, Map<Id, Feedback_Response__c> oldMapList) {
//     try {
//         Map<Id, List<String>> responseToAnswersMap = new Map<Id, List<String>>();
//         Set<Id> questionMap = new Set<Id>();
        
//         for (Feedback_Response__c f : newList) {
//             Feedback_Response__c oldOne = oldMapList.get(f.Id);

//             if (f.Answer__c != oldOne.Answer__c && String.isNotBlank(f.Answer__c)) {
//                 responseToAnswersMap.put(f.Id, f.Answer__c.split(',')); 
//                 questionMap.add(f.Feedback_Question__c);
//             }
//         }
//         System.debug('responseToAnswersMap==>'+responseToAnswersMap);

//         if (responseToAnswersMap.isEmpty()) {
//             System.debug('No Answers To Process');
//             return;
//         }


//        List<Feedback_Question__c> fbList =[SELECT Id,Name FROM Feedback_Question__c WHERE Id IN:questionMap];


        
//         List<Feedback_Response_Answers__c> answersToInsert = new List<Feedback_Response_Answers__c>();
//         for (Id respId : responseToAnswersMap.keySet()) {
//             List<String> ansList = responseToAnswersMap.get(respId);
//             for (Integer i = 0, size = ansList.size(); i < size; i++) {
//                 answersToInsert.add(new Feedback_Response_Answers__c(
//                     Answer__c = ansList[i],
//                     Feedback_Response__c = respId,
//                     Question__c=questionMap.get(respId)

//                 ));
//             }
//         }

       
//         if (!answersToInsert.isEmpty()) {
//             insert answersToInsert;
//             System.debug('Inserted Answer Records ==> ' + answersToInsert);
//         }

//     } catch (Exception e) {
//         System.debug('Error Occurred ==> ' + e.getMessage());
//         System.debug('Error Line Number ==> ' + e.getLineNumber());
//     }
// }

  public static void createAnswerChildObject(List<Feedback_Response__c> newList, Map<Id, Feedback_Response__c> oldMapList) {
    try {
        Map<Id, List<String>> responseToAnswersMap = new Map<Id, List<String>>();
        Map<Id, Id> responseToQuestionMap = new Map<Id, Id>(); // ✅ new map
        Set<Id> questionIds = new Set<Id>();

        // Step 1: Identify changed answers and map responses to questions
        for (Feedback_Response__c f : newList) {
            Feedback_Response__c oldOne = oldMapList.get(f.Id);
            if (f.Answer__c != oldOne.Answer__c && String.isNotBlank(f.Answer__c)) {
                responseToAnswersMap.put(f.Id, f.Answer__c.split(','));
                responseToQuestionMap.put(f.Id, f.Feedback_Question__c); // ✅ track which question belongs to each response
                questionIds.add(f.Feedback_Question__c);
            }
        }

        if (responseToAnswersMap.isEmpty()) {
            System.debug('No Answers To Process');
            return;
        }

        // Step 2: Query question names (optional, if you need names)
        Map<Id, Feedback_Question__c> questionMap = new Map<Id, Feedback_Question__c>(
            [SELECT Id, Name FROM Feedback_Question__c WHERE Id IN :questionIds]
        );

        // Step 3: Create child answer records
        List<Feedback_Response_Answers__c> answersToInsert = new List<Feedback_Response_Answers__c>();

        for (Id respId : responseToAnswersMap.keySet()) {
            List<String> ansList = responseToAnswersMap.get(respId);
            Id questionId = responseToQuestionMap.get(respId);
            String questionName = questionMap.containsKey(questionId) ? questionMap.get(questionId).Name : null;

            for (String ans : ansList) {
                answersToInsert.add(new Feedback_Response_Answers__c(
                    Answer__c = ans,
                    Feedback_Response__c = respId,
                    Question__c = questionName
                ));
            }
        }

        if (!answersToInsert.isEmpty()) {
            insert answersToInsert;
            System.debug('Inserted Answer Records ==> ' + answersToInsert);
        }

    } catch (Exception e) {
        System.debug('Error Occurred ==> ' + e.getMessage());
        System.debug('Error Line Number ==> ' + e.getLineNumber());
    }
}



  //this method is for the 5th Form Logic 
 

}