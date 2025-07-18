public with sharing class DiscrepancyLineItemListController {

    public List<Discrepancy_Line_Item__c> discrepancyRecords { get; set; }
    public ApexPages.StandardSetController ssc;

    public DiscrepancyLineItemListController(ApexPages.StandardSetController stdCtrl) {
        this.ssc = stdCtrl;
        System.debug('stdCtrl '+stdCtrl);
        List<SObject> selectedRecords = stdCtrl.getSelected();
        List<Id> selectedRecordIds = new List<Id>();
        for (SObject sobj : selectedRecords) {
            selectedRecordIds.add(sobj.Id);
        }
      /*  Id listViewId = ApexPages.currentPage().getParameters().get('ListView');
        if (String.isNotBlank(listViewId)) {
            ssc.setFilterId(listViewId); // Apply List View filte
        }

        ssc.setPageSize(1000);
        List<Id> recordIds = new List<Id>();
        for (SObject sobj : ssc.getRecords()) {
            recordIds.add(sobj.Id);
        }
        System.debug('recordIds '+recordIds); */
         discrepancyRecords = [
            SELECT Id, Discrepancy__c, Discrepancy__r.Shipment__r.Order__r.Contact__c,Spare_Approval__c,Discrepancy__r.Name
            FROM Discrepancy_Line_Item__c
            WHERE Id IN :selectedRecordIds AND Spare_Approval__c = 'Re-Sumbit'
        ];
    }

    public PageReference sendNotifications() {
        try {
            // Step 1: Get unique Discrepancy → Contact mappings
            Map<Id, Id> discrepancyToContactIdMap = new Map<Id, Id>();
            Map<Id, String> discrepancyIdToNameMap = new Map<Id, String>();
            System.debug('discrepancyRecords '+discrepancyRecords);
          /*  List<Discrepancy_Line_Item__c> discrepancyLineItemRecords = [
            SELECT Id, Discrepancy__c, Discrepancy__r.Shipment__r.Order__r.Contact__c
            FROM Discrepancy_Line_Item__c
            WHERE Id IN :discrepancyRecords
            ]; */
            for (Discrepancy_Line_Item__c item : discrepancyRecords) {
                Id discrepancyId = item.Discrepancy__c;
                Id contactId = item.Discrepancy__r?.Shipment__r?.Order__r?.Contact__c; // Ensure field path is correct

                if (discrepancyId != null && contactId != null) {
                    discrepancyToContactIdMap.put(discrepancyId, contactId);
                    discrepancyIdToNameMap.put(discrepancyId, item.Discrepancy__r.Name);
                }
            }

            // Step 2: Get users linked to contacts
            Map<Id, User> contactToUserMap = new Map<Id, User>();
            for (User u : [
                SELECT Id, ContactId FROM User
                WHERE ContactId IN :discrepancyToContactIdMap.values()
                AND IsActive = true
            ]) {
                contactToUserMap.put(u.ContactId, u);
            }

            // Step 3: Map DiscrepancyId → UserId
            Map<Id, Id> discrepancyToUserIdMap = new Map<Id, Id>();
            for (Id discrepancyId : discrepancyToContactIdMap.keySet()) {
                Id contactId = discrepancyToContactIdMap.get(discrepancyId);
                if (contactToUserMap.containsKey(contactId)) {
                    discrepancyToUserIdMap.put(discrepancyId, contactToUserMap.get(contactId).Id);
                }
            }

            // Step 4: Send notifications
            CustomNotificationType cnType = [
                SELECT Id FROM CustomNotificationType 
                WHERE DeveloperName = 'Notification_To_Warehouse_User' 
                LIMIT 1
            ];

            Integer successCount = 0;
            Integer failCount = 0;
            
            for (Id discrepancyId : discrepancyToUserIdMap.keySet()) {
                Id userId = discrepancyToUserIdMap.get(discrepancyId);
                
                try {
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Re-submit Required');
                    String discrepancyName = discrepancyIdToNameMap.get(discrepancyId);
                    notification.setBody('Discrepancy "' + discrepancyName + '" requires re-submission.');
                    //notification.setBody('You have a Discrepancy Item requiring re-submission.');
                    notification.setNotificationTypeId(cnType.Id);
                    notification.setSenderId(UserInfo.getUserId());
                    notification.setTargetId(discrepancyId); // Target is the Discrepancy record
                    //notification.setRecipientId(userId); // Note: singular method name
                    
                    notification.send(new Set<String>{userId}); // Send to one user
                    successCount++;
                } catch (Exception e) {
                    System.debug('Failed to send notification for discrepancy: ' + discrepancyId + ' Error: ' + e.getMessage());
                    failCount++;
                }
            }

            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.INFO,
                'Successfully sent ' + successCount + ' notifications. ' + 
                (failCount > 0 ? 'Failed to send ' + failCount + ' notifications.' : '')
            ));

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error sending notifications: ' + e.getMessage()
            ));
            System.debug('Error: ' + e.getStackTraceString());
        }

        return null;
    }
}