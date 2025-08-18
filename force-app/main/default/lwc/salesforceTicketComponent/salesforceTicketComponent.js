import { LightningElement, track, wire } from 'lwc';

import getSalesforceSupportRecords from '@salesforce/apex/SalesforceTicketController.getSalesforceSupportRecords';
import getContactAndUserOptions from '@salesforce/apex/SalesforceTicketController.getContactAndUserOptions';
import createTicketAssignment from '@salesforce/apex/SalesforceTicketController.createTicketAssignment';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Get the Priority Field from Ticket_Assignment__c
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import TICKET_ASSIGNMENT_OBJECT from '@salesforce/schema/Ticket_Assignment__c';
import PRIORITY_FIELD from '@salesforce/schema/Ticket_Assignment__c.Priority__c';

export default class SalesforceTicketComponent extends LightningElement {

    @track ssRecords = [];
    @track ssError;
    @track selectedRecord;
    @track selectedOption = null;
    @track selectedOptionn;
    @track contactRecords = [];
    @track contactError;
    @track contactOptions = [];

    @track allOptions = [];
    @track filteredOptions = [];
    @track contactId;
    @track userId;
    @track searchKey;

    @track showModal = false;
    @track remarks;
    @track priority;

    @track priorityOptions = [];
    @track value;

    // Get the Priority Field of Ticket_Assignment__c Object
    @wire(getObjectInfo, { objectApiName: TICKET_ASSIGNMENT_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: PRIORITY_FIELD
    })
    wiredPicklist({ data, error }) {
        if (data) {
            this.priorityOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }


    // Get All Salesforce Support Records
    @wire(getSalesforceSupportRecords)
    wiredRecords({ data, error }) {

        if (data) {
            this.ssRecords = data;
            this.ssError = undefined;
        }
        else if (error) {
            console.log('ssError : ' + error);
            this.ssError = error;
            this.ssRecords = [];
        }
    }

    // Get All Contact and Users Records
    @wire(getContactAndUserOptions)
    wiredContactUsers({ data, error }) {

        if (data) {
            this.allOptions = data.map(item => ({
                label: item.label,
                value: item.value,
                type: item.type
            }));
        }
        else if (error) {
            console.error('Error loading contact user options', error);
        }
    }

    isDropdownOpen;
    toggleDropdown() {
        this.isDropdownOpen = !this.isDropdownOpen;
        this.selectedOptionn = false;
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.filteredOptions = this.allOptions.filter(opt =>
            opt.label.toLowerCase().includes(this.searchKey)
        );

        if (!this.searchKey || this.searchKey.trim() === '') {
            this.userId = null;
            this.contactId = null;
        }

        //this.toggleDropdown();
        this.isDropdownOpen = true;
    }

    handleSelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        console.log('selectedId : ' + selectedId);
        const selectedType = event.currentTarget.dataset.type;
        const selectedOption = this.allOptions.find(opt => opt.value === selectedId);
        this.selectedOptionn = true;


        if (selectedType === 'Contact') {
            this.contactId = selectedId;
            this.userId = null;
        } else {
            this.userId = selectedId;
            this.contactId = null;
        }

        // Set the input field to selected label
        this.searchKey = selectedOption ? selectedOption.label : '';

        // Hide the dropdown after selection
        //this.filteredOptions = [];
        this.isDropdownOpen = false;
    }

    handleViewDetails(event) {
        const recordId = event.target.dataset.id;
        console.log('recordId : ' + recordId);

        this.selectedRecord = this.ssRecords.find(rec => rec.Id === recordId);

        console.log('selectedRecord : ' + this.selectedRecord);
    }

    handleAssign(event) {
        const recordId = event.target.dataset.id;
        this.selectedRecord = this.ssRecords.find(rec => rec.Id === recordId);
        this.showModal = true;
    }

    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
        console.log('Selected User : ' + this.selectedUserId);
    }

    handleRemarks(event) {
        this.remarks = event.detail.value ? event.detail.value : '';
    }

    handleBack(event) {
        this.selectedRecord = null;
    }

    closeModal() {
        this.showModal = false;
        this.selectedUserId = null;
        this.resetFormFields();
    }

    saveAssignment() {
        console.log(`Assigning ticket ${this.selectedRecord.Id} to user ${this.selectedUserId}`);

        // Validation
        if (!this.userId && !this.contactId) {
            this.showNotification('Error', 'Please select either a User or a Contact.', 'error');
            return;
        }
        if (!this.remarks || this.remarks.trim() === '') {
            this.showNotification('Error', 'Remarks are required.', 'error');
            return;
        }
        if (!this.priority || this.priority.trim() === '') {
            this.showNotification('Error', 'Priority is required.', 'error');
            return;
        }

        createTicketAssignment({ ticketId: this.selectedRecord.Id, userId: this.userId, contactId: this.contactId, remarks: this.remarks, priority: this.priority })
            .then(data => {
                console.log('Ticket Assignment Data : ' + data);
                this.showNotification('Success', data, 'success');
            })
            .catch(error => {
                console.log('Ticket Assignment Error : ' + error);
                this.showNotification('Error', error, 'error');
            });

        this.closeModal();
        this.resetFormFields();

    }

    showNotification(titleText, messageText, variant) {
        const evt = new ShowToastEvent({
            title: titleText,
            message: messageText,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    clearSelection() {
        this.selectedOptionn = false;
        this.searchKey = '';
        this.isDropdownOpen = false;
    }

    handlePriorityChange(event) {
        this.priority = event.detail.value;
    }


    resetFormFields() {
        this.searchKey = '';
        this.filteredOptions = [];
        // this.isDropdownOpen = false;
        this.userId = null;
        this.contactId = null;
        this.remarks = '';
        this.priority = '';
        this.selectedOptionn = false;
    }

}