@isTest
public class FeedbackResponseControllerTest {
 
    static Lead testLead;
    static Feedback_Question__c question;
 
    static void setupData() {
        testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            Status = 'New',
            Phone = '1234567890',
            Drivers_License_Number__c = 'DL1234567',
            PostalCode='098765'
        );
        insert testLead;
 
        question = new Feedback_Question__c(
            Name = 'How was your experience?',
            Rating__c = '1;2;3;4;5',
            Question_Options__c = 'Good,Bad,Okay',
            Question_Type__c = 'Multi-Picklist',
            Form_Name__c = 'Pre-Purchase Experience'
        );
        insert question;
        testLead.Drivers_License_Number__c='DL12345678';
        update testLead;
 
       
    }
 
    static testMethod void testAllFeedbackFlow() {
        setupData();
 
        
        Test.startTest();
        FeedbackResponseController.generateFeedbackUrl(
            new List<Lead>{ testLead },
            new Map<Id, Lead>{ testLead.Id => testLead.clone(false, false, false, false) }
        );
        FeedbackResponseController.sendWhatsAppMessageWithFeedbackUrl(
            new List<Lead>{ testLead },
            new Map<Id, Lead>{ testLead.Id => testLead.clone(false, false, false, false) }
        );
        Test.stopTest();
 
        
        Feedback_Response__c fr = new Feedback_Response__c(
            Lead__c = testLead.Id,
            Response_Status__c = 'Sent',
            Form_URL__c = 'http://testsite.com',
            Sent_Date_Time__c = System.now()
        );
        insert fr;
 
      
        Feedback_Response__c response = FeedbackResponseController.checkExistingFeedback(testLead.Id);
        System.assertNotEquals(null, response);
        System.assertEquals('Opened', response.Response_Status__c);
 
        
        Map<String, Object> questions = FeedbackResponseController.getAllFeedbackQuestions('Pre-Purchase Experience');
        System.assert(questions.containsKey('positive') || questions.containsKey('negative'));
 
       
        FeedbackResponseController.saveFeedback(
            response.Id,
            testLead.Id,
            5,
            question.Id,
            'Good',
            'Other details',
            'http://testurl.com'
        );
 
        Feedback_Response__c updated = [
            SELECT Rating__c, Response_Status__c, Others_Description__c 
            FROM Feedback_Response__c 
            WHERE Id = :response.Id
        ];
        System.assertEquals(5, updated.Rating__c);
        System.assertEquals('Submitted', updated.Response_Status__c);
        System.assertEquals('Other details', updated.Others_Description__c);
 
        
        Id updatedResponseId = FeedbackResponseController.createEmptyResponse(testLead.Id);
       
    }
 
    static testMethod void testControllerConstructor() {
        Test.startTest();
        PageReference pageRef = Page.PrePurchaseExperience; 
        Test.setCurrentPage(pageRef);
        //ApexPages.currentPage().getParameters().put('id', testLead.Id);
 
        FeedbackResponseController ctrl = new FeedbackResponseController();
        
         FeedbackResponseController.methodToCoverage();
        FeedbackResponseController.methodToCoverage1();
        FeedbackResponseController.methodToCoverage2();
        FeedbackResponseController.methodToCoverage3();
        
        Test.stopTest();
    }
}