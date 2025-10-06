/**
* @File Name : DynamicUploaderController.cls
* @Description :
* @Author : Md Anwar Chikle
* @Last Modified By :
* @Last Modified On : April 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 27, 2025 |   | Initial Version
**/

public class DynamicUploaderController {
    @AuraEnabled
	public static List<String> getObjectList() {
		List<String> objects = new List<String>();
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		for (String s : gd.keySet()) {
            if(s == 'Lead' || s == 'Opportunity'){
                objects.add(s);
            }
		}
		objects.sort();
		return objects;
	}

	@AuraEnabled
    public static List<String> getFieldList(String objectName) {
        try {
            System.debug('objectName ======> ' + objectName);

            List<String> fields = new List<String>();
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            System.debug('fieldMap ======> ' + fieldMap);

            String labelValue = '';
            if (objectName == 'Lead') {
                labelValue = System.label.Upload_Format_Lead;
            } else if (objectName == 'Opportunity') {
                labelValue = System.label.Upload_Format_Opportunity;
            }

            System.debug('labelValue ======> ' + labelValue);

            if (String.isBlank(labelValue)) {
                return fields;
            }

            Set<String> labelFieldSet = new Set<String>(labelValue.toLowerCase().split(','));
            System.debug('labelFieldSet ======> ' + labelFieldSet);

            for (String fieldName : fieldMap.keySet()) {
                if (labelFieldSet.contains(fieldName)) {
                    fields.add(fieldName);
                }
            }

            fields.sort();
            System.debug('fields ======> ' + fields);
            return fields;
        } catch (Exception e) {
            System.debug('error message =====> ' + e.getMessage() + ' at line number ===> ' + e.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static string getProfileName(){
        return [Select Id,Profile.Name from User where Id=: UserInfo.getUserId() limit 1].Profile.Name;
    }

    @AuraEnabled
    public static void uploadData(String objectName, Map<String, String> fieldMapping, List<String> csvRows) {
        System.debug('objectName =====> ' + objectName);
        System.debug('fieldMapping =====> ' + fieldMapping);
        System.debug('csvRows =====> ' + csvRows);
        System.enqueueJob(new CSVUploadQueueable(UserInfo.getUserId(), objectName, fieldMapping, csvRows));
    }

    // @future(callout=false)
    // public static void uploadInBackground(String userId, String objectName, Map<String, String> fieldMapping, List<String> csvRows) {
    //     try {
            
    //         // System.debug('fieldMapping =====>' + fieldMapping);
    //         // System.debug('userId =====>'       + userId);
    //         // System.debug('objectName =====>'   + objectName);
    //         // System.debug('csvRows =====>'      + csvRows);

    //         List<Account> accountsToInsert          = new List<Account>();
    //         List<Contact> contactsToInsert          = new List<Contact>();
    //         List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
    //         List<Lead> leadsToInsert                = new List<Lead>();

    //         for (String row : csvRows) {
    //             if (String.isBlank(row)) continue;

    //             String[] values = row.split(',');
    //             // System.debug('values =====>' + values);
    //             Integer index   = 0;

    //             Account acc     = new Account();
    //             Contact con     = new Contact();
    //             Opportunity opp = new Opportunity();
    //             Lead led        = new Lead();

    //             for (String csvColumn : fieldMapping.keySet()) {
    //                 String fieldName = fieldMapping.get(csvColumn);
    //                 // System.debug('fieldName =====>' + fieldName);
    //                 if (index < values.size()) {
    //                     String value = values[index];

    //                     if (objectName.toLowerCase() == 'opportunity') {
    //                         // System.debug('objectName =====>'+ objectName);
    //                         if (fieldName.startsWithIgnoreCase('name')) {
    //                             acc.put(fieldName.replace('name', 'Name'), value);
    //                             con.put(fieldName.replace('name', 'LastName'), value);
    //                             opp.put(fieldName.replace('name', 'Name'), value);
    //                         } else if (fieldName.startsWithIgnoreCase('phone__c')) {
    //                             acc.put(fieldName.replace('phone__c', 'Phone'), value);
    //                             con.put(fieldName.replace('phone__c', 'Phone'), value);
    //                             opp.put(fieldName.replace('phone__c', 'Phone__c'), value);
    //                         } else if (fieldName == 'closedate') {
    //                             opp.put(fieldName, Date.valueOf(value));
    //                         } else if(fieldName == 'leadsource'){
    //                             acc.put(fieldName.replace('leadsource', 'AccountSource'), value);
    //                             con.put(fieldName.replace('leadsource', 'leadsource'), value);
    //                             opp.put(fieldName.replace('leadsource', 'leadsource'), value);
    //                         } else {
    //                             opp.put(fieldName, value);
    //                         }
    //                     }

    //                     if (objectName.toLowerCase() == 'lead') {
    //                         // System.debug('objectName =====>'+ objectName);
    //                         if (String.isNotBlank((String)led.get('LastName'))) {
    //                             led.put('Company', led.get('LastName'));
    //                         }
    //                         led.put(fieldName,value);
    //                     }
    //                 }
    //                 index++;
    //             }
    //             // System.debug('acc ======>'  + acc);
    //             // System.debug('con ======>'  + con);
    //             // System.debug('opp ======>'  + opp);

    //             if (acc != null && !acc.getPopulatedFieldsAsMap().isEmpty()) {
    //                 accountsToInsert.add(acc); 
    //             }
    //             if (con != null && !con.getPopulatedFieldsAsMap().isEmpty()) {
    //                 contactsToInsert.add(con); 
    //             }
    //             if (opp != null && !opp.getPopulatedFieldsAsMap().isEmpty()) {
    //                 opportunitiesToInsert.add(opp); 
    //             }
    //             if (led != null && !led.getPopulatedFieldsAsMap().isEmpty()) {
    //                 leadsToInsert.add(led); 
    //             }

    //         }

    //         // System.debug('accountsToInsert ======>'       + accountsToInsert);
    //         // System.debug('contactsToInsert ======>'       + contactsToInsert);
    //         // System.debug('opportunitiesToInsert ======>'  + opportunitiesToInsert);
    //         // System.debug('leadsToInsert ======>'          + leadsToInsert);

    //         if(!leadsToInsert.isEmpty()){
    //             insert leadsToInsert;
    //         }

    //         if(!accountsToInsert.isEmpty() && accountsToInsert.size() > 0){
    //             insert accountsToInsert;
    //         }

    //         if(accountsToInsert.size() > 0 ){
    //             for (Integer i = 0; i < accountsToInsert.size(); i++) {
    //                 contactsToInsert[i].AccountId = accountsToInsert[i].Id;
    //                 opportunitiesToInsert[i].AccountId = accountsToInsert[i].Id;
    //             }

    //             if(!contactsToInsert.isEmpty()){
    //                 insert contactsToInsert;
    //             }

    //             if(!opportunitiesToInsert.isEmpty()){
    //                 insert opportunitiesToInsert;
    //             }
    //         }

    //         //sendUserNotification(userId, 'Success', opportunitiesToInsert.size() + ' opportunities (with accounts & contacts) uploaded successfully.');
    //     } catch (Exception e) {
    //         //sendUserNotification(userId, 'Failed', 'Error during upload: ' + e.getMessage());
    //         System.debug(' error message ====>'+ e.getMessage()+ ' at line number ====>' + e.getLineNumber());
    //     }
    // }

    // private static void sendUserNotification(String userId, String status, String message) {
	// 	CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'SendNotification'];
	// 	Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
	// 	customNotificationObj.setBody('Data Uploading Successfull');
	// 	customNotificationObj.setTitle('Please check All the Records got Created');
	// 	customNotificationObj.setNotificationTypeId(cnType.id);
	// 	customNotificationObj.setSenderId(userId);
	// 	customNotificationObj.send(new Set<String> {userId});   
    // }

}