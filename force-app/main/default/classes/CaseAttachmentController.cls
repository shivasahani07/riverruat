public with sharing class CaseAttachmentController {
    public class FileDTO {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public Id latestPublishedVersionId;
    }

    @AuraEnabled(cacheable=true)
    public static List<FileDTO> getCaseAttachments(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case Id is required.');
        }

        // Step 1: Get all linked document IDs
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
        ];

        if (links.isEmpty()) return new List<FileDTO>();

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }

        // Step 2: Fetch ContentDocument metadata
        List<ContentDocument> docs = [
            SELECT Id, Title, FileType, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id IN :docIds
            ORDER BY CreatedDate DESC
        ];

        List<FileDTO> result = new List<FileDTO>();
        for (ContentDocument doc : docs) {
            FileDTO dto = new FileDTO();
            dto.contentDocumentId = doc.Id;
            dto.title = doc.Title;
            dto.fileType = doc.FileType;
            dto.latestPublishedVersionId = doc.LatestPublishedVersionId;
            result.add(dto);
        }

        return result;
    }
}