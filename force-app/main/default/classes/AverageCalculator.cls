public class AverageCalculator {

    public static void calculateAverage(List<Feedback_Response_Answers__c> newList) {
        try {
            if (newList == null || newList.isEmpty()) return;

            
            Set<Id> parentIds = new Set<Id>();
            for (Feedback_Response_Answers__c fr : newList) {
                if (fr.Feedback_Response__c != null) {
                    parentIds.add(fr.Feedback_Response__c);
                }
            }
            if (parentIds.isEmpty()) return;

            
            Map<Id, List<Feedback_Response_Answers__c>> answersByParent = new Map<Id, List<Feedback_Response_Answers__c>>();

            for (Feedback_Response_Answers__c ans : [
                SELECT Id, Feedback_Response__c, Answer__c,
                       Feedback_Response__r.Response_Status__c,
                       Feedback_Response__r.Name_Of_Form__c
                FROM Feedback_Response_Answers__c
                WHERE Feedback_Response__c IN :parentIds
                AND Feedback_Response__r.Response_Status__c = 'Submitted'
                AND Feedback_Response__r.Name_Of_Form__c = 'PSF'
            ]) {
                if (!answersByParent.containsKey(ans.Feedback_Response__c)) {
                    answersByParent.put(ans.Feedback_Response__c, new List<Feedback_Response_Answers__c>());
                }
                answersByParent.get(ans.Feedback_Response__c).add(ans);
            }

            List<Feedback_Response__c> toUpdate = new List<Feedback_Response__c>();

           
            for (Id parentId : answersByParent.keySet()) { 
                List<Feedback_Response_Answers__c> childList = answersByParent.get(parentId);

                Decimal total = 0;
                Integer count = 0;

                for (Feedback_Response_Answers__c child : childList) {
                    if (child.Answer__c == null) continue;

                    Decimal val;

                    
                    if (child.Answer__c.equalsIgnoreCase('Yes')) {
                        val = 5;
                    } else if (child.Answer__c.equalsIgnoreCase('No')) {
                        val = 1;
                    } else if (child.Answer__c.isNumeric()) {
                        val = Decimal.valueOf(child.Answer__c);
                    } else {
                        continue;
                    }

                    total += val;
                    count++;
                }

                if (count > 0) {
                    Decimal avg = total.divide(count, 2); 
                    toUpdate.add(new Feedback_Response__c(
                        Id = parentId,
                        Rating__c = avg
                    ));
                }
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }

        } catch (Exception e) {
            System.debug('AverageCalculator Error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
}