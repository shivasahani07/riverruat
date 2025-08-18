@isTest
public class AverageCalculationOnFeedbackPSFTest {
    @isTest
     static void testMethodForAverage(){
        Feedback_Response__c f = new Feedback_Response__c(Response_Status__c='Sent',Form_URL__c='https://river.com/Feedbackform/PostServiceFeedback?id=o3456');
        insert f; 
         
        Test.startTest();
        f.Answers_For_Post_7_Day_Service__c='1)Did you receive a call from the Service Team after your Indie was serviced? = No, 2)How convenient was it to schedule a service appointment for your Indie? = 2, 3)How helpful was the Service Advisor in resolving your issues? = 1, 4)Were the job card and invoice provided and explained to you? = Yes, 5)How clean was the delivered vehicle after service? = 1, 6)How effectively was your issue resolved during the service? = 1, 7)Was your Indie service completed on time? = No';
        update f; 
        f.Answers_For_Post_7_Day_Service__c='1)Did you receive a call from the Service Team after your Indie was serviced? = No, 2)How convenient was it to schedule a service appointment for your Indie? = 2, 3)How helpful was the Service Advisor in resolving your issues? = 1, 4)Were the job card and invoice provided and explained to you? = Yes, 5)How clean was the delivered vehicle after service? :i';
        f.Answer__c='Quick Service,CSAT Complexity';
        update f; 
        Test.stopTest(); 
    }

}