import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

import getvehicleRecord from '@salesforce/apex/AppointmentFormController.getvehicleRecord';
import getCurrentServiceCenter from '@salesforce/apex/AppointmentFormController.getCurrentServiceCenter';
import getSlotItems from '@salesforce/apex/AppointmentFormController.getSlotItems';
import createAppointmentforServiceAppointment from '@salesforce/apex/AppointmentFormController.createAppointmentforServiceAppointment';

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
    minDate;
    showDescriptionField = false;

    serviceCenterId = '';
    serviceCenterName = '';

    @wire(getCurrentServiceCenter)
    wiredCenterName({ error, data }) {
        if (data) {
            console.log('data : ', data);
            this.serviceCenterId = data.accountId;
            this.serviceCenterName = data.accountName;
            console.log('this.serviceCenterName : ', this.serviceCenterName);
        } else if (error) {
            console.error('Could not get center name', error);
        }
    }

    connectedCallback() {
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

    setMinDate() {
        const today = new Date();
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0'); // Month is 0-based
        const day = String(today.getDate()).padStart(2, '0');
        this.minDate = `${year}-${month}-${day}`;
        console.log('this.minDate : ', this.minDate);
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

    handleServiceCenterChange(e) {
        this.selectedServiceCenter = e.detail.recordId;
        this.loadSlotItems();
    }

    // handleDateChange(e) {
    //     this.appointmentDate = e.target.value;
    //     this.loadSlotItems();
    // }

    handleDateChange(e){
        this.appointmentDate = e.target.value;

        const selectedDate = new Date(this.appointmentDate);
        const today = new Date();

        selectedDate.setHours(0, 0, 0, 0);
        today.setHours(0, 0, 0, 0);

        if(selectedDate >= today){
            this.loadSlotItems();
        }
        else {
            this.appointmentSlotId = '';
            this.slotItemOptions = [];
            this.slotsAvailable = false;
            this.selectedSlotItem = '';
        }
    }


    handleSlotItemChange(e) {
        this.selectedSlotItem = e.detail.value;
    }

    handleAppointmentDesc(e){
        this.appointmentDecription = e.detail.value;
    }

   @track slotsAvailable = false; // <-- new tracked property

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

                // Convert from UTC to IST by subtracting 5 hours 30 minutes (330 mins)
                start.setMinutes(start.getMinutes() - 330);
                end.setMinutes(end.getMinutes() - 330);

                const options = { hour: '2-digit', minute: '2-digit', hour12: true };

                return {
                    label: ` ${i.Name} | ${start.toLocaleTimeString([], options)} - ${end.toLocaleTimeString([], options)}`,
                    value: i.Id
                };
            });

            this.slotItemOptions = items;
            this.slotsAvailable = items.length > 0;

            if (this.slotsAvailable) {
                this.showDescriptionField = true;
            }

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
        debugger;
        if (!this.serviceCenterId || !this.vrn || !this.appointmentDate
            || !this.contactNumber || !this.selectedSlotItem
            || !this.appointmentSlotId) {

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
            slotId: this.appointmentSlotId,
            slotItemId: this.selectedSlotItem,
            appointmentDecription: this.appointmentDecription
        })
            .then(appointmentId => {
                this.showToast('Success', 'Appointment created successfully.', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());

                // Redirect to Appointment record
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

    get filter() {
        return {
            criteria: [
                {
                    fieldPath: 'Type',
                    operator: 'eq',
                    value: 'Service Center',
                }
            ]
        };
    }
}