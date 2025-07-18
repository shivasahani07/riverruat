@isTest
public class ClaimItemTriggerHandlerTest {
    @isTest
    static void testProcessClaimUpdates() {
        
        Create_Batch__c testBatch = new Create_Batch__c(Status__c = 'Received');
        insert testBatch;
        
        Account testAccount = new Account(Name = 'Test Account', Type = 'Customer');
        insert testAccount;	
        
        
        List<Claim> claims = new List<Claim>();
        for (Integer i = 0; i < 2; i++) {
            claims.add(new Claim(Name = 'Test Claim ' + i, Status = 'Pending', AccountId = testAccount.Id, Create_Batch__c = testBatch.Id));
        }
        insert claims;
        
        
        List<ClaimItem> claimItems = new List<ClaimItem>();
        for (Claim claim : claims) {
            claimItems.add(new ClaimItem(Name = 'Claim Item 1', ClaimId = claim.Id, Status__c = 'Pending'));
            claimItems.add(new ClaimItem(Name = 'Claim Item 2', ClaimId = claim.Id, Status__c = 'Pending'));
        }
        insert claimItems;
        
        
        for (ClaimItem ci : claimItems) {
            ci.Status__c = 'Approved';
            ci.Approved_Amount__c = 1000;
        }
        update claimItems;
        
        
        List<Claim> updatedClaims = [
            SELECT Id, Status 
            FROM Claim 
            WHERE Id IN :claims
        ];
        for (Claim claim : updatedClaims) {
            
        }
        
        
        System.debug('Email logic was executed for claims: ' + updatedClaims);
    }
    
    @isTest
    static void testProcessClaimUpdatesPartial() {
        
        Create_Batch__c testBatch = new Create_Batch__c(Status__c = 'Received');
        insert testBatch;
        
        Account testAccount = new Account(Name = 'Test Account', Type = 'Customer');
        insert testAccount;	
        
        Claim testClaim = new Claim(
            Name = 'Test Claim Partial', 
            Status = 'Pending', 
            AccountId = testAccount.Id, 
            Create_Batch__c = testBatch.Id
        );
        try{
            
            insert testClaim;
        }catch(Exception e){
            
        }
        
        
        
        List<ClaimItem> claimItems = new List<ClaimItem>{
            new ClaimItem(Name = 'Claim Item 1', ClaimId = testClaim.Id, Status__c = 'Pending', FaultDate = Date.Today(), Approved_Amount__c = 1000),
                new ClaimItem(Name = 'Claim Item 2', ClaimId = testClaim.Id, Status__c = 'Pending', FaultDate = Date.Today(), Approved_Amount__c = 1000)
                };
                    insert claimItems;
        
        
        claimItems[1].Status__c = 'Approved';
        update claimItems;
        
        
        Claim updatedClaim = [
            SELECT Id, Status 
            FROM Claim 
            WHERE Id = :testClaim.Id
        ];
        
    }
    
    
}