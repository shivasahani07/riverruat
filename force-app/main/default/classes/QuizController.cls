public with sharing class QuizController {

    @AuraEnabled
    public static Map<String, List<QuestionAnswer>> getQuizData(String templateName) {
        Map<String, List<QuestionAnswer>> quizData = new Map<String, List<QuestionAnswer>>();
        System.debug('Entering getQuizData method');
        
        try {
            List<Question_Line_Item__c> questions = [
                SELECT Id, Question__c, Section__c FROM Question_Line_Item__c 
                WHERE Question_Template__r.Name = :templateName
            ];
            System.debug('Fetched questions: ' + questions);

            for (Question_Line_Item__c q : questions) {
                if (!quizData.containsKey(q.Section__c)) {
                    quizData.put(q.Section__c, new List<QuestionAnswer>());
                }
                quizData.get(q.Section__c).add(new QuestionAnswer(q.Question__c));
            }
        } catch (Exception e) {
            System.debug('Error in getQuizData: ' + e.getMessage());
            throw new AuraHandledException('Error fetching quiz data: ' + e.getMessage());
        }
        System.debug('Returning quizData: ' + quizData);
        return quizData;
    }

    @AuraEnabled
    public static String createOrUpdateQuizTemplates(String accountId, List<QuestionAnswer> questionAnswers) {
        System.debug('Entering createOrUpdateQuizTemplates method');
        System.debug('Account ID: ' + accountId);
        System.debug('Question Answers: ' + questionAnswers);

        try {
            Questions__c questionsRecord = new Questions__c();
            questionsRecord.Store__c = accountId;
            questionsRecord.Question_Template__c = [SELECT Id FROM Question_Template__c WHERE Name = 'ARM Checklist' LIMIT 1].Id;
            insert questionsRecord;
            System.debug('Inserted Questions__c record: ' + questionsRecord);

            List<Quiz_Response__c> responsesToInsert = new List<Quiz_Response__c>();

            for (QuestionAnswer qa : questionAnswers) {
                List<Question_Line_Item__c> questionLineItems = [
                    SELECT Id FROM Question_Line_Item__c WHERE Question__c = :qa.question LIMIT 1
                ];

                if (!questionLineItems.isEmpty()) {
                    Question_Line_Item__c questionLineItem = questionLineItems[0];

                    Quiz_Response__c newResponse = new Quiz_Response__c();
                    newResponse.Question_Template__c = questionsRecord.Question_Template__c;
                    newResponse.Question_Line_Item__c = questionLineItem.Id;
                    newResponse.Comments__c = qa.remarks;
                    newResponse.Score__c = qa.score;
                    newResponse.CheckList_Response__c = questionsRecord.Id;
                    responsesToInsert.add(newResponse);
                }
            }

            if (!responsesToInsert.isEmpty()) {
                insert responsesToInsert;
                System.debug('Inserted Quiz_Response__c records: ' + responsesToInsert);
            }

            Questions__c insertedCheckListRecord = [SELECT Id FROM Questions__c WHERE Id =: questionsRecord.Id];
            AggregateResult result = [
                SELECT SUM(Score__c) totalScore FROM Quiz_Response__c WHERE CheckList_Response__c = :insertedCheckListRecord.Id
            ];
            

            updateAccountStatus(accountId);
            return 'Quiz records created and account status updated';
        } catch (Exception e) {
            System.debug('Error in createOrUpdateQuizTemplates: ' + e.getMessage());
            throw new AuraHandledException('Error processing quiz submission: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateAccountStatus(String accountId) {
        System.debug('Entering updateAccountStatus method');
        System.debug('Account ID: ' + accountId);

        try {
            Questions__c latestQuestionsRecord = [
                SELECT Id FROM Questions__c WHERE Store__c = :accountId ORDER BY CreatedDate DESC LIMIT 1
            ];
            System.debug('Latest Questions__c record: ' + latestQuestionsRecord);

            AggregateResult result = [
                SELECT SUM(Score__c) totalScore FROM Quiz_Response__c WHERE CheckList_Response__c = :latestQuestionsRecord.Id
            ];
            Decimal totalScore = (Decimal) result.get('totalScore');
            System.debug('Total Score: ' + totalScore);

            

            
        } catch (Exception e) {
            System.debug('Error in updateAccountStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating account status: ' + e.getMessage());
        }
    }

    public class QuestionAnswer {
        @AuraEnabled
        public String question { get; set; }
        @AuraEnabled
        public Decimal score { get; set; }
        @AuraEnabled
        public String remarks { get; set; }
        public QuestionAnswer() {}
        public QuestionAnswer(String question) {
            this.question = question;
        }
    }
}