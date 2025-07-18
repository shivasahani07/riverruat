import { LightningElement, api } from 'lwc';
import updateCaseAttachmentFlag from '@salesforce/apex/CaseFileUploadController.updateCaseAttachmentFlag';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FileUploadOnCase extends LightningElement {
    @api recordId;
    acceptedFormats = ['.pdf', '.png', '.jpg', '.docx', '.xlsx'];
     
 connectedCallback() {
         
            if (!this.recordId) {
            const url = window.location.href;
            const match = url.match(/\/case\/([^/]+)/);
            if (match) {
                this.recordId = match[1];
            }
        }
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        console.log('Files uploaded:', uploadedFiles.length);

        updateCaseAttachmentFlag({ caseId: this.recordId })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'File uploaded and Case updated!',
                    variant: 'success'
                }));
            })
            .catch(error => {
                console.error('Error:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error updating Case',
                    message: error.body?.message || error.message,
                    variant: 'error'
                }));
            });
    }
}