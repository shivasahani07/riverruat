global class GetUsersInQueue {
    @InvocableMethod(label='Get Users from Queue' description='Returns the list of user')
    public static List<User> getUsers(List<Id> queueIds) {
        Set<Id> groupIds = new Set<Id>(queueIds);
        Set<Id> userIds = new Set<Id>();

        for (GroupMember gm : [
            SELECT UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId IN :groupIds
        ]) {
            if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
                userIds.add(gm.UserOrGroupId);
            }
        }

        return [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];
    }
}