/**@author Ram Kumar
* @email ram.k@utilitarianlabs.com
* @create date 4-11-2025
* @modify date 4-11-2025
* @desc [Invocie Record Creation For Job Card]
*/

public class JobCardOrderInvoiceHandler {
    
    public static void CreateOrderInvoice(List<WorkOrder> newRecords, Map<Id, WorkOrder> oldMapRecords) {
       
        try {
            System.debug('CreateOrderInvoice started. Processing ' + newRecords.size() + ' new WorkOrders.');
            
            List<Job_Card_Invoice__c> invoicesToInsert = new List<Job_Card_Invoice__c>();
            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
            Map<Id, Integer> accountSequenceTracker = new Map<Id, Integer>();
            List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
            Set<Id> accountIds = new Set<Id>();
            
            for (WorkOrder wrd : newRecords) {
                System.debug('Checking WorkOrder Id: ' + wrd.Id + ', Status: ' + wrd.Status + ', Old Status: ' + oldMapRecords.get(wrd.Id).Status);
                System.debug('Service Center : ' + wrd.Service_Center__c);
                
                if (wrd.Status == 'Ready For Delivery'
                    && oldMapRecords.get(wrd.Id).Status != 'Ready For Delivery'
                    && wrd.Is_Order_Invoice_Generated__c == false
                    && wrd.Service_Center__c != null) {
                        accountIds.add(wrd.Service_Center__c);
                        System.debug('WorkOrder Id: ' + wrd.Id + ' eligible for invoice creation. Service Center Id: ' + wrd.Service_Center__c);
                    }
            }
            
            if (accountIds.isEmpty()) {
                System.debug('No Order Invoice was Created. Please check all the conditions.');
                return;
            }
            
            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id, Center_Code__c, Invoice_Sequence__c
                FROM Account
                WHERE Id IN :accountIds
            ]);
            System.debug('Fetched ' + accountMap.size() + ' Service Centers for invoice generation.');
            
            for (WorkOrder wrd : newRecords) {
                if (wrd.Status == 'Ready For Delivery'
                    && oldMapRecords.get(wrd.Id).Status != 'Ready For Delivery'
                    && wrd.Is_Order_Invoice_Generated__c == false
                    && wrd.Service_Center__c != null
                    && accountMap.containsKey(wrd.Service_Center__c)) {
                        
                        Account acc = accountMap.get(wrd.Service_Center__c);
                        String company = 'RC';
                        String centre = acc.Center_Code__c;
                        String product = '';
                        Integer seq = accountSequenceTracker.containsKey(acc.Id)
                            ? accountSequenceTracker.get(acc.Id)
                            : (acc.Invoice_Sequence__c != null ? Integer.valueOf(acc.Invoice_Sequence__c) : 1);
                                
                                System.debug('Generating Service invoice for WorkOrder Id: ' + wrd.Id + ' with sequence starting at: ' + seq);
                        
                        // --- Create Service Invoice ---
                        String serviceInvoiceNum = String.valueOf(seq);
                        String serviceInvoiceId = GenerateInvoiceId.generateInvoiceId(company, centre, product, serviceInvoiceNum);
                        
                        Job_Card_Invoice__c serviceInvoice = new Job_Card_Invoice__c();
                        serviceInvoice.Name = 'Service Invoice';
                        serviceInvoice.Invoice_Number__c = serviceInvoiceId;
                        serviceInvoice.Invoice_Type__c = 'Service';
                        serviceInvoice.Job_Card__c = wrd.Id;
                        invoicesToInsert.add(serviceInvoice);
                        System.debug('Created Service invoice with Invoice_Number__c: ' + serviceInvoiceId);
                        
                        seq++;
                        
                        // --- If Accidental, create Insurance Invoice ---
                        if (wrd.RR_Job_Type__c == 'Accidental') {
                            System.debug('WorkOrder Id: ' + wrd.Id + ' is Accidental. Generating Insurance invoice with sequence: ' + seq);
                            String insuranceInvoiceNum = String.valueOf(seq);
                            String insuranceInvoiceId = GenerateInvoiceId.generateInvoiceId(company, centre, product, insuranceInvoiceNum);
                            
                            Job_Card_Invoice__c insuranceInvoice = new Job_Card_Invoice__c();
                            insuranceInvoice.Name = 'Insurance';
                            insuranceInvoice.Invoice_Number__c = insuranceInvoiceId;
                            insuranceInvoice.Invoice_Type__c = 'Insurance';
                            insuranceInvoice.Job_card__c = wrd.Id;
                            invoicesToInsert.add(insuranceInvoice);
                            System.debug('Created Insurance invoice with Invoice_Number__c: ' + insuranceInvoiceId);
                            
                            seq++;
                        }
                        
                        accountSequenceTracker.put(acc.Id, seq);
                        workOrdersToUpdate.add(wrd);
                    }
            }
            
            if (!invoicesToInsert.isEmpty()) {
                insert invoicesToInsert;
                System.debug('Inserted ' + invoicesToInsert.size() + ' Order_Invoice__c records.');
                
                for (WorkOrder wrd : workOrdersToUpdate) {
                    wrd.Is_Order_Invoice_Generated__c = true;
                }
                
                for (Id accId : accountSequenceTracker.keySet()) {
                    Account accToUpdate = new Account(Id = accId, Invoice_Sequence__c = accountSequenceTracker.get(accId));
                    accountsToUpdate.put(accId, accToUpdate);
                    System.debug('Updating Account Id: ' + accId + ' Invoice_Sequence__c to: ' + accountSequenceTracker.get(accId));
                }
                
                if (!accountsToUpdate.isEmpty()) update accountsToUpdate.values();
                if (!workOrdersToUpdate.isEmpty()) update workOrdersToUpdate;
                
                System.debug('Updated ' + accountsToUpdate.size() + ' Account(s) and ' + workOrdersToUpdate.size() + ' WorkOrder(s) after invoice creation.');
            } else {
                System.debug('No invoices were created. Skipping updates.');
            }
            
        } catch (Exception e) {
            System.debug('Error ==> ' + e.getMessage() + ' Line Number ==> ' + e.getLineNumber());
        }
    }
}