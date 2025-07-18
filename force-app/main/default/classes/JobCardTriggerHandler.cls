public class JobCardTriggerHandler {
	@future
    public static void generateFeedbackLinks(List<Id> workOrderIds) {
        try {
            List<WorkOrder> toUpdate = new List<WorkOrder>();

            // Update your community or site domain below
            String baseUrl = 'https://rivermobilityprivatelimited2--rruat.sandbox.my.site.com';

            List<WorkOrder> workOrders = [
                SELECT Id, Status, Feedback_Form_URL__c
                FROM WorkOrder
                WHERE Id IN :workOrderIds
            ];

            for (WorkOrder wo : workOrders) {
                if (wo.Status == 'Completed' && String.isBlank(wo.Feedback_Form_URL__c)) {
                    String feedbackUrl = baseUrl + '/apex/ServiceFeedback?id=' + wo.Id;
                    DateTime expiry = System.now().addDays(2);

                    toUpdate.add(new WorkOrder(
                        Id = wo.Id,
                        Feedback_Form_URL__c = feedbackUrl,
                        Feedback_Link_Expiry__c = expiry
                    ));
                }
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }

        } catch (Exception e) {
            System.debug('Error generating feedback form links: ' + e.getMessage());
        }
    }
}