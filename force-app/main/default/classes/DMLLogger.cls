public without sharing class DMLLogger {

    /**
     * Main method to log changes asynchronously
     */
    public static void logChanges(Map<Id, SObject> oldMap,Map<Id, SObject> newMap,String operation,String objectName) {
        List<Object_DML_Log__c> logs = new List<Object_DML_Log__c>();

        // Fetch tracked fields configuration for this object
        List<Important_Object_Field__mdt> fieldConfigs = [
            SELECT Object_API__c, Field_API__c, Track_Update__c, Track_Delete__c 
            FROM Important_Object_Field__mdt 
            WHERE Object_API__c = :objectName
        ];

        if (fieldConfigs.isEmpty()) {
            System.debug('⚠️ No tracked fields found for object: ' + objectName);
            return;
        }

        if (operation == 'DELETE') {
            for (SObject oldRec : oldMap.values()) {
                for (Important_Object_Field__mdt fieldConfig : fieldConfigs) {
                    if (fieldConfig.Track_Delete__c) {
                        logs.add(new Object_DML_Log__c(
                            Object_Name__c = objectName,
                            Record_Id__c = oldRec.Id,
                            Operation__c = 'DELETE',
                            Old_Values__c = JSON.serialize(oldRec),
                            Performed_By__c = UserInfo.getUserId(),
                            Performed_On__c = System.now()
                        ));
                        break; // only need one log per record for delete
                    }
                }
            }
        }
        else if (operation == 'UPDATE') {
            for (Id recId : newMap.keySet()) {
                SObject oldRec = oldMap.get(recId);
                SObject newRec = newMap.get(recId);

                Map<String, Object> changes = new Map<String, Object>();

                for (Important_Object_Field__mdt fieldConfig : fieldConfigs) {
                    if (!fieldConfig.Track_Update__c) continue;

                    List<String> fieldApiList = fieldConfig.Field_API__c.split(',');
                    
                    for (String field : fieldApiList) {
                        Object oldVal = oldRec.get(field);
                        Object newVal = newRec.get(field);

                        if (oldVal != newVal) {
                            changes.put(field, new Map<String, Object>{ 
                                'old' => oldVal, 
                                'new' => newVal 
                            });
                        }
                    }
                }

                if (!changes.isEmpty()) {
                    logs.add(new Object_DML_Log__c(
                        Object_Name__c = objectName,
                        Record_Id__c = recId,
                        Operation__c = 'UPDATE',
                        Changed_Fields__c = String.join(new List<String>(changes.keySet()), ','),
                        Old_Values__c = JSON.serialize(oldRec),
                        New_Values__c = JSON.serialize(newRec),
                        Performed_By__c = UserInfo.getUserId(),
                        Performed_On__c = System.now()
                    ));
                }
            }
        }

        if (!logs.isEmpty()) {
            System.enqueueJob(new DMLLoggerQueueable(logs));
        }
    }

    /**
     * Inner Queueable class for async insert of logs
     */
    public class DMLLoggerQueueable implements Queueable {
        private List<Object_DML_Log__c> logsToInsert;

        public DMLLoggerQueueable(List<Object_DML_Log__c> logs) {
            this.logsToInsert = logs;
        }

        public void execute(QueueableContext qc) {
            if (!logsToInsert.isEmpty()) {
                try {
                    System.debug('logsToInsert' +logsToInsert);
                    insert logsToInsert;
                } catch (Exception e) {
                    System.debug('❌ Failed to insert logs: ' + e.getMessage());
                    System.debug('❌ Failed to insert logs at line  ' + e.getLineNumber());
                    // (Optional) fallback: publish a Platform Event here
                }
            }
        }
    }
}