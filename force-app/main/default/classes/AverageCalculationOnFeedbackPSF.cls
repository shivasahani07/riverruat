/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 07-03-2025
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
}