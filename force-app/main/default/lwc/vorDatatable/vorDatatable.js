import { LightningElement } from 'lwc';
import getVorOfCurrentUser from '@salesforce/apex/vorDatatable.getVorOfCurrentUser';

const columns = [
    {
        label: 'Name',
        fieldName: 'vorLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
    },
    { label: 'Ageing', fieldName: 'Ageing__c' },
    {
        label: 'Job Card',
        fieldName: 'jobCardLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'JobCardName' }, target: '_blank' }
    }
];

export default class VorDatatable extends LightningElement {
    data = [];
    columns = columns;
    error;
    value = 'without Reason';

    pageSize = 10;
    currentOffset = 0;
    isNextDisabled = false;
    isPrevDisabled = true;

    get options() {
        return [
            { label: 'without Reason', value: 'without Reason' },
            { label: 'with Reason', value: 'with Reason' },
        ];
    }

    connectedCallback() {
        debugger;
        this.fetchData();
    }

    handleChange(event) {
        debugger;
        this.value = event.detail.value;
        this.currentOffset = 0;
        this.fetchData();
    }

    fetchData() {
        debugger;
        getVorOfCurrentUser({
            filter: this.value,
            limitSize: this.pageSize,
            offsetSize: this.currentOffset
        })
            .then(result => {
                this.data = result.map(row => ({
                    ...row,
                    vorLink: '/' + row.Id,
                    jobCardLink: row.Job_Card__c ? '/' + row.Job_Card__c : '',
                    JobCardName: row.Job_Card__r ? row.Job_Card__r.WorkOrderNumber : ''
                }));
                this.error = undefined;
                this.isPrevDisabled = this.currentOffset === 0;
                this.isNextDisabled = result.length < this.pageSize;
            })
            .catch(error => {
                this.error = error;
                this.data = [];
            });
    }

    handleNext() {
        debugger
        this.currentOffset += this.pageSize;
        this.fetchData();
    }

    handlePrevious() {
        debugger;
        this.currentOffset = Math.max(0, this.currentOffset - this.pageSize);
        this.fetchData();
    }
}