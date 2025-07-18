/**
* @File Name : UserTrackingcontroller.cls
* @Description :
* @Author : Anwar Chikle
* @Last Modified By :
* @Last Modified On : March 12, 2025
* @Modification Log : 
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 12, 2025 |   | Initial Version
**/

public class UserTrackingcontroller {
    
    @AuraEnabled
    public static UserTrack OnpageLoad(string userId){
        UserTrack usr = new UserTrack();
        try{
            String LoggedInUser = UserInfo.getUserId();
            
            
            System.debug('LoggedInUser =====> ' + LoggedInUser);
            list<User_Tracking__c> userTracking = [select id, Checkin_Datetime__c, Checkout_Datetime__c, Member__c
                                                   from User_Tracking__c
                                                   where Member__c = :userId and CreatedDate = TODAY
                                                   limit 1];
            
            
            if (!userTracking.isEmpty()){
                usr.checkin = true;
                if (userTracking[0].Checkout_Datetime__c != null){
                    System.debug('checkout ===> ');
                    usr.checkout = true;
                } else{
                    System.debug('checkout in this ===> ');
                    usr.checkout = false;
                }
            } else{
                usr.checkin = false;
                usr.checkout = true;
            }
        } catch (Exception e){
            System.debug('stack trace ======> ' + e.getStackTraceString());
        }
        return usr;
    }
    
    @AuraEnabled
    public static UserTrackWrapperAfterCheckin UserCheckin(string userId){
      
        UserTrackWrapperAfterCheckin UserTrackWrap = new UserTrackWrapperAfterCheckin();
        String eventStatus = 'Something went wrong';
        string groupName = '';
        DateTime dt = DateTime.now();
        String dayOfWeek = dt.format('EEEE');
      
        if (System.now().time() < Time.newInstance(08, 59, 00, 00)){
            eventStatus = 'You can not checkin before 9:00 AM.';
        }
        
        map<string, string> mapofGroupNameBySourceIntent = new map<string, string>();
        if (userId != null){
            list<User_Tracking__c> userTracking = new list<User_Tracking__c>();
            list<Assignment_Group_Member__c> agmList = new list<Assignment_Group_Member__c>();
            userTracking = [select id, Checkin_Datetime__c, Checkout_Datetime__c, Member__c
                            from User_Tracking__c
                            where Member__c = :userId and CreatedDate = TODAY
                            limit 1];
            system.debug('userTracking::'+userTracking);
            agmList = [select id, Group_Member__c, Assignment_Group__r.name,Out_Of_Office__c
                       from Assignment_Group_Member__c
                       where Group_Member__c = :userId];
            system.debug('agmList::'+agmList);
            
            
            if (userTracking.isEmpty()){
                User_Tracking__c userTrackRec = new User_Tracking__c();
                userTrackRec.Member__c = userId;
                userTrackRec.Checkin_Datetime__c = DateTime.now();
                insert userTrackRec;
                if (!agmList.isEmpty()){
                    for (Assignment_Group_Member__c agm : agmList){
                        agm.Out_Of_Office__c = false;
                        
                    }
                    update agmList;
                    if(userTrackRec.Checkin_Datetime__c != null){
                        SobjectLoadAssignment.ExecuteLoadAssignment(10);
                    }
                }
                eventStatus = 'Checkin successful';
            } else{
                eventStatus = 'Your checkin was already created.';
            }
            
        } else{
            eventStatus = 'User is not registered in system.Please contact to your admin.';
        }
        UserTrackWrap.eventStatus = eventStatus;
        return UserTrackWrap;
    }
    
    @AuraEnabled
    public static String UserCheckout(string userId){
        String eventStatus = 'Something went wrong';
        
        
        if (userId != null){
            list<User_Tracking__c> userTracking = new list<User_Tracking__c>();
            list<Assignment_Group_Member__c> agmList = new list<Assignment_Group_Member__c>();
            
            
            userTracking = [select id, Checkin_Datetime__c, Checkout_Datetime__c, Member__c
                            from User_Tracking__c
                            where Member__c = :userId and createddate = TODAY
                            limit 1];
            agmList = [select id, Group_Member__c
                       from Assignment_Group_Member__c
                       where Group_Member__c = :userId];
            if (!userTracking.isEmpty()){
                for (User_Tracking__c ut : userTracking){
                    ut.Checkout_Datetime__c = DateTime.now();
                }
                update userTracking;
               
                if (!agmList.isEmpty()){
                    for (Assignment_Group_Member__c agm : agmList){
                        agm.Out_Of_Office__c = true;
                    }
                    
                    update agmList;
                }
                
                eventStatus = 'Checkout datetime has been updated.';
            } else{
                eventStatus = 'You can not checkout without checkin.';
            }
            
        } else{
            eventStatus = 'User is not registered in system.Please contact to your admin.';
        }
        
        
        return eventStatus;
    }
      
    public class UserTrack{
        @AuraEnabled
        public boolean checkin;
        @AuraEnabled
        public boolean checkout;
    }
    
    public class UserTrackWrapperAfterCheckin{
        @AuraEnabled
        public String eventStatus; 
    }
    
    @AuraEnabled
    public static UsersTrackWrapper getAllUserTrack(Date oldDate) {
        try {
            UsersTrackWrapper userTrackWrap = new UsersTrackWrapper();
            userTrackWrap.allUsers = new List<User>();
            userTrackWrap.allUserscheckedIn = new List<UserTrackingInfo>();
            userTrackWrap.allUserscheckedOut = new List<UserTrackingInfo>();

            List<Assignment_Group__c> assignmentGroupList = [
                SELECT Id, Name, (SELECT Id, Name, Group_Member__c FROM Assignment_Group_Members__r)
                FROM Assignment_Group__c 
                WHERE Name = 'Lead HQ Assignment'
            ];

            Set<Id> userIdSet = new Set<Id>();
            for (Assignment_Group__c groupRec : assignmentGroupList) {
                for (Assignment_Group_Member__c groupMember : groupRec.Assignment_Group_Members__r) {
                    if (groupMember.Group_Member__c != null) {
                        userIdSet.add(groupMember.Group_Member__c);
                    }
                }
            }

            if (!userIdSet.isEmpty()) {
                userTrackWrap.allUsers = [SELECT Id, Name, Email, MobilePhone FROM User WHERE Id IN :userIdSet];
            }

            Datetime startDate, endDate;
            if (oldDate != null) {
                startDate = Datetime.newInstance(oldDate.year(), oldDate.month(), oldDate.day());
            } else {
                startDate = System.today();
            }
            endDate = startDate.addDays(1).addSeconds(-1);

            List<User_Tracking__c> userTracking = [
                SELECT Id, Checkin_Datetime__c, Checkout_Datetime__c, Member__c, 
                    Member__r.Name, Member__r.Email, Member__r.MobilePhone 
                FROM User_Tracking__c
                WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate 
                AND Member__c IN :userIdSet
            ];

            Map<Id, Integer> userLeadCountMap = new Map<Id, Integer>();
            if (!userIdSet.isEmpty()) {
                Date assignedDate = oldDate != null ? oldDate : Date.today();
                AggregateResult[] leadCounts = [
                    SELECT OwnerId, COUNT(Id) leadCount
                    FROM Lead
                    WHERE Is_Assigned_to_User__c = true
                    AND Assigned_Date__c = :assignedDate
                    AND OwnerId IN :userIdSet
                    GROUP BY OwnerId
                ];

                for (AggregateResult ar : leadCounts) {
                    userLeadCountMap.put((Id) ar.get('OwnerId'), (Integer) ar.get('leadCount'));
                }
            }

            Set<Id> checkedInUserIds = new Set<Id>();
            Set<Id> checkedOutUserIds = new Set<Id>();

            for (User_Tracking__c track : userTracking) {
                UserTrackingInfo checkInInfo = new UserTrackingInfo();
                checkInInfo.memberId = track.Member__c;
                checkInInfo.memberName = track.Member__r.Name;
                checkInInfo.email = track.Member__r.Email;
                checkInInfo.phone = track.Member__r.MobilePhone;

                if (track.Checkin_Datetime__c != null) {
                    checkInInfo.checkinTime = track.Checkin_Datetime__c.format('dd-MM-yyyy HH:mm');
                    checkInInfo.NoOfLeadRecordsAssignedToThatUser = userLeadCountMap.containsKey(track.Member__c) 
                        ? userLeadCountMap.get(track.Member__c) : 0;
                    userTrackWrap.allUserscheckedIn.add(checkInInfo);
                    checkedInUserIds.add(track.Member__c);
                }
                
                if (track.Checkout_Datetime__c != null) {
                    UserTrackingInfo checkOutInfo = new UserTrackingInfo();
                    checkOutInfo.memberId = track.Member__c;
                    checkOutInfo.memberName = track.Member__r.Name;
                    checkOutInfo.email = track.Member__r.Email;
                    checkOutInfo.phone = track.Member__r.MobilePhone;
                    checkOutInfo.checkinTime = track.Checkin_Datetime__c.format('dd-MM-yyyy HH:mm');
                    checkOutInfo.checkoutTime = track.Checkout_Datetime__c.format('dd-MM-yyyy HH:mm');
                    checkOutInfo.NoOfLeadRecordsAssignedToThatUser = userLeadCountMap.containsKey(track.Member__c) 
                        ? userLeadCountMap.get(track.Member__c) : 0;
                    userTrackWrap.allUserscheckedOut.add(checkOutInfo);
                    checkedOutUserIds.add(track.Member__c);
                }
                
            }

            List<User> remainingUsers = new List<User>();
            for (User user : userTrackWrap.allUsers) {
                if (!checkedInUserIds.contains(user.Id)) {
                    remainingUsers.add(user);
                }
            }
            userTrackWrap.allUsers = remainingUsers;

            List<UserTrackingInfo> remainingCheckedIn = new List<UserTrackingInfo>();
            for (UserTrackingInfo info : userTrackWrap.allUserscheckedIn) {
                if (!checkedOutUserIds.contains(info.memberId)) {
                    remainingCheckedIn.add(info);
                }
            }
            userTrackWrap.allUserscheckedIn = remainingCheckedIn;

            List<User> finalRemainingUsers = new List<User>();
            for (User user : userTrackWrap.allUsers) {
                if (!checkedOutUserIds.contains(user.Id)) {
                    finalRemainingUsers.add(user);
                }
            }
            userTrackWrap.allUsers = finalRemainingUsers;

            return userTrackWrap;
        } catch (Exception e) {
            System.debug('Error Message: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static String userRecordToUpdate(string userId, String actionType) {
        try {
            
            List<User_Tracking__c> userTracking = [
                SELECT Id, Checkin_Datetime__c, Checkout_Datetime__c, Member__c, 
                    Member__r.Name, Member__r.Email, Member__r.Phone 
                FROM User_Tracking__c
                WHERE Member__c =: userId AND CreatedDate = TODAY
            ];

            if(!userTracking.isEmpty()){
                for(User_Tracking__c userTrackRec : userTracking){
                    if(actionType == 'checkout'){
                        userTrackRec.Checkout_Datetime__c = DateTime.now();
                    } else if(actionType == 'removecheckout'){
                        userTrackRec.Checkout_Datetime__c = null;
                    }
                }
                update userTracking;
                return 'User record updated successfully';
            }else{
                return 'No user record found for the given userId';
            }

        } catch (Exception e) {
            System.debug('Error Message: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
            return null;
        }
    }

    public class UsersTrackWrapper {
        @AuraEnabled public List<User> allUsers;
        @AuraEnabled public List<UserTrackingInfo> allUserscheckedIn;
        @AuraEnabled public List<UserTrackingInfo> allUserscheckedOut;
    }

    public class UserTrackingInfo {
        @AuraEnabled public Id memberId;
        @AuraEnabled public String memberName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String checkinTime;
        @AuraEnabled public String checkoutTime;
        @AuraEnabled public Integer NoOfLeadRecordsAssignedToThatUser;
    }

    
}