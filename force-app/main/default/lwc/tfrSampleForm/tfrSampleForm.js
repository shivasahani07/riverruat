import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import verifyExistingTFR from '@salesforce/apex/TFRController.verifyExistingTFR';
const BLOCKED_STATUSES = new Set([
    'Cancelled',
    'Rejected',
    'Sumbit for Approval',
    'Ready for Delivery',
    'Completed',
    'Re-Work',
    'On Hold'
]);

const EDITABLE_STATUSES = new Set(['Pending', 'Approved']);

export default class TfrSampleForm extends LightningElement {

    @api inputObject
    @api recordId;
    @track relatedPart;
    @track tfrSampleRecord
    @track partId;
    @track isTFRRecordDisabled = false;
    @track isLoading = true;

    connectedCallback() {
        this.partId = this.inputObject.Id
        console.log(JSON.stringify(this.inputObject))
    }

    @wire(verifyExistingTFR, { partId: '$partId' })
    wiredData({ error, data }) {
        debugger;
        if (data) {
            const wireData = data;
            this.relatedPart = wireData?.workOrderLineItemRec;
            this.tfrSampleRecord = wireData?.tfrSampleRecord;
            this.recordId = wireData?.tfrSampleRecord?.Id;
            if (this.relatedPart.WorkOrder.Status == 'Completed' || this.relatedPart.WorkOrder.Status == 'Ready for Delivery' || this.relatedPart.WorkOrder.Status == 'Sumbit for Approval') {
                this.isTFRRecordDisabled = true;
            } else if (this.relatedPart?.Warranty_Prior__r?.Status__c) {
                let status = this.relatedPart?.Warranty_Prior__r?.Status__c
                this.isTFRRecordDisabled = !(EDITABLE_STATUSES.has(status) && !BLOCKED_STATUSES.has(status));
            }
            this.isLoading = false;
            console.log('wireData', wireData);
        } else if (error) {
            console.error('Error:', error);
            this.showToast('Error', error, 'error');
            this.isLoading = false;
        }
    }

    handleSuccess(event) {
        debugger;
        this.isLoading = true;
        this.recordId = event.detail.id;
        this.showToast('Success', 'TFR Sample record created/updated', 'success');
        // this.sendEevntToParent('Success',true,event.detail.id,this.inputObject.Id);
        this.isLoading = false;
    }

    handleError(event) {
        debugger
        const error = event.detail;
        this.showToast('Error', error.message || "Unknown error", 'error');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
        window.location.reload();
    }

    sendEevntToParent(message, isSuccess,recordid,parentId) {
        debugger;
        this.dispatchEvent(new CustomEvent('tfrsubmitsucess', {
            detail: {
                message: message,
                isSuccess: isSuccess,
                recordId:recordid,
                parentId:parentId
            }
        }));

    }
    
    // NOT IN  USE
    updateTFRonPart(partId,tfrid){
      const  parts = [];
      WorkOrderLineItem = {};
      WorkOrderLineItem.Id=partId;
      WorkOrderLineItem.TFR__C=tfrid;

    }
}