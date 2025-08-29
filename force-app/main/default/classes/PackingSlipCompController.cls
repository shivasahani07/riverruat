public class PackingSlipCompController {

    @AuraEnabled(cacheable=true)
    public static List<Claim> getActivatedClaims(String batchId){

        try {
            List<Claim> claims = [
                SELECT Id, Name, Total_Claim_Amount__c, Create_Batch__c, Status
                FROM Claim 
                WHERE Create_Batch__c = :batchId
                AND Status = 'Submitted'
            ];


            System.debug('Fetched claims:::' + claims);

            return claims;
        } 
        catch (Exception e) {
            throw new AuraHandledException('Error fetching claims: ' + e.getMessage());
        }
    }
}