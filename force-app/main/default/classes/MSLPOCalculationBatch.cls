// Batch 2: PO Calculation and Generation
global without sharing class MSLPOCalculationBatch implements Database.Batchable<String>, Database.Stateful {
    global Map<String, Decimal> dealerProductMonthlyQty;
    global Map<String, Date> dealerProductFirstConsumption;
    global Map<String, Date> dealerProductLastConsumption;
    global Date today = Date.today();
    global Map<Id, List<Purchase_Order_Recommendation_Line__c>> dealerRecommendations = new Map<Id, List<Purchase_Order_Recommendation_Line__c>>();
    
    global MSLPOCalculationBatch(
        Map<String, Decimal> monthlyQty,
        Map<String, Date> firstConsumption,
        Map<String, Date> lastConsumption
    ) {
        dealerProductMonthlyQty = monthlyQty;
        dealerProductFirstConsumption = firstConsumption;
        dealerProductLastConsumption = lastConsumption;
    }
    
    global Iterable<String> start(Database.BatchableContext BC) {
        return dealerProductFirstConsumption.keySet();
    }
    
    global void execute(Database.BatchableContext BC, List<String> scope) {
        for (String key : scope) {
            String[] parts = key.split('_');
            Id dealerId = Id.valueOf(parts[0]);
            Id productId = Id.valueOf(parts[1]);
            
            // Check if eligible for MSL calculation
            if (isMSLEligible(dealerId, productId)) {
                Decimal msl = calculateMSL(dealerId, productId);
                Decimal recommendedQty = calculateRecommendedQty(dealerId, productId, msl);
                
                if (recommendedQty > 0) {
                    addRecommendation(dealerId, productId, recommendedQty);
                }
            }
            else {
                // Handle default stock level logic
                Decimal defaultStock = getDefaultStockLevel(productId);
                Decimal recommendedQty = calculateRecommendedQty(dealerId, productId, defaultStock);
                
                if (recommendedQty > 0) {
                    addRecommendation(dealerId, productId, recommendedQty);
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Create draft PO recommendations
        List<Purchase_Order_Recommendation__c> poRecommendations = new List<Purchase_Order_Recommendation__c>();
        Map<Id, Purchase_Order_Recommendation__c> dealerToPO = new Map<Id, Purchase_Order_Recommendation__c>();
        
        for (Id dealerId : dealerRecommendations.keySet()) {
            Purchase_Order_Recommendation__c po = new Purchase_Order_Recommendation__c(
                Dealer__c = dealerId,
                Status__c = 'Draft',
                Recommendation_Date__c = today
            );
            poRecommendations.add(po);
            dealerToPO.put(dealerId, po);
        }
        insert poRecommendations;
        
        // Create PO lines
        List<Purchase_Order_Recommendation_Line__c> poLines = new List<Purchase_Order_Recommendation_Line__c>();
        for (Id dealerId : dealerRecommendations.keySet()) {
            for (Purchase_Order_Recommendation_Line__c line : dealerRecommendations.get(dealerId)) {
                line.Purchase_Order_Recommendation__c = dealerToPO.get(dealerId).Id;
                poLines.add(line);
            }
        }
        insert poLines;
        
        // Send notifications
        sendNotifications(dealerToPO.keySet());
    }
    
    private Boolean isMSLEligible(Id dealerId, Id productId) {
        String key = dealerId + '_' + productId;
        Date firstDate = dealerProductFirstConsumption.get(key);
        Date lastDate = dealerProductLastConsumption.get(key);
        
        // Check if 6 months have passed since first consumption
        Boolean hasSixMonthsData = firstDate <= today.addMonths(-6);
        
        // Check consumption in last two months
        Boolean recentConsumption = lastDate >= today.addMonths(-2);
        
        return hasSixMonthsData && recentConsumption;
    }
    
    private Decimal calculateMSL(Id dealerId, Id productId) {
        List<Decimal> monthlyConsumptions = new List<Decimal>();
        
        // Collect last 6 months of consumption
        for (Integer i = 0; i < 6; i++) {
            Date refDate = today.addMonths(-i);
            String monthKey = dealerId + '_' + productId + '_' + 
                refDate.year() + '-' + refDate.month();
            
            if (dealerProductMonthlyQty.containsKey(monthKey)) {
                Decimal monthlyQty = dealerProductMonthlyQty.get(monthKey);
                if (monthlyQty > 0) {
                    monthlyConsumptions.add(monthlyQty);
                }
            }
        }
        
        // Calculate average skipping zero months
        if (monthlyConsumptions.isEmpty()) return 0;
        
        Decimal total = 0;
        for (Decimal val : monthlyConsumptions) {
            total += val;
        }
        
        return total / monthlyConsumptions.size();
    }
    
    private Decimal calculateRecommendedQty(Id dealerId, Id productId, Decimal requiredStock) {
        System.debug('dealerId: ' + dealerId);
        System.debug('productId: ' + productId);
        System.debug('requiredStock: ' + requiredStock);
        
        // Default required stock to 0 if null
        Decimal safeRequiredStock = requiredStock != null ? requiredStock : 0;
        
        // Get current inventory (handle null)
        Decimal currentInventory = getCurrentInventory(dealerId, productId);
        currentInventory = currentInventory != null ? currentInventory : 0;
        
        // Get open order quantities (handle null)
        Decimal openOrders = getOpenOrders(dealerId, productId);
        openOrders = openOrders != null ? openOrders : 0;
        
        // Calculate recommended quantity
        Decimal recommended = safeRequiredStock - (currentInventory + openOrders);
        
        // Get Minimum Order Quantity from Product2
        Product2 p;
        try {
            p = [
                SELECT Minimum_Order_Qty__c 
                FROM Product2 
                WHERE Id = :productId
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('Failed to fetch Product2: ' + e.getMessage());
            return recommended > 0 ? recommended : 0;
        }
        
        Decimal moq = p.Minimum_Order_Qty__c != null ? p.Minimum_Order_Qty__c : 0;
        
        // Return MOQ if applicable
        if (moq > 0 && recommended > 0) {
            return moq;
        }
        
        return recommended > 0 ? recommended : 0;
    }
    
    
    private Decimal getCurrentInventory(Id dealerId, Id productId) {
        // Query inventory object - implementation depends on your schema
        List<ProductItem> inv=[SELECT id, Product2Id, Quantity_In_Hand__c,Location.Account__c  FROM ProductItem where Location.Account__c  =:dealerId AND Product2Id = :productId];
        return inv.isEmpty() ? 0 : inv[0].Quantity_In_Hand__c;
    }
    
    private Decimal getOpenOrders(Id dealerId, Id productId) {
        // Query to get total quantity requested for open orders
        AggregateResult[] results = [
            SELECT SUM(QuantityRequested) total 
            FROM ProductRequestLineItem 
            WHERE Parent.SourceLocation.Account__c = :dealerId 
            AND Product2Id = :productId
            // AND Status__c IN ('Draft', 'Ordered') -- Uncomment if needed
        ];
        
        Decimal totalOpenOrders = (Decimal) (results.isEmpty() ? 0 : results[0].get('total'));
        return totalOpenOrders;
    }
    
    private Decimal getDefaultStockLevel(Id productId) {
        // Get the minimum order quantity from Product2
        Product2 product = [
            SELECT Minimum_Order_Qty__c 
            FROM Product2 
            WHERE Id = :productId
            LIMIT 1
        ];
        
        Decimal minOrderQty = product.Minimum_Order_Qty__c != null ? product.Minimum_Order_Qty__c : 0;
        return minOrderQty;
    }
    
    private void addRecommendation(Id dealerId, Id productId, Decimal quantity) {
        if (!dealerRecommendations.containsKey(dealerId)) {
            dealerRecommendations.put(dealerId, new List<Purchase_Order_Recommendation_Line__c>());
        }
        
        dealerRecommendations.get(dealerId).add(
            new Purchase_Order_Recommendation_Line__c(
                Product__c = productId,
                Recommended_Quantity__c = quantity,
                Minimum_Quantity__c = quantity  // Users can't reduce below this
            )
        );
    }
    
    private void sendNotifications(Set<Id> dealerIds) {
        // Implementation depends on your notification requirements
        // Would typically query for dealer contacts and send emails/alerts
    }
}