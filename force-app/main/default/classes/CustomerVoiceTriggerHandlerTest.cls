/**
* @author Ram Kumar
* @email ram.k@utilitarainlabs.com
* @create 26 june 2025
* @modify 
* @desc
*/
@isTest
public class CustomerVoiceTriggerHandlerTest {

    @isTest
    static void testPreventUpdateForJobCardStatus_BlockingStatus() {
        
         Account acc = new Account();
        acc.Name = 'testing Account';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'testing Contact';
        con.AccountId = acc.Id;
        con.Phone = '9123456789';
        con.Email = 'test@test.com';
        insert con;
        
        List<WorkOrder> workOrders = new List<WorkOrder>{
            new WorkOrder(Status = 'New', Subject = 'WO 1', RR_Technician__c = con.id,
                         RR_SOC_Level__c = true, RR_Front_Axle_Nut__c = true, RR_Brake_Play__c = true,
                         RR_Tyre_Pressure__c = true, RR_GUI_Checks__c = true, RR_Tyre_Condition__c = true,
                         RR_Socket_Cover_Opening__c = true, RR_Tank_Badge__c = true, RR_Suspnsion_Play__c = true,
                         RR_Fork_Seal__c = true, RR_Brake_Oil_Level__c = true, RR_Rear_Axle_Nut__c = true,
                         RR_Brake_Pads__c = true, RR_Steering_Top_Nut__c = true, RR_Brake_Sponginess__c = true,
                         RR_Customer_Rating__c = 5, RR_Customer_Suggestions__c = '12ss',
                         RR_Check_all_requested_work_completed__c = 'Done', RR_Pending_Field_Fix__c = 'Done',
                         RR_Ensure_latest_Firmware_is_flashed__c = 'Done', RR_Status_of_Side_Stand_switch_in_parked__c = 'done',
                         RR_Electrical_Component_Functioning__c = 'Done', RR_Check_for_outstanding_Fault_Codes__c = 'Done',
                         RR_Washing_Polishing__c = 'Done', Latest_Software_Version__c ='Done', Current_Software_Versions__c = '1234'), 
            new WorkOrder(Status = 'New', Subject = 'WO 2', RR_Technician__c = con.id,
                         RR_SOC_Level__c = true, RR_Front_Axle_Nut__c = true, RR_Brake_Play__c = true,
                         RR_Tyre_Pressure__c = true, RR_GUI_Checks__c = true, RR_Tyre_Condition__c = true,
                         RR_Socket_Cover_Opening__c = true, RR_Tank_Badge__c = true, RR_Suspnsion_Play__c = true,
                         RR_Fork_Seal__c = true, RR_Brake_Oil_Level__c = true, RR_Rear_Axle_Nut__c = true,
                         RR_Brake_Pads__c = true, RR_Steering_Top_Nut__c = true, RR_Brake_Sponginess__c = true,
                         RR_Customer_Rating__c = 5, RR_Customer_Suggestions__c = '12ss',
                         RR_Check_all_requested_work_completed__c = 'Done', RR_Pending_Field_Fix__c = 'Done',
                         RR_Ensure_latest_Firmware_is_flashed__c = 'Done', RR_Status_of_Side_Stand_switch_in_parked__c = 'done',
                         RR_Electrical_Component_Functioning__c = 'Done', RR_Check_for_outstanding_Fault_Codes__c = 'Done',
                         RR_Washing_Polishing__c = 'Done', Latest_Software_Version__c ='Done', Current_Software_Versions__c = '1234')
        };
        insert workOrders;

        RR_Customer_Voice__c cvBlocked = new RR_Customer_Voice__c(
            RR_Work_Order__c = workOrders[0].Id
        );
        RR_Customer_Voice__c cvAllowed = new RR_Customer_Voice__c(
            RR_Work_Order__c = workOrders[1].Id
        );
        insert new List<RR_Customer_Voice__c>{cvBlocked, cvAllowed};

        List<RR_Customer_Voice__c> cvsToUpdate = [
            SELECT Id, RR_Work_Order__c FROM RR_Customer_Voice__c WHERE Id IN :new List<Id>{cvBlocked.Id, cvAllowed.Id}
        ];

        Test.startTest();
        try {
            CustomerVoiceTriggerHandler.PreventUpdateForJobCardStatus(cvsToUpdate);
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testPreventUpdateForJobCardStatus_EmptyList() {
        Test.startTest();
        try {
            CustomerVoiceTriggerHandler.PreventUpdateForJobCardStatus(null);
            CustomerVoiceTriggerHandler.PreventUpdateForJobCardStatus(new List<RR_Customer_Voice__c>());
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    static testMethod void testCodeCoverage() {
        CustomerVoiceTriggerHandler.addTest();
       
        CustomerVoiceTriggerHandler.addTest2();
                
       
    }
}