import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 

export default class TestRideDocumentsUpload extends LightningElement {
    @api recordId;

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }

    handleUploadFinished(event) {
        debugger;
        const uploadedFiles = event.detail.files;
        console.log('Files uploaded: ', uploadedFiles);
    }

    handleSuccess(event) {
        debugger;
        this.showToast('Success', 'Record updated successfully: ', 'success');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(event) {
        debugger;
        this.showToast('Error', event.detail, 'error');
        console.error('Error occurred:', event.detail);
    }

    handleCancel() {
        debugger;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSave(){
        debugger;

    }

    showToast(title, message, variant) {
        debugger;
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}