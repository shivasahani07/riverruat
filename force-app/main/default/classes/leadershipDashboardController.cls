public class leadershipDashboardController {
    
    @AuraEnabled(cacheable=true)
    public static List<Employee__c> getEmployeeDetails(){
        List<Employee__c> employeeList = [select id,Employee_name__c,Points__c,Badges__c from Employee__c order by points__c desc];
        return employeeList;
    }
    
    @AuraEnabled(cacheable= true)
    public static Employee__c getCurrentUserDetails(){
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Id, Name FROM User WHERE Id = :currentUserId limit 1];
        String currentUserName = currentUser.Name;
        system.debug(currentUser);
        Employee__c empRec = [select id,Employee_name__c,Points__c,Badges__c from Employee__c where Employee_name__c =: currentUserName];
        system.debug(empRec);
        return empRec;
    }
}