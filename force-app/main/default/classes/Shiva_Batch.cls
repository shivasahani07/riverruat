public class Shiva_Batch {
    
    public class mslWrapper{
        public Id DealerId;
        public list<productDetailsWrapper> splits;
        
    }
    
    public class productDetailsWrapper{
        public Id ProductId;
        public date startDate;
        public date endDate;
        public integer Quantity;
        public string monthName;
        public integer sequence;
    }
    
    public static void getData(String type ,integer No){
        List<mslWrapper> allConsumption = new List<mslWrapper>();
        mslWrapper mslobject = new mslWrapper();
        
        for (Sales_Consumption__c sale:[SELECT Id, CreatedDate, Quantity_Consumed__c, Dealer__c, 
                                        Product__c,Product_Inventory__r.Account__c, Order__r.AccountId 
                                        FROM Sales_Consumption__c  WHERE    Manual_Date_Test__c >= :System.today().addMonths(-6) 
                                        AND Order__r.Dealer__r.Type != 'Customer' AND Order__r.Account.Type != 'Customer'])
        {
            mslobject.DealerId=sale.Order__r.AccountId;
            productDetailsWrapper prdtdetails = new productDetailsWrapper();
            prdtdetails.ProductId=sale.Product__c;
            
        }
        
        for (ProductConsumed consumed : [
            SELECT Id, ProductItemId, Quantity_Consumed__c, QuantityConsumed, Product2Id, WorkOrder.Service_Center__c,
            CreatedDate
            FROM ProductConsumed
            WHERE
            Manual_Created_Date__c >= :System.today().addMonths(-6)
            AND WorkOrder.Service_Center__r.Type != 'Customer'
        ])
        {
            
        }
        
        
        
        
    }
}