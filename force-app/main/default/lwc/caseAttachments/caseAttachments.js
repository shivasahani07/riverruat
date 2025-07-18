import { LightningElement, api, track } from 'lwc';
import getCaseAttachments from '@salesforce/apex/CaseAttachmentController.getCaseAttachments';

export default class CaseAttachments extends LightningElement {
    @api recordId;
    @track attachments = [];
    @track error;
    isLoading = true;
    noFiles = false;

    connectedCallback() {
        if (!this.recordId) {
            const url = window.location.href;
            const match = url.match(/\/case\/([^/]+)/);
            if (match) {
                this.recordId = match[1];
            }
        }
        this.fetchAttachments();
    }

    fetchAttachments() {
        this.isLoading = true;
        getCaseAttachments({ caseId: this.recordId })
            .then(result => {
                this.attachments = result.map(item => ({
                    Id: item.contentDocumentId,
                    Title: item.title,
                    FileType: item.fileType,
                    previewUrl: `/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=${item.latestPublishedVersionId}`
                }));
                this.noFiles = this.attachments.length === 0;
                this.error = null;
            })
            .catch(error => {
                this.error = error.body?.message || JSON.stringify(error);
                this.attachments = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}