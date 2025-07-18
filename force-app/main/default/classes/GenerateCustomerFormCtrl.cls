public class GenerateCustomerFormCtrl {
 @AuraEnabled
     public Static String GenerateCustomerFormPDFHP(String recordId){
         try{
            Case invRec = [SELECT Id,Is_Attachment__c	 FROM Case WHERE Id =:recordId];
             List<Attachment> attachList = new List<Attachment>();
             PageReference pdfPage = Page.CustomerFeedbackForm;
             pdfPage.getParameters().put('id',recordId);
             blob pdfBody;
             pdfBody = Test.isRunningTest() ? Blob.valueOf('For Test Class') : pdfPage.getContent();
             Attachment attach = new Attachment(); 
             attach.Body = pdfBody;
             String var = System.now().format();
             attach.Name = 'Customer Feedback Form.Pdf';
             attach.IsPrivate = false; 
             attach.ParentId = recordId;
             attach.ContentType = 'application/pdf';
             attachList.add(attach);
             if(!attachList.isEmpty()){
                 //insert attachList;
                 if(!attachList.IsEmpty()){
                     invRec.Is_Attachment__c = true;
                     update invRec;
                 }
             }
             return attachList[0].Id;
         }catch(Exception e){
             System.debug('Error :: '+e.getMessage() + ' AND Line :: '+e.getLineNumber());
         }
         return null;
     }
}