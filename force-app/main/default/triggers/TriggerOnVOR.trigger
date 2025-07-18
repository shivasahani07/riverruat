trigger TriggerOnVOR on VOR__c (before update) {
    if(trigger.isBefore && trigger.isUpdate){
        if(system.label.ActiveVORTrigger == 'True'){
            VORTriggerHelper.VORReasonDurationUpdate(trigger.new,Trigger.oldMap);       
        }
    }
     if(trigger.isBefore && trigger.isUpdate){
        if(system.label.ActiveVORTrigger == 'True'){
            VORReasonDurationHelper.VORReasonDurationUpdate(trigger.new,Trigger.oldMap);       
        }
    }
}