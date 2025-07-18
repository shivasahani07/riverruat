import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord, createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Schema imports
import VRN_FIELD from '@salesforce/schema/Appointment__c.VRN__c';
import CONTACT_FIELD from '@salesforce/schema/Appointment__c.Contact_Number__c';
import SERVICE_CENTER_FIELD from '@salesforce/schema/Appointment__c.Service_Center__c';
import SERVICE_CENTER_NAME from '@salesforce/schema/Appointment__c.Service_Center__r.Name';
import APPOINTMENT_DATE_FIELD from '@salesforce/schema/Appointment__c.Appointment_Date__c';
import STATUS_FIELD from '@salesforce/schema/Appointment__c.Status__c';

const FIELDS = [VRN_FIELD, CONTACT_FIELD, SERVICE_CENTER_FIELD, SERVICE_CENTER_NAME, APPOINTMENT_DATE_FIELD];

export default class RescheduleAppointmentForm extends LightningElement {
    @api recordId;

    vrn;
    contactNumber;
    appointmentDate;
    serviceCenterId;
    serviceCenterName;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAppointment({ error, data }) {
        if (data) {
            this.vrn = getFieldValue(data, VRN_FIELD);
            this.contactNumber = getFieldValue(data, CONTACT_FIELD);
            this.appointmentDate = getFieldValue(data, APPOINTMENT_DATE_FIELD);
            this.serviceCenterId = getFieldValue(data, SERVICE_CENTER_FIELD);
            this.serviceCenterName = getFieldValue(data, SERVICE_CENTER_NAME);
        } else if (error) {
            console.error('Error fetching appointment record:', error);
        }
    }

    handleDateChange(event) {
        this.appointmentDate = event.target.value;
    }

    async handleSubmit() {
        try {
            // Step 1: Create new Appointment
            const newFields = {
                VRN__c: this.vrn,
                Contact_Number__c: this.contactNumber,
                Service_Center__c: this.serviceCenterId,
                Appointment_Date__c: this.appointmentDate
            };

            const recordInput = {
                apiName: 'Appointment__c',
                fields: newFields
            };

            await createRecord(recordInput);

            // Step 2: Update current Appointment's status
            await updateRecord({
                fields: {
                    Id: this.recordId,
                    Status__c: 'Reschedule'
                }
            });

            // Success feedback
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Appointment rescheduled and new appointment created.',
                    variant: 'success'
                })
            );
        } catch (error) {
            console.error('Error during rescheduling:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Something went wrong.',
                    variant: 'error'
                })
            );
        }
    }
}