({
   /* doInit : function(component, event, helper) {
        debugger;
        var label = $A.get("$Label.c.PdfBaseURL	");
        component.set('v.siteURL',label+component.get('v.recordId'));
        var action1 = component.get("c.SavePDF");
        $A.enqueueAction(action1);
    },
    SavePDF : function(component, event, helper){
        debugger;
        var recordId = component.get("v.recordId");
        var action = component.get("c.GenerateCustomerFormPDFHP");
        action.setParams({
            "recordId" : recordId
        });
        action.setCallback(this, function(response){
            var State = response.getState();
            if(State === "SUCCESS"){
                var result = response.getReturnValue();
                if(result !=null){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Success',
                        message: 'E-Invoice PDF Generated Successfully !',
                        duration:' 6000',
                        key: 'info_alt',
                        type: 'success',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    $A.get('e.force:refreshView').fire();
                }
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'Something went Wrong !',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },*/
})