/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 06-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class RiverOrgWideDMLHelper {
    public static List<Id> createRecords(String objectAPIName,List<Map<String,Object>> rawData){
        try{
            if(rawData == null || rawData.isEmpty()){
                System.debug('No Data Found To Insert');
            }
            List<SObject> recordsToInsert = new List<SObject>();
            for(Map<String,Object> data : rawData){
                SObject record = Schema.getGlobalDescribe().get(objectAPIName).newSObject();
                for(String fieldName : data.keySet()){
                    record.put(fieldName,data.get(fieldName));
                }
                recordsToInsert.add(record);
            }
            if(!recordsToInsert.isEmpty()){
                insert recordsToInsert;
            }
            List<Id> insertedId= new List<Id>();
            for(SObject s : recordsToInsert){
                insertedId.add(s.Id);
            }
            return insertedId;


        }catch(Exception e){
            System.debug('Error Occured==>'+e.getMessage());
            System.debug('Error Line Number Is ==>'+e.getLineNumber());
            return null;
        }
    }
     public static void updateRecords(String objectAPIName, List<Map<String, Object>> rawData) {
        try {
            if (rawData == null || rawData.isEmpty()) {
                System.debug('No Data Found To Update');
                return;
            }
            
            List<SObject> recordsToUpdate = new List<SObject>();
            
            for (Map<String, Object> data : rawData) {
                if (!data.containsKey('Id') || data.get('Id') == null) {
                    System.debug('Skipping Record - Id is mandatory for update');
                    continue;
                }
                
                SObject record = Schema.getGlobalDescribe().get(objectAPIName).newSObject((Id)data.get('Id'));
                
                for (String fieldName : data.keySet()) {
                    if (fieldName == 'Id') continue;
                    record.put(fieldName, data.get(fieldName));
                }
                
                recordsToUpdate.add(record);
            }
            
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
            
        } catch (Exception e) {
            System.debug('Error Occurred During Update ==> ' + e.getMessage());
            System.debug('Error Line Number Is ==> ' + e.getLineNumber());
        }
     }
}