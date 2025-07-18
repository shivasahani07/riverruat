import { LightningElement, wire, track } from 'lwc';
import GetDealerAssociatedVors from '@salesforce/apex/VorListViewDMSController.GetDealerAssociatedVors';
import getUserId from '@salesforce/user/Id';

const PAGE_SIZE =10;

const COLUMNS = [
    {
        label: 'VOR Name',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
    },
    { label: 'VOR Reason', fieldName: 'VOR_Reason__c' },
    {
        label: 'Job Card',
        fieldName: 'jobCardUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'JobCardNumber' },
            target: '_blank'
        }
    },
    { label: 'Ageing', fieldName: 'Ageing__c', type: 'number' }
];

export default class VorListViewDMSGlobal extends LightningElement {
    @track userId =getUserId;
    @track vorData = [];
    @track paginatedData = [];
    @track error;

    columns = COLUMNS;
    selectedReason ="Without Reason";
    currentPage = 1;
    totalPages = 0;

    get showPagination() {
        return this.totalPages > 1;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    // Get VOR records from Apex
    @wire(GetDealerAssociatedVors, { userId: '$userId', vorReason: '$selectedReason' })
    wiredVors({ data, error }) {
        if (data) {
            this.vorData = data.map(row => ({
                ...row,
                JobCardNumber: row.Job_Card__r?.WorkOrderNumber || '',
                recordUrl: this.getSiteUrlForRecord(row.Id),
                jobCardUrl: row.Job_Card__c ? this.getSiteUrlForRecord(row.Job_Card__c) : ''
            }));
            this.error = undefined;
            console.log(JSON.stringify(data))

            this.setupPagination();
        } else if (error) {
            console.log(JSON.stringify(error))
            this.error = error.body?.message || 'Failed to fetch VORs';
            this.vorData = [];
        }
    }

    // Create full record URL for Experience Cloud site
    getSiteUrlForRecord(recordId) {
        const baseUrl = window.location.origin;
        return `${baseUrl}/s/detail/${recordId}`;
    }

    // Pagination setup
    setupPagination() {
        this.totalPages = Math.ceil(this.vorData.length / PAGE_SIZE);
        this.updatePaginatedData();
    }

    updatePaginatedData() {
        const start = (this.currentPage - 1) * PAGE_SIZE;
        const end = this.currentPage * PAGE_SIZE;
        this.paginatedData = this.vorData.slice(start, end);
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedData();
        }
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedData();
        }
    }

    handleReasonChange(event) {
        debugger;
        this.selectedReason = event.detail.value;
        this.currentPage = 1;
    }

    get reasonOptions() {
        return [
            { label: 'Without Reason', value: 'without Reason' },
            { label: 'With Reason', value: 'with Reason' },
            { label: 'All', value: 'All' }
        ];
    }
}