import { LightningElement, api, track,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import subsidyDocumentCollected from '@salesforce/apex/PaymentTriggerHandler.subsidyDocumentCollected';
import PDIDocumentCollected from '@salesforce/apex/PaymentTriggerHandler.PDIDocumentCollected';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from "lightning/uiRecordApi";

const FIELDS = ["Order.Name", "Order.Assigned_Vehicle__c"];
export default class UploadSubsidyAndPDIDocumentsOnOrder extends LightningElement {


    @api recordId;
    @track showButtons = true;
    @track uploadSubsidy = false;
    @track uploadPDI = false;
    value = '';

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    order;

    get name() {
        return this.order.data.fields.Name.value;
    }

    get assignedVehicle() {
        return this.order.data.fields.Assigned_Vehicle__c.value;
    }

    get options() {
        return [
            { label: 'Subsidy Document', value: 'SubsidyDocument' },
            { label: 'PDI Document', value: 'PDIDocument' },
        ];
    }

    handleChange(event) {
        debugger;
        this.value = event.detail.value;
        if (this.value === 'SubsidyDocument') {
            this.uploadSubsidy = true;
            this.showButtons = false;
        }
        if (this.value === 'PDIDocument') {
            this.uploadPDI = true;
            this.showButtons = false;
        }
    }

    handleSubsidyUpload() {
        debugger;
        subsidyDocumentCollected({ recordId: this.recordId })
        .then(() => {
            this.showToast('Success', 'Subsidy Document Upload Successfully', 'success');
            this.handleCancel();
        })
        .catch(error => {
            console.error(error);
            this.showToast('Error', error, 'error');
        })
    }

    handlePDIUpload() {
        PDIDocumentCollected({ recordId: this.recordId })
        .then(() => {
            this.showToast('Success', 'PDI Document Upload Successfully', 'success');
            this.handleCancel();
        })
        .catch(error => {
            console.error(error);
            this.showToast('Error', error, 'error');
        })
    }

    showToast(title, message, variant) {
        debugger;
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }


     handleClick() {
        debugger;
        const pdfUrl = `/apex/Check_pdi_item_screen_pdf?id=${this.assignedVehicle}`;
        window.open(pdfUrl, '_blank');
    }

    handleCancel() {
        debugger;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleBack() {
        debugger;
        this.showButtons = true;
        this.uploadSubsidy = false;
        this.uploadPDI = false;
    }
}