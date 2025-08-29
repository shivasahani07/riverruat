public with sharing class dailyStoreOperations {

    @AuraEnabled(cacheable=false)
    public static void submitDailyStoreOperations(String formData) {
        Map<String, Object> formDataMap = (Map<String, Object>) JSON.deserializeUntyped(formData);
        Daily_Store_Operations__c dso = new Daily_Store_Operations__c();

        System.debug('formDataMap==>'+formDataMap);
        for (String fieldName : formDataMap.keySet()) {
            Object fieldValue = formDataMap.get(fieldName);
            
            if(fieldName == 'openTime'){
                dso.Store_Open_Time__c =  parseISO8601((String) fieldValue);
            } else if(fieldName == 'closeTime' ){
                dso.Store_Close_Time__c = parseISO8601((String) fieldValue);
            } else if(fieldName == 'issuesNoted' ){
                dso.Any_Issues_Noted__c = (String) fieldValue;
            } else if(fieldName == 'comments' ){
                dso.Comments__c = (String) fieldValue;
            } else if(fieldName == 'stockLevel' ){
                dso.Stock_Level__c = (String) fieldValue;
            } else if(fieldName == 'shortage' ){
                dso.Any_Shortages__c = (String) fieldValue;
            } else if(fieldName == 'inventoryAdjustments' ){
                dso.Inventory_Adjustments__c = (String) fieldValue;
            } else if(fieldName == 'inventoryComments' ){
                dso.Inventory_Comments__c = (String) fieldValue;
            } else if(fieldName == 'totalSales' ){
                dso.Total_Sales__c = Decimal.valueOf((String) fieldValue);
            } else if(fieldName == 'cashDeposited' ){
                dso.Cash_Deposited__c = Decimal.valueOf((String) fieldValue);
            } else if(fieldName == 'discrepancies' ){
                dso.Any__c = (String) fieldValue;
            } else if(fieldName == 'salesCashComments' ){
                dso.Sales_Cash_Comments__c = (String) fieldValue;
            } else if(fieldName == 'customerComplaints' ){
                dso.Number_of_Customer_Complaints__c = Decimal.valueOf((String) fieldValue);
            } else if(fieldName == 'customerReturns' ){
                dso.Number_of_Customer_Returns__c = Decimal.valueOf((String) fieldValue);
            } else if(fieldName == 'customerSatisfaction' ){
                dso.Overall_Customer_Satisfaction__c = (String) fieldValue;
            } else if(fieldName == 'customerServiceComments' ){
                dso.Customer_Service_Comments__c = (String) fieldValue;
            } else if(fieldName == 'cleanlinessLevel' ){
                dso.Cleanliness_Level__c = (String) fieldValue;
            } else if(fieldName == 'maintenanceIssues' ){
                dso.Any_Maintenance_Issues__c = (String) fieldValue;
            } else if(fieldName == 'housekeepingComments' ){
                dso.Housekeeping_Comments__c = (String) fieldValue;
            } else if(fieldName == 'staffAttendance' ){
                dso.Staff_Attendance__c = (String) fieldValue;
            } else if(fieldName == 'staffIssues' ){
                dso.Any_Staff_Issues__c = (String) fieldValue;
            } else if(fieldName == 'employeeComments' ){
                dso.Employee_Comments__c = (String) fieldValue;
            }else if(fieldName == 'openDate' ){
                dso.Store_Open_Date__c = Date.valueOf((String) fieldValue);
            }else if(fieldName == 'closeDate' ){
                dso.Store_Close_Date__c = Date.valueOf((String) fieldValue);
            }
        }

        insert dso;
    }

    public static Time parseISO8601(String timeString) {
        List<String> timeComponents = timeString.split(':');
        Integer hours = Integer.valueOf(timeComponents[0]);
        Integer minutes = Integer.valueOf(timeComponents[1]);
        // Assuming seconds are optional, you can add logic to handle them if necessary
    
        return Time.newInstance(hours, minutes, 0, 0);
    }
    
    

    
}