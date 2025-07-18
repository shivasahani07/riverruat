({
    onPageReferenceChange : function(component, event, helper) {
        debugger;
        const pageRef = component.get("v.pageReference");
        if (pageRef && pageRef.state && pageRef.state.c__filterName) {
            const filterName = pageRef.state.c__filterName;
            console.log("Filter Name:", filterName);
            component.set("v.filterName", filterName);
            // You can now use this in logic or server call
        }
    }
})