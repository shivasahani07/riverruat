@IsTest
public class TriggerOnFailureCodeHelperv2Test {
    @IsTest
    static void beforeInsertMethods(){
        TFR__c tfr = new TFR__c(VIN_Start__c = 'VIN12345');
        insert tfr;
        
        Product2 prod = new Product2(Name = 'Brake Pad', ProductCode = 'P123', isActive = true, HSN_Code__c='HSN-34U', Type__c='Parts');
        insert prod;
        
        Product2 prod2 = new Product2(Name = 'Brake Pad', ProductCode = 'P123', isActive = true, HSN_Code__c='HSN-34U', Type__c='Parts');
        insert prod2;
        
        Product2 prod3 = new Product2(Name = 'Brake Pad', ProductCode = 'P123', isActive = true, HSN_Code__c='HSN-34U', Type__c='Parts');
        insert prod3;
        
        CodeSet cs = new CodeSet(Name = 'CS-01', Code = 'C01');
        insert cs;
        
        TFR_Part_Effect__c tfrPart = new TFR_Part_Effect__c(TFR__c = tfr.Id,Product__c = prod.Id);
        insert tfrPart;
        
        TFR_Part_Effect__c tfrPart2 = new TFR_Part_Effect__c(TFR__c = tfr.Id,Product__c = prod.Id);
        insert tfrPart2;
        
        TFR_Labour_Effect__c tfrLabour = new TFR_Labour_Effect__c(TFR__c = tfr.Id,Code_Set__c = cs.Id);
        insert tfrLabour;
        
        TFR_Labour_Effect__c tfrLabour2 = new TFR_Labour_Effect__c(TFR__c = tfr.Id,Code_Set__c = cs.Id);
        insert tfrLabour2;
        
        
         Failure_Code__c fc = new Failure_Code__c(
            Name = 'FC-Part',
            TFR_Part_Effect__c = tfrPart.Id,
            TFR_Labour_Effect__c = tfrLabour.Id
        );
        
        Test.startTest();
       
        insert fc;
        
        Failure_Code__c fc2 = new Failure_Code__c(
            Name = 'FC-Part',
            TFR_Labour_Effect__c = tfrLabour.Id
        );
        insert fc2;
        
        fc.TFR_Part_Effect__c = tfrPart2.Id;
        update fc;
        
        fc2.TFR_Part_Effect__c = null;
        update fc2;
        
        fc2.TFR_Labour_Effect__c = tfrLabour2.Id;
        update fc2;
        
        fc2.TFR_Labour_Effect__c = null;
        update fc2;
        
        fc.TFR_Part_Effect__c = null;
        update fc;
        
        
        
        
              
        Test.stopTest();
    }

}