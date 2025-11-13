@IsTest
public class AverageCalculatorTest {
        @isTest
     static void testMethodForAverage(){
        Feedback_Response__c f = new Feedback_Response__c(Response_Status__c='Submitted',Form_URL__c='https://river.com/Feedbackform/PostServiceFeedback?id=o3456',Name_Of_Form__c='PSF');
        insert f; 
         
        Feedback_Response_Answers__c ans = new Feedback_Response_Answers__c(Answer__c='5',Feedback_Response__c=f.Id);   
        Test.startTest();
        insert ans;        
        Test.stopTest(); 
    }

}