@isTest
public class VINCutOffManagement_Test {
	
    @isTest
    private static void test_VINCutOffManagement(){
        VINCutOffManagement.compareVINFormat('P7BAAAXX1GT033277', 'P7BAAAXX1GT033278');
    }
    
    @isTest
    private static void test_VINCutOffManagement_BlankValues(){
        VINCutOffManagement.compareVINFormat('', '');
    }
    
    @isTest
    private static void test_VINCutOffManagement_CheckLength(){
        VINCutOffManagement.compareVINFormat('P7BA', 'P7BA');
    }
    
    @isTest
    private static void test_VINCutOffManagement_validateVIN(){
        VINCutOffManagement.validateVIN('P7BA');
    }
}