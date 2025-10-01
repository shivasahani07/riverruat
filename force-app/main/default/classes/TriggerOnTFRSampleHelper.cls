public class TriggerOnTFRSampleHelper {
    
    // public static void BeforeInsert(List<TFR_Sample__c> insertedSamples) {
    //     Set<Id> jobCardIds = new Set<Id>();
        
    //     for (TFR_Sample__c tfrsm : insertedSamples) {
    //         if (tfrsm.Job_Card__c != null) {
    //             jobCardIds.add(tfrsm.Job_Card__c);
    //         }
    //     }
        
    //     // Query Job Card to get DealerCode
    //     Map<Id, WorkOrder> jobCardMap = new Map<Id, WorkOrder>(
    //         [SELECT Id, Dealer_contact__r.Dealer_Code__c FROM WorkOrder WHERE Id IN :jobCardIds]
    //     );
        
    //     Integer sequence = (Integer) [SELECT COUNT() FROM TFR_Sample__c WHERE CreatedDate = TODAY];
        
    //     for (TFR_Sample__c tfrsm : insertedSamples) {
    //         String dealerCode = '';
    //         if (jobCardMap.containsKey(tfrsm.Job_Card__c)) {
    //             dealerCode = jobCardMap.get(tfrsm.Job_Card__c).Dealer_contact__r.Dealer_Code__c;
    //         }
            
    //         String mm = String.valueOf(System.today().month());
    //         if (mm.length() == 1) mm = '0' + mm;
    //         String yy = String.valueOf(System.today().year()).right(2);
    //         String mmYY = mm + yy;
            
            
    //         sequence++;
    //         //String formattedSeq = String.format('{0,number,0000}', new List<Object>{Decimal.valueOf(sequence)});
    //         //list<String> formattedSeqlist=tfrsm.Name.split('-');
    //         String formattedSeq='00001';
    //         String customName = dealerCode + mmYY +formattedSeq;
    //         tfrsm.Name__c = customName;
            
    //     }
    // }

    public static void beforeInsert(List<TFR_Sample__c> newSamples) {
        Set<Id> jobCardIds = new Set<Id>();

        // Collect Job Card IDs
        for (TFR_Sample__c tfrsm : newSamples) {
            if (tfrsm.Job_Card__c != null) {
                jobCardIds.add(tfrsm.Job_Card__c);
            }
        }

        // Query Job Cards with Dealer Code
        Map<Id, WorkOrder> jobCardMap = new Map<Id, WorkOrder>(
            [SELECT Id, Dealer_contact__r.Dealer_Code__c 
             FROM WorkOrder 
             WHERE Id IN :jobCardIds]
        );

        // Get today’s existing count for sequence calculation
        // Integer sequence = (Integer) [SELECT COUNT() 
        //                               FROM TFR_Sample__c 
        //                               WHERE CreatedDate = TODAY AND Dealer_contact__r.Dealer_Code__c];

        // Loop through new records and assign Name__c
        for (TFR_Sample__c tfrsm : newSamples) {
            String dealerCode = '';
            if (jobCardMap.containsKey(tfrsm.Job_Card__c)) {
                dealerCode = jobCardMap.get(tfrsm.Job_Card__c).Dealer_contact__r.Dealer_Code__c;
            }

            Integer sequence = (Integer) [SELECT COUNT() FROM TFR_Sample__c WHERE  Service_Center__r.Center_Code__c =: dealerCode];

            // Build MMYY
            String mm = String.valueOf(System.today().month());
            if (mm.length() == 1) mm = '0' + mm;
            String yy = String.valueOf(System.today().year()).right(2);
            String mmYY = mm + yy;

            // Increment sequence
            sequence++;
            String formattedSeq = String.valueOf(sequence).leftPad(5, '0'); // 00001, 00002

            // Final Custom Name
            String customName = dealerCode + mmYY + formattedSeq;
            tfrsm.Name__c = customName;
        }
    }


    
    public static void AfterInsert(List<TFR_Sample__c> insertedSamples) {
        Set<Id> failureCodeIds = new Set<Id>();
        
        // Step 1: Collect related Failure_Code__c IDs from inserted samples
        for (TFR_Sample__c sample : insertedSamples) {
            if (sample.Failure_Code__c != null && sample.jc_Status__c =='Completed') {
                failureCodeIds.add(sample.Failure_Code__c);
            }
        }
        
        if (failureCodeIds.isEmpty()) return;
        
        // Step 2: Query current Failure_Code__c data
        Map<Id, Failure_Code__c> failureCodeMap = new Map<Id, Failure_Code__c>(
            [SELECT Id, Batch_Size__c, Sample_Collected__c, Is_Active__c,Status__c
             FROM Failure_Code__c
             WHERE Id IN :failureCodeIds]
        );
        
        system.debug('failureCodeMap---'+failureCodeMap);
        // Step 3: Query count of TFR_Sample__c grouped by Failure_Code__c
        Map<Id, Integer> sampleCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Failure_Code__c fcode, COUNT(Id) sampleCount
            FROM TFR_Sample__c
            WHERE Failure_Code__c IN :failureCodeIds
            GROUP BY Failure_Code__c
        ]) {
            sampleCounts.put((Id)ar.get('fcode'), (Integer)ar.get('sampleCount'));
        }
        
        // Step 4: Prepare updates to Failure_Code__c
        List<Failure_Code__c> updates = new List<Failure_Code__c>();
        
        for (Id fcId : failureCodeIds) {
            Failure_Code__c fc = failureCodeMap.get(fcId);
            Integer collected = sampleCounts.get(fcId);
            fc.Status__c='Started';
            if (fc != null && collected != null) {
                // Increment Batch_Size__c by 1 for newly referenced failure codes
                if (fc.Batch_Size__c == null) {
                    //fc.Batch_Size__c = 1;
                } else {
                    //fc.Batch_Size__c += 1;
                }
                
                // Update collected sample count
                fc.Sample_Collected__c = collected;
                
                // Deactivate if quota met
                if (collected >= fc.Batch_Size__c) {
                    fc.Status__c='TFR Completed';
                    //fc.Is_Active__c = false;
                }
                
                system.debug('fc---'+fc);
                updates.add(fc);
            }
        }
        
        if (!updates.isEmpty()) {
            system.debug('updates---'+updates);
            update updates;
        }
    }
    
    
}