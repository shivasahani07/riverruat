public class JobCardPDFController {
    public workorder jobCard { get; set; }
    public List<TFR_Sample__c> tfrSamples { get; set; }
    
    public JobCardPDFController(ApexPages.StandardController std) {
        Id jobCardId ='0WOBh000003WQQfOAO';
        
        jobCard = [
            SELECT Id, workordernumber, Status, Odometer_Reading__c, CreatedDate
            FROM workorder
            WHERE Id = :jobCardId
            LIMIT 1
        ];
        
        tfrSamples = [
            SELECT Actions_Taken__c,Approved_by__c,CreatedById,CreatedDate,
            Customer_Account__c,Customer_Contact__c,Date_of_Complaint__c,
            Date_of_Repair__c,Date_of_Sale__c,Failure_Code__c,Failure_Code__r.name,Id,IsDeleted,
            Issue_Severity__c,Job_Card__c,LastModifiedById,LastModifiedDate,
            LastReferencedDate,LastViewedDate,Media__c,Name,Name__c,Observations__c,
            Odometer_Reading__c,OwnerId,Part__c,Service_Center__c,SystemModstamp,
            TFR_Post_Vin_Cutt_off__c,TFR__c,VIN_No__c,VOC__c,Warranty_Claim_Number__c FROM TFR_Sample__c
            WHERE Job_Card__c = :jobCardId
        ];
    }
}