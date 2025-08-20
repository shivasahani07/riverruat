@RestResource(urlMapping='/EventGENOrder')
global class GEN3_EventOrder {
    @HttpPost
    global static void createOrder() { 
        RestRequest req = RestContext.request;
        system.debug(' req ===============>' + req);
        Blob body = req.requestBody;
        try {
            String requestString = req.requestBody != null ? req.requestBody.toString() : '';
            system.debug(' requestString ===============>' + requestString);
            if (String.isBlank(requestString)) {
                GEN3_Wrapper.setResponse(400, 'Empty request body', null);
                return;
            }
            
            GEN3_Wrapper.getOrder wrp = (GEN3_Wrapper.getOrder) JSON.deserialize(requestString, GEN3_Wrapper.getOrder.class);
            system.debug('Request Body: ' + requestString);
            system.debug('Request Body: ' + body);    
            
            String OrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();
            
            if(wrp.phone == null || String.isBlank(wrp.phone) || wrp.phone == '') {
                GEN3_Wrapper.setResponse(401, 'Please provide phone', null);
                return;
            }
            String phone = wrp.phone;
            
            Map<String, Object> responseData = new Map<String, Object>();
            List<Order> ordList = [SELECT Id, OwnerId, ContractId, AccountId, Pricebook2Id, OriginalOrderId, OpportunityId, RecordTypeId, EffectiveDate, EndDate, IsReductionOrder, Status, Description, 
                                   CustomerAuthorizedById, CustomerAuthorizedDate, CompanyAuthorizedById, CompanyAuthorizedDate, Type, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                                   BillingStateCode, BillingCountryCode, BillingLatitude, BillingLongitude, BillingGeocodeAccuracy, BillingAddress, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
                                   ShippingCountry, ShippingStateCode, ShippingCountryCode, ShippingLatitude, ShippingLongitude, ShippingGeocodeAccuracy, ShippingAddress, Name, PoDate, PoNumber, OrderReferenceNumber, 
                                   BillToContactId, ShipToContactId, ActivatedDate, ActivatedById, StatusCode, SalesAgreementId, OrderNumber, TotalAmount, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById,
                                   IsDeleted, SystemModstamp, LastViewedDate, LastReferencedDate, Additional_Discount__c, Approval_Status__c, Assigned_Vehicle__c, Booking_Amount__c, Booking_Payment_Id__c, Dealer__c,
                                   EMI_Amount__c, Eligible_For_Subsidy__c, Finance__c, Financed_Amount__c, Handling_Charges__c, Insurance_Amount__c, Insurance__c, Invoice_No__c, Loan_Start_Date__c, Offers_Amount__c,
                                   RTO_Charges__c, Subsidy_Amount__c, Tenure_Type__c, Tenure__c, Warranty_Amount__c, Warranty_Term__c, Website_Order_Id__c, Total_Amount_paid__c, Grand_Total__c, Remaining_Amount__c, 
                                   ADD_On__c, Cancel_Order__c, Company_warehouse__c, Dealer_Warehouse__c, Down_Payment__c, Extended_Warranty__c, Manufacture_Unit__c, Notify_By_Email__c, Notify_By_SMS__c, Order_Available__c,
                                   Order_Status__c, Payment_Status__c, Subsidy__c, Time_Period__c, Waiting_Periods__c, Refund_Status__c, Policy_Number__c, Offers__c, Refund_Amount__c, Is_Return__c, Phone__c, SMS_Opt_out__c,
                                   Transportation_Charges__c, Internal_Purchase__c, Cancellation_Request_Status__c, Discount_on_Ex_Showroom_Price__c, Is_Integration__c, Offer_description__c, State_Govt_Subsidy__c, Status__c,
                                   Total_Amount1__c, Previous_Status__c, Vehicle_Colour__c, Payment_Method__c, Booking_Partial_Payment__c, Accessories_Discount_Amount__c, Accessories_Discount_Description__c, Account_email__c, 
                                   Accessories_Parts_Subtotal__c, Vehicle_Subtotal__c, Invoice_Generated__c, RSA_Activation_date__c, City__c, Dealer_Code__c, Invoice_date__c, Discounted_Amount_on_Accessories__c,
                                   Accessories_Net_Amount__c, CGST_Amount_rollup__c, SGST_Amount_Rollup__c, Total_CGST__c, Total_SGST__c, Total_GST__c, Is_Future__c, Accessories_CGST_Rollup__c, Accessories_SGST_Rollup__c,
                                   Total_Accessories_GST__c, IsOrderInvoicesGenerated__c, Purchase_Order__c, Total_UTR_Amount__c, Record_Type_Name__c, RSA_Active__c, Delivery_Date__c, UTR_Meets_Condition__c, Is_QR_Generated__c,
                                   IsBackOrder__c, Contact__c, IsVOR__c, PO_Tax__c, VOR_5__c, PO_Sub_Total__c, PO_Grand_Total__c, Total_Order_Quantity__c, Total_Outstanding_Quantity__c, Is_Transfer__c, Total_Log_Payment__c,
                                   IsAmount_Paid__c, Merchandise_Additional_Discount__c, Is_IGST_on_Intrastate__c, LineItem_Merchandise_Disccount__c, Total_Merchandise_Disccount__c, OTC_Additional_Discount_Amount__c,
                                   Booking_Form_File_URL__c, Allotment_In_Process_File_URL__c, IRN_No__c, Is_E_invoice_Generated__c, IRN_Generated_DateTime__c, Is_Invoice_PDF_Generated__c, Is_IRN_Cancelled__c, 
                                   Can_Cancel_IRN__c, Is_Not_Blank_IRN__c, Approval__c, Approval_Statuses__c, Employee_Id__c, Store_Type__c, User__c, Employee_Discount__c, ASM_Comments__c, Approval_Statuse__c, 
                                   Is_Vehicle_Invoice_Generated__c, Is_DC_Generated__c, Is_RTO_and_IR_Generated__c, IS_OCT_Generated__c, Tax_Percent__c, IsAccessories_Generated__c, IsMerchandise_Generated__c,
                                   RTO_Receipt_Number__c, Base_Handling_Charges__c, GST_Amount__c, Is_Email_Send_on_RTO__c, OTC_Total_Product_Discount_Amount__c, Manager_Email__c, Total_Vehicle_Amount__c, 
                                   Total_accessories_Amount__c, Dealer_Email__c, Total_Merchandise_Amount__c, GST__c, Invoice_Number__c, Vehicle_Total_Discount__c, Vehicle_identification_Number__c, Same_State__c, 
                                   Total_Accessories_RollUp__c, Total_Vehicle_RollUp__c, Total_Merchandise_RollUp__c, Merchandise_Discount__c, Final_Merchandise_Amount__c, Accessories_IRN_No__c, Merchandise_IRN_No__c, 
                                   Payment_Receipt_PDF_URL__c, Website_Response_Id__c, Finance_Name__c, sap_delivery_no__c, Total_Merchandise_Unit_Price__c, Total_Accessories_Unit_Price__c, Order_prod_count__c, Shopify_Order__c,
                                   Coupon_Code__c, Coupon_Redeemed_Value__c, Is_Coupon_Applied__c, Customer_Has_No_Coupon__c, Order_Source__c, Total_Pre_GST_Discount__c, Inventory_Error__c, UTR_Ref_No__c FROM 
                                   Order Where AccountId != null AND Account.Phone =: phone];
            
            for(Order ord : ordList){
                if(!responseData.containskey(ord.Id)){
                    responseData.put(ord.Id,ord);  
                }
            }
            
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = 'GEN 3',
                Request_Payload__c = JSON.serializePretty(body),
                Response_Payload__c = 'Enquiry Created successfully: ',
                Status__c = 'Success'
            );
            insert logObj;
            
            GEN3_Wrapper.setResponse(200, 'Success', responseData);
            
        } catch (Exception e) { 
            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = 'GEN 3',
                Request_Payload__c = JSON.serializePretty(body),
                Response_Payload__c = 'Error: ' + e.getMessage(),
                Error_Message__c = 'Exception: ' + e.getMessage(),
                Status__c = 'Failed'
            );
            insert logObj;
            
            System.debug('Error: ' + e.getStackTraceString() + ' Message ====>' + e.getMessage() + ' Line Number ====>' + e.getLineNumber());
            GEN3_Wrapper.setResponse(500, 'Internal server error: ' + e.getMessage(), null);
        }
    }
}