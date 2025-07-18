public without sharing class DynamicComponentService {
    
    // Allowed objects and fields whitelist to prevent SOQL injection and unauthorized access
    private static final Map<String, Set<String>> ALLOWED_OBJECT_FIELDS = new Map<String, Set<String>>{
        'Account' => new Set<String>{ 'ID', 'NAME', 'PHONE' },
            'Contact' => new Set<String>{ 'ID', 'FIRSTNAME', 'LASTNAME', 'EMAIL' }
    };
        
        /**
* Fetches dynamic component mapping record for a given key
*/
        @AuraEnabled(cacheable=true)
        public static Dynamic_Component_Mapping__c getComponentMapping(String key) {
            return [
                SELECT Component_Name__c, Query_Condition__c 
                FROM Dynamic_Component_Mapping__c
                WHERE Primary_Key__c = :key and is_Active__c =true
                LIMIT 1
            ];
        }
    
    /**
* Runs a dynamic SOQL query (use with caution, no sanitization)
*/
    @AuraEnabled
    public static List<SObject>  runDynamicQuery(String soql) {
        try {
            system.debug('soql--'+soql);
            List<SObject> results = Database.query(soql);
            //return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(results));
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error running dynamic query: ' + e.getMessage());
        }
    }
    
    /**
* Runs a safe dynamic SOQL query after validating object and fields against a whitelist
*/
    public static Map<String, Object> runSafeQuery(String rawSoql) {
        String cleaned = rawSoql.trim();
        
        // Inline flags: (?i) case-insensitive, (?s) dotall
        Pattern p = Pattern.compile('(?is)SELECT\\s+(.*?)\\s+FROM\\s+(\\w+)');
        Matcher m = p.matcher(cleaned);
        
        if (!m.find()) {
            throw new AuraHandledException('Invalid SOQL format.');
        }
        
        String fieldsPart = m.group(1);
        String objectName = m.group(2).toUpperCase();
        
        if (!ALLOWED_OBJECT_FIELDS.containsKey(objectName)) {
            throw new AuraHandledException('Object "' + objectName + '" not allowed.');
        }
        
        Set<String> allowedFields = ALLOWED_OBJECT_FIELDS.get(objectName);
        
        // Validate each requested field is in allowedFields set
        for (String field : fieldsPart.split(',')) {
            String trimmedField = field.trim().toUpperCase();
            if (!allowedFields.contains(trimmedField)) {
                throw new AuraHandledException('Field "' + trimmedField + '" not allowed for object "' + objectName + '".');
            }
        }
        
        try {
            List<SObject> results = Database.query(cleaned);
            return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(results));
        } catch (Exception e) {
            throw new AuraHandledException('Error running safe query: ' + e.getMessage());
        }
    }
}