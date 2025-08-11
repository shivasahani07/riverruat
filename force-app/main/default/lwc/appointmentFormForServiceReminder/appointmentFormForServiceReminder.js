import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

import getvehicleRecord from '@salesforce/apex/AppointmentFormController.getvehicleRecord';
import getCurrentServiceCenter from '@salesforce/apex/AppointmentFormController.getCurrentServiceCenter';
import getSlotItems from '@salesforce/apex/AppointmentFormController.getSlotItems';
import createAppointmentforServiceAppointment from '@salesforce/apex/AppointmentFormController.createAppointmentforServiceAppointment';
import getPicklistValues from '@salesforce/apex/AppointmentFormController.getPicklistValues';

export default class AppointmentForm extends NavigationMixin(LightningElement) {
    @api recordId;

    @track selectedServiceCenter = '';
    @track appointmentDate = '';
    @track vrn = '';
    @track contactNumber = '';
    @track appointmentDecription = '';

    @track appointmentSlotId = '';
    @track selectedSlotItem = '';
    @track slotSearchTriggered = false;
    @track slotsAvailable = false;
    @track slotItemOptions = [];
    @track showDescriptionField = false;

    minDate;
    serviceCenterId = '';
    serviceCenterName = '';

    @wire(getCurrentServiceCenter)
    wiredCenterName({ error, data }) {
        if (data) {
            this.serviceCenterId = data.accountId;
            this.serviceCenterName = data.accountName;
        } else if (error) {
            console.error('Could not get center name', error);
        }
    }

    connectedCallback() {
        this.loadPicklistValues();
        if (!this.recordId) {
            
            const url = window.location.href;
            const match = url.match(/\/case\/([^/]+)/);
            if (match) {
                this.recordId = match[1];
            }
        }

        if (this.recordId) {
            this.fetchVehicleData();
        }

        this.setMinDate();
    }


     loadPicklistValues() {
        getPicklistValues({ objectApiName: 'ServiceAppointment', fieldApiName: 'Type_Of_Requested_Services__c' }) // Example: Account.Industry
            .then(result => {
                this.options = result.map(value => ({
                    label: value,
                    value: value
                }));
            })
            .catch(error => {
                console.error('Error loading picklist values', error);
            });
    }

    setMinDate() {
        const today = new Date();
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = String(today.getDate()).padStart(2, '0');
        this.minDate = `${year}-${month}-${day}`;
    }

    fetchVehicleData() {
        getvehicleRecord({ sourceIdStr: this.recordId })
            .then(r => {
                if (r) {
                    this.vrn = r.VehicleRegistrationNumber || '';
                    this.contactNumber = r.CurrentOwner?.Phone || '';
                }
            })
            .catch(() => this.showToast('Error', 'Failed to load vehicle data', 'error'));
    }

    handleDateChange(e) {
        this.appointmentDate = e.target.value;

        const selectedDate = new Date(this.appointmentDate);
        const today = new Date();

        selectedDate.setHours(0, 0, 0, 0);
        today.setHours(0, 0, 0, 0);

        if (selectedDate >= today) {
            this.loadSlotItems();
        } else {
            this.appointmentSlotId = '';
            this.slotItemOptions = [];
            this.slotsAvailable = false;
            this.selectedSlotItem = '';
        }
    }

    handleSlotItemChange(e) {
        this.selectedSlotItem = e.detail.value;
    }

    handleAppointmentDesc(e) {
        this.appointmentDecription = e.detail.value;
    }

    handleSelectServices(event) {
        this.selectedValue = event.detail.value;
        console.log('Selected Service:', this.selectedValue);
    }

    loadSlotItems() {
        if (!this.serviceCenterId || !this.appointmentDate) return;

        this.slotSearchTriggered = true;

        getSlotItems({
            serviceCenterId: this.serviceCenterId,
            appointmentDate: this.appointmentDate
        })
            .then(res => {
                this.appointmentSlotId = res.slotId;

                const items = (res.slotItems || []).map(i => {
                    let start = new Date(i.Start_Time__c);
                    let end = new Date(i.End_Time__c);

                    // Convert UTC to IST
                    start.setMinutes(start.getMinutes() - 330);
                    end.setMinutes(end.getMinutes() - 330);

                    const options = { hour: '2-digit', minute: '2-digit', hour12: true };

                    return {
                        label: `${i.Name} | ${start.toLocaleTimeString([], options)} - ${end.toLocaleTimeString([], options)}`,
                        value: i.Id
                    };
                });

                this.slotItemOptions = items;
                this.slotsAvailable = items.length > 0;

                this.showDescriptionField = this.slotsAvailable;
                this.selectedSlotItem = '';
            })
            .catch(err => {
                this.appointmentSlotId = '';
                this.slotItemOptions = [];
                this.slotsAvailable = false;
                this.showToast(
                    'Error',
                    err?.body?.message || 'Failed to load slot items',
                    'error'
                );
            });
    }

    handleSubmit() {
        if (this.isSubmitDisabled) {
            this.showToast('Missing Fields',
                'Please fill all fields including slot item.',
                'warning');
            return;
        }

        createAppointmentforServiceAppointment({
            serviceAppId: this.recordId,
            accountId: this.serviceCenterId,
            vrn: this.vrn,
            appointmentDate: this.appointmentDate,
            contactNumber: this.contactNumber,
            serviceType :this.selectedValue,
            slotId: this.appointmentSlotId,
            slotItemId: this.selectedSlotItem,
            appointmentDecription: this.appointmentDecription
        })
            .then(appointmentId => {
                this.showToast('Success', 'Appointment created successfully.', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: appointmentId,
                        objectApiName: 'Appointment__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(err => this.showToast('Error',
                err?.body?.message || 'Error creating appointment.',
                'error'));
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }

    get isSubmitDisabled() {
        const baseFieldsFilled = this.serviceCenterId &&
            this.vrn &&
            this.contactNumber &&
            this.appointmentDate &&
            this.selectedSlotItem &&
            this.appointmentSlotId;

        return this.showDescriptionField
            ? !(baseFieldsFilled && this.appointmentDecription)
            : !baseFieldsFilled;
    }
}