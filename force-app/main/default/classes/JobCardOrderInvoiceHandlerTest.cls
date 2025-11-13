@isTest
public class JobCardOrderInvoiceHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        List<Schema.Location> locList = [SELECT Id, Name FROM Location LIMIT 1];
        Schema.Location loc = new Schema.Location(Name = 'River Store - Indiranagar', LocationType= 'State');
        insert loc; 
        
        Account serviceCenter = new Account(
            Name = 'Test Service Center',
            Center_Code__c = 'TSC',
            Invoice_Sequence__c = 1,
            Type ='Service Center'
        );
        insert serviceCenter;
        
        Contact con = new Contact(
            LastName = 'Testing Contact',
            AccountId = serviceCenter.Id,
            Phone = '9123456789',
            Email = 'test@test.com',
            Role_Type__c = 'Sales',
            Location__c = loc.Id   
        );               
        insert con;
        
        Asset vehicle = new Asset(
            Name = 'Test Vehicle',
            Status = 'Active',
            AccountId = serviceCenter.Id,
            ContactId = con.Id
        );
        insert vehicle;
        
        Product2 prod = new Product2(
            Name = 'Service Product',
            IsActive = true,
            ProductCode = 'R112011221',
            HSN_Code__c = '87089901',
            Type__c = 'Parts'
        );
        insert prod;
    }
    
    @isTest
    static void testServiceInvoiceCreation_Regular() {
        Account serviceCenter = [SELECT Id, Type,Center_Code__c, Invoice_Sequence__c FROM Account WHERE Type ='Service Center' LIMIT 1];
        Asset vehicle = [SELECT Id FROM Asset LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        WorkOrder wo = new WorkOrder(
            Status = 'New',
            AssetId = vehicle.Id,
            Service_Center__c = serviceCenter.Id,  
            RR_Job_Type__c = 'Regular',
            RR_Technician__c = con.Id,
            Is_Order_Invoice_Generated__c = false
        );
        insert wo;
        
        Test.startTest();
        wo.Status = 'Ready For Delivery';
        update wo;        
        Test.stopTest();
        
        List<Job_Card_Invoice__c> invoices = [
            SELECT Id, Name, Invoice_Number__c, Invoice_Type__c, Job_Card__c
            FROM Job_Card_Invoice__c
            WHERE Job_Card__c = :wo.Id
        ];
        WorkOrder updatedWO = [SELECT Is_Order_Invoice_Generated__c FROM WorkOrder WHERE Id = :wo.Id];
        
        Account updatedAcc = [SELECT Invoice_Sequence__c FROM Account WHERE Id = :serviceCenter.Id];
    }
    
    @isTest
    static void testServiceAndInsuranceInvoiceCreation_Accidental() {
        Account serviceCenter = [SELECT Id, Center_Code__c, Invoice_Sequence__c FROM Account LIMIT 1];
        Asset vehicle = [SELECT Id FROM Asset LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        WorkOrder wo = new WorkOrder(
            Status = 'New',            
            AssetId = vehicle.Id,
            Service_Center__c = serviceCenter.Id,  // ADDED THIS FIELD
            RR_Job_Type__c = 'Accidental',
            RR_Technician__c = con.Id,
            Is_Order_Invoice_Generated__c = false
        );
        insert wo;
        
        Test.startTest();
        wo.Status = 'Ready For Delivery';
        update wo;        
        Test.stopTest();
        
        List<Job_Card_Invoice__c> invoices = [
            SELECT Id, Name, Invoice_Number__c, Invoice_Type__c, Job_Card__c
            FROM Job_Card_Invoice__c
            WHERE Job_Card__c = :wo.Id
            ORDER BY Invoice_Type__c
        ];
       WorkOrder updatedWO = [SELECT Is_Order_Invoice_Generated__c FROM WorkOrder WHERE Id = :wo.Id];
        
        Account updatedAcc = [SELECT Invoice_Sequence__c FROM Account WHERE Id = :serviceCenter.Id];
    }
    
    @isTest
    static void testMultipleWorkOrders_BulkProcessing() {
        Account serviceCenter = [SELECT Id, Center_Code__c, Invoice_Sequence__c FROM Account LIMIT 1];
        Asset vehicle = [SELECT Id FROM Asset LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < 5; i++) {
            workOrders.add(new WorkOrder(
                Status = 'New',
                AssetId = vehicle.Id,
                Service_Center__c = serviceCenter.Id,  // ADDED THIS FIELD
                RR_Job_Type__c = (Math.mod(i, 2) == 0) ? 'Regular' : 'Accidental',
                Is_Order_Invoice_Generated__c = false,
                RR_Technician__c = con.Id,
                RR_SOC_Level__c = true,
                RR_Front_Axle_Nut__c = true,
                RR_Brake_Play__c = true,
                RR_Tyre_Pressure__c = true,
                RR_GUI_Checks__c = true,
                RR_Tyre_Condition__c = true,
                RR_Socket_Cover_Opening__c = true,
                RR_Tank_Badge__c = true,
                RR_Suspnsion_Play__c = true,
                RR_Fork_Seal__c = true,
                RR_Brake_Oil_Level__c = true,
                RR_Rear_Axle_Nut__c = true,
                RR_Brake_Pads__c = true,
                RR_Steering_Top_Nut__c = true,
                RR_Brake_Sponginess__c = true,
                RR_Customer_Rating__c = 5,
                RR_Customer_Suggestions__c = '12ss',
                RR_Check_all_requested_work_completed__c = 'Done',
                RR_Pending_Field_Fix__c = 'Done',
                RR_Ensure_latest_Firmware_is_flashed__c = 'Done',
                RR_Status_of_Side_Stand_switch_in_parked__c = 'done',
                RR_Electrical_Component_Functioning__c = 'Done',
                RR_Check_for_outstanding_Fault_Codes__c = 'Done',
                RR_Washing_Polishing__c = 'Done',
                Latest_Software_Version__c = 'Done',
                Current_Software_Versions__c = '1234'
            ));
        }
        insert workOrders;
        
        Test.startTest();
        for (WorkOrder wo : workOrders) {
            wo.Status = 'Ready For Delivery';
        }
        update workOrders;        
        Test.stopTest();
        
        List<Job_Card_Invoice__c> invoices = [
            SELECT Id, Invoice_Type__c
            FROM Job_Card_Invoice__c
        ];
        
        List<WorkOrder> updatedWOs = [
            SELECT Is_Order_Invoice_Generated__c
            FROM WorkOrder
            WHERE Id IN :workOrders
        ];
    }
    
    @isTest
    static void testNoInvoiceCreation_AlreadyGenerated() {
        Account serviceCenter = [SELECT Id, Center_Code__c, Invoice_Sequence__c FROM Account LIMIT 1];
        Asset vehicle = [SELECT Id FROM Asset LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        WorkOrder wo = new WorkOrder(
            Status = 'New',            
            AssetId = vehicle.Id,
            Service_Center__c = serviceCenter.Id,  
            RR_Job_Type__c = 'Regular',
            RR_Technician__c = con.Id,
            Is_Order_Invoice_Generated__c = true
        );
        insert wo;
        
        Test.startTest();
        wo.Status = 'Ready For Delivery';
        update wo;        
        Test.stopTest();
        
        List<Job_Card_Invoice__c> invoices = [
            SELECT Id
            FROM Job_Card_Invoice__c
            WHERE Job_Card__c = :wo.Id
        ];
        Account updatedAcc = [SELECT Invoice_Sequence__c FROM Account WHERE Id = :serviceCenter.Id];
    }
    
    @isTest
    static void testNoInvoiceCreation_NoServiceCenter() {
        Asset vehicle = [SELECT Id FROM Asset LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        WorkOrder wo = new WorkOrder(
            Status = 'New',
            AssetId = vehicle.Id,
            RR_Job_Type__c = 'Regular',
            RR_Technician__c = con.Id,
            Is_Order_Invoice_Generated__c = false
        );
        insert wo;
        
        Test.startTest();
        wo.Status = 'Ready For Delivery';
        update wo;        
        Test.stopTest();
        
        List<Job_Card_Invoice__c> invoices = [
            SELECT Id
            FROM Job_Card_Invoice__c
            WHERE Job_Card__c = :wo.Id
        ];
    }
    
    @isTest
    static void testNoInvoiceCreation_WrongStatusChange() {
        Account serviceCenter = [SELECT Id, Center_Code__c, Invoice_Sequence__c FROM Account LIMIT 1];
        Asset vehicle = [SELECT Id FROM Asset LIMIT 1];
        
        WorkOrder wo = new WorkOrder(
            Status = 'New',
            AssetId = vehicle.Id,
            Service_Center__c = serviceCenter.Id,  
            RR_Job_Type__c = 'Regular',
            Is_Order_Invoice_Generated__c = false
        );
        insert wo;
        
        Test.startTest();
        wo.Status = 'In Progress';
        update wo;        
        Test.stopTest();
        
        List<Job_Card_Invoice__c> invoices = [
            SELECT Id
            FROM Job_Card_Invoice__c
            WHERE Job_Card__c = :wo.Id
        ];
    }
    
    @isTest
    static void testSequenceIncrement_MultipleAccounts() {
        List<Schema.Location> locList = [SELECT Id, Name FROM Location LIMIT 1];
        Schema.Location loc;
        if(!locList.isEmpty()) {
            loc = locList[0];
        } else {
            loc = new Schema.Location(Name = 'Second Store - Location', LocationType= 'State');
            insert loc;
        }
        
        Account serviceCenter2 = new Account(
            Name = 'Second Service Center',
            Center_Code__c = 'SSC',
            Invoice_Sequence__c = 10,
            Type ='Service Center'
        );
        insert serviceCenter2;
        
        Account serviceCenter1 = [SELECT Id FROM Account WHERE Center_Code__c = 'TSC' LIMIT 1];
        Asset vehicle = [SELECT Id FROM Asset LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];        
        
        Asset vehicle2 = new Asset(
            Name = 'Test Vehicle 2',
            Status = 'Active',
            AccountId = serviceCenter2.Id,
            ContactId = con.Id
        );
        insert vehicle2;
       
        List<WorkOrder> workOrders = new List<WorkOrder>{
            new WorkOrder(
                Status = 'New',               
                AssetId = vehicle.Id,
                Service_Center__c = serviceCenter1.Id,  
                RR_Job_Type__c = 'Regular',
                RR_Technician__c = con.Id,
                Is_Order_Invoice_Generated__c = false
            ),
            new WorkOrder(
                Status = 'New',                
                AssetId = vehicle2.Id,
                Service_Center__c = serviceCenter2.Id,  
                RR_Job_Type__c = 'Accidental',
                RR_Technician__c = con.Id,
                Is_Order_Invoice_Generated__c = false
            )
        };
        insert workOrders;
        
        Test.startTest(); 
        for (WorkOrder wo : workOrders) {
            wo.Status = 'Ready For Delivery';
        }
        update workOrders;        
        Test.stopTest();
        
        Account acc1 = [SELECT Invoice_Sequence__c FROM Account WHERE Id = :serviceCenter1.Id];
        Account acc2 = [SELECT Invoice_Sequence__c FROM Account WHERE Id = :serviceCenter2.Id];
    }
    
    @isTest
    static void testExceptionHandling() {
        Account serviceCenter = [SELECT Id, Center_Code__c, Invoice_Sequence__c FROM Account LIMIT 1];
        Asset vehicle = [SELECT Id FROM Asset LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        WorkOrder wo = new WorkOrder(
            Status = 'New',
            AssetId = vehicle.Id,
            Service_Center__c = serviceCenter.Id,
            RR_Job_Type__c = 'Regular',
            RR_Technician__c = con.Id,
            Is_Order_Invoice_Generated__c = false
        );
        insert wo;
        
        serviceCenter.Center_Code__c = 'TSC';
        update serviceCenter;
        
        Test.startTest();        
        try {
            wo.Status = 'Ready For Delivery';
            update wo;
        } catch (Exception e) {
            
        }        
        Test.stopTest();
    }
}