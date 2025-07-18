@isTest
public class CaseAttachmentControllerTest {

    @isTest
    static void testGetCaseAttachments_WithAttachments() {
        // Step 1: Create test Case
        Case testCase = new Case(Subject = 'Test Case', Status = 'New');
        insert testCase;

        // Step 2: Create test ContentVersion (this creates ContentDocument automatically)
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Dummy content')
        );
        insert cv;

        // Step 3: Query ContentDocumentId from ContentVersion
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Id contentDocId = insertedVersion.ContentDocumentId;

        // Step 4: Create ContentDocumentLink
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = testCase.Id,
            ShareType = 'V', // View access
            Visibility = 'AllUsers'
        );
        insert link;

        // Step 5: Call the method
        Test.startTest();
        List<CaseAttachmentController.FileDTO> attachments = CaseAttachmentController.getCaseAttachments(testCase.Id);
        Test.stopTest();

        // Step 6: Assert results
        System.assertNotEquals(0, attachments.size(), 'There should be at least one attachment.');
        CaseAttachmentController.FileDTO file = attachments[0];
        System.assertEquals('TestFile', file.title);
        System.assertEquals(contentDocId, file.contentDocumentId);
        System.assertNotEquals(null, file.latestPublishedVersionId);
    }

    @isTest
    static void testGetCaseAttachments_NoAttachments() {
        // Create a Case with no attachments
        Case noAttachmentCase = new Case(Subject = 'No Files Case', Status = 'New');
        insert noAttachmentCase;

        // Call method
        Test.startTest();
        List<CaseAttachmentController.FileDTO> attachments = CaseAttachmentController.getCaseAttachments(noAttachmentCase.Id);
        Test.stopTest();

        // Assert empty list
        System.assertEquals(0, attachments.size(), 'No attachments should be returned.');
    }

    @isTest
    static void testGetCaseAttachments_NullCaseId() {
        // Call method with null ID to test exception
        Test.startTest();
        try {
            CaseAttachmentController.getCaseAttachments(null);
            System.assert(false, 'Expected exception for null caseId');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Case Id is required.'));
        }
        Test.stopTest();
    }
}