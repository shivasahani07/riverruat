@isTest
public class MobileApp_WrapperTest {
    
    @isTest
    public static void testMobileApp_Wrapper(){
        User usr = UtilityTestClass.createSalesManagerUser();

        // Test MobileApp_LeadTotalLeadsWrapper
        MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper leadTotalWrapper = new MobileApp_Wrapper.MobileApp_LeadTotalLeadsWrapper();
        leadTotalWrapper.UserId = usr.Id;
        leadTotalWrapper.FilterDate = '2025-07-01';
        leadTotalWrapper.FilterEndRange = '2025-08-01';

        // Test MobileApp_ResponseLeadsWrapper
        MobileApp_Wrapper.MobileApp_ResponseLeadsWrapper responseWrapper = new MobileApp_Wrapper.MobileApp_ResponseLeadsWrapper();
        responseWrapper.StatusCode = '200';
        responseWrapper.StatusMessage = 'Success';

        // Test MobileApp_CreateLead
        MobileApp_Wrapper.MobileApp_CreateLead createLead = new MobileApp_Wrapper.MobileApp_CreateLead();
        createLead.UserId = usr.Id;
        createLead.FirstName = 'John';
        createLead.LastName = 'Doe';
        createLead.Phone = '9999999999';
        createLead.Email = 'john.doe@example.com';
        createLead.LeadSource = 'Online';
        createLead.LeadSecondarySource = 'Social Media';
        createLead.LeadSecondarySourceOthers = 'Instagram';

        // Test MobileApp_TransferEnquiry
        MobileApp_Wrapper.MobileApp_TransferEnquiry transfer = new MobileApp_Wrapper.MobileApp_TransferEnquiry();
        transfer.UserId = usr.Id;
        transfer.Phone = '8888888888';

        // Test MobileApp_CreateTestDrive
        MobileApp_Wrapper.MobileApp_CreateTestDrive testDrive = new MobileApp_Wrapper.MobileApp_CreateTestDrive();
        testDrive.UserId = usr.Id;
        testDrive.LeadId = '00QXXXXXXXXXXXX'; // dummy Id
        testDrive.TestDriveDate = '2025-08-10';
        testDrive.TestDriveTime = '15:30';
        testDrive.homeTestDrive = true;
        testDrive.HomeTestDriveAddress = '123 Test Street';
        testDrive.storeTestDrive = false;
        testDrive.pincode = '123456';

        // Test MobileApp_UpdateTestDrive
        MobileApp_Wrapper.MobileApp_UpdateTestDrive updateDrive = new MobileApp_Wrapper.MobileApp_UpdateTestDrive();
        updateDrive.UserId = usr.Id;
        updateDrive.TestDriveId = 'a0BXXXXXXXXXXXX';
        updateDrive.TestDriveStatus = 'Completed';
        updateDrive.TestDriveDate = '2025-08-11';
        updateDrive.TestDriveTime = '16:00';
        updateDrive.StartTestDrive = true;
        updateDrive.CompleteTestDrive = true;

        // Test MobileApp_UpdateLead
        MobileApp_Wrapper.MobileApp_UpdateLead updateLead = new MobileApp_Wrapper.MobileApp_UpdateLead();
        updateLead.UserId = usr.Id;
        updateLead.LeadId = '00QYYYYYYYYYYYY';
        updateLead.LeadStatus = 'Interested';

        // Test MobileApp_DropLead
        MobileApp_Wrapper.MobileApp_DropLead dropLead = new MobileApp_Wrapper.MobileApp_DropLead();
        dropLead.UserId = usr.Id;
        dropLead.LeadId = '00QZZZZZZZZZZZZZ';
        dropLead.DropOutReason = 'Not Interested';
        dropLead.DropOutSubReason = 'Price too high';
        dropLead.Others = 'Competitor offer';

        // Test MobileApp_CreateFollowUp
        MobileApp_Wrapper.MobileApp_CreateFollowUp createFollowUp = new MobileApp_Wrapper.MobileApp_CreateFollowUp();
        createFollowUp.UserId = usr.Id;
        createFollowUp.LeadId = '00QLEADFOLLOWUP';
        createFollowUp.FollowUpDate = '2025-08-05';
        createFollowUp.FollowUpTime = '10:30';
        createFollowUp.FollowUpFeedback = 'Positive';
        createFollowUp.followUpType = 'Call';

        // Test MobileApp_UpdateFollowUp
        MobileApp_Wrapper.MobileApp_UpdateFollowUp updateFollowUp = new MobileApp_Wrapper.MobileApp_UpdateFollowUp();
        updateFollowUp.UserId = usr.Id;
        updateFollowUp.FollowUpId = 'a1ZXXXXXXXXXXXX';
        updateFollowUp.FollowUpStatusCompleted = true;
        updateFollowUp.followUprating = '5';

        // Test MobileApp_CreateTicket
        MobileApp_Wrapper.MobileApp_CreateTicket ticket = new MobileApp_Wrapper.MobileApp_CreateTicket();
        ticket.UserId = usr.Id;
        ticket.description = 'Issue description';
        ticket.SS1 = EncodingUtil.base64Encode(Blob.valueOf('sample image data'));
        ticket.SS2 = EncodingUtil.base64Encode(Blob.valueOf('sample image data1'));
        ticket.SS3 = EncodingUtil.base64Encode(Blob.valueOf('sample image data2'));
        ticket.SS4 = EncodingUtil.base64Encode(Blob.valueOf('sample image data3'));
        ticket.SS5 = EncodingUtil.base64Encode(Blob.valueOf('sample image data4'));

        // Test MobileApp_BookOrder
        MobileApp_Wrapper.MobileApp_BookOrder bookOrder = new MobileApp_Wrapper.MobileApp_BookOrder();
        bookOrder.userId = usr.Id;
        bookOrder.opportunityId = '006XXXXXXXXXXXX';
        bookOrder.paymentStatus = 'Success';
        bookOrder.transactionId = 'TRX123456';
        bookOrder.paymentMode = 'Credit Card';
        bookOrder.paymentGateway = 'Razorpay';
        bookOrder.orderAmount = 25000.00;
        bookOrder.vehicleColor = 'Red';
        bookOrder.timestamp = System.now();
        bookOrder.gatewayResponseMessage = 'Transaction Successful';
        
        MobileApp_Wrapper.CustomerDetails customer = new MobileApp_Wrapper.CustomerDetails();
        customer.name = 'John Customer';
        customer.email = 'customer@example.com';
        customer.phone = '7777777777';
        bookOrder.customerDetails = customer;
        bookOrder.signature = 'abc123signature';

        // Test MobileApp_Comments
        MobileApp_Wrapper.MobileApp_Comments comment = new MobileApp_Wrapper.MobileApp_Comments();
        comment.userId = usr.Id;
        comment.OrderId = '801XXXXXXXXXXXX';
        comment.Comments = 'Order placed and processed';

        // Simulate response context (not executed in actual test but covers methods)
        RestContext.response = new RestResponse();
        MobileApp_Wrapper.setResponse(200, 'Success', new Map<String, Object>{ 'key' => 'value' });
        
        RestContext.response = new RestResponse();
        List<Map<String, Object>> dataList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'dataKey' => 'dataValue' }
        };
        MobileApp_Wrapper.setResponses(200, 'Success', dataList);

    }
}