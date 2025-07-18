public with sharing class CSCaseRaiseController {

    @AuraEnabled
    public static List<Id> createCases(List<Map<String, Object>> casesFieldsList) {
        System.debug('START: createCases method');
        System.debug('Input casesFieldsList: ' + casesFieldsList);

        List<Case> casesToInsert = new List<Case>();

        for (Map<String, Object> caseFields : casesFieldsList) {
            Case cse = new Case();
            for (String key : caseFields.keySet()) {
                Object value = caseFields.get(key);
                if (value != null) {
                    cse.put(key, value);
                }
            }
            System.debug('Prepared Case record: ' + cse);
            casesToInsert.add(cse);
        }

        try {
            insert casesToInsert;
            System.debug('Inserted Case records successfully.');

            List<Id> newIds = new List<Id>();
            for (Case cse : casesToInsert) {
                newIds.add(cse.Id);
            }

            System.debug('Returning Case Ids: ' + newIds);
            return newIds;

        } catch (Exception e) {
            System.debug('Error while inserting Case records: ' + e.getMessage() + 'Error while inserting Case records: '+ e.getLineNumber());
            throw new AuraHandledException('Failed to create Cases: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getAccountName(Id accountId) {
        System.debug('START: getAccountName method');
        System.debug('Input accountId: ' + accountId);

        try {
            List<Account> accList = [SELECT Name FROM Account WHERE Id = :accountId];
            System.debug('Queried Accounts: ' + accList);

            if (!accList.isEmpty()) {
                System.debug('Returning Account Name: ' + accList[0].Name);
                return accList[0].Name;
            } else {
                System.debug('No Account found for Id: ' + accountId);
                throw new AuraHandledException('No Account found for the provided Id.');
            }

        } catch (Exception e) {
            System.debug('Error while fetching Account Name: ' + e.getMessage());
            throw new AuraHandledException('Failed to get Account Name: ' + e.getMessage());
        }
    }
}