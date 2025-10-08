import { LightningElement, api, track } from 'lwc';

export default class Pagination extends LightningElement {
    @api records = [];       // full list of records (if parent provides all)
    @api totalRecords = 0;   // total records (if data is paged from Apex)
    @api pageSizeOptions = [5, 10, 20,30, 50];

    @track pageSize =30;
    @track pageNumber = 1;

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }

    get disablePrev() {
        return this.pageNumber <= 1;
    }

    get disableNext() {
        return this.pageNumber >= this.totalPages;
    }

    connectedCallback() {
        this.handlePagination();
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.pageNumber = 1;
        this.handlePagination();
    }

    handlePrev() {
        if (this.pageNumber > 1) {
            this.pageNumber -= 1;
            this.handlePagination();
        }
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber += 1;
            this.handlePagination();
        }
    }

    handlePagination() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = this.pageNumber * this.pageSize;

        let pageRecords = [];
        if (this.records && this.records.length > 0) {
            pageRecords = this.records.slice(start, end);
        }

        // Fire custom event with page data
        this.dispatchEvent(new CustomEvent('pagechange', {
            detail: {
                pageRecords,
                pageNumber: this.pageNumber,
                pageSize: this.pageSize,
                totalPages: this.totalPages
            }
        }));
    }
}