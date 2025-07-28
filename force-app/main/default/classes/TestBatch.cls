public class TestBatch {
    public static void getData() {
        Date today = Date.today();
        Date runEndDate = today;
        Date runStartDate = today.addMonths(-6);
        
        Map<Id, DealerConsumptionWrapper> dealerMap = new Map<Id, DealerConsumptionWrapper>();
        
        // SALES CONSUMPTION
        List<Sales_Consumption__c> scList = [
            SELECT Product__c, Quantity_Consumed__c, 
            Order__r.Dealer__c, Manual_Date_Test__c 
            FROM Sales_Consumption__c 
            WHERE Manual_Date_Test__c >= :runStartDate AND Quantity_Consumed__c !=null
            AND Order__r.Dealer__c != null
        ];
        
        for (Sales_Consumption__c sc : scList) {
            Id dealerId = sc.Order__r.Dealer__c;
            if (dealerId == null || sc.Product__c == null || sc.Manual_Date_Test__c == null) continue;
            
            Date dt = sc.Manual_Date_Test__c;
            String monthKey = dt.year() + '-' + dt.month();
            
            if (!dealerMap.containsKey(dealerId)) {
                DealerConsumptionWrapper wrapper = new DealerConsumptionWrapper();
                wrapper.dealerId = dealerId;
                wrapper.batchRunDate = today;
                wrapper.batchStartDate = runStartDate;
                wrapper.batchEndDate = runEndDate;
                wrapper.productDetails = new List<MonthlyProductEstimationDetails>();
                dealerMap.put(dealerId, wrapper);
            }
            //system.debug('dealerMap---'+dealerMap);
            DealerConsumptionWrapper dealerWrapper = dealerMap.get(dealerId);
            MonthlyProductEstimationDetails monthDetail = findOrCreateMonthDetail(dealerWrapper.productDetails, monthKey, sc.Product__c, dt);
            //system.debug('monthDetail---'+monthDetail);
            monthDetail.quantity += (Integer)sc.Quantity_Consumed__c;
        }
        
        // PRODUCT CONSUMED
        List<ProductConsumed> pcList = [
            SELECT Product__c, Quantity_Consumed__c, 
            WorkOrder.Service_Center__c, Manual_Created_Date__c 
            FROM ProductConsumed 
            WHERE Manual_Created_Date__c >= :runStartDate
            AND WorkOrder.Service_Center__c != null
        ];
        
        for (ProductConsumed pc : pcList) {
            Id dealerId = pc.WorkOrder.Service_Center__c;
            if (dealerId == null || pc.Product__c == null || pc.Manual_Created_Date__c == null) continue;
            
            Date dt = pc.Manual_Created_Date__c;
            String monthKey = dt.year() + '-' + dt.month();
            
            if (!dealerMap.containsKey(dealerId)) {
                DealerConsumptionWrapper wrapper = new DealerConsumptionWrapper();
                wrapper.dealerId = dealerId;
                wrapper.batchRunDate = today;
                wrapper.batchStartDate = runStartDate;
                wrapper.batchEndDate = runEndDate;
                wrapper.productDetails = new List<MonthlyProductEstimationDetails>();
                dealerMap.put(dealerId, wrapper);
            }
            //system.debug('dealerMap---'+dealerMap);
            DealerConsumptionWrapper dealerWrapper = dealerMap.get(dealerId);
            MonthlyProductEstimationDetails monthDetail = findOrCreateMonthDetail(dealerWrapper.productDetails, monthKey, pc.Product__c, dt);
            monthDetail.quantity += (Integer)pc.Quantity_Consumed__c;
        }
        
       list<DealerConsumptionWrapper> lists = new list<DealerConsumptionWrapper>();
        for (DealerConsumptionWrapper dealerWrapper : dealerMap.values()) {
            //System.debug('Dealer ID: ' + dealerWrapper.dealerId);
            lists.add(dealerWrapper);
            for (MonthlyProductEstimationDetails mp : dealerWrapper.productDetails) {
                //System.debug('dealerWrapper---'+dealerWrapper);
            }
        }
        
         //System.debug('lists---'+lists);
        String jsonString = JSON.serialize(lists);
    	System.debug('Serialized JSON: ' + jsonString);
    }
    
    private static MonthlyProductEstimationDetails findOrCreateMonthDetail(List<MonthlyProductEstimationDetails> lists, String monthKey, Id productId, Date dateRef) {
        for (MonthlyProductEstimationDetails detail : lists) {
            if (detail.monthKey == monthKey && detail.productId == String.valueOf(productId)) {
                return detail;
            }
        }
        MonthlyProductEstimationDetails newDetail = new MonthlyProductEstimationDetails();
        newDetail.monthKey = monthKey;
        newDetail.productId = String.valueOf(productId);
        newDetail.monthName = getMonthName(dateRef.month()) + '-' + String.valueOf(dateRef.year());
        newDetail.monthStartDate = Date.newInstance(dateRef.year(), dateRef.month(), 1);
        newDetail.monthEndDate = newDetail.monthStartDate.addMonths(1).addDays(-1);
        newDetail.quantity = 0;
        lists.add(newDetail);
        //system.debug('newDetail---'+newDetail);
        return newDetail;
    }
    
    // Helper method to convert numeric month to full name
    private static String getMonthName(Integer month) {
        List<String> months = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June',
                'July', 'August', 'September', 'October', 'November', 'December'
                };
                    return months[month - 1];
    }
    
    public class details{
        public list<DealerConsumptionWrapper> lists;
    }
    
    public class DealerConsumptionWrapper {
        public Id dealerId;
        public Date batchRunDate;
        public Date batchStartDate;
        public Date batchEndDate;
        public List<MonthlyProductEstimationDetails> productDetails;
    }
    
    public class MonthlyProductEstimationDetails {
        public String monthKey;
        public String monthName;
        public String productId;
        public Integer quantity;
        public Date monthStartDate;
        public Date monthEndDate;
        
        // ✅ Fix: Add "override"
        public override String toString() {
            return 'Product: ' + productId + 
                ' | Month: ' + monthName + 
                ' | Qty: ' + quantity +
                ' | Start: ' + monthStartDate +
                ' | End: ' + monthEndDate;
        }
    }
}