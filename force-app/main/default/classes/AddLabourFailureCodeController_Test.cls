@isTest
private class AddLabourFailureCodeController_Test {
    
    @testSetup
    static void setupTestData() {
        // Create TFR with VIN cutoff
        TFR__c tfr = new TFR__c(
            VIN_Start__c = 'P7BAAAXX1GT033277',
            Is_Active__c = true
        );
        insert tfr;
        
        // Create CodeSet for Labour Effects
        CodeSet cs = new CodeSet(
            Name = 'Test Labour CodeSet',
            Code = 'LAB-1001',
            IsActive = true
        );
        insert cs;
        
        // Create TFR Labour Effect
        TFR_Labour_Effect__c labourEffect = new TFR_Labour_Effect__c(
            Code_Set__c = cs.Id,
            TFR__c = tfr.Id
        );
        insert labourEffect;
        
        // Create Active Failure Code for Labour
        Failure_Code__c fcActive = new Failure_Code__c(
            Name = 'FC_LABOUR_ACTIVE',
            Batch_Size__c = 5,
            Is_Active__c = true,
            TFR_Labour_Effect__c = labourEffect.Id,
            VIN_Cut_off__c = tfr.Id
        );
        insert fcActive;
        
        // Create Inactive Failure Code for Labour
        Failure_Code__c fcInactive = new Failure_Code__c(
            Name = 'FC_LABOUR_INACTIVE',
            Batch_Size__c = 5,
            Is_Active__c = false,
            TFR_Labour_Effect__c = labourEffect.Id,
            VIN_Cut_off__c = tfr.Id
        );
        insert fcInactive;
    }
    
    // Test successful creation of new labour failure code with new VIN
    @isTest
    static void testCreatePostVINFCLabourVIN_SuccessNewVIN() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            'NEW_FC_LABOUR_001',
            cs.Id,
            'P7BAAAXX1GT033278', // New VIN
            10
        );
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Operation should succeed for new labour failure code');
        System.assertNotEquals(null, result.recordId, 'Should return record ID');
    }
    
    @isTest
    static void testCreatePostVINFCLabourVIN_SuccessHigherVin() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            'FC_LABOUR_ACTIVE',
            cs.Id,
            'P7BAAAXX1GT033279', // Higher VIN
            10
        );
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Operation should succeed for new labour failure code');
        System.assertNotEquals(null, result.recordId, 'Should return record ID');
    }
    
    // Test creation when labour failure code already exists with same VIN
    @isTest
    static void testCreatePostVINFCLabourVIN_ExistingSameVIN() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        Failure_Code__c existingFC = [SELECT Id, Name FROM Failure_Code__c WHERE Name = 'FC_LABOUR_ACTIVE' LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            'FC_LABOUR_ACTIVE',
            cs.Id,
            'P7BAAAXX1GT033277', // Same VIN as existing
            10
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess, 'Should fail with existing VIN');
    }
    
    // Test creation when labour failure code exists with lower VIN
    @isTest
    static void testCreatePostVINFCLabourVIN_ExistingLowerVIN() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            'FC_LABOUR_ACTIVE',
            cs.Id,
            'P7BAAAXX1GT033276', // Lower VIN than existing
            10
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess, 'Should fail with lower VIN');
    }
    
    // Test creation without VIN (null VIN)
    @isTest
    static void testCreatePostVINFCLabourVIN_NoVIN() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            'NEW_FC_LABOUR_NO_VIN',
            cs.Id,
            null, // No VIN
            15
        );
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Should succeed without VIN');
    }
    
    // Test with invalid inputs
    @isTest
    static void testCreatePostVINFCLabourVIN_InvalidInputs() {
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            '', // Empty FC name
            '', // Empty labour code
            null,
            0
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess, 'Should fail with invalid inputs');
    }
    
    // Test with non-existent labour code
    @isTest
    static void testCreatePostVINFCLabourVIN_InvalidLabourCode() {
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            'NEW_FC_LABOUR',
            'invalid_labour_code_id',
            'P7BAAAXX1GT033277',
            10
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess, 'Should fail with invalid labour code');
    }
    
    // Test input validation - success case
    @isTest
    static void testValidateInputs_Success() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.validateInputs(
            'VALID_FC_LABOUR',
            cs.Id,
            'P7BAAAXX1GT033277'
        );
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Validation should succeed');
    }
    
    @isTest
    static void testValidateInputs_Success1() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.validateInputs(
            '',
            cs.Id,
            'P7BAAAXX1GT033277'
        );
        Test.stopTest();
    }
    
    @isTest
    static void testValidateInputs_Success2() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.validateInputs(
            'LABOUR_CODE',
            '',
            'P7BAAAXX1GT033277'
        );
        Test.stopTest();
    }
    
    @isTest
    static void testValidateInputs_Success3() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.validateInputs(
            '',
            '',
            ''
        );
        Test.stopTest();
    }
    
    @isTest
    static void testValidateInputs_Success4() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.validateInputs(
            '',
            '',
            'P7BAAAXX1GT033277'
        );
        Test.stopTest();
    }
    
    
    /*
    // Test VIN creation helper method
    @isTest
    static void testCheckAndCreateVIN() {
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.checkandCreateVIN('P7BAAAXX1GT033279');
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'VIN creation should succeed');
    }
    
    // Test VIN creation with existing VIN
    @isTest
    static void testCheckAndCreateVIN_Existing() {
        TFR__c existingTFR = [SELECT Id, VIN_Start__c FROM TFR__c LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.checkandCreateVIN(existingTFR.VIN_Start__c);
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Should find existing VIN');
    }
    
    // Test labour effect creation
    @isTest
    static void testCheckLabourEffect() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        TFR__c tfr = [SELECT Id FROM TFR__c LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.checkLabourEffect(cs.Id, tfr.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Labour effect check should succeed');
    }
    
    // Test labour effect with invalid labour code
    @isTest
    static void testCheckLabourEffect_InvalidLabourCode() {
        TFR__c tfr = [SELECT Id FROM TFR__c LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.checkLabourEffect('invalid_labour_code', tfr.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess, 'Should fail with invalid labour code');
    }
    
    // Test labour effect with inactive labour code
    @isTest
    static void testCheckLabourEffect_InactiveLabourCode() {
        // Create inactive CodeSet
        CodeSet inactiveCS = new CodeSet(
            Name = 'Inactive Labour CodeSet',
            Code = 'LAB-1002',
            IsActive = false
        );
        insert inactiveCS;
        
        TFR__c tfr = [SELECT Id FROM TFR__c LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.checkLabourEffect(inactiveCS.Id, tfr.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess, 'Should fail with inactive labour code');
    }
    
    // Test failure code creation helper
    @isTest
    static void testCreateFailureCode() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        TFR__c tfr = [SELECT Id FROM TFR__c LIMIT 1];
        TFR_Labour_Effect__c labourEffect = [SELECT Id FROM TFR_Labour_Effect__c LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createFailureCode(
            'TEST_FC_LABOUR_CREATE',
            labourEffect.Id,
            tfr.Id,
            20
        );
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Failure code creation should succeed');
    }
    
    // Test input validation - success case
    @isTest
    static void testValidateInputs_Success() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.validateInputs(
            'VALID_FC_LABOUR',
            cs.Id,
            'P7BAAAXX1GT033277'
        );
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Validation should succeed');
    }
    
    // Test input validation - success case without VIN
    @isTest
    static void testValidateInputs_SuccessNoVIN() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.validateInputs(
            'VALID_FC_LABOUR',
            cs.Id,
            null
        );
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Validation should succeed without VIN');
    }
    
    // Test input validation - failure cases
    @isTest
    static void testValidateInputs_Failures() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        // Test empty FC name
        AddLabourFailureCodeController.OperationResult result1 = AddLabourFailureCodeController.validateInputs('', cs.Id, 'P7BAAAXX1GT033277');
        System.assertEquals(false, result1.isSuccess, 'Should fail with empty FC name');
        
        // Test empty labour code
        AddLabourFailureCodeController.OperationResult result2 = AddLabourFailureCodeController.validateInputs('TEST_FC_LABOUR', '', 'P7BAAAXX1GT033277');
        System.assertEquals(false, result2.isSuccess, 'Should fail with empty labour code');
        
        // Test invalid labour code
        AddLabourFailureCodeController.OperationResult result3 = AddLabourFailureCodeController.validateInputs('TEST_FC_LABOUR', 'invalid_labour_code', 'P7BAAAXX1GT033277');
        System.assertEquals(false, result3.isSuccess, 'Should fail with invalid labour code');
    }
    
    // Test input validation with invalid VIN format
    @isTest
    static void testValidateInputs_InvalidVIN() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.validateInputs(
            'TEST_FC_LABOUR',
            cs.Id,
            'INVALID_VIN_FORMAT' // Invalid VIN format
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess, 'Should fail with invalid VIN format');
    }
    
    // Test checkFailureCode method with all parameters
    @isTest
    static void testCheckFailureCode_WithParams() {
        Failure_Code__c oldFC = [SELECT Id FROM Failure_Code__c WHERE Name = 'FC_LABOUR_ACTIVE' LIMIT 1];
        TFR_Labour_Effect__c labourEffect = [SELECT Id FROM TFR_Labour_Effect__c LIMIT 1];
        TFR__c tfr = [SELECT Id FROM TFR__c LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.checkFailureCode(
            oldFC, 
            'NEW_FC_TEST', 
            labourEffect.Id, 
            tfr.Id, 
            15
        );
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Should successfully create new failure code and deactivate old one');
    }
    
    // Test checkFailureCode method with only TFR ID
    @isTest
    static void testCheckFailureCode_WithTFROnly() {
        Failure_Code__c oldFC = [SELECT Id FROM Failure_Code__c WHERE Name = 'FC_LABOUR_ACTIVE' LIMIT 1];
        TFR__c tfr = [SELECT Id FROM TFR__c LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.checkFailureCode(oldFC, tfr.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.isSuccess, 'Should successfully update failure code with VIN cutoff');
    }
    
    // Test exception handling in main method
    @isTest
    static void testCreatePostVINFCLabourVIN_Exception() {
        // Force an exception by passing invalid parameters
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            null, // This should cause exception
            null,
            null,
            null
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess, 'Should handle exception gracefully');
    }
    
    // Test the OperationResult inner class constructors
    @isTest
    static void testOperationResultConstructors() {
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result1 = new AddLabourFailureCodeController.OperationResult(true, 'Test message');
        AddLabourFailureCodeController.OperationResult result2 = new AddLabourFailureCodeController.OperationResult(false, 'Test message', 'recordId', 'failureCodeName');
        Test.stopTest();
        
        System.assertEquals(true, result1.isSuccess, 'First constructor should set success flag');
        System.assertEquals('Test message', result1.message, 'First constructor should set message');
        System.assertEquals('recordId', result2.recordId, 'Second constructor should set recordId');
        System.assertEquals('failureCodeName', result2.failureCodeName, 'Second constructor should set failureCodeName');
    }
    
    // Test scenario where VIN comparison returns 1 (new VIN is greater)
    @isTest
    static void testCreatePostVINFCLabourVIN_NewVINGreater() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        // Mock the VINCutOffManagement to return comparison result 1
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            'FC_LABOUR_ACTIVE',
            cs.Id,
            'P7BAAAXX1GT033999', // Higher VIN
            10
        );
        Test.stopTest();
        
        // This test might need proper mocking of VINCutOffManagement
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    // Test scenario where VIN comparison returns -1 (new VIN is older)
    @isTest
    static void testCreatePostVINFCLabourVIN_NewVINOlder() {
        CodeSet cs = [SELECT Id FROM CodeSet LIMIT 1];
        
        Test.startTest();
        AddLabourFailureCodeController.OperationResult result = AddLabourFailureCodeController.createPostVINFCLabourVIN(
            'FC_LABOUR_ACTIVE',
            cs.Id,
            'P7BAAAXX1GT033000', // Lower VIN
            10
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess, 'Should fail with older VIN');
    }
	*/
}