({
    doInit : function(component, event, helper) {
        var action = component.get("c.getPsfIdFromTask");
        action.setParams({ taskId: component.get("v.recordId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var psfId = response.getReturnValue();
                console.log("PSF Id from Apex:", psfId);
                component.set("v.psfId", psfId);
                
                var recordId = component.get("v.recordId");
        		console.log("Task Id from Aura (recordId):", recordId);
                component.set("v.taskId", recordId);
                
                component.set("v.isLoaded", true);
            } else {
                console.error("Error getting PSF Id");
            }
        });

        $A.enqueueAction(action);
    }
})