import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createSlot from '@salesforce/apex/AppointmentSlotController.createSlot';
import getServiceBayCount from '@salesforce/apex/AppointmentSlotController.getServiceBayCount';
import getCurrentContactServiceCenter from '@salesforce/apex/AppointmentSlotController.getCurrentContactServiceCenter';
import getRemainingBays from '@salesforce/apex/AppointmentSlotController.getRemainingBayCountForRange';

const PAGE_SIZE = 10;

export default class CreateAppointmentSlots extends LightningElement {
    @track serviceCenterId;
    @track serviceCenterName = '';
    @track fullSlotItems = [];
    @track slotItems = [];
    @track startDate;
    @track endDate;
    @track dayStart;
    @track dayEnd;
    @track duration = 30;
    @track bayCount;
    @track bayNumber = 0;   // Default 0
    @track remainingBays;
    @track showForm = false;
    @track showBackButton = false;
    @track errorMessage = '';
    @track filterStartDate;
    @track filterEndDate;
    @track selectedStatus = '';
    @api recordId;

    currentPage = 1;
    totalPages = 1;

    get options() {
        return [
            { label: 'All', value: '' },
            { label: 'Available', value: 'Available' },
            { label: 'Booked', value: 'Booked' }
        ];
    }

    get minStartDate() {
        const today = new Date();
        today.setDate(today.getDate() + 15);
        return today.toISOString().split('T')[0];
    }

    get hasSlotItems() {
        return this.slotItems && this.slotItems.length > 0;
    }

    get filterApplied() {
        return this.filterStartDate || this.filterEndDate || this.selectedStatus;
    }

    get disablePrev() {
        return this.currentPage <= 1;
    }

    get disableNext() {
        return this.currentPage >= this.totalPages;
    }

    get showTable() {
        return !this.showForm;
    }

    get disableSave() {
        return !this.serviceCenterId || 
               !this.startDate || 
               !this.endDate || 
               !this.dayStart || 
               !this.dayEnd || 
               !this.duration ||
               new Date(this.startDate) > new Date(this.endDate) ||
               new Date(this.startDate) < new Date(this.minStartDate) ||  
               this.dayEnd <= this.dayStart ||
               this.duration < 15 || 
               this.duration > 60 ||
               this.bayNumber <= 0 || 
               (this.remainingBays && this.bayNumber > this.remainingBays); 
    }

    @wire(getCurrentContactServiceCenter)
    wiredCenterName({ error, data }) {
        if (data) {
            this.serviceCenterId = data.accountId;
            this.serviceCenterName = data.accountName;
            this.fullSlotItems = this.processSlotItems(data.asiList || []);
            this.updatePaginatedItems();
            this.fetchBayCount();
        } else if (error) {
            this.handleError(error, 'Failed to load service center data');
        }
    }

    processSlotItems(rawList) {
        function convertUTCToIST(dateTimeStr) {
            const utcDate = new Date(dateTimeStr);
            utcDate.setMinutes(utcDate.getMinutes() - 330);
            return utcDate;
        }

        return rawList.map(row => {
            const start = convertUTCToIST(row.Start_Time__c);
            const end = convertUTCToIST(row.End_Time__c);

            return {
                Id: row.Id,
                slotitemName: row.Name,
                apppointDate: new Date(row.Appointment_Slot_Date__c).toLocaleDateString('en-IN'),
                formattedStart: start.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true }),
                formattedEnd: end.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true }),
                slotUrl: row.Appointment_Slot__c ? '/' + row.Appointment_Slot__c : '',
                slotName: row.Appointment_Slot__r?.Name || '—',
                asiUrl: '/' + row.Id,
                bayId: row.Service_Bay__c || '',
                bayName: row.Service_Bay__r?.Name || '—',
                bookingstatus: row.Booking_Status__c,
                rawDate: row.Appointment_Slot_Date__c
            };
        });
    }

    statushandleChange(event) {
        this.selectedStatus = event.detail.value;
        this.currentPage = 1;
        this.updatePaginatedItems();
    }

    handleFilterDateChange(event) {
        const { name, value } = event.target;
        this[name] = value;

        if (this.filterStartDate && this.filterEndDate) {
            const start = new Date(this.filterStartDate);
            const end = new Date(this.filterEndDate);
            if (start > end) {
                event.target.setCustomValidity('End date must be after start date');
                event.target.reportValidity();
                return;
            }
        }

        event.target.setCustomValidity('');
        event.target.reportValidity();

        this.currentPage = 1;
        this.updatePaginatedItems();
    }

    filteredSlotItems() {
        const startDate = this.filterStartDate ? new Date(this.filterStartDate) : null;
        const endDate = this.filterEndDate ? new Date(this.filterEndDate) : null;
        const status = this.selectedStatus;

        return this.fullSlotItems.filter(item => {
            let matches = true;

            if (startDate || endDate) {
                const itemDate = new Date(item.rawDate);
                itemDate.setHours(0, 0, 0, 0);
                if (startDate) startDate.setHours(0, 0, 0, 0);
                if (endDate) endDate.setHours(0, 0, 0, 0);
                if (startDate && itemDate < startDate) matches = false;
                if (endDate && itemDate > endDate) matches = false;
            }

            if (status && item.bookingstatus !== status) {
                matches = false;
            }

            return matches;
        });
    }

    updatePaginatedItems() {
        const filtered = this.filteredSlotItems();
        this.totalPages = Math.ceil(filtered.length / PAGE_SIZE) || 1;
        if (this.currentPage > this.totalPages) {
            this.currentPage = this.totalPages;
        }
        const startIdx = (this.currentPage - 1) * PAGE_SIZE;
        const endIdx = startIdx + PAGE_SIZE;
        this.slotItems = filtered.slice(startIdx, endIdx);
    }

    handleInput(event) {
        const { name, value } = event.target;
        this[name] = value;

        if (name === 'bayNumber') {
            const bays = Number(value);
            const max = Number(this.remainingBays || 0);
            if (bays > max) {
                event.target.setCustomValidity(`Cannot allocate more than ${max} Available Bays`);
            } else if (bays <= 0) {
                event.target.setCustomValidity('Bays to Allocate must be greater than 0');
            } else {
                event.target.setCustomValidity('');
            }
        }

        if (name === 'duration') {
            const dur = Number(value);
            if (dur < 15 || dur > 60) {
                event.target.setCustomValidity('Duration must be between 15 and 60 minutes');
            } else {
                event.target.setCustomValidity('');
            }
        }

        if ((name === 'dayStart' || name === 'dayEnd') && this.dayStart && this.dayEnd) {
            if (this.dayEnd <= this.dayStart) {
                this.template.querySelector(`[name="${name}"]`)
                    .setCustomValidity('End time must be after start time');
            } else {
                this.template.querySelector(`[name="${name}"]`).setCustomValidity('');
            }
        }

        if (name === 'startDate') {
            const selected = new Date(value);
            const min = new Date(this.minStartDate);
            if (selected < min) {
                event.target.setCustomValidity('Start Date must be at least 15 days from today');
            } else {
                event.target.setCustomValidity('');
            }
        }

        event.target.reportValidity();

        if ((name === 'startDate' || name === 'endDate') && this.startDate && this.endDate) {
            this.checkRemainingBays();
        }
    }

    handlePrevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedItems();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedItems();
        }
    }

    toggleForm() {
        this.showForm = !this.showForm;
        this.showBackButton = this.showForm;
        this.errorMessage = '';
    }

    handleBack() {
        this.showForm = false;
        this.showBackButton = false;
        this.errorMessage = '';
    }

    fetchBayCount() {
        if (!this.serviceCenterId) return;
        getServiceBayCount({ serviceCenterId: this.serviceCenterId })
            .then(count => {
                this.bayCount = count;
            })
            .catch(error => this.handleError(error, 'Failed to load bay count'));
    }

    checkRemainingBays() {
        if (!this.serviceCenterId || !this.startDate || !this.endDate) return;
        getRemainingBays({
            serviceCenterId: this.serviceCenterId,
            startDate: this.startDate,
            endDate: this.endDate
        })
        .then(count => {
            this.remainingBays = count;
        })
        .catch(error => this.handleError(error, 'Failed to check available bays'));
    }

    createSlot() {
        this.errorMessage = '';
        createSlot({
            serviceCenterId: this.serviceCenterId,
            startDate: this.startDate,
            endDate: this.endDate,
            dayStartTime: this.formatTimeForApex(this.dayStart),
            dayEndTime: this.formatTimeForApex(this.dayEnd),
            serviceBaynumber: Number(this.bayNumber),
            slotDurationMins: Number(this.duration)
        })
        .then(() => {
            this.showToast('Success', 'Appointment slots created successfully', 'success');
            this.resetForm();
            return getCurrentContactServiceCenter();
        })
        .then(({ data }) => {
            if (data) {
                this.fullSlotItems = this.processSlotItems(data.asiList || []);
                this.currentPage = 1;
                this.updatePaginatedItems();
            }
            this.showForm = false;
            this.showBackButton = false;
        })
        .catch(error => {
            this.errorMessage = this.reduceError

            this.showToast('Error', this.errorMessage, 'error');
        });
    }

    resetForm() {
        this.startDate = null;
        this.endDate = null;
        this.dayStart = null;
        this.dayEnd = null;
        this.duration = 30;
        this.bayNumber = 0;
        this.remainingBays = null;
    }

    formatTimeForApex(timeString) {
        return timeString ? `${timeString}:00.000Z` : null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleError(error, defaultMessage) {
        console.error(error);
        this.errorMessage = this.reduceError(error) || defaultMessage;
        this.showToast('Error', this.errorMessage, 'error');
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        } else if (error?.body?.message) {
            return error.body.message;
        } else if (typeof error?.message === 'string') {
            return error.message;
        }
        return 'Unknown error occurred';
    }
}