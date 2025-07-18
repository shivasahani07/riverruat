import { LightningElement, api, track, wire } from 'lwc';
import getServiceCenters from '@salesforce/apex/AppointmentFormController.getServiceCenters';
import createAppointment from '@salesforce/apex/AppointmentFormController.createAppointment';
import getVehicleOwnerContacts from '@salesforce/apex/AppointmentFormController.getVehicleOwnerContacts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions'; // 🔁 Import this
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Ticket__c.Job_Card__r.Vehicle_Registration_Number__c'
];

export default class AppointmentForm extends LightningElement {
    @api recordId; // Ticket__c Id passed from the quick action
    @track serviceCenterOptions = [];
    @track selectedServiceCenter = '';
    @track vrn = '';
    @track appointmentDate = '';
    @track contactNumber = '';

    connectedCallback() {
        this.fetchServiceCenters();
        //this.fetchTicketData();
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredTicket({ error, data }) {
        if (data) {
            this.vrn = data.fields.Job_Card__r.value.fields.Vehicle_Registration_Number__c.value;
            console.log('this.vrn:', this.vrn);
        } else if (error) {
            console.error('Error fetching ticket:', error);
        }
    }

    @wire(getVehicleOwnerContacts, { ticketId: '$recordId'})
    wiredVehicleOwnerContacts( { error, data }){
        console.log('---------- INSIDE getVehicleOwnerContacts ------------');
        if(data){
            console.log('DATA : ', data);
            this.contactNumber = data;
        }
        if(error){
            console.log('ERROR : ', error);
        }
    }

    fetchServiceCenters() {
        getServiceCenters()
            .then(result => {
                this.serviceCenterOptions = result.map(acc => ({
                    label: acc.Name,
                    value: acc.Id
                }));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to load service centers',
                    variant: 'error'
                }));
            });
    }

    handleChange(event) {
        const { name, value } = event.target;
        this[name] = value;
    }

    handleSubmit() {
        console.log('----- handleSubmit triggered -------');
        if (!this.selectedServiceCenter || !this.vrn || !this.appointmentDate || !this.contactNumber) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Missing Fields',
                message: 'Please fill all fields.',
                variant: 'warning'
            }));
            return;
        }

        createAppointment({
            ticketId: this.recordId,
            accountId: this.selectedServiceCenter,
            vrn: this.vrn,
            appointmentDate: this.appointmentDate,
            contactNumber: this.contactNumber
        })
        .then(() => {
            console.log('------- Inside then --------');
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Appointment created successfully.',
                variant: 'success'
            }));

            // ✅ Close the quick action modal
            this.dispatchEvent(new CloseActionScreenEvent());

            this.resetForm();
        })
        .catch(error => {
            console.log('------- Inside error -------');
            console.log('------- ERROR : ', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Error creating appointment.',
                variant: 'error'
            }));
        });
    }

    resetForm() {
        this.selectedServiceCenter = '';
        this.vrn = '';
        this.appointmentDate = '';
        this.contactNumber = '';
    }
}