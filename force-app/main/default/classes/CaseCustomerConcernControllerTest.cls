@IsTest
public class CaseCustomerConcernControllerTest {
    @IsTest
    public static void createCaseCustomerConcern(){
        Case casrec = new Case();
        casrec.SuppliedName= 'Test';
        casrec.Department__c  = 'Service';
        casrec.Origin = 'Email';
        casrec.Status = 'Open';
        insert casrec;
        
        List<Customer_Concern__c> cunsernList = new list<Customer_Concern__c>();
        Customer_Concern__c custConRec = new Customer_Concern__c();
        custConRec.Case__c = casrec.id;
        custConRec.Case_Category__c  = 'Parts';
        custConRec.VOC__c = 'test';
         cunsernList.add(custConRec);
        
        
        Customer_Concern__c custConRec1 = new Customer_Concern__c();
        custConRec1.Case__c = casrec.id;
        custConRec1.Case_Category__c  = 'Parts';
        custConRec1.VOC__c = 'test';
         cunsernList.add(custConRec1);
        
        insert cunsernList;
        
        Test.StartTest();
        CaseCustomerConcernController.getConcernsByCaseId(casrec.Id);
        CaseCustomerConcernController.updateConcerns(cunsernList);   
        CaseCustomerConcernController.getUserProfileName();
        CaseFileUploadController.updateCaseAttachmentFlag(casrec.Id);
        CaseAttachmentController.getCaseAttachments(casrec.Id);
        Test.StopTest();
    }
}