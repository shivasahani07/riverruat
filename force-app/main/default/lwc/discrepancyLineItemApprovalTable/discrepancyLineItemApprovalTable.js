import { LightningElement, api, track, wire } from 'lwc';
import getDiscrepancyLineItems from '@salesforce/apex/DiscrepancyLineItemController.getDiscrepancyLineItems';
import updateApproval from '@salesforce/apex/DiscrepancyLineItemController.updateApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshView } from 'lightning/refresh';

export default class DiscrepancyLineItemTable extends LightningElement {
    @api recordId;
    @track records = [];
    @track error;

    @wire(getDiscrepancyLineItems, { discrepancyId: '$recordId' })
    wiredItems({ error, data }) {
        if (data) {
            this.records = data.map(item => ({ ...item }));
            this.error = undefined;
        } else {
            this.error = error;
            this.records = [];
        }
    }

    handleApprovalChange(event) {
        const id = event.target.dataset.id;
        const isChecked = event.target.checked;
        const index = this.records.findIndex(r => r.Id === id);
        if (index !== -1) {
            this.records[index].Approved__c = isChecked;
            this.records[index].Status__c = isChecked ? 'Approved' : 'Rejected';
        }
    }

    handleSave() {
        updateApproval({ itemsToUpdate: this.records, lotID: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records updated successfully.',
                        variant: 'success'
                    })
                );

                // Close the Quick Action modal
                this.dispatchEvent(new CloseActionScreenEvent());

                // Refresh the record page
                setTimeout(() => {
                    eval("$A.get('e.force:refreshView').fire();");
                }, 500);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}