public class PostServiceFeedbackHandler {

    public static void handleStatusCompleted(List<Post_Service_Feedback__c> newList, Map<Id, Post_Service_Feedback__c> oldMap) {
        List<Id> completedPSFIds = new List<Id>();

        for (Post_Service_Feedback__c psf : newList) {
            Post_Service_Feedback__c oldPsf = oldMap.get(psf.Id);
           if (psf.Status__c == 'Completed' && oldPsf.Status__c != 'Completed') {
                completedPSFIds.add(psf.Id);
            }
        }

        if (!completedPSFIds.isEmpty()) {
            updateAverageRatings(completedPSFIds);
        }
    }

    private static void updateAverageRatings(List<Id> psfIds) {
        // Map to hold PSF Id to list of Ratings
        Map<Id, List<Decimal>> psfRatingsMap = new Map<Id, List<Decimal>>();

        // Query related Questionnair__c records
        List<Questionnaire__c> questions = [
            SELECT Id, Rating_Number__c, Post_Service_Feedback__c
            FROM Questionnaire__c
            WHERE Post_Service_Feedback__c IN :psfIds
              AND Rating_Number__c != null
        ];
        System.debug('------------------------ ' + questions.size() + '-----------------------------');

        for (Questionnaire__c q : questions) {
            Id psfId = q.Post_Service_Feedback__c;
            if (!psfRatingsMap.containsKey(psfId)) {
                psfRatingsMap.put(psfId, new List<Decimal>());
            }
            psfRatingsMap.get(psfId).add(q.Rating_Number__c);
        }

        List<Post_Service_Feedback__c> updates = new List<Post_Service_Feedback__c>();

        for (Id psfId : psfRatingsMap.keySet()) {
            List<Decimal> ratings = psfRatingsMap.get(psfId);
            Decimal sum = 0;
            for (Decimal rating : ratings) {
                sum += rating;
            }
            Decimal average = (ratings.size() > 0) ? (sum / ratings.size()).setScale(2) : null;

            updates.add(new Post_Service_Feedback__c(
                Id = psfId,
                Average_Rating__c = average
            ));
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}