public class actionPlanHandler {
    
    public static void getTheCountOfTheActionPlansOfaFieldFix(List<ActionPlan> listOfActionPlan) {
        Set<Id> setOfFieldFix = new Set<Id>();
        for (ActionPlan ap : listOfActionPlan) {
            if (ap.Field_Fix__c != null) {
                setOfFieldFix.add(ap.Field_Fix__c);
            }
        }
        
        if (setOfFieldFix.isEmpty()) return;
        
        // Query all Action Plans
        List<ActionPlan> allPlans = [
            SELECT Id, Field_Fix__c, To_be_Completed_in_JC__c, Job_Card__c
            FROM ActionPlan
            WHERE Field_Fix__c IN :setOfFieldFix
        ];
        
        Map<Id, Integer> totalMap = new Map<Id, Integer>();
        Map<Id, Integer> completedMap = new Map<Id, Integer>();
        Map<Id, Set<Id>> fieldFixToJobCardsMap = new Map<Id, Set<Id>>();
        
        for (ActionPlan ap : allPlans) {
            Id fieldFixId = ap.Field_Fix__c;
            
            totalMap.put(fieldFixId, totalMap.containsKey(fieldFixId) ? totalMap.get(fieldFixId) + 1 : 1);
            
            if (ap.To_be_Completed_in_JC__c) {
                completedMap.put(fieldFixId, completedMap.containsKey(fieldFixId) ? completedMap.get(fieldFixId) + 1 : 1);
                if (ap.Job_Card__c != null) {
                    if (!fieldFixToJobCardsMap.containsKey(fieldFixId)) {
                        fieldFixToJobCardsMap.put(fieldFixId, new Set<Id>());
                    }
                    fieldFixToJobCardsMap.get(fieldFixId).add(ap.Job_Card__c);
                }
            }
        }
        
        // Flatten all Job_Card__c IDs to query WorkOrders
        Set<Id> allJobCardIds = new Set<Id>();
        for (Set<Id> jobCardSet : fieldFixToJobCardsMap.values()) {
            allJobCardIds.addAll(jobCardSet);
        }
        
        // Query completed Job Cards (WorkOrders)
        Map<Id, Boolean> jobCardCompletedMap = new Map<Id, Boolean>();
        if (!allJobCardIds.isEmpty()) {
            for (WorkOrder wo : [SELECT Id, Status FROM WorkOrder WHERE Id IN :allJobCardIds]) {
                // You can customize this logic if your completion status is different
                jobCardCompletedMap.put(wo.Id, wo.Status == 'Completed');
            }
        }
        
        // Count completed Job Cards per Field Fix
        Map<Id, Integer> jobCardCountMap = new Map<Id, Integer>();
        for (Id fieldFixId : fieldFixToJobCardsMap.keySet()) {
            Integer count = 0;
            for (Id jcId : fieldFixToJobCardsMap.get(fieldFixId)) {
                if (jobCardCompletedMap.containsKey(jcId) && jobCardCompletedMap.get(jcId)) {
                    count++;
                }
            }
            jobCardCountMap.put(fieldFixId, count);
        }
        
        // Prepare updates
        List<Field_Fix__c> fieldFixUpdates = new List<Field_Fix__c>();
        for (Id fieldFixId : setOfFieldFix) {
            Field_Fix__c fieldFix = new Field_Fix__c(
                Id = fieldFixId,
                Total_Action_Plans__c = totalMap.get(fieldFixId),
                Completed_Action_Plans__c = completedMap.containsKey(fieldFixId) ? completedMap.get(fieldFixId) : 0,
                Total_Job_Card_Completed__c = jobCardCountMap.containsKey(fieldFixId) ? jobCardCountMap.get(fieldFixId) : 0
            );
            fieldFixUpdates.add(fieldFix);
        }
        
        if (!fieldFixUpdates.isEmpty()) {
            update fieldFixUpdates;
        }
    }
    
    // BEFORE UPDATE TO VALIDATE INVETORY IS AVALIABLE BY SHIVA 18/JUNE/2025
    public static void checkInventoryValidation(List<ActionPlan> newActionPlans, Map<Id, ActionPlan> oldActionPlanMap) {
        
        Set<Id> fieldFixIds = new Set<Id>();
        Set<Id> jobCardIds = new Set<Id>();
        Id profileId = UserInfo.getProfileId();
        String profileName = [SELECT Name FROM Profile WHERE Id = :profileId].Name;
        System.debug('Current User Profile Name: ' + profileName);
        
        // Collect lookup IDs
        for (ActionPlan ap : newActionPlans) {
            ActionPlan oldAp = oldActionPlanMap.get(ap.Id);
            if (ap.To_be_Completed_in_JC__c == true && oldAp != null && oldAp.To_be_Completed_in_JC__c != true) {
                if (ap.Field_Fix__c != null) fieldFixIds.add(ap.Field_Fix__c);
                if (ap.Job_Card__c != null) jobCardIds.add(ap.Job_Card__c);
            }if(ap.To_be_Completed_in_JC__c != true && oldAp != null && oldAp.To_be_Completed_in_JC__c == true && profileName == 'Sales Manager (Partner)'){
                ap.addError('you can not uncheck this, its already checked');
            }
        }
        
        // Query Field Fix and Job Card related data
        Map<Id, Field_Fix__c> fieldFixMap = new Map<Id, Field_Fix__c>(
            [SELECT Id, Action_Plan_Template__c FROM Field_Fix__c WHERE Id IN :fieldFixIds]
        );
        
        Map<Id, workorder> jobCardMap = new Map<Id, workorder>(
            [SELECT Id, Location__c FROM workorder WHERE Id IN :jobCardIds]
        );
        
        // Prepare tracking structures
        Set<Id> actionTemplateIds = new Set<Id>();
        Set<Id> locationIds = new Set<Id>();
        Map<Id, Id> actionPlanToTemplate = new Map<Id, Id>();
        Map<Id, Id> actionPlanToLocation = new Map<Id, Id>();
        
        for (ActionPlan ap : newActionPlans) {
            ActionPlan oldAp = oldActionPlanMap.get(ap.Id);
            if (ap.To_be_Completed_in_JC__c == true && oldAp != null && oldAp.To_be_Completed_in_JC__c != true) {
                if (ap.Field_Fix__c != null && fieldFixMap.containsKey(ap.Field_Fix__c)) {
                    Id templateId = fieldFixMap.get(ap.Field_Fix__c).Action_Plan_Template__c;
                    if (templateId != null) {
                        actionTemplateIds.add(templateId);
                        actionPlanToTemplate.put(ap.Id, templateId);
                    }
                }
                
                if (ap.Job_Card__c != null && jobCardMap.containsKey(ap.Job_Card__c)) {
                    Id locationId = jobCardMap.get(ap.Job_Card__c).Location__c;
                    if (locationId != null) {
                        locationIds.add(locationId);
                        actionPlanToLocation.put(ap.Id, locationId);
                    }
                }
            }
        }
        
        // Query Required Products
        List<Required_Product__c> requiredProducts = [
            SELECT Id, Action_Plan_Template__c, Product__c, Quantity__c 
            FROM Required_Product__c 
            WHERE Action_Plan_Template__c IN :actionTemplateIds
        ];
        
        // Query Inventory (ProductItem)
        List<ProductItem> productInventory = [
            SELECT Id, Product2Id, Quantity_In_Hand__c, LocationId 
            FROM ProductItem 
            WHERE LocationId IN :locationIds
        ];
        
        // Map: ProductId + LocationId → Quantity
        Map<String, Decimal> inventoryMap = new Map<String, Decimal>();
        for (ProductItem item : productInventory) {
            String key = item.Product2Id + '_' + item.LocationId;
            inventoryMap.put(key, item.Quantity_In_Hand__c);
        }
        
        system.debug('actionTemplateIds---'+actionTemplateIds);
        system.debug('locationIds---'+locationIds);
        system.debug('inventoryMap---'+inventoryMap);
        
        // Map: TemplateId → List of Required_Product__c
        Map<Id, List<Required_Product__c>> templateToProducts = new Map<Id, List<Required_Product__c>>();
        for (Required_Product__c req : requiredProducts) {
            if (!templateToProducts.containsKey(req.Action_Plan_Template__c)) {
                templateToProducts.put(req.Action_Plan_Template__c, new List<Required_Product__c>());
            }
            templateToProducts.get(req.Action_Plan_Template__c).add(req);
        }
        
        // Final validation loop
        for (ActionPlan ap : newActionPlans) {
            if (ap.To_be_Completed_in_JC__c == true &&
                actionPlanToTemplate.containsKey(ap.Id) &&
                actionPlanToLocation.containsKey(ap.Id)) {
                    
                    Id templateId = actionPlanToTemplate.get(ap.Id);
                    Id locationId = actionPlanToLocation.get(ap.Id);
                    List<Required_Product__c> reqProducts = templateToProducts.get(templateId);
                    
                    if (reqProducts != null) {
                        for (Required_Product__c req : reqProducts) {
                            String key = req.Product__c + '_' + locationId;
                            Decimal availableQty = inventoryMap.containsKey(key) ? inventoryMap.get(key) : 0;
                            if (availableQty < req.Quantity__c) {
                                ap.addError(
                                    'Insufficient inventory for product ' + req.Product__c + 
                                    ' at location ' + locationId + 
                                    '. Required: ' + req.Quantity__c + 
                                    ', Available: ' + availableQty
                                );
                            }
                        }
                    }
                }
        }
        
    }
    
    public static void createProductAndlabour(List<ActionPlan> newActionPlans, Map<Id, ActionPlan> oldActionPlanMap) {
        Set<Id> jobCardIds = new Set<Id>();
        Set<Id> templateVersionIds = new Set<Id>();
        Map<Id, ActionPlan> actionPlanMap = new Map<Id, ActionPlan>();
        
        // Identify action plans that need processing
        for (ActionPlan ap : newActionPlans) {
            ActionPlan oldAp = oldActionPlanMap.get(ap.Id);
            if (ap.To_be_Completed_in_JC__c && (oldAp == null || !oldAp.To_be_Completed_in_JC__c)) {
                actionPlanMap.put(ap.Id, ap);
                if (ap.Job_Card__c != null) jobCardIds.add(ap.Job_Card__c);
                if (ap.ActionPlanTemplateVersionId != null) templateVersionIds.add(ap.ActionPlanTemplateVersionId);
            }
        }
        
        if (actionPlanMap.isEmpty()) return;
        
        // Check for existing warranties
        Map<Id, Warranty_Prior__c> jobCardToWarranty = new Map<Id, Warranty_Prior__c>();
        for (Warranty_Prior__c wp : [
            SELECT Id,Name, Job_Card__c FROM Warranty_Prior__c 
            WHERE Job_Card__c IN :jobCardIds
        ]) {
            jobCardToWarranty.put(wp.Job_Card__c, wp);
        }
        
        // Create warranties for job cards that don't have one
        Map<Id, WorkOrder> jobCardsWithoutWarranty = new Map<Id, WorkOrder>([
            SELECT Id, Odometer_Reading__c, Vehicle__c, Vehicle_Registration_Number__c,
            Vehicle__r.EngineNumber, Vehicle__r.VehicleIdentificationNumber, AccountId
            FROM WorkOrder 
            WHERE Id IN :jobCardIds AND Id NOT IN :jobCardToWarranty.keySet()
        ]);
        
        if (!jobCardsWithoutWarranty.isEmpty()) {
            List<Warranty_Prior__c> newWarranties = new List<Warranty_Prior__c>();
            for (WorkOrder wo : jobCardsWithoutWarranty.values()) {
                newWarranties.add(new Warranty_Prior__c(
                    Job_Card__c = wo.Id,
                    Motor_Number__c = wo.Vehicle__r.EngineNumber,
                    Odometer_Reading__c = wo.Odometer_Reading__c,
                    Registration_Number__c = wo.Vehicle_Registration_Number__c,
                    VIN__c = wo.Vehicle__r.VehicleIdentificationNumber,
                    Warranty_Prior_Date__c = Date.today(),
                    Status__c = 'Approved',
                    Total_Claim_Amount__c = 0
                ));
            }
            insert newWarranties;
            
            // Add new warranties to our map
            for (Warranty_Prior__c wp : newWarranties) {
                jobCardToWarranty.put(wp.Job_Card__c, wp);
            }
        }
        
        // Get template information
        Map<Id, Id> versionToTemplateId = new Map<Id, Id>();
        for (ActionPlanTemplateVersion v : [
            SELECT Id, ActionPlanTemplateId 
            FROM ActionPlanTemplateVersion 
            WHERE Id IN :templateVersionIds
        ]) {
            versionToTemplateId.put(v.Id, v.ActionPlanTemplateId);
        }
        
        Set<Id> templateIds = new Set<Id>(versionToTemplateId.values());
        
        System.debug('--------------------- templateIds ---------------------- : ' + templateIds);
        // Get required products from templates
        Map<Id, List<Required_Product__c>> templateProducts = new Map<Id, List<Required_Product__c>>();
        for (Required_Product__c rp : [
            SELECT Id, Name, Product__c, Quantity__c, Action_Plan_Template__c  
            FROM Required_Product__c 
            WHERE Action_Plan_Template__c IN :templateIds
        ]) {
            if (!templateProducts.containsKey(rp.Action_Plan_Template__c)) {
                templateProducts.put(rp.Action_Plan_Template__c, new List<Required_Product__c>());
            }
            templateProducts.get(rp.Action_Plan_Template__c).add(rp);
        }
        System.debug('--------------------- templateProducts ---------------------- : ' + templateProducts);
        
        // Get required labours from templates
        Map<Id, List<Required_Labour__c>> templateLabour = new Map<Id, List<Required_Labour__c>>();
        for (Required_Labour__c rl : [
            SELECT Id, Name, Code_Set__c, Action_Plan_Template__c 
            FROM Required_Labour__c 
            WHERE Action_Plan_Template__c IN :templateIds
        ]) {
            if (!templateLabour.containsKey(rl.Action_Plan_Template__c)) {
                templateLabour.put(rl.Action_Plan_Template__c, new List<Required_Labour__c>());
            }
            templateLabour.get(rl.Action_Plan_Template__c).add(rl);
        }
        
        // Create work order line items (parts) and work plans (labours)
        List<WorkOrderLineItem> newLineItems = new List<WorkOrderLineItem>();
        List<WorkPlan> newLabourItems = new List<WorkPlan>();
        
        for (ActionPlan ap : actionPlanMap.values()) {
            Id tmplId = versionToTemplateId.get(ap.ActionPlanTemplateVersionId);
            Id jobId = ap.Job_Card__c;
            Id warrantyId = jobCardToWarranty.containsKey(jobId) ? jobCardToWarranty.get(jobId).Id : null;
            
            // Create parts
            List<Required_Product__c> products = templateProducts.containsKey(tmplId)
                ? templateProducts.get(tmplId)
                : new List<Required_Product__c>();
            
            System.debug('--------------------- products ---------------------- : ' + products);
            
            for (Required_Product__c p : products) {
                if (p.Product__c != null) {
                    newLineItems.add(new WorkOrderLineItem(
                        WorkOrderId = jobId,
                        Description = p.Name,
                        RR_Product__c = p.Product__c,
                        Quantity = p.Quantity__c,
                        UnitPrice = 0,
                        Status = 'Approved',
                        RR_Parts_Category__c = 'River Warranty: Field Fix',
                        Warranty_Prior__c = warrantyId  // Associate with warranty
                    ));
                }
            }
            
            // Create labours
            List<Required_Labour__c> labours = templateLabour.containsKey(tmplId)
                ? templateLabour.get(tmplId)
                : new List<Required_Labour__c>();
            
            for (Required_Labour__c l : labours) {
                newLabourItems.add(new WorkPlan(
                    Name = l.Name,
                    WorkOrderId = jobId,
                    RR_Labour_Code__c = l.Code_Set__c,
                    RR_Labour_Category__c = 'River Warranty: Field Fix',
                    Status__c = 'Approved',
                    Warranty_Prior__c = warrantyId  // Associate with warranty
                ));
            }
        }
        
        // Insert parts and labours
        if (!newLabourItems.isEmpty()) {
            insert newLabourItems;
        }
        if (!newLineItems.isEmpty()) {
            insert newLineItems;
        }
        
        // Create claims and claim items
        Map<Id, WorkOrder> jobCards = new Map<Id, WorkOrder>([
            SELECT Id, AccountId, Vehicle__c FROM WorkOrder WHERE Id IN :jobCardIds
        ]);
        
        // check existing claims
        Map<Id, Claim> existingClaimsMap = new Map<Id, Claim>();
        for (Claim c : [
            SELECT Id, Job_Card__c 
            FROM Claim 
            WHERE Job_Card__c IN :jobCardIds
        ]) {
            existingClaimsMap.put(c.Job_Card__c, c);
        }
        
        List<Claim> newClaims = new List<Claim>();
        Map<Id, Id> jobCardToClaimId = new Map<Id, Id>();
        
        for (Id jobId : jobCardIds) {
            WorkOrder wo = jobCards.get(jobId);
            Warranty_Prior__c wp = jobCardToWarranty.get(jobId);
            String warrantyName = '';
            List<Warranty_Prior__c> warranties = [
                SELECT Id, Name FROM Warranty_Prior__c WHERE Job_Card__c = :jobId LIMIT 1
            ];
            
            if (!warranties.isEmpty()) {
                warrantyName = warranties[0].Name;
            }
            System.debug('warrantyName  '+warrantyName);
            System.debug('wp.Name  '+wp.Name);
            System.debug('wp.Name  '+wp);
            if (existingClaimsMap.containsKey(jobId)) {
                // Use existing claim
                jobCardToClaimId.put(jobId, existingClaimsMap.get(jobId).Id);
            } else {
                // Create a new claim
                Claim c = new Claim(
                    Name = 'Claim - ' + warrantyName,
                    AccountId = wo.AccountId,
                    By_Pass__c = true,
                    Vehicle__c = wo.Vehicle__c,
                    Job_Card__c = wo.Id,
                    Warranty_Prior__c = wp != null ? wp.Id : null,
                    Status = 'Draft'
                );
                newClaims.add(c);
            }
        }
        
        // Insert only new Claims
        if (!newClaims.isEmpty()) {
            insert newClaims;
            for (Claim c : newClaims) {
                jobCardToClaimId.put(c.Job_Card__c, c.Id);
            }
        }
        
        
        
        // Create claim items
        List<ClaimItem> claimItems = new List<ClaimItem>();
        for (WorkOrderLineItem part : newLineItems) {
            Id claimId = jobCardToClaimId.get(part.WorkOrderId);
            claimItems.add(new ClaimItem(
                Name = part.Description,
                ClaimId = claimId,
                Part__c = part.Id,
                Quantity__c = part.Quantity,
                FaultDate = Date.today(),
                Status__c = 'Pending',
                Claim_Type__c = 'Part'
            ));
        }
        
        for (WorkPlan labour : newLabourItems) {
            Id claimId = jobCardToClaimId.get(labour.WorkOrderId);
            claimItems.add(new ClaimItem(
                Name = labour.Name,
                ClaimId = claimId,
                FaultDate = Date.today(),
                Status__c = 'Pending',
                Claim_Type__c = 'Labour',
                Labour_Code__c = labour.Id
            ));
        }
        
        if (!claimItems.isEmpty()) {
            insert claimItems;
        }
    }
    
}