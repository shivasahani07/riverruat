public class insuranceDetailsUpdation {
    
    @AuraEnabled
    public static Order getRecordDeatil(string recordId){
        Order orderList = new Order();
        try {
            if(recordId != null){
                orderList = [Select Id,Insurance_Type__c,Status from Order where Id =:recordId];
            }
        } catch (Exception e) {
            system.debug('error message =====>'+e.getMessage() + 'at line number =====>'+e.getLineNumber());
        }
        return orderList;
    }

    @AuraEnabled
    public static string updateDetails(Map<String,String> details,string recordId){
        try {
            if(recordId != null){
                
            }
            return 'Success';
        } catch (Exception e) {
            system.debug('error message =====>'+e.getMessage() + 'at line number =====>'+e.getLineNumber());
            return e.getMessage();
        }
    }
}