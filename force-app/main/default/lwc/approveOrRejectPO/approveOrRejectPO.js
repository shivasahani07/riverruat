import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPOLineItems from '@salesforce/apex/POReviewCompController.getPOLineItems2';
import submitApprovalDecision from '@salesforce/apex/POReviewCompController.submitApprovalDecision';

export default class ApproveOrRejectPO extends LightningElement {

    @api recordId;
    @track lineItems = [];

    approvedIds = []
    rejectedIds = [];

    @wire(getPOLineItems, { poId: '$recordId' })
    wiredLineItems({ data, error }) {
        if (data) {
            // Add UI flags
            this.lineItems = data.lineItems.map(item => ({
                ...item,
                isApproved: false,
                isRejected: false
            }));
        } else if (error) {
            console.error('Error fetching line items:', error);
        }
    }

    handleClick(event) {
        debugger;
        const action = event.target.name;
        const index = event.target.dataset.index;
        const updatedItems = [...this.lineItems];
        const item = updatedItems[index];

        if (action === 'approve') {
            item.isApproved = true;
            item.isRejected = false;

            if (!this.approvedIds.includes(item.Id)) {
                this.approvedIds.push(item.Id);
            }
            this.rejectedIds = this.rejectedIds.filter(id => id !== item.Id);
        } else if (action === 'reject') {
            item.isApproved = false;
            item.isRejected = true;
            if (!this.rejectedIds.includes(item.Id)) {
                this.rejectedIds.push(item.Id);
            }
            this.approvedIds = this.approvedIds.filter(id => id !== item.Id);
        }
        this.lineItems = updatedItems;
    }

    handleSave() {
        debugger;
        const approvedList = Array.from(this.approvedIds);
        const rejectedList = Array.from(this.rejectedIds);

        submitApprovalDecision({ approvedIds: approvedList, rejectedIds: rejectedList })
            .then(() => {
                console.log('Approval/Rejection submitted successfully.');
                this.showToast('Success', 'Approval Status Updated !', 'success');
            })
            .catch(error => {
                console.error('Error submitting decision:', error);
                this.showToast('Error', 'Error while updating the Approval Status', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}