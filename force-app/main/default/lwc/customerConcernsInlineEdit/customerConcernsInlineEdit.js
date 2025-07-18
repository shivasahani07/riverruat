import { LightningElement, api, track, wire } from 'lwc';
import customerConcernList from '@salesforce/apex/CustomerConcernsInlineEditController.customerConcernList';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomerConcernsInlineEdit extends LightningElement {
    @api recordId;
    @track data = [];
    @track draftValues = [];

    sortBy;
    sortDirection;

    columns = [
        { label: 'ID', fieldName: 'Name', sortable: true },
        { label: 'Concerns', fieldName: 'Concerns__c',  sortable: true },
        { label: 'Subconcerns', fieldName: 'Subconcerns__c',  sortable: true },
        { label: 'VOC', fieldName: 'VOC__c',  sortable: true },
        { label: 'Closed Resolution', fieldName: 'Closed_Resolution__c', editable: true, sortable: true },
        { label: 'Case Category', fieldName: 'Case_Category__c', editable: true, sortable: true }
    ];

    connectedCallback() {
        debugger;
        setTimeout(() => {
            this.recordId = this.recordId;
            this.fetchConcernList();
        }, 300);
    }

    fetchConcernList() {
        debugger;
        customerConcernList({ caseId: this.recordId })
            .then(result => {
                this.data = result;
            })
            .catch(error => {
                console.error('Error fetching concern list:', error);
                this.showToast('Error', 'Failed to fetch Customer Concerns', 'error');
            });
    }

    doSorting(event) {
        debugger;
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        debugger;
        let parseData = JSON.parse(JSON.stringify(this.data));
        let isReverse = direction === 'asc' ? 1 : -1;
        parseData.sort((x, y) => {
            x = x[fieldname] || '';
            y = y[fieldname] || '';
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
    }

    handleSave(event) {
        debugger;
        const updatedFields = event.detail.draftValues;
        const recordInputs = updatedFields.map(draft => ({ fields: { ...draft } }));
        
        Promise.all(recordInputs.map(recordInput => updateRecord(recordInput)))
            .then(() => {
                this.showToast('Success', 'Records updated successfully', 'success');
                this.draftValues = [];
                this.fetchConcernList();
            })
            .catch(error => {
                this.showToast('Error updating records', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}