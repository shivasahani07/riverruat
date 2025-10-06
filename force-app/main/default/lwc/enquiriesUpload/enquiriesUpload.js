import { LightningElement, track } from 'lwc';
import getObjectList from '@salesforce/apex/DynamicUploaderController.getObjectList';
import getProfileName from '@salesforce/apex/DynamicUploaderController.getProfileName';
import getFieldList from '@salesforce/apex/DynamicUploaderController.getFieldList';
import uploadData from '@salesforce/apex/DynamicUploaderController.uploadData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LABEL_OPPORTUNITY from '@salesforce/label/c.Upload_Format_Opportunity';
import LABEL_LEAD from '@salesforce/label/c.Upload_Format_Lead';
import Business_Hours from '@salesforce/label/c.Business_Hours';

export default class EnquiriesUpload extends LightningElement {
    @track objectOptions = [];
    @track fieldOptions = [];
    @track filteredFieldOptions = [];
    @track selectedObject;
    @track columnHeaders = [];
    @track fieldMapping = {};
    @track csvRows = [];
    @track isLoading = false;
    @track checkTime = false;
    @track ProfileName;

    connectedCallback() {
        debugger;
        this.getCurrentUserProfile();
        this.loadObjects();
        this.businessHours();
    }

    getCurrentUserProfile() {
        debugger;
        getProfileName()
            .then(result => {
                this.ProfileName = result;
            });
    }

    loadObjects() {
        debugger;
        getObjectList().then(result => {
            let filteredList = result;

            if (this.ProfileName === 'Sales Manager (Partner)') {
                filteredList = result.filter(obj => obj.toLowerCase() !== 'lead');
            } else {
                filteredList = result.filter(obj => obj.toLowerCase() !== 'opportunity');
            }

            this.objectOptions = filteredList.map(obj => {
                let label = obj;

                if (this.ProfileName === 'Sales Manager (Partner)') {
                    if (obj.toLowerCase() === 'opportunity') {
                        label = 'Enquiry';
                    }
                    return { label: label, value: obj };
                } else {
                    if (obj.toLowerCase() === 'lead') {
                        label = 'Lead';
                    }
                    return { label: label, value: obj };
                }
            });
        });
    }


    // businessHours() {
    //     debugger;
    //     const now = new Date();
    //     const hours = now.getHours();
    //     const businessHours = Business_Hours;

    //     if (hours >= 10 && hours < 19) {
    //         this.checkTime = false;
    //     } else {
    //         this.checkTime = true;
    //         this.showToast('Error', 'Please Upload the Data in Business Hours', 'warning');
    //     }
    // }

    businessHours() {
        // debugger;
        // const now = new Date();
        // const hours = now.getHours();

        // const [startHour, endHour] = Business_Hours.split(',').map(Number);

        // if (hours >= startHour && hours < endHour) {
        //     this.checkTime = false;
        // } else {
        //     this.checkTime = true;
        //     this.showToast('Error', 'Please Upload the Data in Business Hours', 'warning');
        // }
        this.checkTime = false;
    }


    handleObjectChange(event) {
        debugger;
        this.selectedObject = event.detail.value;

        getFieldList({ objectName: this.selectedObject })
            .then(result => {
                this.fieldOptions = result.map(field => ({ label: field, value: field }));
                this.filteredFieldOptions = this.fieldOptions;
            });
    }

    handleClick() {
        debugger;
        if (!this.selectedObject) {
            this.showToast('Error', 'Please select an object first', 'error');
            return;
        }

        let headers;
        switch (this.selectedObject.toLowerCase()) {
            case 'lead':
                headers = LABEL_LEAD.split(',').map(h => h.trim());
                break;
            case 'opportunity':
                headers = LABEL_OPPORTUNITY.split(',').map(h => h.trim());
                break;
            default:
                this.showToast('Error', `No template available for ${this.selectedObject}`, 'error');
                return;
        }

        this.downloadTemplate(headers);
    }

    downloadTemplate(headers) {
        if (!headers || !headers.length) {
            alert('No headers found to download.');
            return;
        }

        let csvString = headers.join(',') + '\n';

        let downloadElement = document.createElement('a');
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        downloadElement.download = `${this.selectedObject}_Template.csv`;
        document.body.appendChild(downloadElement);
        downloadElement.click();
        document.body.removeChild(downloadElement);

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success!',
                message: 'CSV Downloaded Successfully',
                variant: 'success',
                mode: 'dismissable'
            })
        );
    }



    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                const contents = e.target.result;
                const lines = contents.split(/\r?\n/).filter(r => r.trim() !== '');
                const headers = lines[0].split(',').map(h => h.trim());

                if (headers[headers.length - 1] === '') {
                    headers.pop();
                }

                this.columnHeaders = headers;

                // Guess which columns might be dates (based on header name)
                const dateColumns = headers.map((h, i) => {
                    return /date|dob|birth|created/i.test(h) ? i : -1;
                }).filter(index => index !== -1);

                // Process each row
                this.csvRows = lines.slice(1).map(line => {
                    const values = line.split(',').map(v => v.trim());

                    // Format date columns
                    dateColumns.forEach(i => {
                        if (values[i]) {
                            const formatted = this.formatDate(values[i]);
                            if (formatted) values[i] = formatted;
                        }
                    });

                    return values.join(',');
                });
            };
            reader.readAsText(file);
        }
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        if (!isNaN(date.getTime())) {
            const year = date.getFullYear();
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const day = String(date.getDate()).padStart(2, '0');
            return `${year}-${month}-${day}`;
        }
        return null;
    }


    handleFieldMappingChange(event) {
        debugger;
        const column = event.target.dataset.column;
        const value = event.detail.value;
        this.fieldMapping = { ...this.fieldMapping, [column]: value };
    }

    handleFieldSearch(event) {
        debugger;
        const searchTerm = event.target.value.toLowerCase();
        this.filteredFieldOptions = this.fieldOptions.filter(option =>
            option.label.toLowerCase().includes(searchTerm)
        );
    }

    handleUpload() {
        debugger;
        if (!this.selectedObject || !this.fieldMapping || !this.csvRows.length) {
            this.showToast('Error', 'Please select an object, map fields, and select a file.', 'error');
            return;
        }

        this.isLoading = true;

        uploadData({ objectName: this.selectedObject, fieldMapping: this.fieldMapping, csvRows: this.csvRows })
            .then(() => {
                this.showToast('Success', 'Upload started. You will receive an email when done.', 'success');
                this.resetComponent();
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        debugger;
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    resetComponent() {
        debugger;
        this.selectedObject = null;
        this.columnHeaders = [];
        this.fieldMapping = {};
        this.csvRows = [];
        this.fileData = null;
    }
}