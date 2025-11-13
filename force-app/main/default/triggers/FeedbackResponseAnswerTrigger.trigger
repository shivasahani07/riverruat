trigger FeedbackResponseAnswerTrigger on Feedback_Response_Answers__c (before insert,after insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        AverageCalculator.calculateAverage(Trigger.new);
    }

}