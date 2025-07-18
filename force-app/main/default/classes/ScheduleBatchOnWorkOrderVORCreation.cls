global class ScheduleBatchOnWorkOrderVORCreation implements Schedulable{
	 global void execute(SchedulableContext sc) {
        BatchOnWorkOrderVORCreation batch = new BatchOnWorkOrderVORCreation();
        Database.executeBatch(batch, 200); 
    }
}