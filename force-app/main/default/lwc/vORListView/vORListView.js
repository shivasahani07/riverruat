import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getRecentVORRecorDetails from '@salesforce/apex/VORHelper.getRecentVORRecorDetails';
import updateVORRecords from '@salesforce/apex/VORHelper.updateVORRecords';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import VOR_OBJECT from '@salesforce/schema/VOR__c';
//import STATUS_FIELD from '@salesforce/schema/VOR__c.Status__c';
import VOR_REASON_FIELD from '@salesforce/schema/VOR__c.VOR_Reason__c';

export default class VORListView extends NavigationMixin(LightningElement) {
    @api recordId;
    @track vors = [];
    @track error;
    @track isLoading = true;
    @track isSaving = false;
    @track fetchedVORS = [];
    @track statusOptions = [];

    editingVorId = null;
    editedStatusValue = null;
    wiredVorsResult;

    // Fetch object info to get recordTypeId
    @wire(getObjectInfo, { objectApiName: VOR_OBJECT })
    objectInfo;

    // Fetch dynamic picklist values for Status__c
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: VOR_REASON_FIELD
    })
    wiredStatusValues({ data, error }) {
        if (data) {
            this.statusOptions = data.values.map(option => ({
                label: option.label,
                value: option.value
            }));
        } else if (error) {
            console.error('Error loading status picklist values:', error);
            this.showToast('Error', 'Failed to load status picklist values.', 'error');
        }
    }

    connectedCallback() {
        if (!this.recordId) {
            const url = window.location.href;
            const match = url.match(/\/workorder\/([^/]+)/);
            if (match) {
                this.recordId = match[1];
            }
        }
    }

    @wire(getRecentVORRecorDetails, { jobcardId: '$recordId' })
    wiredVors(result) {
        this.wiredVorsResult = result;
        const { data, error } = result;

        if (data && Array.isArray(data)) {
            this.fetchedVORS = data.filter(v => !v.VOR_Reason__c);
            this.vors = this.fetchedVORS.map(vor => {
                if (!vor || !vor.Id) return null;
                return {
                    ...vor,
                    vorUrl: `/${vor.Id}`,
                    formattedCreatedDate: this.formatDate(vor?.CreatedDate),
                    isEditingStatus: false,
                    WorkOrderNumber: vor?.Job_Card__r?.WorkOrderNumber || '',
                    workOrderUrl: `/${vor?.Job_Card__c}`
                };
            }).filter(vor => vor !== null);

            this.error = undefined;
        } else if (error) {
            this.vors = [];
            this.error = error;
            console.error('Error loading VORs:', JSON.stringify(error));
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }

        this.isLoading = false;
        this.cancelEditing();
    }

    get hasVors() {
        return Array.isArray(this.vors) && this.vors.length > 0;
    }

    get vorCount() {
        return this.vors?.length || 0;
    }

    getStatusClass(status) {
        const statusMap = {
            'Ready for Delivery': 'slds-text-color_success',
            'Rework': 'slds-text-color_error',
            'Awaiting Diagnosis': 'slds-text-color_warning'
        };
        return statusMap[status] || 'slds-text-color_default';
    }

    formatDate(dateString) {
        return dateString ? new Date(dateString).toLocaleDateString() : '';
    }

    handleStatusClick(event) {
        const vorId = event.currentTarget?.dataset?.vorId;
        if (!vorId) return;

        this.editingVorId = vorId;
        this.vors = this.vors.map(vor => ({
            ...vor,
            isEditingStatus: vor.Id === vorId
        }));

        const targetVor = this.vors.find(vor => vor.Id === vorId);
        this.editedStatusValue = targetVor?.Status__c || null;
    }

    handleStatusChange(event) {
        const newStatus = event.detail.value;
        this.editedStatusValue = newStatus;
    }

    handleSaveStatus() {
        const vorId = this.editingVorId;
        const newStatus = this.editedStatusValue;

        if (!vorId || !newStatus) {
            this.showToast('Error', 'Invalid VOR or status.', 'error');
            return;
        }

        this.isSaving = true;

        updateVORRecords({ vorId, newStatus })
            .then(() => {
                this.showToast('Success', 'VOR updated successfully.', 'success');
                this.cancelEditing();
                return refreshApex(this.wiredVorsResult);
            })
            .catch(error => {
                console.error('Error updating VOR:', error);
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    handleCancelEdit() {
        this.cancelEditing();
    }

    cancelEditing() {
        this.editingVorId = null;
        this.editedStatusValue = null;
        this.vors = this.vors.map(vor => ({ ...vor, isEditingStatus: false }));
    }

   
    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredVorsResult)
            .catch(error => {
                console.error('Refresh error:', error);
                this.showToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            })
        );
    }

    get hasEditing() {
        return this.vors.some(vor => vor.isEditingStatus);
    }

    getErrorMessage(error) {
        try {
            if (error?.body?.message) return error.body.message;
            if (Array.isArray(error?.body)) return error.body.map(e => e.message).join(', ');
            return error?.message || 'An unknown error occurred.';
        } catch (err) {
            return 'An unknown error occurred.';
        }
    }
}