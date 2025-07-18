({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");

        if (recordId) {
            var vfUrl = "https://rivermobilityprivatelimited2--rruat--c.sandbox.vf.force.com/apex/CustomerFeedbackForm?id=" + recordId;
            window.open(vfUrl, "_blank");
        } else {
            console.error("recordId is missing");
        }
        $A.get("e.force:closeQuickAction").fire();
    }
})