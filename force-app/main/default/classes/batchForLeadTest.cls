@isTest
public class batchForLeadTest {
	@isTest
    static void testBatchExecution() {
        Test.startTest();
        batchForLead batch = new batchForLead();
        Database.executeBatch(batch, 10);
        batchForLead.mytest();
        Test.stopTest();
    }
}