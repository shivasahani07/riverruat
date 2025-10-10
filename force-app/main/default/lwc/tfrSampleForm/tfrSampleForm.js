import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import verifyExistingTFR from '@salesforce/apex/TFRController.verifyExistingTFR';
import getTFRRelatedWp from '@salesforce/apex/TFRController.getTFRRelatedWp';
import updateWorkplan from '@salesforce/apex/TFRController.updateWorkplan';


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

   @track  listOptions;
        

    // defaultOptions = ['7', '2', '3'];

    @track requiredOptions;

    @api inputObject
    @api recordId;
    @track relatedPart;
    @track tfrSampleRecord
    @track partId;
    @track isTFRRecordDisabled = false;
    @track isLoading = true;
    @track associatedLabours=[];

    connectedCallback() {
        this.partId = this.inputObject.Id
        console.log(JSON.stringify(this.inputObject))
        if(this.inputObject.WorkOrderId){
            
        }
    }

    @wire(verifyExistingTFR, { partId: '$partId' })
    wiredData({ error, data }) {
        debugger;
        if (data) {
            const wireData = data;
             console.log('wired data tfr form',JSON.stringify(data));
            this.relatedPart = wireData?.workOrderLineItemRec;
            this.tfrSampleRecord = wireData?.tfrSampleRecord;
            this.recordId = wireData?.tfrSampleRecord?.Id;
            this.getTFRRelatedWorkplanms(this.inputObject.WorkOrderId)
            if (this.relatedPart?.WorkOrder.Status == 'Completed' || this.relatedPart?.WorkOrder.Status == 'Ready for Delivery' || this.relatedPart.WorkOrder?.Status == 'Sumbit for Approval') {
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
        let wps=[];
        this.requiredOptions.forEach(itemId => {
            wps.push({
                Id: itemId,
                TFR_Sample__c: this.recordId
            });
        });
        this.updateWorkplan(wps);
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

    handleChange(event) {
        debugger;
        // Get the list of the "value" attribute on all the selected options
        const selectedOptionsList = event.detail.value;
        this.requiredOptions=event.detail.value;
        // alert(`Options selected: ${selectedOptionsList}`);
    }

    getTFRRelatedWorkplanms(workOrderId) {
        debugger;
    getTFRRelatedWp({ workOrderId: workOrderId })
        .then(result => {
            this.requiredOptions = [];
            this.listOptions = [];
            result.forEach(item => {
                this.listOptions.push({ value: item.Id, label: item.Name });
                if ((item.TFR_Sample__c != undefined && this.recordId != undefined ) && (item.TFR_Sample__c === this.recordId)) {
                    this.requiredOptions.push(item.Id);
                } else {
                    this.listOptions.push({ value: item.Id, label: item.Name });
                }
            });
        })
        .catch(error => {
            console.error('Error fetching related Workplans:', error);
        });
        console.log(JSON.stringify('----',this.listOptions))
    }


    
    updateWorkplan(workplans){
        debugger;
        updateWorkplan({workplans:workplans})
        .then(result =>{
            this.showToast('Success', 'Labour code tagged with TFR from', 'success');
            
        })
        .catch(error =>{
            this.showToast('Error', error.message || "Unknown error", 'error');
        })
    }
}