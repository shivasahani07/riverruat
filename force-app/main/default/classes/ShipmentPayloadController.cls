/*
@RestResource(urlMapping='/shipment/*')
global with sharing class ShipmentPayloadController {

global class shipmentswrapper {
public List<ShipmentRequest> shipments;
}

global class ShipmentRequest {
public String sap_shipment_id;
public String sap_delivery_no;
public String ShipToName;
public String status;
public String LR_Date;
public String LR_no;
public String e_way_bill_no;
public String invoice_date;
public String invoice_no;
public Decimal invoice_amount;
public String itemCode;
public Integer quantity;
public List<lineItemWrappwe> lineItems;
}

global class lineItemWrappwe {
public Integer quantity;
public String item_code;
}

@HttpPost
global static void createShipment() {
SAPResponseApi.ApiResponse apiResponse = new SAPResponseApi.ApiResponse();

try {
RestRequest req = RestContext.request;
ShipmentRequest payload = (ShipmentRequest) JSON.deserialize(req.requestBody.toString(), ShipmentRequest.class);
System.debug('Payload: ' + JSON.serialize(payload));

Shipment shipment = new Shipment();
shipment.LR_Date__c = Date.parse(payload.LR_Date);
shipment.ShipToName = payload.ShipToName;
shipment.Invoice_Date__c = Date.parse(payload.invoice_date);
shipment.E_Way_bill__c = payload.e_way_bill_no;
shipment.Invoice_No__c = payload.invoice_no;
shipment.Invoice_Amount__c = payload.invoice_amount;
shipment.Status = payload.status;

insert shipment;
System.debug('Inserted Shipment Id: ' + shipment.Id);

List<ShipmentItem> sLineItem = new List<ShipmentItem>();
for (lineItemWrappwe item : payload.lineItems) {
ShipmentItem sli = new ShipmentItem();
sli.ShipmentId = shipment.Id;
sli.Quantity = item.quantity;
// sli.Item_Code__c = item.item_code; // Uncomment if this field exists
sLineItem.add(sli);
}
insert sLineItem;

apiResponse.status = true;
apiResponse.message = 'Success! Shipment ID: ' + shipment.Id;
apiResponse.errorLine = null;
apiResponse.errorMessage = null;

RestContext.response.statusCode = 201;
RestContext.response.responseBody = Blob.valueOf(JSON.serialize(apiResponse));

} catch (Exception e) {
System.debug('Error creating shipment: ' + e.getMessage());
apiResponse.status = false;
apiResponse.message = 'Failed to create shipment.';
apiResponse.errorLine = e.getLineNumber();
apiResponse.errorMessage = e.getMessage();

RestContext.response.statusCode = 500;
RestContext.response.responseBody = Blob.valueOf(JSON.serialize(apiResponse));
}
} 
}
*/

@RestResource(urlMapping='/shipment/*')
global with sharing class ShipmentPayloadController {
    
    global class shipmentswrapper {
        public List<ShipmentRequest> shipments;
    }
    
    global class ShipmentRequest {
        public String sap_shipment_id;
        public String sap_delivery_no;
        public String ShipToName;
        public String status;
        public String LR_Date;
        public String LR_no;
        public String e_way_bill_no;
        public String invoice_date;
        public String invoice_no;
        public Decimal invoice_amount;
        public String itemCode;
        public Integer quantity;
        public List<lineItemWrappwe> lineItems;
    }
    
    global class lineItemWrappwe {
        public Integer quantity;
        public String item_code;
    }
    
    public class OrderWrapper {
        public String record_Type;
        public String status;
        public String order_start_date;
        public String CreatedDate ;
        public String activated_date;
        public String Name;
        public List<OrderLineItemWrapper> line_items;
    }
    public class OrderLineItemWrapper{
        
    }
    
    @HttpPost
    global static void createShipment() {
        SAPResponseApi.ApiResponse apiResponse = new SAPResponseApi.ApiResponse();
        
        try {
            RestRequest req = RestContext.request;
            ShipmentRequest payload = (ShipmentRequest) JSON.deserialize(req.requestBody.toString(), ShipmentRequest.class);
            System.debug('Payload: ' + JSON.serialize(payload));
            
            Account acc = [SELECT Id FROM Account LIMIT 1]; 
            RecordType orderRT = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Order' LIMIT 1];
            
            // order creation
            Order ord = new Order();
            ord.RecordTypeId = orderRT.Id;
            ord.Status =payload.Status;
            // ord.Name =payload.Name ;
            ord.AccountId = acc.Id; 
            insert ord;
            
            Shipment shipment = new Shipment();
            shipment.LR_Date__c = Date.parse(payload.LR_Date);
            shipment.ShipToName = payload.ShipToName;
            shipment.Invoice_Date__c = Date.parse(payload.invoice_date);
            shipment.E_Way_bill__c = payload.e_way_bill_no;
            shipment.Invoice_No__c = payload.invoice_no;
            shipment.Invoice_Amount__c = payload.invoice_amount;
            shipment.Status = payload.status;
            
            insert shipment;
            System.debug('Inserted Shipment Id: ' + shipment.Id);
            
            List<ShipmentItem> sLineItem = new List<ShipmentItem>();
            for (lineItemWrappwe item : payload.lineItems) {
                ShipmentItem sli = new ShipmentItem();
                sli.ShipmentId = shipment.Id;
                sli.Quantity = item.quantity;
                sLineItem.add(sli);
            }
            insert sLineItem;
            
            apiResponse.status = true;
            apiResponse.message = 'Success! Shipment ID: ' + shipment.Id;
            apiResponse.errorLine = null;
            apiResponse.errorMessage = null;
            
            RestContext.response.statusCode = 201;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(apiResponse));
            
        } catch (Exception e) {
            System.debug('Error creating shipment: ' + e.getMessage());
            apiResponse.status = false;
            apiResponse.message = 'Failed to create shipment.';
            apiResponse.errorLine = e.getLineNumber();
            apiResponse.errorMessage = e.getMessage();
            
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(apiResponse));
        }
    } 
}