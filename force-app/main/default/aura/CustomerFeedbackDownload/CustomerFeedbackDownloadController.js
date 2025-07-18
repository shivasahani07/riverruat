({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");

        // Build the VF page URL using the recordId
        var vfPageUrl = 'autocloudSite/apex/CustomerFeedbackForm?id=' + recordId;

        // Open the Visualforce PDF page in a new tab
        window.open(vfPageUrl, '_blank');

        // Close the Quick Action panel
        $A.get("e.force:closeQuickAction").fire();
    }
})