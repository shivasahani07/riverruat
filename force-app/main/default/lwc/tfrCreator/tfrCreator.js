import { LightningElement, wire, track } from "lwc";
import getExistingVIN from "@salesforce/apex/TFRController.getExistingVIN";

export default class SamleTfr extends LightningElement {
    @track existingVINCuttoff = [];
    error;

    @wire(getExistingVIN)
    wiredData({ error, data }) {
        if (data) {
            this.existingVINCuttoff = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error;
            this.existingVINCuttoff = [];
        }
    }

    handleRowAction(event) {
        const recordId = event.target.dataset.id;
        console.log("Row button clicked for record Id:", recordId);

        // 👉 You can add your custom logic here
        // For example, fire an event, update something, or navigate
    }

    addFailureCodeAction(event){
      debugger;
      const recordId = event.target.dataset.id;
      
    }
}