@isTest
public class SendEmailHandllerTest {
    
    @isTest
    Public static void SendEmailHandllerTest(){
        Map<string,Object> newMap = TestDataFactory.CreateOrder();
        Order o = (Order)newMap.get('OrderId');        
        List<attachment> attachmentsToInsert = new List<attachment>();
        Attachment att1 = new Attachment();
        att1.Name = 'Pre Order Receipt' + o.Id + '.pdf';
        att1.Body = Blob.valueOf('test data');
        att1.ParentId = o.Id;
        att1.ContentType = 'application/pdf';
        
        attachmentsToInsert.add(att1);
        
        Order_Payment__c op = (Order_Payment__c)newMap.get('OrderPaymentId'); 
        Map<Id, List<Attachment>> mapOrderIdToAttachments = new Map<Id, List<Attachment>>();
        mapOrderIdToAttachments.put(o.Id,attachmentsToInsert);
        
         Website_Creds__c mockIntegrations = new Website_Creds__c(
                Name = 'Website Creds',
                BaseURL__c = 'https://river-crm-apis.dev.rideriver.com',
                ClientId__c = '7f2a1bk826eb5179ec8e357340408fd444ab3ssbb1d5fb40a06f6eac590f6b8d51bea40886bf80cd388813f296effa4269550ce98d4e4e5c7e582da19e9faff0',
                ClientSecret__c = 'a7ebb3r90eaa4eac1a356c351a0f7c5fdesa87c87010298fa84bc728d6db305638b68b6bce984110e8d70fd2e39eab0dbcdd2b5264570ae77e320acb6937afe32'
            );
            insert mockIntegrations;
        
        Test.starttest();
        SendEmailHandller.SendEmailHandller(new List<Order>{o}, mapOrderIdToAttachments);
        SendEmailHandller.SendEmailHandller2(new List<Order>{o},attachmentsToInsert);
        SendEmailHandller.sendPreAttchamnets(op.Id,attachmentsToInsert);
        test.stoptest();        
    }
    
}