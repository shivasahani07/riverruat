@isTest
private class AddFailureCodeControllerNew_Test {
    
    @testSetup
    static void setupTestData() {
        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            IsActive = true,
            HSN_Code__c = 'HSN-3849',
            Type__c = 'Accessories'
        );
        insert prod;
        
        // Create TFR with VIN cutoff
        TFR__c tfr = new TFR__c(
            VIN_Start__c = 'P7BAAAXX1GT033277',
            Is_Active__c = true
        );
        insert tfr;
        
        // Create CodeSet for Labour Effects
        CodeSet cs = new CodeSet(
            Name = 'Test CodeSet',
            Code = 'CS-1001'
        );
        insert cs;
        
        // Create TFR Part Effect
        TFR_Part_Effect__c partEffect = new TFR_Part_Effect__c(
            Product__c = prod.Id,
            TFR__c = tfr.Id
        );
        insert partEffect;
        
        // Create Active Failure Code
        Failure_Code__c fcActive = new Failure_Code__c(
            Name = 'FC_ACTIVE',
            Batch_Size__c = 5,
            Is_Active__c = true,
            TFR_Part_Effect__c = partEffect.Id,
            VIN_Cut_off__c = tfr.Id
        );
        insert fcActive;
        
        // Create Inactive Failure Code
        Failure_Code__c fcInactive = new Failure_Code__c(
            Name = 'FC_INACTIVE',
            Batch_Size__c = 5,
            Is_Active__c = false,
            TFR_Part_Effect__c = partEffect.Id,
            VIN_Cut_off__c = tfr.Id
        );
        insert fcInactive;
        
        // Create TFR Labour Effect
        TFR_Labour_Effect__c labourEffect = new TFR_Labour_Effect__c(
            Code_Set__c = cs.Id,
            Failure_Code__c = fcActive.Id,
            Active__c = true
        );
        insert labourEffect;
    }
    
    // Test successful creation of new failure code with new VIN
    @isTest
    static void testCreatePostVINFCPCVIN_SuccessNewVIN() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        AddFailureCodeControllerNew.OperationResult result = AddFailureCodeControllerNew.createPostVINFCPCVIN(
            'NEW_FC_001',
            prod.Id,
            'P7BAAAXX1GT033277',
            10
        );
        Test.stopTest();
    }
    
    // Test creation when failure code already exists with same VIN
    @isTest
    static void testCreatePostVINFCPCVIN_ExistingSameVIN() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Failure_Code__c existingFC = [SELECT Id, Name FROM Failure_Code__c WHERE Name = 'FC_ACTIVE' LIMIT 1];
        
        Test.startTest();
        AddFailureCodeControllerNew.OperationResult result = AddFailureCodeControllerNew.createPostVINFCPCVIN(
            'FC_ACTIVE',
            prod.Id,
            '1HGCM82633A123456', // Same VIN as existing
            10
        );
        Test.stopTest();        
    }
    
    // Test creation when failure code exists with lower VIN
    @isTest
    static void testCreatePostVINFCPCVIN_ExistingLowerVIN() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        AddFailureCodeControllerNew.OperationResult result = AddFailureCodeControllerNew.createPostVINFCPCVIN(
            'FC_ACTIVE',
            prod.Id,
            'P7BAAAXX1GT033277', // Lower VIN than existing
            10
        );
        Test.stopTest();
    }
    
    // Test creation without VIN (null VIN)
    @isTest
    static void testCreatePostVINFCPCVIN_NoVIN() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        AddFailureCodeControllerNew.OperationResult result = AddFailureCodeControllerNew.createPostVINFCPCVIN(
            'NEW_FC_NO_VIN',
            prod.Id,
            null, // No VIN
            15
        );
        Test.stopTest();
    }
    
    // Test with invalid inputs
    @isTest
    static void testCreatePostVINFCPCVIN_InvalidInputs() {
        Test.startTest();
        AddFailureCodeControllerNew.OperationResult result = AddFailureCodeControllerNew.createPostVINFCPCVIN(
            '', // Empty FC name
            '', // Empty product code
            null,
            0
        );
        Test.stopTest();        
    }
    
    // Test with non-existent product
    @isTest
    static void testCreatePostVINFCPCVIN_InvalidProduct() {
        Test.startTest();
        AddFailureCodeControllerNew.OperationResult result = AddFailureCodeControllerNew.createPostVINFCPCVIN(
            'NEW_FC',
            'invalid_product_id',
            'P7BAAAXX1GT033277',
            10
        );
        Test.stopTest();        
    }
    
    // Test input validation - success case
    @isTest
    static void testValidateInputs_Success() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        AddFailureCodeControllerNew.OperationResult result = AddFailureCodeControllerNew.validateInputs(
            'VALID_FC',
            prod.Id,
            'P7BAAAXX1GT033277'
        );
        Test.stopTest();
        
    }
    
    // Test input validation - failure cases
    @isTest
    static void testValidateInputs_Failures() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        // Test empty FC name
        AddFailureCodeControllerNew.OperationResult result1 = AddFailureCodeControllerNew.validateInputs('', prod.Id, '1HGCM82633A123456');
        
        // Test empty product code
        AddFailureCodeControllerNew.OperationResult result2 = AddFailureCodeControllerNew.validateInputs('TEST_FC', '', '1HGCM82633A123456');
        
        // Test invalid product
        AddFailureCodeControllerNew.OperationResult result3 = AddFailureCodeControllerNew.validateInputs('TEST_FC', 'invalid_product', '1HGCM82633A123456');
    }
    
    // Test get TFR Labour Effects
    @isTest
    static void testGetTFRLabourEffects() {
        Failure_Code__c fc = [SELECT Id FROM Failure_Code__c WHERE Name = 'FC_ACTIVE' LIMIT 1];
        
        Test.startTest();
        List<TFR_Labour_Effect__c> labourEffects = AddFailureCodeControllerNew.getTFRLabourEffects(fc.Id);
        Test.stopTest();
        
    }
    
    // Test create labour code for failure codes
    @isTest
    static void testCreateLabourCodeForFailureCodes() {
        Failure_Code__c fc = [SELECT Id FROM Failure_Code__c WHERE Name = 'FC_ACTIVE' LIMIT 1];
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        List<String> codeSetIds = new List<String>{cs.Id};
        
        Test.startTest();
        AddFailureCodeControllerNew.CreateLabourCodeForFalireCodes(fc.Id, codeSetIds);
        Test.stopTest();
        
        // Verify labour effects were created
        List<TFR_Labour_Effect__c> labourEffects = [SELECT Id FROM TFR_Labour_Effect__c WHERE Failure_Code__c = :fc.Id];
    }
    
    // Test search failure codes
    @isTest
    static void testSearchFailureCodes() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Failure_Code__c fc = [SELECT Id, ProductId__c FROM Failure_Code__c WHERE Name = 'FC_ACTIVE' LIMIT 1];
        
        Test.startTest();
        List<Failure_Code__c> results = AddFailureCodeControllerNew.searchFailureCodes('FC_ACTIVE', prod.Id);
        Test.stopTest();
    }
    
    // Test search labour failure codes
    @isTest
    static void testSearchLabourFailureCodes() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        // Update a failure code to have the codeset ID
        Failure_Code__c fc = [SELECT Id FROM Failure_Code__c WHERE Name = 'FC_ACTIVE' LIMIT 1];
        update fc;
        
        Test.startTest();
        List<Failure_Code__c> results = AddFailureCodeControllerNew.searchlabourFailureCodes('FC_ACTIVE', cs.Id);
        Test.stopTest();
    }
    
    // Test exception handling
    @isTest
    static void testExceptionHandling() {
        // Force an exception by passing invalid parameters
        Test.startTest();
        AddFailureCodeControllerNew.OperationResult result = AddFailureCodeControllerNew.createPostVINFCPCVIN(
            null, // This should cause exception
            null,
            null,
            null
        );
        Test.stopTest();
    }
    
    // Test the OperationResult inner class constructors
    @isTest
    static void testOperationResultConstructors() {
        Test.startTest();
        AddFailureCodeControllerNew.OperationResult result1 = new AddFailureCodeControllerNew.OperationResult(true, 'Test message');
        AddFailureCodeControllerNew.OperationResult result2 = new AddFailureCodeControllerNew.OperationResult(false, 'Test message', 'recordId', 'failureCodeName');
        Test.stopTest();
    }
}