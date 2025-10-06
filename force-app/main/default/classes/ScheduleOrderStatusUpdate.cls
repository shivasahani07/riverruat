global class ScheduleOrderStatusUpdate implements Schedulable {
    Set<Id> orderIds;

    public ScheduleOrderStatusUpdate(Set<Id> orderIds) {
        this.orderIds = orderIds;
    }

    global void execute(SchedulableContext sc) {
        System.enqueueJob(new QueueableOrderStatusUpdate(orderIds));
    }
}