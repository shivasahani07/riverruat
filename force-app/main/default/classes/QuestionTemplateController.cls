public class QuestionTemplateController {

    @AuraEnabled
    public static void saveTemplates(List<QuestionTemplateWrapper> templates) {
        
        List<Question_Template__c> questionTemplatesToInsert = new List<Question_Template__c>();
        List<Question_Line_Item__c> questionLineItemsToInsert = new List<Question_Line_Item__c>();

        for (QuestionTemplateWrapper template : templates) {
            Question_Template__c qTemplate = new Question_Template__c();
            qTemplate.Name = template.name;
            questionTemplatesToInsert.add(qTemplate);
            
            for (QuestionWrapper question : template.questions) {
                Question_Line_Item__c qLineItem = new Question_Line_Item__c();
                qLineItem.Question_Template__c = qTemplate.Id; // Link to the parent question template
               qLineItem.Question__c = question.text;
                questionLineItemsToInsert.add(qLineItem);
            }
        }
        
        if (!questionTemplatesToInsert.isEmpty()) {
            insert questionTemplatesToInsert;
        }
        
        if (!questionLineItemsToInsert.isEmpty()) {
            insert questionLineItemsToInsert;
        }
    }

    public class QuestionTemplateWrapper {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public List<QuestionWrapper> questions { get; set; }
    }

    public class QuestionWrapper {
        @AuraEnabled public String text { get; set; }
    }



}